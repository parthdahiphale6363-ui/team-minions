# Small Shop Assistant — Adversarial Audit & Structural Fixes Report

During system-level penetration testing and edge-case simulation, four critical vulnerabilities were uncovered in the baseline workflow exports. This document details each defect and the architectural fix applied in the production workflows.

---

## 1. Vulnerability 1: Concurrent Commit Race Condition

### Defect
When two concurrent requests arrived with the exact same approval token simultaneously:
1. Request 1 updated `status` to `COMMIT_VALIDATING`.
2. Request 2 matched 0 rows (since status was no longer `APPROVAL_ISSUED`).
3. However, Request 2 subsequently re-read the row by `event_id`, saw `status == 'COMMIT_VALIDATING'` (set by Request 1), and falsely assumed its own reservation succeeded.
4. **Impact**: Both requests proceeded to append duplicate entries to the Google Sheets EventJournal, violating idempotent ledger guarantees.

### Structural Fix
In `workflows/production/SSA-04-Commit-Validate-Write.json`:
- `Reserve Approval` stamps a unique execution lock ID `exec_lock_id` into `status_reason`.
- Node `Confirm Reservation` strictly evaluates:
  ```javascript
  if (r.status_reason !== 'LOCKED:' + lockId) {
    reasons.push('CONCURRENT_COMMIT_RACE_LOST');
  }
  ```
- Only the specific execution that actually performed the atomic update proceeds. Competitors are rejected immediately with `CONCURRENT_COMMIT_RACE_LOST`.

---

## 2. Vulnerability 2: False Success on Google Sheets Outage / Timeout

### Defect
The Google Sheets node `Append to Google Sheets Journal` was configured with `onError: continueRegularOutput`.
- When the Google Sheets API was unreachable, rate-limited (HTTP 429), or threw a server error (HTTP 500), n8n forwarded the error object to the next node.
- The workflow proceeded to increment the ledger revision and mark the proposal `COMMITTED`.
- The bot falsely notified the shopkeeper that the transaction succeeded, while no row was written to Google Sheets.

### Structural Fix
- The Google Sheets node is now configured with `onError: continueErrorOutput`.
- Output 0 (Success) advances to `Increment Ledger Revision` ➔ `Update Projections` ➔ `Mark COMMITTED`.
- Output 1 (Error) diverts to `Mark WRITE_FAILED` and triggers a high-priority failure notice to Telegram:
  `❌ COMMIT FAILED: WRITE UNVERIFIED. Google Sheets EventJournal could not be updated. Ledger revision unchanged.`

---

## 3. Vulnerability 3: Stale In-Memory Projections Post-Commit

### Defect
Upon transaction commitment, `SSA-04` marked the proposal committed, but did not update the customer's `current_debt` in `ssa_customers` or the product's `current_stock` in `ssa_products`.
- Subsequent balance and stock commands displayed stale numbers until manual sync.
- Credit limit checks permitted customers to exceed their credit threshold on subsequent purchases.

### Structural Fix
Added direct projection update nodes in `SSA-04`:
- For `CREDIT_SALE`: Atomically updates `ssa_customers.current_debt += amount`.
- For `REPAYMENT`: Atomically updates `ssa_customers.current_debt = max(0, current_debt - amount)`.
- For `STOCK_OUT` and `ACCEPTED_ORDER`: Atomically deducts `ssa_products.current_stock -= quantity`.
- For `STOCK_IN`: Atomically increases `ssa_products.current_stock += quantity`.

---

## 4. Vulnerability 4: Non-Functional Balance and Stock Commands

### Defect
The baseline intake workflow parsed `BALANCE` and `STOCK` commands, but returned a static placeholder message ("Read-only query recognised. Balance and stock lookups are not built yet. Look at Google Sheets.").

### Structural Fix
Integrated full read queries into `workflows/production/SSA-01-Telegram-Intake.json`:
- `BALANCE`:
  - Without argument: Queries all customers and calculates total shop debtor balance.
  - With customer name: Resolves customer and returns current debt and available credit.
- `STOCK`:
  - Without argument: Queries all products and generates an itemized stock list.
  - With product name: Resolves product and returns exact stock quantity and unit pricing.
