# Small Shop Assistant (n8n) — Complete Master Documentation & Deliverables

Welcome to the **Small Shop Assistant** project documentation. This package provides an end-to-end, transactionally safe conversational assistant for small retail shop owners built using **n8n**, **Telegram**, **n8n Data Tables**, and an append-only **Google Sheets EventJournal**.

---

## Table of Contents
1. [Executive Summary & Workflow Connection Map](#1-executive-summary--workflow-connection-map)
2. [Adversarial Audit & Four Structural Fixes](#2-adversarial-audit--four-structural-fixes)
3. [List of Nodes & Circuit Breaker Logic](#3-list-of-nodes--circuit-breaker-logic)
4. [Data Table & Google Sheets EventJournal Schemas](#4-data-table--google-sheets-eventjournal-schemas)
5. [Credential & Environment Variable Setup](#5-credential--environment-variable-setup)
6. [n8n Import & Configuration Instructions](#6-n8n-import--configuration-instructions)
7. [Step-by-Step 20-Scenario Testing Guide & Execution Status](#7-step-by-step-20-scenario-testing-guide--execution-status)
8. [Hackathon Live Demo Script](#8-hackathon-live-demo-script)
9. [Enterprise ACID: PostgreSQL / Supabase Migration Blueprint](#9-enterprise-acid-postgresql--supabase-migration-blueprint)
10. [Rollback Plan & Remaining Honest Limitations](#10-rollback-plan--remaining-honest-limitations)

---

## 1. Executive Summary & Workflow Connection Map

The Small Shop Assistant implements a strict 6-stage transaction lifecycle:
```
PREPARE ➔ PREVIEW ➔ APPROVAL TOKEN ➔ COMMIT VALIDATION ➔ VERIFIED JOURNAL WRITE ➔ CONFIRMATION
```

### Architecture Topology

```
+----------------------------------------------------------------------------------------------------+
|                                    TELEGRAM MESSAGING LAYER                                        |
|                               (Registered Owner: $env.OWNER_TELEGRAM_ID)                           |
+-------------------------------------------------+--------------------------------------------------+
                                                  | Webhook
                                                  v
+----------------------------------------------------------------------------------------------------+
|                                      SSA-01-Telegram-Intake                                        |
|  - Verify Owner Telegram ID                                                                        |
|  - Universal Deduplication (ssa_processed_updates)                                                 |
|  - Deterministic Command Parser (COMMIT / CANCEL / EDIT / SALE / CREDIT / REPAY / STOCK / QUERY)   |
+--------+--------------------------+------------------------------+--------------------+------------+
         |                          |                              |                    |
         | kind: TRANSACTION        | kind: COMMIT                 | kind: CANCEL/EDIT  | kind: QUERY
         v                          v                              v                    v
+-----------------------+  +-----------------------+  +-----------------------+  +-------------------+
|  SSA-02B-Resolve-and- |  |  SSA-04-Commit-       |  |  SSA-05-Cancel-or-    |  |  Query Handler    |
|  Store-Pending        |  |  Validate-Write       |  |  Edit-Invalidate      |  |  (BALANCE / STOCK |
|                       |  |                       |  |                       |  |   / HELP)         |
| - Validate Schema     |  | - Verify Owner/Format |  | - Verify Token & Owner|  | - Real customer & |
| - Resolve Customer/   |  | - Rebuild Binding Hash|  | - Invalidate Token    |  |   product lookups |
|   Product & Units     |  | - Atomic Token Burn   |  | - If CANCEL: Discard  |  |   from tables!    |
| - Verify Stock/Debt   |  |   (COMMIT_VALIDATING) |  | - If EDIT: Chain to   |  +-------------------+
| - Compute Projections |  | - Lock ID Verification|  |   SSA-02B with fresh  |
| - 16-Hex Crypto Token |  |   (Prevents races!)   |  |   payload & new token |
| - Store in Pending    |  | - Append to Google    |  +-----------------------+
|   (APPROVAL_ISSUED)   |  |   Sheets EventJournal |
| - Return Preview Msg  |  | - Verify Write Result |
+-----------------------+  | - Increment Revision  |
                           | - Update Debt & Stock |
                           |   Projections in DB   |
                           | - Mark COMMITTED      |
                           +-----------------------+
```

---

## 2. Adversarial Audit & Four Structural Fixes

During our second adversarial audit, four major system-level vulnerabilities were uncovered and fixed in `output/`:

### Fix 1: Elimination of Concurrent Commit Race via Execution-ID Lock
- **Defect Identified**: Previously, when two concurrent requests arrived with the same token, Request 1 updated the status to `COMMIT_VALIDATING`. Request 2's update matched 0 rows, but when Request 2 re-read the row by `event_id`, it saw `status == 'COMMIT_VALIDATING'` (set by Request 1) and assumed its own reservation succeeded, causing **both requests to write duplicate entries to Google Sheets**.
- **Fix Applied**: In `SSA-04-Commit-Validate-Write.json`, `Reserve Approval` stamps an execution-unique lock ID `exec_lock_id` into `status_reason`. Node `Confirm Reservation` strictly verifies:
  ```javascript
  if (r.status_reason !== 'LOCKED:' + lockId) reasons.push('CONCURRENT_COMMIT_RACE_LOST');
  ```
  Only the specific execution that actually performed the update can proceed; concurrent competitors abort immediately with `COMMIT_REJECTED`.

### Fix 2: Elimination of False Success on Google Sheets Failure
- **Defect Identified**: `Append to Google Sheets Journal` previously used `onError: "continueRegularOutput"`. If Google Sheets threw an error or timed out, n8n passed the error object directly into the ledger revision increment and marked the proposal `COMMITTED`, falsely replying to Telegram that the transaction succeeded!
- **Fix Applied**: `Append to Google Sheets Journal` now uses `onError: "continueErrorOutput"`.
  - Output 0 (Success): Advances to `Increment Ledger Revision` ➔ `Update Projections` ➔ `Mark COMMITTED`.
  - Output 1 (Error / Timeout): Diverts to `Mark WRITE_FAILED` and sends a failure notice:
    `❌ COMMIT FAILED: WRITE UNVERIFIED. Google Sheets EventJournal could not be updated. Ledger revision unchanged.`

### Fix 3: Real Database Debt & Stock Projection Updates
- **Defect Identified**: Previously, `SSA-04` marked the proposal committed but never updated `ssa_customers` or `ssa_products`. Subsequent queries and previews continued to display stale debt and stock numbers.
- **Fix Applied**: Added `Lookup Customer for Projection` ➔ `Update Customer Debt Projection` (for `CREDIT_SALE` and `REPAYMENT`), and `Lookup Product for Projection` ➔ `Update Product Stock Projection` (for `STOCK_IN`, `STOCK_OUT`, `ACCEPTED_ORDER`) in `SSA-04`. Projections are updated immediately after the journal write is confirmed.

### Fix 4: Real BALANCE and STOCK Query Lookups
- **Defect Identified**: `SSA-01` returned a static placeholder message ("look at Google Sheets") for `BALANCE` and `STOCK`.
- **Fix Applied**: Added real Data Table lookups in `SSA-01`:
  - `BALANCE`: Queries `ssa_customers` to show individual customer debt/credit limits or summarizes all shop debtors.
  - `STOCK`: Queries `ssa_products` to show individual product stock/pricing or summarizes total shop inventory.

---

## 3. List of Nodes & Circuit Breaker Logic

### Complete Circuit Breaker Safeguards
1. **Owner Authentication Gate**: Rejects any Telegram sender whose ID does not match `$env.OWNER_TELEGRAM_ID`.
2. **Update Deduplication Gate**: Checks `ssa_processed_updates`. Skips updates already marked `PROCESSED` or claimed within 120s.
3. **Format & Range Validator**: Validates required fields, positive amounts, valid units (`kg`, `g`, `litre`, `ml`, `packet`, `piece`, `dozen`), and currency (`INR`).
4. **Business Rule Gate**: Verifies `current_debt + amount <= credit_limit` and `quantity <= current_stock`.
5. **Ledger Revision Binding Gate**: Binds approval token to exact `ledger_revision`. Rejects if revision changed.
6. **Token Expiry Gate**: Enforces 90-second epoch limit (`$now.toMillis() <= expires_epoch`).
7. **Single-Use Reservation Lock**: Atomically burns `token_hash` and verifies execution lock ID.
8. **Journal Verification Gate**: Only increments revision and updates balances after Google Sheets append succeeds.

---

## 4. Data Table & Google Sheets EventJournal Schemas

### Google Sheets: `EventJournal` Tab

| Column Header | Format / Type | Description |
|---|---|---|
| `event_id` | String | Unique event identifier (`EVT-<uuid>`) |
| `transaction_id` | String | Human-readable transaction identifier (`TXN-YYYYMMDD-HHMMSS`) |
| `event_type` | String | `SALE`, `CREDIT_SALE`, `REPAYMENT`, `STOCK_IN`, `STOCK_OUT`, `ACCEPTED_ORDER` |
| `shop_id` | String | Shop identifier (`SHOP-001`) |
| `customer_id` | String | Resolved customer ID (`CUST-001`) or blank |
| `product_id` | String | Resolved product ID (`PROD-001`) or blank |
| `quantity` | Number | Quantity units or blank |
| `unit` | String | Unit of measure (`kg`, `packet`, etc.) |
| `amount` | Number | Monetary amount in INR |
| `currency` | String | Always `INR` |
| `original_event_id` | String | Linked compensating event ID if reversal |
| `payload_hash` | String | SHA-256 hash of canonical sorted payload |
| `actor_id` | String | Telegram sender ID of actor |
| `created_at` | String (ISO) | UTC timestamp of commitment |
| `revision` | Number | Monotonically increasing ledger revision number |
| `status` | String | `COMMITTED` |

### n8n Data Tables

1. **`ssa_pending_proposals`**: Stores draft proposals, cryptographic hashes, and execution lock IDs.
2. **`ssa_customers`**: Stores `customer_id`, `name`, `phone`, `current_debt`, `credit_limit`.
3. **`ssa_products`**: Stores `product_id`, `name`, `unit`, `current_stock`, `unit_price`.
4. **`ssa_ledger_state`**: Stores `shop_id`, `journal_id`, `revision`, `last_event_id`.
5. **`ssa_processed_updates`**: Stores `source_update_id`, `status` (`RECEIVED`, `PROCESSED`, `FAILED`).

---

## 5. Credential & Environment Variable Setup

### Environment Variables
Configure these in your n8n `.env` file:
```bash
# Shop Configuration
SHOP_ID="SHOP-001"
OWNER_TELEGRAM_ID="7973198714"

# Google Sheets Configuration
GOOGLE_SHEETS_JOURNAL_ID="Small_Shop_Assistant_Journal"
```

### Credentials in n8n
1. **Telegram API Account**: Name: `Telegram account` (Token from `@BotFather`).
2. **Google Sheets OAuth2 Account**: Name: `Google Sheets account`.

---

## 6. n8n Import & Configuration Instructions

1. In n8n UI, navigate to **Workflows** ➔ **Add Workflow** ➔ **Import from File**.
2. Import all 6 files from `c:\Users\Asus\OneDrive\Desktop\Small-Shop-Assistant\output\`:
   - `SSA-02-Prepare-Preview.json`
   - `SSA-02B-Resolve-and-Store-Pending.json`
   - `SSA-03-Issue-Approval-Token.json`
   - `SSA-04-Commit-Validate-DryRun.json`
   - `SSA-05-Cancel-or-Edit-Invalidate.json`
   - `SSA-01-Telegram-Intake.json`
3. **Re-bind Data Tables**:
   - In each workflow containing a Data Table node, ensure the table dropdown targets your instance's table name.
4. **Activate Intake**:
   - Set `SSA-01-Telegram-Intake` to **Active**.

---

## 7. Step-by-Step 20-Scenario Testing Guide & Execution Status

All 20 scenarios have been evaluated against our offline verification harness. The table below distinguishes **verified offline tests** from tests requiring a **live n8n instance and external API credentials**:

| # | Scenario | Test Input / Action | Expected Result | Verification Status |
|---|---|---|---|---|
| **1** | Valid preview | `SALE 200` | Returns Preview with Event ID, `COMMIT <token>` valid 90s. No write. | ✅ Verified Offline (Regex & Canonical Hash) |
| **2** | Ambiguous customer | `CREDIT Deshmukh 500` (if 2 match) | Returns `CLARIFICATION NEEDED` listing matching IDs & names. | ✅ Verified Offline (Resolution Logic) |
| **3** | Unknown product | `STOCKIN Quinoa 5 kg` | Returns `PROPOSAL REJECTED: Unknown product: Quinoa`. | ✅ Verified Offline (Resolution Logic) |
| **4** | Negative/invalid amount | `SALE -50` | Returns `PROPOSAL REJECTED: amount must be positive`. | ✅ Verified Offline (Schema Validator) |
| **5** | Insufficient stock | `STOCKOUT Sugar 100 kg` (have 50) | Returns `PROPOSAL REJECTED: Insufficient stock...`. | ✅ Verified Offline (Business Rule Engine) |
| **6** | Credit limit exceeded | `CREDIT Sunita 6000` (limit 5000) | Returns `PROPOSAL REJECTED: Credit limit exceeded...`. | ✅ Verified Offline (Business Rule Engine) |
| **7** | Correct, unexpired token | `COMMIT <valid_token>` | Appends row to Sheets, increments rev, updates debt/stock, confirms. | ⏳ Requires Live Google Sheets Credential |
| **8** | Incorrect token | `COMMIT 0123456789abcdef` | Returns `COMMIT REJECTED: TOKEN_NOT_FOUND_OR_ALREADY_USED`. | ✅ Verified Offline (Token Matcher) |
| **9** | Expired token | `COMMIT <token>` after 95s | Returns `COMMIT REJECTED: EXPIRED`. | ✅ Verified Offline (Epoch Expiry Logic) |
| **10** | Reused token | Send `COMMIT <token>` twice | 1st commits. 2nd returns `TOKEN_NOT_FOUND_OR_ALREADY_USED`. | ✅ Verified Offline (Single-Use Token Burn) |
| **11** | Altered payload | Modify canonical JSON in DB | Returns `COMMIT REJECTED: BINDING_MISMATCH`. | ✅ Verified Offline (SHA-256 Tamper Test) |
| **12** | Stale ledger revision | Advance revision in ledger table | Returns `COMMIT REJECTED: STALE_LEDGER_REVISION`. | ✅ Verified Offline (SHA-256 Binding Test) |
| **13** | Unauthorized sender | Message from non-owner ID | Returns `Unauthorized: this bot only accepts registered owner`. | ✅ Verified Offline (Auth Filter Logic) |
| **14** | Duplicate update ID | Re-send same update ID | Suppressed by deduplication node; skipped. | ⏳ Requires Live Telegram Webhook |
| **15** | Concurrent commits | Two simultaneous `COMMIT <token>` | Only lock winner writes; second rejected with `CONCURRENT_COMMIT_RACE_LOST`. | ✅ Verified Offline (Execution-ID Lock Logic) |
| **16** | CANCEL command | `CANCEL <token>` | Token burned, proposal marked `CANCELLED`. | ✅ Verified Offline (Invalidation Parser) |
| **17** | EDIT command | `EDIT <token> SALE 300` | Old token burned (`SUPERSEDED`), fresh preview & token issued. | ✅ Verified Offline (Edit Parser & Chaining) |
| **18** | Google Sheets error | Sheets API offline (500) | Proposal marked `WRITE_FAILED`, no false success, owner notified. | ✅ Verified Structure (onError Circuit Breaker) |
| **19** | Timeout during write | Network hiccup on append | Diverts to error handler, revision stays unchanged. | ⏳ Requires Live Network Simulator |
| **20** | Telegram delivery failure | Sheet write ok, Telegram fails | Event row remains permanently committed in Google Sheets. | ⏳ Requires Live Telegram Webhook |

---

## 8. Hackathon Live Demo Script

Follow this 3-minute script for a live demonstration:

### Step 1: Query Current Balances (30 seconds)
1. Send: `BALANCE`
2. **Show**: Bot returns real customer balances from `ssa_customers`:
   `📊 SHOP CREDIT BALANCE SUMMARY: Total Outstanding Debt: Rs 200`
3. Send: `STOCK`
4. **Show**: Bot returns real inventory counts from `ssa_products`:
   `📦 Sugar: 50 kg, Cooking Oil: 20 litre`

### Step 2: Safe Preview & Business Protection (45 seconds)
1. Send: `STOCKOUT Sugar 100 kg`
2. **Show**: Instant rejection: `Insufficient stock for Sugar. Available: 50 kg`.
3. Send: `CREDIT Sunita Deshmukh 500`
4. **Show**: Bot responds with formatted Preview:
   - Debt Projection: `Rs 200 ➔ Rs 700 (Limit: Rs 5000)`
   - Single-use Approval Token: `COMMIT <token>` (expires in 90 seconds).
   - *Point out that Google Sheets and ledger revision are completely untouched.*

### Step 3: Verified Commit to Google Sheets (45 seconds)
1. Send: `COMMIT <token>`
2. **Show Telegram Confirmation**: Transaction ID, Event ID, and Revision incremented.
3. **Switch to Google Sheets**: Show the newly appended row in `EventJournal` tab with matching `event_id` and `payload_hash`.
4. Send: `BALANCE Sunita Deshmukh`
5. **Show**: Updated balance immediately reflects committed debt: `Rs 700`!

### Step 4: Replay & Race Protection (30 seconds)
1. Send the exact same `COMMIT <token>` again.
2. **Show**: Bot rejects: `TOKEN_NOT_FOUND_OR_ALREADY_USED`. Token was burned permanently upon reservation.

### Step 5: Edit & Supersede Flow (30 seconds)
1. Send: `SALE 100` ➔ Copy token.
2. Send: `EDIT <token> SALE 150`
3. **Show**: Previous proposal marked `SUPERSEDED`, old token invalidated, and a brand new preview with a new approval token is returned.

---

## 9. Enterprise ACID: PostgreSQL / Supabase Migration Blueprint

If your production deployment requires strict, database-level ACID transactions (preventing any partial state if an n8n node crashes mid-execution), use this minimal migration path:

1. **Create Postgres Schema**:
   ```sql
   CREATE TABLE event_journal (
     event_id UUID PRIMARY KEY,
     transaction_id TEXT NOT NULL,
     event_type TEXT NOT NULL,
     shop_id TEXT NOT NULL,
     customer_id TEXT,
     product_id TEXT,
     quantity NUMERIC,
     amount NUMERIC,
     payload_hash TEXT NOT NULL,
     actor_id TEXT NOT NULL,
     revision INT NOT NULL,
     created_at TIMESTAMPTZ DEFAULT NOW()
   );
   ```
2. **Atomic Commit Procedure**:
   ```sql
   CREATE OR REPLACE FUNCTION commit_transaction(
     p_event_id UUID, p_token_hash TEXT, p_lock_id TEXT, p_journal JSONB
   ) RETURNS BOOLEAN AS $$
   DECLARE
     v_updated INT;
   BEGIN
     -- 1. Atomic reservation with row lock
     UPDATE ssa_pending_proposals 
     SET status = 'COMMIT_VALIDATING', status_reason = p_lock_id, token_hash = ''
     WHERE event_id = p_event_id AND status = 'APPROVAL_ISSUED' AND token_hash = p_token_hash;
     
     GET DIAGNOSTICS v_updated = ROW_COUNT;
     IF v_updated = 0 THEN RETURN FALSE; END IF;
     
     -- 2. Append to journal
     INSERT INTO event_journal (event_id, transaction_id, event_type, shop_id, customer_id, product_id, quantity, amount, payload_hash, actor_id, revision)
     VALUES ((p_journal->>'event_id')::UUID, p_journal->>'transaction_id', p_journal->>'event_type', p_journal->>'shop_id', p_journal->>'customer_id', p_journal->>'product_id', (p_journal->>'quantity')::NUMERIC, (p_journal->>'amount')::NUMERIC, p_journal->>'payload_hash', p_journal->>'actor_id', (p_journal->>'revision')::INT);
     
     -- 3. Increment ledger revision
     UPDATE ssa_ledger_state SET revision = revision + 1, last_event_id = (p_journal->>'event_id')::TEXT WHERE shop_id = p_journal->>'shop_id';
     
     -- 4. Mark committed
     UPDATE ssa_pending_proposals SET status = 'COMMITTED' WHERE event_id = p_event_id;
     
     RETURN TRUE;
   END;
   $$ LANGUAGE plpgsql;
   ```
3. In n8n `SSA-04`: Replace the separate Data Table and Google Sheets nodes with a single Postgres node calling `SELECT commit_transaction(...)`. This eliminates all distributed race windows.

---

## 10. Rollback Plan & Remaining Honest Limitations

### Rollback Plan
- Original exported JSON files in the workspace root remain completely untouched.
- To rollback, re-import the original 6 JSON files from `c:\Users\Asus\OneDrive\Desktop\Small-Shop-Assistant\`.

### Honest Architectural Limitations
1. **Google Sheets API Latency**: Sheets append calls take 500ms–2000ms. Under high traffic, rate limits (60 requests/minute) can be reached.
2. **Distributed Crash Boundary**: If the n8n container crashes exactly between the Google Sheets append and the ledger increment node, the proposal remains `COMMIT_VALIDATING` while the sheet entry was written. A manual reconciliation query against `EventJournal` by `event_id` is required to finalize the record.
3. **NLP Absence**: Commands require deterministic syntax. AI interpretation nodes can be placed in front of SSA-02B if freeform language is desired in the future.
