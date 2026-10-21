# Small Shop Assistant 🏪🤖

A transactionally safe conversational assistant for small retail shop owners built using **n8n**, **Telegram**, **n8n Data Tables**, and an append-only **Google Sheets EventJournal**.

[![n8n](https://img.shields.io/badge/Workflow-n8n-EA4B71?style=for-the-badge&logo=n8n)](https://n8n.io)
[![Telegram](https://img.shields.io/badge/Interface-Telegram_Bot-24A1DE?style=for-the-badge&logo=telegram)](https://telegram.org)
[![Google Sheets](https://img.shields.io/badge/Ledger-Google_Sheets-34A853?style=for-the-badge&logo=googlesheets)](https://sheets.google.com)

---

## 📌 Project Overview

Small Shop Assistant allows kirana / small grocery shop owners to manage daily credit sales, cash sales, stock movements, and customer debt balances purely via Telegram messages. It enforces a strict 6-stage transaction lifecycle:

```
PREPARE ➔ PREVIEW ➔ APPROVAL TOKEN ➔ COMMIT VALIDATION ➔ VERIFIED JOURNAL WRITE ➔ CONFIRMATION
```

### Key Highlights
- 🔒 **Cryptographically Bound Single-Use Tokens**: Every transaction generates a 16-hex approval token bound to the canonical payload hash, shop ID, ledger revision, and actor ID (90-second expiry).
- 🛡️ **Race-Condition & Double-Commit Protection**: Enforces execution-ID locking to prevent concurrent commits from writing duplicate events.
- 🚫 **Zero False Successes**: Google Sheets appends are strictly error-isolated. If the write fails or times out, the ledger revision is **never** advanced.
- 📦 **Real-time Projections & Inventory Checks**: Automatically rejects transactions that exceed customer credit limits or physical inventory stock.
- 📊 **Dynamic Balance & Stock Lookups**: Check debtor balances (`BALANCE [customer]`) or stock counts (`STOCK [product]`) directly in Telegram.
- 🔄 **Edit & Supersede**: Modify pending transactions with `EDIT <token> <new command>` which burns the old token and issues a fresh proposal.

---

## 📂 Project Structure

```
Small-Shop-Assistant/
├── output/                                  # Upgraded & fully wired production workflows
│   ├── SSA-01-Telegram-Intake.json          # Main intake with universal dedupe & query routing
│   ├── SSA-02-Prepare-Preview.json          # Standalone test harness for validation
│   ├── SSA-02B-Resolve-and-Store-Pending.json # Stock/debt validation, projections & token generation
│   ├── SSA-03-Issue-Approval-Token.json     # Standalone approval token issuer with binding hash
│   ├── SSA-04-Commit-Validate-DryRun.json   # Live commit with token burning & Google Sheets append
│   ├── SSA-05-Cancel-or-Edit-Invalidate.json# Token cancellation & fresh proposal chaining for EDIT
│   └── README.md                            # Comprehensive architecture docs, schemas & checklist
│
├── SSA-01-Telegram-Intake.json              # Original baseline export (preserved)
├── SSA-02-Prepare-Preview.json              # Original baseline export (preserved)
├── SSA-02B-Resolve-and-Store-Pending.json   # Original baseline export (preserved)
├── SSA-03-Issue-Approval-Token.json         # Original baseline export (preserved)
├── SSA-04-Commit-Validate-DryRun.json       # Original baseline export (preserved)
├── SSA-05-Cancel-or-Edit-Invalidate.json   # Original baseline export (preserved)
└── README.md                                # Root repository guide
```

---

## 🚀 Quick Start & n8n Import

1. **Import Workflows**:
   - In n8n, navigate to **Workflows** ➔ **Import from File**.
   - Import all 6 files from the `output/` directory.
2. **Re-bind Data Tables**:
   - Link nodes to your workspace's local n8n Data Tables (`ssa_customers`, `ssa_products`, `ssa_ledger_state`, `ssa_pending_proposals`, `ssa_processed_updates`).
   - Detailed mapping guide is available in [`output/README.md`](output/README.md).
3. **Configure Credentials & Env**:
   - Set `OWNER_TELEGRAM_ID`, `SHOP_ID`, and `GOOGLE_SHEETS_JOURNAL_ID`.
   - Connect your Telegram Bot token and Google Sheets OAuth2 account.
4. **Activate**:
   - Turn on `SSA-01-Telegram-Intake`.

---

## 💬 Supported Commands

| Command | Action |
|---|---|
| `SALE <amount>` | Cash sale preview & approval token |
| `CREDIT <customer> <amount>` | Credit sale preview with customer debt projection |
| `REPAY <customer> <amount>` | Debt repayment preview |
| `STOCKIN <product> <qty> <unit>` | Inventory intake preview with stock projection |
| `STOCKOUT <product> <qty> <unit>` | Inventory deduction preview (rejects if insufficient) |
| `ORDER <customer> \| <prod> <qty> <unit>` | Customer order preview |
| `COMMIT <token>` | Consumes token, appends to Google Sheets EventJournal |
| `CANCEL <token>` | Burns token, cancels proposal |
| `EDIT <token> <new command>` | Supersedes old proposal, issues new token |
| `BALANCE [customer]` | Look up customer debt / credit limit or all shop debtors |
| `STOCK [product]` | Look up product inventory or total inventory summary |
| `HELP` | Show command reference |

---

## 📖 Complete Documentation

For the full architectural audit report, circuit breaker breakdown, Data Table & Google Sheets schemas, 20-scenario test matrix, and the live demo script, see:
👉 **[output/README.md](output/README.md)**
