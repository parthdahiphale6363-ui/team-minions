# Shop Assistant AI

> Run sales, stock, and customer khata from one Telegram chat.

Shop Assistant AI is a Python-based Telegram bot concept for small shops. It lets an authorized shopkeeper record sales, purchases, payments, and inventory changes using everyday language, review each operation, and then confirm it before the records are saved to Google Sheets.

## Table of Contents

- [Why Shop Assistant AI?](#why-shop-assistant-ai)
- [Features](#features)
- [Screenshots](#screenshots)
- [How It Works](#how-it-works)
- [Architecture](#architecture)
- [Example Messages](#example-messages)
- [Customer Reminder Flow](#customer-reminder-flow)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Setup](#setup)
- [Configuration](#configuration)
- [Running the Bot](#running-the-bot)
- [Two-Phase Ledger Commit and Append-Only Event Journal](#two-phase-ledger-commit-and-append-only-event-journal)
- [Security and Data Integrity](#security-and-data-integrity)
- [Live Demonstration Checklist](#live-demonstration-checklist)
- [Known Limitations and Next Steps](#known-limitations-and-next-steps)
- [Contributing](#contributing)
- [License](#license)

## Project Screenshots

### Telegram bot interface
![Telegram bot home screen with supported commands and quick actions](telegram-home.png)

### Customer payment receipt
![Example customer payment receipt showing amount, method, and outstanding balance](payment-receipt.png)

### Customer khata and outstanding credit
![Example list of outstanding customer balances](outstanding-balances.png)

![Example total outstanding customer credit summary](outstanding-credit-summary.png)

## Why Shop Assistant AI?

Small shops often manage stock and customer credit using handwritten registers or memory. This can make it difficult to find old entries, spot low stock, track outstanding balances, and send payment reminders.

Shop Assistant AI aims to make everyday bookkeeping as simple as sending a message.

## Features

- **Natural-language bookkeeping:** Enter transactions in everyday language instead of filling out complex forms.
- **Sales tracking:** Record cash and credit sales after reviewing and confirming the details.
- **Purchase tracking:** Record incoming stock, purchase costs, suppliers, and low-stock limits.
- **Inventory management:** View stock, identify low-stock items, and prepare a reorder list.
- **Customer khata:** Track customer balances, statements, and payments by cash or UPI.
- **Bulk stock entry:** Add inventory items in bulk, with a review step before saving.
- **Customer reminders:** Send reminders only after customers opt in and the shopkeeper reviews and confirms the message.
- **Daily summary:** Review daily sales, collections, purchases, and items sold.
- **Google Sheets storage:** Keep stock and ledger records in a familiar, shareable spreadsheet.
- **Access control:** Restrict shop operations to configured Telegram user IDs.


## Screenshots

The screenshots below show the Telegram bot interface and example bookkeeping responses.

### Telegram bot home and quick actions

![Shop Assistant AI Telegram home screen](telegram-home.png)

The home screen introduces the supported workflows, including sales, stock and inventory, bulk stock entry, customer khata, customer payments, reports, and quick-action buttons.

### Customer payment confirmation

![Customer payment receipt](payment-receipt.png)

Example receipt for a payment from Ramesh showing the amount received, payment method, remaining outstanding balance, and transaction date.

### Outstanding customer balances

![Outstanding customer balances](outstanding-balances.png)

Example list of customer balances and the total outstanding amount. The bot labels these balances as unpaid customer credit, not cash received.

### Outstanding credit summary

![Outstanding customer credit summary](outstanding-credit-summary.png)

Example summary showing total outstanding customer credit and clarifying that the amount is unpaid credit rather than cash received.

> **Note:** These are example screenshots. Names, balances, and transaction details shown are sample data from the supplied images.

## How It Works

1. The shopkeeper sends a message or bot command in Telegram.
2. The bot checks whether the Telegram user is authorized.
3. The bot interprets the request and prepares a summary.
4. The shopkeeper reviews the summary and chooses **Confirm** or **Cancel**.
5. If confirmed, the bot writes the transaction to the ledger and updates stock when applicable.
6. The bot replies with the result.

Cancelled requests should not be saved. If the ledger is written successfully but the stock update fails, the bot warns the shopkeeper to check both sheets before retrying.

## Architecture

```text
Shopkeeper
    |
    v
Telegram App <---------------- Customer (opt-in reminders)
    |
    v
Telegram Bot API
    |
    v
Python Bot
    |-- main.py              Commands, buttons, and confirmations
    |-- config.py            Bot token, authorized IDs, startup checks
    |-- natural_language.py  Interprets everyday messages and bulk input
    |-- sheets.py            Reads and writes Google Sheets
    |
    v
Google Sheets
    |-- Stock
    |-- Ledger
    |-- Customer links
```

## Example Messages

Examples of messages the bot is intended to understand:

| Message | Purpose |
|---|---|
| `Show stock` | View current inventory |
| `Sold 2 kg rice for 120 cash` | Record a cash sale |
| `Sold 1 oil for 150 on credit to Ramesh` | Record a credit sale |
| `Ramesh paid 200 cash` | Record a customer payment |
| `Who owes money?` | Review outstanding customer balances |
| `Reorder list` | Identify items that need replenishment |

The bot should present a confirmation summary before saving supported changes.

## Customer Reminder Flow

1. The shopkeeper runs `/invitecustomer NAME` to generate a one-time linking code.
2. The code is shared privately with the customer.
3. The code expires after 15 minutes and can be used only once.
4. The customer opens the bot and sends `/link CODE`.
5. The shopkeeper runs `/remind NAME`, reviews the reminder, and confirms it.
6. The customer can stop reminders at any time using `/stopreminders`.

Only send reminders to customers who have opted in.

## Tech Stack

- **Language:** Python
- **Bot interface:** Telegram Bot API
- **Data storage:** Google Sheets
- **Configuration:** Environment variables / local environment configuration

The presentation identifies the core technologies above. Exact library versions and deployment-provider requirements depend on the implementation in the repository.

## Project Structure

The main modules described for this project are:

```text
.
├── main.py
├── config.py
├── natural_language.py
├── sheets.py
├── .env.example
├── .gitignore
└── README.md
```

> This is the intended high-level structure based on the project architecture. Keep only files that exist in your repository, and update this section if your actual structure differs.

## Setup

### Prerequisites

Before running the bot, arrange the following:

- Python installed on your system
- A Telegram bot token from [BotFather](https://t.me/BotFather)
- A Google Cloud project with the Google Sheets API enabled
- A Google spreadsheet prepared for the bot's stock and ledger data
- Google credentials with access to that spreadsheet
- Your Telegram user ID for the authorized-user allowlist

### 1. Clone the repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd <YOUR_PROJECT_DIRECTORY>
```

Replace the placeholders with your repository URL and project directory.

### 2. Create and activate a virtual environment

**Windows (PowerShell):**

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

**macOS / Linux:**

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Install dependencies

If the repository contains a dependency file, install from it:

```bash
pip install -r requirements.txt
```

If `requirements.txt` does not exist, install the dependencies documented by the source code and create a requirements file. Do not assume package names or versions without checking the imports used in your project.

### 4. Configure Google Sheets

1. Enable the Google Sheets API in your Google Cloud project.
2. Create or select the spreadsheet used by the bot.
3. Configure the credentials expected by the project's `sheets.py` module.
4. Grant the configured Google identity access to the spreadsheet.
5. Ensure the required Stock, Ledger, and customer-link data structures match what the code expects.

Follow the authentication method implemented in your code; the exact credential filename and spreadsheet identifier variable may differ.

### 5. Configure environment variables

Create a local `.env` file or configure environment variables in your hosting platform. Use the names expected by `config.py`.

Example template (replace the names with the exact variables used by your code):

```dotenv
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
AUTHORIZED_TELEGRAM_USER_IDS=your_telegram_user_id
LOG_LEVEL=INFO
```

If your implementation uses a Google service-account JSON file or additional spreadsheet settings, configure those separately as required by `sheets.py`.

**Never commit `.env`, bot tokens, private keys, or service-account credentials to GitHub.**

### 6. Start the bot

Run the entry point used by your project. If `main.py` is the configured entry point:

```bash
python main.py
```

Keep the process running and open the bot in Telegram to test it. Hosting is required if the bot must remain online continuously.

## Configuration

| Setting | Purpose |
|---|---|
| `TELEGRAM_BOT_TOKEN` | Authenticates the bot with Telegram |
| `AUTHORIZED_TELEGRAM_USER_IDS` | Restricts shop operations to approved Telegram users |
| `LOG_LEVEL` | Controls application logging verbosity |

These names are based on the project's documented configuration module. Verify the expected format for authorized IDs and any additional settings in `config.py` before running the application.


## Two-Phase Ledger Commit and Append-Only Event Journal

> **Safety invariant:** An AI model may propose a transaction, but it must never write directly to the ledger. Every ledger-changing operation must pass through **PREPARE → PREVIEW → COMMIT**. A transaction is not saved until the authorized shop owner explicitly approves the exact preview with a valid, one-time token.

This section describes the required workflow for the assigned high-difficulty twist. Treat each guarantee as implemented only after the corresponding code path and tests have been verified.

### 1. Transaction state machine

```text
Telegram update
      |
      v
Authenticate owner + deduplicate update
      |
      v
PREPARE: parse -> strict schema -> resolve identities -> validate rules
      |
      +---- missing/ambiguous/invalid ----> Ask clarification / reject
      |
      v
PREVIEW: normalize payload -> calculate expected changes
      -> bind one-time token to payload + shop + ledger revision
      |
      +---- EDIT <token> ... ------------> Invalidate old token, re-prepare
      +---- CANCEL <token> --------------> Discard pending proposal
      |
      v
COMMIT <token> received within 90 seconds
      |
      v
Revalidate owner, token, payload, expiry, revision and idempotency
      |
      +---- any check fails -------------> Reject without writing
      |
      v
Append journal event (idempotent event_id)
      |
      v
Verify journal by event_id
      |
      +---- outcome uncertain -----------> STATUS UNKNOWN; verify before retry
      |
      v
Update/rebuild deterministic projections
      |
      v
Reply SAVED + committed event_id
```

### 2. PREPARE — Parse and validate

Convert a Telegram message into a typed transaction proposal. Supported transaction types must include:

- Cash sale
- Credit sale / udhaar
- Customer repayment
- Stock-in / purchase
- Stock-out / stock adjustment
- Accepted order, if accepted orders affect the ledger or inventory

Validate the proposal before it can reach the preview stage:

- Required fields exist and have the expected types; reject unknown or extra critical fields.
- Amounts and quantities are positive and represented with appropriate numeric types (use decimal-safe money handling).
- Customer and item identities resolve unambiguously to known records.
- Stock availability and credit rules are checked when applicable.
- The proposal includes a unique `event_id`, the shop/spreadsheet identity, and the originating Telegram update/message ID when available.
- AI output (including Claude/Gemini output) is **untrusted input**. Parse it as data, validate it against a strict schema, and never execute instructions or accept its arithmetic as authoritative.
- If a name such as “Ramesh” matches multiple customers, or an item name is ambiguous, ask the owner to clarify. Do not guess, preview a guessed identity, or commit unresolved data.

Read-only requests such as “Ramesh ka udhaar kitna hai?” can continue without a commit token. Clearly label pending proposals as pending, and distinguish them from committed ledger facts.

### 3. PREVIEW — Show the exact normalized transaction

Before asking for approval, show a human-readable preview containing:

- Transaction type
- Customer, supplier, and/or item identity
- Quantity, unit price, and total amount where relevant
- Current and expected after-transaction customer balance or stock, where applicable
- The transaction's `event_id` and the confirmation instructions
- The token expiry window (90 seconds)

Example preview:

```text
PREVIEW — Credit sale
Customer: Ramesh (customer ID: CUST-004)
Item: Rice (item ID: ITEM-012)
Quantity: 2 kg
Total: ₹120.00
Current udhaar: ₹300.00
Expected udhaar after commit: ₹420.00

No changes have been saved yet.
Approve within 90 seconds by replying exactly:
COMMIT <one-time-token>

Or use:
EDIT <one-time-token> <corrected details>
CANCEL <one-time-token>
```

Generate a cryptographically strong, unique, one-time token. Bind it to the canonical normalized transaction payload, the shop/Google Sheets identity, and the ledger revision observed during preview. The committed payload must have the same meaning as the previewed payload. Do not regenerate transaction details from the original natural-language request at commit time.

### 4. COMMIT — Explicit, time-limited owner approval

A ledger write is permitted only when the authorized owner sends the exact command `COMMIT <token>` within 90 seconds of preview. At commit time, recheck all relevant conditions:

- Sender is an authorized owner.
- Command and token match exactly.
- Token exists, has not expired, and has not been used or invalidated.
- The normalized payload is unchanged.
- The shop/spreadsheet identity matches the token binding.
- The ledger revision is still the revision used for the preview.
- The Telegram update and event have not already been processed.

Reject plain `yes`, missing/wrong tokens, expired or reused tokens, changed payloads, unauthorized senders, and stale revisions without applying a transaction. A stale proposal must receive a fresh preview and require fresh approval.

Commands:

- `COMMIT <token>` — attempt to commit the exact pending proposal.
- `EDIT <token> <corrected details>` — invalidate the old token, re-prepare the edited proposal, and issue a new preview and token.
- `CANCEL <token>` — invalidate and discard the pending proposal without a ledger write.

Persist pending transaction state if approval must survive bot restarts. Do not allow an approval token for a ledger transaction to authorize a customer reminder. Reminder sending is a separate action with its own explicit owner approval.

### 5. Append-only Google Sheets event journal

Create a dedicated Google Sheets tab, for example `EventJournal`, to hold committed business events. Append a new row for each committed transaction. Do not silently overwrite or delete historical events.

Recommended journal fields:

| Field | Purpose |
|---|---|
| `event_id` | Unique ID for the prepared/committed event |
| `event_type` | Sale, credit sale, repayment, stock-in, stock-out, reversal, etc. |
| `status` | Committed event status; pending proposals are not committed journal facts |
| `shop_id` / spreadsheet ID | Identifies the ledger scope |
| `telegram_update_id` | Detects duplicate Telegram deliveries |
| `telegram_message_id` | Links the action to its source message where available |
| `created_at` | Event creation timestamp |
| `committed_at` | Commit timestamp |
| `customer_id` | Stable customer identity, when applicable |
| `item_id` | Stable inventory item identity, when applicable |
| `quantity` / `unit_price` / `amount` | Normalized transaction values |
| `reference_event_id` | Original event ID for a reversal or compensating event |
| `payload_hash` | Hash of the canonical normalized payload |
| `ledger_revision` | Revision used for validation/commit |
| `actor_telegram_user_id` | Authorized owner who approved the transaction |
| `reason` | Explanation for corrections or adjustments |

Use a stable schema and document any additional fields required by the implementation. A unique `event_id` must be assigned to every prepared and committed event. A prepared event is not a committed business fact until the commit is verified.

**Corrections:** Never edit the original committed event to correct history. Append a reversal or compensating event with its own unique `event_id`, a reference to the original `reference_event_id`, and a reason. Apply the correction as a new event in the deterministic projection.

### 6. Idempotency and duplicate protection

Telegram may redeliver updates, and users may repeat commands. Protect both preparation and commitment:

- Record processed Telegram update IDs and reject duplicates.
- Enforce uniqueness for committed `event_id` values.
- Make repeated `COMMIT <token>` commands unable to apply the transaction twice.
- Mark or consume a token atomically with respect to the application's commit logic; do not rely only on in-memory flags if multiple workers or restarts are possible.
- Handle out-of-order messages safely. A commit received before its matching preview/token exists must not write anything.
- If an update is replayed, return the known status/result where possible rather than applying it again.
- Where Google Sheets cannot enforce uniqueness or provide an atomic compare-and-append operation, document the concurrency limitation and use a serialized commit mechanism plus read-back verification. Do not claim database-grade atomicity from Sheets alone.

### 7. Deterministic balances and stock

Customer balances and stock-on-hand must be derived from committed journal events, or from documented projections rebuilt deterministically from those events. AI-generated arithmetic and manually edited running totals are not authoritative.

For each projection, document the event types and sign conventions. For example, a credit sale increases the customer's outstanding balance; a repayment decreases it; stock-in increases on-hand quantity; a sale or stock-out decreases it. Reversals and compensating events apply the opposite or correcting effect by reference to the original event.

The preview must calculate its before/after values from the committed event history or a verified projection. If the revision changes between preview and commit, reject the approval as stale and generate a fresh preview.

### 8. Verified writes, failures, and recovery

Only reply **Saved** after the journal write has been read back and verified by `event_id` and the saved payload. Include the committed `event_id` in the success response.

Use clear outcomes:

- **NOT COMMITTED** — validation failed, approval was invalid, or the system can establish that no event was committed.
- **STATUS UNKNOWN** — the write may have reached Google Sheets but its outcome cannot yet be verified.
- **SAVED** — the expected journal event was found and its identity/payload were verified.

If Google Sheets is unavailable, a revision changes, the workflow times out, or a write result is ambiguous, do not claim success. For uncertain outcomes, query the journal by `event_id` before retrying. If the event already exists and matches the intended payload, return its verified status; if it exists with a different payload, stop and raise an integrity error. Retry only after determining that the event was not committed, and preserve the same idempotency identity for that logical transaction.

A successful Google Sheets API response or successful n8n execution alone is not sufficient proof of a committed transaction. Log failures and recovery decisions without logging secrets.

### 9. Reminder approval is separate

A reminder can be drafted for owner review, but sending it requires a separate explicit approval step. A `COMMIT <token>` issued for a ledger transaction must never send a reminder or authorize any other side effect. Preserve the existing customer opt-in and unsubscribe rules.


## Security and Data Integrity

- **PREPARE → PREVIEW → COMMIT:** Never let the AI write directly to the ledger; require an exact, time-limited owner approval token.
- **Allowlist access:** Only configured Telegram user IDs should be able to operate the shop.
- **Append-only history:** Preserve committed events; record corrections as linked reversal or compensating events.
- **Idempotency:** Deduplicate Telegram updates and event IDs, and verify uncertain writes before retrying.
- **Deterministic totals:** Derive customer balances and stock from committed events or a documented projection.
- **Customer privacy:** Use opt-in reminders and require separate approval before sending them.
- **Protect credentials:** Keep tokens and service-account secrets out of source control.
- **Back up the spreadsheet:** Maintain regular backups of the Google Sheet.


## Live Demonstration Checklist

Use a test spreadsheet and test Telegram account where possible. Capture the bot responses and journal rows for the jury.

- [ ] Valid transaction: show PREPARE, exact PREVIEW, `COMMIT <token>`, verified `SAVED`, and the resulting journal event ID.
- [ ] Plain `yes`: rejected with no new journal event.
- [ ] Wrong, expired, and reused token: each rejected without a second write.
- [ ] Altered payload or stale ledger revision: approval rejected; a fresh preview is required.
- [ ] Ambiguous customer/item: bot asks for clarification and does not prepare a commit.
- [ ] Duplicate Telegram update and repeated commit command: transaction is applied at most once.
- [ ] Correction: append a reversal/compensating event linked to the original event ID; original history remains intact.
- [ ] Deterministic calculations: rebuild or verify customer balance and stock from committed events.
- [ ] Simulated Google Sheets timeout: bot reports `STATUS UNKNOWN`, checks the journal by `event_id`, and avoids double-counting.
- [ ] Reminder: ledger commit token does not send a reminder; reminder requires separate approval.

A README checklist is documentation, not proof that a behavior is implemented. Mark each test complete only after demonstrating it against the current code.

## Known Limitations and Next Steps

The project presentation identifies these possible next steps:

- Persist pending confirmation tokens, expiry, and transaction state across bot restarts.
- Implement and test the strict PREPARE → PREVIEW → COMMIT state machine.
- Add the append-only `EventJournal` tab and deterministic balance/stock projections.
- Implement duplicate update/event protection, revision checks, and event-ID read-back verification.
- Add automated tests for invalid, expired, reused, altered, duplicate, stale, and ambiguous transactions.
- Host the bot so it stays online all day and back up the Google Sheet regularly.

The assigned twist requires code-level state integrity, not only README documentation. Verify that each safeguard is implemented before describing it as production-ready.

## Contributing

Contributions and suggestions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Make your changes and test them.
4. Commit with a clear message.
5. Open a pull request describing the change.

Please do not include credentials, customer data, or private spreadsheet contents in commits or issues.

## License

No license was specified in the project presentation. Add a `LICENSE` file and update this section before distributing the project publicly.
