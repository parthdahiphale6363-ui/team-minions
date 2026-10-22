# Small Shop Assistant: Prompt Pack

**Hackathon:** Technovision 2026: Zero Syntax (No Code Hackathon)
**Team:** TEAM MINIONS | **Team leader:** Parth Dahiphale
**Problem statement:** Small Shop Assistant

**Stack:** n8n (workflow) · Telegram Bot (chat interface) · Google Sheets (database) · AI models (ChatGPT, Gemini, Claude)

**How the AI tools were used**

| Tool | Used for |
|---|---|
| ChatGPT | Idea brainstorming, n8n setup steps, test data |
| Gemini | Telegram/Sheets setup help, Hindi/Marathi testing, runtime AI model |
| Claude | Agent system prompts, Sheet design, credit score logic, pitch content, runtime AI model |

Prompts are numbered P1 to P20. Copy and paste them in order to rebuild the project.

---

## Phase 1: Idea and planning

### P1. Solution ideas (ChatGPT)
```
I am in a no-code hackathon called "Zero Syntax". My problem statement is "Small Shop Assistant". Small shopkeepers in India use paper notebooks (udhaar khata). Give me 5 solution ideas using only no-code tools: n8n, Google Sheets, a Telegram bot and an AI model. For each idea give: the problem solved, how it works in 3 steps, and why a shopkeeper would use it.
```

### P2. Problem analysis (ChatGPT)
```
Explain the top 3 problems of paper ledgers for small Indian shops in simple words. Cover: forgotten credit (udhaar) and untracked partial payments, no profit analytics, and stock running out without warning. Give one real-life example for each.
```

### P3. Feature scope (Claude)
```
My solution is a Telegram chatbot that turns messages in Hindi, Marathi, English and Hinglish into structured records in Google Sheets. Organise the features under three jobs: LOG (sales, credit, repayments, stock), ASK (udhaar balance, daily summary, stock levels) and ACT (low-stock warning, polite reminder draft, owner approval). Keep the owner in control of every entry.
```

---

## Phase 2: Setup

### P4. Telegram bot (Gemini)
```
Give me step-by-step instructions to create a Telegram bot using BotFather, get the bot token, and connect it to an n8n Telegram Trigger node. Also explain how to find the shop owner's chat ID so the bot can message them.
```

### P5. Google Sheet design (Claude)
```
Design a Google Sheet as the database for a small shop ledger. Tabs and exact columns:
1. Customers: customer_id, name, phone, telegram_id, credit_limit, credit_score, current_balance
2. Transactions: date, customer_name, type (credit_sale / cash_sale / repayment / stock_in / stock_out), item, quantity, amount, balance_after, status
3. Stock: item, quantity, unit, reorder_level, cost_price, selling_price
4. Orders: order_id, customer_name, item, quantity, status (pending / accepted / edited / declined)
5. Reminders: customer_name, amount_due, draft_text, status (draft / approved)
Show 3 sample rows for each tab and the formula for balance_after.
```

### P6. Connect Sheets to n8n (Gemini)
```
Explain how to connect Google Sheets to n8n using OAuth credentials, and how to use the "Append row", "Get row(s)" and "Update row" operations for the tabs above.
```

---

## Phase 3: Workflow

### P7. Main workflow (ChatGPT)
```
Design an n8n workflow: Telegram Trigger -> AI Agent (understand message) -> validation -> IF message is ambiguous, ask a clarifying question on Telegram -> ELSE write to Google Sheets -> read the row back to verify the write -> reply "Saved". Also add a Schedule Trigger that sends a daily summary every evening. List the nodes in order with settings for each, and show where owner approval goes.
```

### P8. Error handling (Claude)
```
Add error handling to this n8n workflow: what happens if the Google Sheets write fails, the AI returns invalid JSON, the customer is not found, or the same message is sent twice? Give me the nodes and logic to add, and the Telegram error message to send to the owner.
```

---

## Phase 4: The three AI agents

### P9. Agent 1, Understanding (Claude) — paste into the n8n AI Agent system message
```
You are the Understanding Agent for a small shop assistant used by Indian shopkeepers. Messages come in Hindi, Marathi, English or Hinglish.

Task: classify the message and extract fields. Return ONLY valid JSON, no extra text.

Intents:
- credit_sale (e.g. "Ramesh ko 500 ka udhaar diya")
- cash_sale
- repayment (e.g. "Ramesh ne 200 diye")
- stock_in / stock_out
- query (e.g. "Ramesh ka udhaar kitna hai?")
- order_request (a customer asking for an item)
- unknown

JSON format:
{
  "intent": "",
  "customer_name": "",
  "item": "",
  "quantity": null,
  "amount": null,
  "needs_clarification": false,
  "clarification_question": ""
}

Rules:
- If the customer name matches more than one person, or the amount or item is missing, set needs_clarification = true and write a short question in the SAME language as the user (for example: "Which Ramesh?").
- Never guess an amount. Never invent a customer.
- Amounts are in rupees. Convert words like "paanch sau" to 500.
```

### P10. Agent 2, Data processing (Claude)
```
You are the Data Processing Agent. You receive the JSON from the Understanding Agent and the current rows from Google Sheets.

1. Validate: the customer exists, the amount is a positive number, and the item exists in Stock when relevant.
2. Calculate the new balance: new_balance = previous_balance + credit_given - repayment
3. Return the row to write, in the exact column order of the Transactions tab, plus the updated Customers row.
4. If validation fails, return {"valid": false, "reason": "..."} and write nothing.

Return ONLY JSON. Never write to the sheet when valid = false.
```

### P11. Balance code node (ChatGPT)
```
Write an n8n Code node (JavaScript) that takes the transaction JSON and the customer's current_balance, then returns the new balance and the row object ready for Google Sheets. Handle credit_sale (adds to balance) and repayment (subtracts from balance), and never let the balance go below zero.
```

### P12. Agent 3, Communication (Claude)
```
You are the Communication Agent for a small shop. Write short, polite messages in the same language the shopkeeper used (Hindi, Marathi, English or Hinglish).

Tasks:
1. Confirmation: after a record is saved, reply in one line, e.g. "Saved: Ramesh | Rs 500 | Credit sale. Balance: Rs 500".
2. Reminder draft: when a customer's payment is overdue, write a polite, respectful reminder that mentions the amount due. It is only a DRAFT. Never send it. The owner must approve it first.
3. Daily summary: total sales, udhaar due, top 3 items, estimated profit.

Tone: friendly, respectful, no pressure. Keep each message under 3 lines.
```

---

## Phase 5: Smart features

### P13. Credit score (Claude)
```
Design an explainable credit score (0 to 100) for udhaar customers of a small shop using these weights:
- On-time repayments: 40%
- Average days of delay: 25%
- Balance vs credit limit: 20%
- Purchase history length: 15%

Tiers: 80-100 Trusted (higher credit limit), 50-79 Regular (standard limit), below 50 Watch (ask for cash or part payment first).

Give me the formula, an example calculation for a customer who scores 78, and an n8n Code node that calculates it from the Transactions tab. The owner must be able to see exactly why a customer got the score.
```

### P14. Order by chat (Claude)
```
Design the "Order by chat" flow in n8n. A customer sends "Ek kilo chawal bhej do" to the shop bot.
1. AI finds the item and quantity.
2. Check stock and the customer's credit limit.
3. Send the owner a Telegram message with inline buttons: Accept, Edit, Decline.
4. On the owner's tap, notify the customer, then update Stock and the ledger.
Nothing updates before the owner decides. Show the n8n nodes and the Telegram inline keyboard JSON.
```

### P15. Daily summary (ChatGPT)
```
Create an n8n Schedule Trigger that runs every evening at 8 PM. It reads today's rows from the Transactions tab, calculates total sales, total udhaar due, the top 3 items and estimated profit (selling_price - cost_price), then sends the result to the owner on Telegram through the Communication Agent.
```

### P16. Low-stock alert (ChatGPT)
```
Add a low-stock check: after every sale or stock_out, compare the item's quantity with its reorder_level. If it is below the level, send the owner a Telegram warning BEFORE the item runs out. Include the item name, remaining quantity and a suggested reorder quantity.
```

### P17. Overdue reminders (Gemini)
```
Create an n8n flow that runs daily, finds customers whose balance is unpaid for more than 15 days, asks the Communication Agent to write a polite reminder draft in their language, saves it in the Reminders tab with status "draft", and sends it to the owner with Approve and Skip buttons. Never auto-send to the customer.
```

---

## Phase 6: Testing and presentation

### P18. Test messages (ChatGPT)
```
Give me 20 test messages in Hindi, Marathi, English and Hinglish for my shop bot: credit sales, repayments, stock updates, queries and ambiguous messages (like two customers named Ramesh). For each, show the expected JSON output.
```

### P19. Pitch deck (Claude)
```
I am making a hackathon pitch deck for "Small Shop Assistant". Suggest slides: problem, solution (Log, Ask, Act), credit score, order by chat, flow from message to record, architecture (Telegram + n8n + AI + Google Sheets), three AI agents, human in the loop, future features. Write short on-slide text and speaker notes for each slide.
```

### P20. Future features (Gemini)
```
Suggest practical future features for the bot: UPI payment link in reminders, bill photo scan with OCR, voice notes in Hindi and Marathi, credit limit that adjusts with the score, supplier reorder list for low stock, and offer messages for loyal customers. Explain how each could be added in n8n.
```

