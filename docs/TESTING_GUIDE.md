# Small Shop Assistant — 20-Scenario Test Suite & Live Demo Guide

This testing guide provides a complete, auditable verification matrix for validating the safety, concurrency limits, and business logic of **Small Shop Assistant**.

---

## 1. Complete 20-Scenario Test Matrix

| # | Scenario Category | Test Input / Action | Expected Result | Verification Status |
|---|---|---|---|---|
| **1** | Valid preview | `SALE 200` | Returns Preview with Event ID, `COMMIT <token>` valid 90s. No write. | ✅ Verified Offline (Regex & Canonical Hash) |
| **2** | Ambiguous customer | `CREDIT Deshmukh 500` (matches 2 rows) | Returns `CLARIFICATION NEEDED` listing matching IDs & names. | ✅ Verified Offline (Resolution Logic) |
| **3** | Unknown product | `STOCKIN Quinoa 5 kg` | Returns `PROPOSAL REJECTED: Unknown product: Quinoa`. | ✅ Verified Offline (Resolution Logic) |
| **4** | Negative/invalid amount | `SALE -50` | Returns `PROPOSAL REJECTED: amount must be positive`. | ✅ Verified Offline (Schema Validator) |
| **5** | Insufficient stock | `STOCKOUT Sugar 100 kg` (only 50 in stock) | Returns `PROPOSAL REJECTED: Insufficient stock...`. | ✅ Verified Offline (Business Rule Engine) |
| **6** | Credit limit exceeded | `CREDIT Sunita 6000` (limit 5000) | Returns `PROPOSAL REJECTED: Credit limit exceeded...`. | ✅ Verified Offline (Business Rule Engine) |
| **7** | Correct, unexpired token | `COMMIT <valid_token>` | Appends row to Sheets, increments rev, updates debt/stock, confirms. | ⏳ Requires Live Google Sheets Credential |
| **8** | Incorrect token | `COMMIT 0123456789abcdef` | Returns `COMMIT REJECTED: TOKEN_NOT_FOUND_OR_ALREADY_USED`. | ✅ Verified Offline (Token Matcher) |
| **9** | Expired token | `COMMIT <token>` after 95 seconds | Returns `COMMIT REJECTED: EXPIRED`. | ✅ Verified Offline (Epoch Expiry Logic) |
| **10** | Reused token | Send `COMMIT <token>` twice | 1st commits. 2nd returns `TOKEN_NOT_FOUND_OR_ALREADY_USED`. | ✅ Verified Offline (Single-Use Token Burn) |
| **11** | Altered payload | Modify canonical JSON in DB | Returns `COMMIT REJECTED: BINDING_MISMATCH`. | ✅ Verified Offline (SHA-256 Tamper Test) |
| **12** | Stale ledger revision | Advance revision in ledger table | Returns `COMMIT REJECTED: STALE_LEDGER_REVISION`. | ✅ Verified Offline (SHA-256 Binding Test) |
| **13** | Unauthorized sender | Message from non-owner ID | Returns `Unauthorized: this bot only accepts registered owner`. | ✅ Verified Offline (Auth Filter Logic) |
| **14** | Duplicate update ID | Re-send same Telegram update ID | Suppressed by deduplication node; skipped. | ⏳ Requires Live Telegram Webhook |
| **15** | Concurrent commits | Two simultaneous `COMMIT <token>` | Only lock winner writes; second rejected with `CONCURRENT_COMMIT_RACE_LOST`. | ✅ Verified Offline (Execution-ID Lock Logic) |
| **16** | CANCEL command | `CANCEL <token>` | Token burned, proposal marked `CANCELLED`. | ✅ Verified Offline (Invalidation Parser) |
| **17** | EDIT command | `EDIT <token> SALE 300` | Old token burned (`SUPERSEDED`), fresh preview & token issued. | ✅ Verified Offline (Edit Parser & Chaining) |
| **18** | Google Sheets error | Sheets API offline (500) | Proposal marked `WRITE_FAILED`, no false success, owner notified. | ✅ Verified Structure (onError Circuit Breaker) |
| **19** | Timeout during write | Network hiccup on append | Diverts to error handler, revision stays unchanged. | ⏳ Requires Live Network Simulator |
| **20** | Telegram delivery failure | Sheet write ok, Telegram fails | Event row remains permanently committed in Google Sheets. | ⏳ Requires Live Telegram Webhook |

---

## 2. Hackathon 3-Minute Live Demo Script

Use this streamlined sequence during demonstrations to showcase the business value and engineering depth of Small Shop Assistant:

### Minute 1: Instant Lookups & Business Rule Protection
1. **Send**: `BALANCE`
   - **Show**: Bot queries `ssa_customers` and displays outstanding credit summary:
     `📊 SHOP CREDIT BALANCE SUMMARY: Total Outstanding Debt: Rs 200`
2. **Send**: `STOCK`
   - **Show**: Bot queries `ssa_products` and shows live stock:
     `📦 Sugar: 50 kg, Cooking Oil: 20 litre, Basmati Rice: 100 kg`
3. **Send**: `STOCKOUT Sugar 100 kg`
   - **Show**: Immediate rejection before staging: `PROPOSAL REJECTED: Insufficient stock for Sugar. Available: 50 kg`.

### Minute 2: Transaction Preview & Verified Two-Phase Commit
1. **Send**: `CREDIT Sunita Deshmukh 500`
   - **Show**: Formatted preview displaying:
     - Customer resolved: `Sunita Deshmukh (CUST-001)`
     - Debt projection: `Rs 200 ➔ Rs 700 (Credit Limit: Rs 5,000)`
     - Approval command: `COMMIT <token>` (with 90s countdown timer)
     - *Demonstrate that Google Sheets and customer balance remain untouched.*
2. **Send**: `COMMIT <token>`
   - **Show**: Bot replies with confirmation:
     `✅ COMMITTED: Event EVT-... Transaction TXN-... Revision 1`
3. **Show Google Sheets**:
   - Switch to browser with Google Sheets open. Highlight the newly appended row in `EventJournal` with matching `event_id`, `amount: 500`, and `payload_hash`.
4. **Send**: `BALANCE Sunita Deshmukh`
   - **Show**: Balance has dynamically increased to `Rs 700`!

### Minute 3: Double-Commit Prevention & Edit/Supersede
1. **Re-send the exact same `COMMIT <token>`**:
   - **Show**: Immediate rejection: `TOKEN_NOT_FOUND_OR_ALREADY_USED`. Token was burned permanently upon first reservation.
2. **Send**: `SALE 100` ➔ Copy token.
3. **Send**: `EDIT <token> SALE 150`
   - **Show**: Bot burns the first proposal (`SUPERSEDED`), creates a new draft proposal for Rs 150, and issues a brand-new approval token.
4. **Send**: `CANCEL <new_token>`
   - **Show**: Proposal marked `CANCELLED`. Nothing committed.
