# Small Shop Assistant: Systematic AI Prompt Pack

| | |
|---|---|
| **Hackathon** | Technovision 2026: Zero Syntax |
| **Team** | MINIONS |
| **Project** | Small Shop Assistant |
| **Platform** | n8n + Telegram Bot + Google Sheets + AI |

---

## Table of Contents

1. [Project at a Glance](#1-project-at-a-glance)
2. [Prompt Index](#2-prompt-index)
3. [Recommended Order of Use](#3-recommended-order-of-use)
4. [Global Rules (apply to every prompt)](#4-global-rules-apply-to-every-prompt)
5. [Prompt 1: Master Project-Build](#prompt-1--master-project-build-prompt)
6. [Prompt 2: n8n Workflow Architecture](#prompt-2--n8n-workflow-architecture-and-implementation)
7. [Prompt 3: Two-Phase Ledger Commit](#prompt-3--two-phase-ledger-commit-and-approval-safety)
8. [Prompt 4: AI Interpretation and Business Logic](#prompt-4--ai-interpretation-commands-and-business-logic)
9. [Prompt 5: Continue and Fix Existing Project](#prompt-5--continue-and-fix-the-existing-project)
10. [Prompt 6: Testing and Demonstration](#prompt-6--hackathon-testing-and-demonstration)
11. [Prompt 7: GitHub Version Control](#prompt-7--github-version-control-and-submission)
12. [Prompt 8: Final Readiness Review](#prompt-8--final-hackathon-readiness-review)
13. [Final Note for Claude AI](#final-note-for-claude-ai)

---

## 1. Project at a Glance

**What it is:** A smart AI-powered assistant for small Indian shopkeepers, operated through Telegram messages in simple English or natural language.

**Problem:** Small shopkeepers track sales, credit, repayments, inventory, and pending orders manually. This causes calculation errors, missing records, forgotten payments, stock discrepancies, and poor visibility into daily business.

**Core differentiator:** A **preview-and-approval transaction protocol backed by a traceable ledger**.

```
PREPARE  →  PREVIEW  →  APPROVE  →  COMMIT
```

**Principle:** AI is used only for language interpretation. All money, stock, validation, and state checks are deterministic.

### Tech Stack

| Layer | Tool |
|---|---|
| Automation | n8n (native nodes, no Code nodes unless approved) |
| Interface | Telegram Bot |
| Data store | Google Sheets (initial ledger) |
| AI | Language interpretation and structured extraction only |

### Feature Checklist (12 required features)

| # | Feature | Summary |
|---|---|---|
| 1 | Sales management | Cash and credit sales |
| 2 | Customer management | Add customers, IDs, outstanding balances |
| 3 | Credit management | Credit purchases and dues |
| 4 | Repayment management | Payments against balances |
| 5 | Inventory management | Stock-in, stock-out, current quantity, low-stock alerts |
| 6 | Order management | Record and track accepted orders |
| 7 | Business queries | Stock, dues, history, daily sales |
| 8 | AI interpretation | Natural language to structured data |
| 9 | Transaction approval | Preview before any save |
| 10 | Safe corrections | Edit or cancel pending transactions |
| 11 | Audit trail | Full history, no duplicate postings |
| 12 | Daily summary | Shop performance reports |

---

## 2. Prompt Index

| # | Prompt | Role / Persona | Purpose | Phase |
|---|---|---|---|---|
| 1 | Master Project-Build | n8n architect, AI engineer, DB designer, mentor | Define the whole project, constraints, and safety model | Planning |
| 2 | n8n Workflow Architecture | n8n workflow engineer | Modular workflow design and node-by-node guide | Build |
| 3 | Two-Phase Ledger Commit | (Transaction protocol design) | Approval, token, and commit safety lifecycle | Build (core) |
| 4 | AI Interpretation and Business Logic | (AI and domain logic) | Commands, extraction, deterministic calculations | Build |
| 5 | Continue and Fix Existing Project | (Maintainer / debugger) | Inspect, root-cause, and fix without rebuilding | Maintain |
| 6 | Testing and Demonstration | Strict hackathon judge and QA engineer | Reproducible test plan, demo script | Verify |
| 7 | GitHub Version Control | (Repo maintainer) | Clean, secret-free repository and submission | Ship |
| 8 | Final Readiness Review | Strict hackathon judge | Score, risks, verdict | Ship |

---

## 3. Recommended Order of Use

```
Prompt 1  →  Prompt 2  →  Prompt 3  →  Prompt 4      (design and build)
                                           │
                                           ▼
                                      Prompt 5          (fix and iterate; repeat as needed)
                                           │
                                           ▼
                                      Prompt 6          (test and demo)
                                           │
                                           ▼
                                      Prompt 7          (GitHub)
                                           │
                                           ▼
                                      Prompt 8          (final review and verdict)
```

- Always start a new session with **Prompt 1** for context, then paste the specific prompt you need.
- Use **Prompt 5** any time something breaks.
- Run **Prompt 6 → 7 → 8** before submission.

---

## 4. Global Rules (apply to every prompt)

These rules repeat across the pack. Treat them as always on.

| Rule | Detail |
|---|---|
| Inspect first | Review existing workflows before changing anything |
| Preserve working features | Do not rebuild or overwrite what works |
| Minimal, reversible changes | Smallest safe change, test each affected workflow |
| No AI ledger writes | AI never writes directly to the ledger |
| Deterministic finance | Calculations, validations, and state checks are not done by AI |
| No Code nodes | Use native n8n nodes unless explicitly approved |
| No secrets exposed | No tokens, API keys, credentials, or real customer data in logs or GitHub |
| Honest reporting | Never claim a feature works, or a test passed, unless it was actually executed |
| No premature publish | Do not activate or publish workflows without authorization |
| Beginner-friendly | Explain every step simply |

---

# PROMPT 1: Master Project-Build Prompt

**Purpose:** Establish the full project definition, scope, constraints, and safety model.
**Use when:** Starting a session or onboarding an AI to the project.

## Role
You are a senior n8n automation architect, AI workflow engineer, database designer, and hackathon mentor.

## Task
Help me build a hackathon-ready project called **Small Shop Assistant**, a smart AI-powered assistant for small Indian shopkeepers.

## Problem Statement
Small shopkeepers often maintain sales, customer credit, repayments, inventory, and pending orders manually. This leads to calculation errors, missing records, forgotten payments, stock discrepancies, and difficulty tracking daily business activity.

## Objective
Build a conversational assistant that lets a shopkeeper manage daily operations through Telegram messages in simple English or natural language, with support for multilingual input where feasible.

## Required Features
1. **Sales management:** Record cash sales and credit sales.
2. **Customer management:** Add customers, maintain customer IDs, and track outstanding balances.
3. **Credit management:** Record credit purchases against customers and calculate dues.
4. **Repayment management:** Record payments against outstanding customer balances.
5. **Inventory management:** Track stock-in, stock-out, current quantity, and low-stock alerts.
6. **Order management:** Record customer orders and track accepted orders.
7. **Business queries:** Answer questions about current stock, customer dues, transaction history, and daily sales.
8. **AI interpretation:** Convert natural-language messages into structured transaction data.
9. **Transaction approval:** Show a preview before saving any financial or inventory-changing transaction.
10. **Safe corrections:** Allow authorized users to edit or cancel pending transactions.
11. **Audit trail:** Preserve transaction history and prevent accidental duplicate postings.
12. **Daily summary:** Generate useful shop performance summaries.

## Technology Constraints
- Use n8n as the workflow automation platform.
- Use Telegram as the conversational interface.
- Use Google Sheets as the initial business ledger and record store.
- Use an AI model only for language interpretation and structured extraction.
- Perform financial calculations, stock calculations, validations, and transaction-state checks deterministically.
- Do not let the AI directly write to the ledger.
- Use existing working workflows wherever possible.
- Avoid unnecessary new tools, paid dependencies, and complicated infrastructure.
- Explain every step for a beginner.
- Prefer native n8n nodes and visual configuration; do not introduce Code nodes unless explicitly approved.

## Critical Transaction Safety
Every sensitive transaction must follow this process:

**PREPARE → PREVIEW → APPROVE → COMMIT**

| Step | Meaning |
|---|---|
| PREPARE | Parse the request and validate its fields |
| PREVIEW | Show the intended transaction, customer, item, quantity, amount, and effects |
| APPROVE | Obtain explicit owner approval for the exact pending transaction |
| COMMIT | Verify the approval and transaction token, then persist the transaction |
| CANCEL | Cancel a pending transaction |
| EDIT | Revise a pending transaction and require approval of the revised version |

No financial or inventory changes should be written before the required approval and commit steps.

## Expected Output
First inspect the existing project and workflows. Then explain:
- Architecture
- Workflow connections
- Node configurations
- Data schemas
- Security controls
- Testing strategy
- Deployment steps

Do not claim a feature works unless it has been tested. Preserve existing functionality and explain any limitations honestly.

---

# PROMPT 2: n8n Workflow Architecture and Implementation

**Purpose:** Design modular n8n workflows and produce a node-by-node implementation guide.
**Use when:** Building or restructuring the workflow layout.

## Role
Act as an expert n8n workflow engineer.

## Task
Design and implement the Small Shop Assistant using **modular workflows** rather than one giant workflow.

## Core Workflows

| Workflow | Responsibility |
|---|---|
| `SSA-01-Telegram-Intake` | Receive Telegram messages, identify the user, and route requests |
| Transaction interpretation | Extract the intended operation and structured fields |
| Validation and preview | Validate customer, product, quantity, amount, and transaction type |
| Approval and commit | Handle pending transaction approval, commit tokens, and safe persistence |
| Inventory management | Stock-in, stock-out, stock lookup, and low-stock detection |
| Customer and credit management | Customer lookup, credit sales, outstanding payments, and repayments |
| Reporting | Daily summary, transaction history, and business queries |

> These names are architectural labels; retain the project's actual workflow names if they differ.

## Implementation Requirements
1. Inspect the existing workflows before making changes.
2. Reuse existing Telegram credentials and working integrations without exposing secrets.
3. Use native n8n nodes wherever possible.
4. Route messages to the correct workflow and handle unknown commands gracefully.
5. Keep business rules and calculations deterministic.
6. Add validation for missing customers, unknown products, invalid quantities, insufficient stock, and invalid amounts.
7. Return helpful Telegram responses for success, rejection, missing information, and errors.
8. Prevent a message from being processed as multiple unintended transactions.
9. Ensure that only authorized shop owners can approve or commit transactions.
10. Do not publish or activate a workflow automatically without authorization.

## Expected Output
A node-by-node implementation guide including:
- Node names
- Operation types
- Expressions
- Field mappings
- Connections
- Error handling

---

# PROMPT 3: Two-Phase Ledger Commit and Approval Safety

**Purpose:** Implement the core differentiator, a protocol separating preparation from permanent ledger posting.
**Use when:** Building or auditing the approval, token, and commit logic.

## Task
Implement a transaction protocol that separates transaction preparation from permanent ledger posting.

## Required Transaction Lifecycle

```
PREPARED  →  APPROVED  →  COMMITTED
```

Also support: `CANCELLED`, `REJECTED`, and `EXPIRED` (if expiration is implemented).

## Phase Specifications

### PREPARE
- Parse and validate the transaction.
- Generate a unique transaction or event ID.
- Store a pending transaction containing the intended operation and validated fields.
- Generate an approval token associated with that exact transaction.
- Show the complete preview to the authorized owner.
- **Do not change stock, balances, or the permanent ledger.**

### APPROVE
- Accept only the expected event ID and valid approval token.
- Verify the owner's Telegram identity.
- Verify that the pending transaction still exists and is eligible for approval.
- Reject expired, cancelled, malformed, or already-used approval tokens.
- Bind approval to the exact transaction version.

### COMMIT
- Verify the transaction, approval, and commit token.
- Prevent reuse of tokens.
- Detect duplicate commits and repeated Telegram updates.
- Write the validated transaction to the ledger and update the appropriate business records.
- Return an accurate final status only after verifying the actual persistence result.

### EDIT and CANCEL
- Editing a pending transaction must invalidate its old approval.
- A revised transaction must receive a new preview and approval.
- Cancellation must prevent the pending transaction from being committed.
- Do not silently modify a transaction that has already been committed.

## Ledger Integrity
- Keep an **append-only journal** of committed business events.
- Do not overwrite historical financial records to correct mistakes; use traceable correction or reversal events.
- Maintain transaction IDs, timestamps, statuses, and audit references.
- Consider retries, partial writes, concurrent requests, and recovery after a workflow failure.
- Use atomic database transactions or an appropriate idempotency and recovery design when supported by the storage system.

## Honesty Constraint
Do not claim exactly-once processing or atomicity unless the implementation and tests actually guarantee it. Explain any limitations of Google Sheets as a transactional storage system.

### State Summary

| State | Meaning | Can commit? |
|---|---|---|
| PREPARED | Validated, awaiting approval | No |
| APPROVED | Owner approved exact version | Yes |
| COMMITTED | Persisted to ledger | Final |
| CANCELLED | Cancelled by owner | No |
| REJECTED | Rejected | No |
| EXPIRED | Timed out (if implemented) | No |

---

# PROMPT 4: AI Interpretation, Commands, and Business Logic

**Purpose:** Make the assistant understand shopkeeper requests while keeping business operations deterministic.
**Use when:** Defining command syntax, AI extraction, and calculation rules.

## Task
Improve the assistant so it correctly understands shopkeeper requests while keeping business operations deterministic.

## Supported Operations

| Operation | Command | Meaning |
|---|---|---|
| Cash sale | `SALE 200` | Record a cash sale of ₹200, using the project's defined cash-sale semantics |
| Credit sale | `CREDIT Sunita Deshmukh \| Sugar 2 kg 100` | Credit sale of 2 kg sugar for ₹100 against Sunita Deshmukh |
| Repayment | `REPAY Sunita Deshmukh 200` | Repayment of ₹200 against her outstanding balance |
| Stock-in | `STOCKIN Sugar 10 kg` | Increase sugar inventory by 10 kg |
| Stock-out | `STOCKOUT Sugar 2 kg` | Reduce sugar inventory by 2 kg, subject to stock validation |
| Customer order | `ORDER Sunita Deshmukh \| Sugar 5 kg` | Record an order for 5 kg of sugar. An accepted order must **not** automatically become a completed sale or stock deduction unless business rules explicitly say so |
| Customer lookup | `CUSTOMER CUST-001` | Retrieve customer details and outstanding balance |
| Customer creation | `ADDCUSTOMER Ramesh Patil [credit limit]` | Create a customer with validated details and optional credit limit |

## AI Extraction Requirements
Convert user messages into structured fields:

- Intent
- Customer identifier
- Product identifier
- Quantity and unit
- Monetary amount and currency
- Payment type
- Requested operation
- Missing information
- Validation errors

**Do not guess** missing quantities, prices, customer identities, or units. Ask follow-up questions when the request is ambiguous.

**Example:** If a shopkeeper says *"Sunita bought sugar for 300,"* clarify the quantity and whether it is a cash or credit sale when those details are not established by the existing system.

## Deterministic Calculations
- Calculate line totals using validated quantities and prices.
- Track customer dues from committed credit sales and repayments.
- Calculate current stock from the authoritative inventory records or a consistent stock ledger.
- Validate credit limits and stock availability where applicable.
- Do not let an AI-generated explanation determine the actual financial balance.

> **Use the AI for interpretation, not as the source of truth for accounting.**

---

# PROMPT 5: Continue and Fix the Existing Project

**Purpose:** Debug and extend the current build without rebuilding it.
**Use when:** Something is broken, a command is misrouted, or tokens/statuses misbehave.

## Task
Continue the existing Small Shop Assistant project rather than rebuilding it from scratch.

Inspect the current n8n workflows, node configurations, Telegram command handling, data mappings, Google Sheets structure, and transaction protocol.

## Existing Functionality
- Cash sales and credit sales
- Customer balances and outstanding payments
- Repayments
- Stock-in and stock-out
- Customer orders
- Stock and customer queries
- Preview, approval, and commit
- Cancellation and editing

## Requirements
1. Identify the actual root cause of every reported issue before changing the workflow.
2. Preserve working features and existing business data.
3. Fix command routing so supported commands reach the correct handler.
4. Ensure examples displayed by Telegram match the command parser's actual accepted syntax.
5. Validate the full PREPARE → PREVIEW → APPROVE → COMMIT lifecycle.
6. Fix token errors, duplicate processing, missing event IDs, and incorrect status messages.
7. Ensure pending transactions are not written to permanent ledgers prematurely.
8. Make every user-facing status reflect the real workflow and persistence result.
9. Use clear error messages and safe recovery paths.
10. Avoid Code nodes unless specifically approved; prefer visual n8n nodes.
11. Do not expose tokens, API keys, credentials, or customer data in logs or GitHub.
12. Make minimal, reversible changes and test each affected workflow.

## Report Before Modifying
- Current architecture
- Existing working features
- Confirmed defects
- Proposed fixes
- Regression risks

## Report After Modifying
- Changed workflows
- Tests performed
- Results
- Remaining limitations

> **Never report a test as passed if it was not executed.**

---

# PROMPT 6: Hackathon Testing and Demonstration

**Purpose:** Build a reproducible test plan that proves real functionality.
**Use when:** Preparing for the demo and validating behavior.

## Role
Act as a strict hackathon judge and QA engineer evaluating Small Shop Assistant.

## Task
Build a reproducible test plan that demonstrates real functionality rather than merely showing a polished Telegram interface.

## A. Functional Tests

| # | Test | Verify |
|---|---|---|
| 1 | Record a cash sale | Resulting ledger entry |
| 2 | Record a credit sale for an existing customer | Entry created |
| 3 | Check outstanding balance after credit sale | Increases correctly |
| 4 | Record a repayment | Balance decreases correctly |
| 5 | Add stock | Inventory quantity |
| 6 | Remove stock | Inventory quantity |
| 7 | Invalid stock-out | Stock cannot go negative |
| 8 | Create and look up a customer | Correct record |
| 9 | Create an order | Not recorded as a completed sale |
| 10 | Request daily summary | Matches underlying committed records |

## B. Security and Transaction Tests

| # | Test | Expected |
|---|---|---|
| 11 | Commit without approval | Rejected |
| 12 | Approve with invalid event ID | Rejected |
| 13 | Reuse a consumed token | Rejected |
| 14 | Commit the same transaction twice | Second commit blocked |
| 15 | Edit pending transaction, use old approval | Old approval invalid |
| 16 | Cancel pending transaction, then commit | Commit blocked |
| 17 | Submit same Telegram update more than once | Processed once |
| 18 | Simulate failure between ledger operations | Recovery behavior inspected |
| 19 | Approve/commit from unauthorized Telegram account | Rejected |
| 20 | Persistence failure | Bot does not claim success |

## Testing Rules
- Use test customers and clearly identified test data.
- Record the expected result, actual result, and evidence for every test.
- Verify actual Google Sheets records, not only Telegram responses.
- Do not test by modifying real customer records.
- Do not expose credentials or approval tokens in screenshots or the public repository.
- Clearly distinguish **passing, failing, blocked, and untested** cases.

## Test Results Template

| # | Test | Expected | Actual | Evidence | Status (Pass / Fail / Blocked / Untested) |
|---|---|---|---|---|---|
| | | | | | |

## Final Deliverables
- A concise architecture diagram
- A workflow inventory
- A feature checklist
- A test-results table
- Known limitations and recovery procedures
- A two-minute live demonstration script
- A short explanation of the project's innovation and business value

> Do not promise a perfect score or claim the system is production-ready solely because the demo works. Base all claims on verified tests.

---

# PROMPT 7: GitHub Version Control and Submission

**Purpose:** Maintain a clean, reviewable, secret-free repository.
**Use when:** Committing, pushing, and preparing the submission repo.

## Task
Help me maintain a clean, reviewable GitHub repository for the Small Shop Assistant hackathon project.

## Repository Requirements
- Export the n8n workflows as JSON files.
- Use descriptive filenames and keep the workflows organized.
- Include a README with: problem statement, solution, architecture, features, setup instructions, and limitations.
- Include a safe `.env.example` containing placeholder values only.
- Include test documentation and sanitized sample data.
- **Exclude:** API keys, Telegram bot tokens, credentials, passwords, private webhook URLs, real customer data, and exported secrets.

## Git Workflow
1. Inspect the changed files before committing.
2. Review workflow JSON for accidental secrets.
3. Validate the exported workflow files.
4. Stage only intended project files.
5. Create a descriptive commit for each meaningful change.
6. Push changes to the intended GitHub repository.
7. Verify that the latest commit appears on GitHub.
8. Keep an understandable commit history rather than repeatedly overwriting project files.

## Suggested Repo Structure

```
small-shop-assistant/
├── README.md
├── .env.example
├── workflows/
│   ├── SSA-01-Telegram-Intake.json
│   └── ...
├── docs/
│   ├── architecture.md
│   └── test-results.md
└── sample-data/
    └── sanitized-sample.csv
```

> Never claim a commit or push succeeded without checking the result. Never include credentials merely to make a workflow easier to import.

---

# PROMPT 8: Final Hackathon Readiness Review

**Purpose:** Strict final judging before submission.
**Use when:** All building and testing is done.

## Role
Evaluate the complete Small Shop Assistant as a strict judge for a no-code/low-code automation hackathon.

## Scoring (1 to 10)

| Criterion | Score | Evidence |
|---|---|---|
| Problem relevance | | |
| Innovation | | |
| Workflow architecture | | |
| AI usefulness | | |
| Transaction safety | | |
| Data integrity | | |
| User experience | | |
| Reliability | | |
| Demo quality | | |
| Documentation | | |

Inspect the actual workflows and evidence. Do not award points simply because a feature is described in the README.

## Identify
1. Critical bugs that could invalidate the demo.
2. Features that are incomplete or only simulated.
3. Financial or inventory integrity risks.
4. Security and privacy weaknesses.
5. The five highest-impact improvements that can realistically be completed before submission.
6. A short, reliable live-demo sequence.
7. Questions judges may ask and technically honest answers.

## Readiness Verdict (choose one)
- [ ] Not ready
- [ ] Demo-ready
- [ ] Hackathon-ready with known limitations
- [ ] Ready for a controlled pilot

Explain the verdict using verified evidence and clearly state what still needs testing.

---

# Final Note for Claude AI

Treat these prompts as a **project specification**, not permission to rebuild or overwrite everything.

1. Start by inspecting the existing implementation.
2. Keep working functionality and identify gaps.
3. Make the smallest safe changes and verify the result.
4. If a requirement cannot be met with the existing stack, explain the limitation and propose the simplest defensible solution before implementing it.

The most important differentiator is the **preview-and-approval transaction protocol backed by a traceable ledger**. A bot that only replies to commands is not sufficient; the underlying business records, balances, stock calculations, and failure handling must be correct.
