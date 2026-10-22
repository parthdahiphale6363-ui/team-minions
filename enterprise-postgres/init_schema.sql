-- ==============================================================================
-- Small Shop Assistant — Enterprise PostgreSQL / Supabase ACID Schema & Functions
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ssa;

-- 1. Customers Table (Debt and credit limit tracking)
CREATE TABLE IF NOT EXISTS ssa.customers (
    customer_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    current_debt NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    credit_limit NUMERIC(12, 2) NOT NULL DEFAULT 5000.00,
    shop_id TEXT NOT NULL DEFAULT 'SHOP-001'
);

-- 2. Products Table (Inventory stock and unit pricing)
CREATE TABLE IF NOT EXISTS ssa.products (
    product_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    unit TEXT NOT NULL,
    current_stock NUMERIC(12, 3) NOT NULL DEFAULT 0.000,
    unit_price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    shop_id TEXT NOT NULL DEFAULT 'SHOP-001'
);

-- 3. Ledger State (Monotonically advancing ledger revision)
CREATE TABLE IF NOT EXISTS ssa.ledger_state (
    shop_id TEXT PRIMARY KEY,
    journal_id TEXT NOT NULL,
    revision INTEGER NOT NULL DEFAULT 0,
    last_event_id TEXT
);

-- 4. Processed Updates (Universal deduplication & replay protection)
CREATE TABLE IF NOT EXISTS ssa.processed_updates (
    source_update_id TEXT PRIMARY KEY,
    source_message_id TEXT,
    sender_id TEXT,
    status TEXT NOT NULL, -- RECEIVED, PROCESSED, FAILED
    received_iso TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Pending Proposals (Staged proposals and 90-second approval tokens)
CREATE TABLE IF NOT EXISTS ssa.pending_proposals (
    proposal_id TEXT PRIMARY KEY,
    event_id TEXT UNIQUE NOT NULL,
    shop_id TEXT NOT NULL,
    journal_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload_canonical TEXT NOT NULL,
    payload_hash TEXT NOT NULL,
    binding_hash TEXT,
    token_hash TEXT,
    status TEXT NOT NULL, -- PENDING, APPROVAL_ISSUED, COMMIT_VALIDATING, COMMITTED, CANCELLED, SUPERSEDED, WRITE_FAILED
    status_reason TEXT,
    source_update_id TEXT,
    source_message_id TEXT,
    chat_id TEXT,
    sender_id TEXT,
    source_text TEXT,
    created_iso TIMESTAMPTZ DEFAULT NOW(),
    updated_iso TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    expires_epoch BIGINT NOT NULL,
    ledger_revision INTEGER NOT NULL
);

-- 6. Event Journal (Append-only immutable audit trail)
CREATE TABLE IF NOT EXISTS ssa.event_journal (
    event_id TEXT PRIMARY KEY,
    transaction_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    shop_id TEXT NOT NULL,
    customer_id TEXT,
    product_id TEXT,
    quantity NUMERIC(12, 3),
    unit TEXT,
    amount NUMERIC(12, 2),
    currency TEXT NOT NULL DEFAULT 'INR',
    original_event_id TEXT,
    payload_hash TEXT NOT NULL,
    actor_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    revision INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'COMMITTED'
);

-- Seed Initial State
INSERT INTO ssa.ledger_state (shop_id, journal_id, revision, last_event_id)
VALUES ('SHOP-001', 'Small_Shop_Assistant_Journal', 0, 'EVT-GENESIS')
ON CONFLICT (shop_id) DO NOTHING;

INSERT INTO ssa.customers (customer_id, name, phone, current_debt, credit_limit, shop_id)
VALUES
    ('CUST-001', 'Sunita Deshmukh', '+919876543201', 200.00, 5000.00, 'SHOP-001'),
    ('CUST-002', 'Ramesh Patil', '+919876543202', 1500.00, 4000.00, 'SHOP-001'),
    ('CUST-003', 'Amit Sharma', '+919876543203', 0.00, 10000.00, 'SHOP-001'),
    ('CUST-004', 'Priya Nair', '+919876543204', 450.00, 3000.00, 'SHOP-001')
ON CONFLICT (customer_id) DO NOTHING;

INSERT INTO ssa.products (product_id, name, unit, current_stock, unit_price, shop_id)
VALUES
    ('PROD-001', 'Sugar', 'kg', 50.000, 42.00, 'SHOP-001'),
    ('PROD-002', 'Cooking Oil', 'litre', 20.000, 145.00, 'SHOP-001'),
    ('PROD-003', 'Basmati Rice', 'kg', 100.000, 90.00, 'SHOP-001'),
    ('PROD-004', 'Toor Dal', 'kg', 35.000, 160.00, 'SHOP-001'),
    ('PROD-005', 'Wheat Flour', 'kg', 80.000, 38.00, 'SHOP-001'),
    ('PROD-006', 'Milk', 'litre', 30.000, 60.00, 'SHOP-001')
ON CONFLICT (product_id) DO NOTHING;

-- ==============================================================================
-- Atomic 2-Phase Commit Procedure (Zero-Race Guarantee)
-- ==============================================================================
CREATE OR REPLACE FUNCTION ssa.commit_transaction(
    p_event_id TEXT,
    p_token_hash TEXT,
    p_exec_lock_id TEXT,
    p_journal_entry JSONB
) RETURNS JSONB AS $$
DECLARE
    v_proposal RECORD;
    v_current_rev INT;
    v_new_rev INT;
    v_updated_rows INT;
BEGIN
    -- 1. Row Lock on Proposal
    SELECT * INTO v_proposal
    FROM ssa.pending_proposals
    WHERE event_id = p_event_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'PROPOSAL_NOT_FOUND');
    END IF;

    -- 2. Verify status, token and expiry
    IF v_proposal.status <> 'APPROVAL_ISSUED' THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_STATUS', 'current_status', v_proposal.status);
    END IF;

    IF v_proposal.token_hash <> p_token_hash THEN
        RETURN jsonb_build_object('success', false, 'error', 'TOKEN_HASH_MISMATCH');
    END IF;

    IF EXTRACT(EPOCH FROM NOW()) * 1000 > v_proposal.expires_epoch THEN
        RETURN jsonb_build_object('success', false, 'error', 'TOKEN_EXPIRED');
    END IF;

    -- 3. Atomic Token Burn & Execution Lock Reservation
    UPDATE ssa.pending_proposals
    SET status = 'COMMIT_VALIDATING',
        status_reason = 'LOCKED:' || p_exec_lock_id,
        token_hash = NULL,
        updated_iso = NOW()
    WHERE event_id = p_event_id;

    -- 4. Read & Lock Current Ledger State
    SELECT revision INTO v_current_rev
    FROM ssa.ledger_state
    WHERE shop_id = v_proposal.shop_id
    FOR UPDATE;

    v_new_rev := v_current_rev + 1;

    -- 5. Append to Immutable Event Journal
    INSERT INTO ssa.event_journal (
        event_id, transaction_id, event_type, shop_id, customer_id,
        product_id, quantity, unit, amount, currency, original_event_id,
        payload_hash, actor_id, created_at, revision, status
    ) VALUES (
        p_event_id,
        p_journal_entry->>'transaction_id',
        v_proposal.event_type,
        v_proposal.shop_id,
        p_journal_entry->>'customer_id',
        p_journal_entry->>'product_id',
        (p_journal_entry->>'quantity')::NUMERIC,
        p_journal_entry->>'unit',
        (p_journal_entry->>'amount')::NUMERIC,
        COALESCE(p_journal_entry->>'currency', 'INR'),
        p_journal_entry->>'original_event_id',
        v_proposal.payload_hash,
        p_journal_entry->>'actor_id',
        NOW(),
        v_new_rev,
        'COMMITTED'
    );

    -- 6. Advance Monotonic Revision
    UPDATE ssa.ledger_state
    SET revision = v_new_rev,
        last_event_id = p_event_id
    WHERE shop_id = v_proposal.shop_id;

    -- 7. Update Real Debt & Stock Projections
    IF v_proposal.event_type = 'CREDIT_SALE' THEN
        UPDATE ssa.customers
        SET current_debt = current_debt + (p_journal_entry->>'amount')::NUMERIC
        WHERE customer_id = p_journal_entry->>'customer_id';
    ELSIF v_proposal.event_type = 'REPAYMENT' THEN
        UPDATE ssa.customers
        SET current_debt = GREATEST(0, current_debt - (p_journal_entry->>'amount')::NUMERIC)
        WHERE customer_id = p_journal_entry->>'customer_id';
    END IF;

    IF v_proposal.event_type IN ('STOCK_OUT', 'ACCEPTED_ORDER') THEN
        UPDATE ssa.products
        SET current_stock = current_stock - (p_journal_entry->>'quantity')::NUMERIC
        WHERE product_id = p_journal_entry->>'product_id';
    ELSIF v_proposal.event_type = 'STOCK_IN' THEN
        UPDATE ssa.products
        SET current_stock = current_stock + (p_journal_entry->>'quantity')::NUMERIC
        WHERE product_id = p_journal_entry->>'product_id';
    END IF;

    -- 8. Mark Proposal COMMITTED
    UPDATE ssa.pending_proposals
    SET status = 'COMMITTED',
        status_reason = 'COMMITTED_REV_' || v_new_rev,
        updated_iso = NOW()
    WHERE event_id = p_event_id;

    RETURN jsonb_build_object(
        'success', true,
        'event_id', p_event_id,
        'revision', v_new_rev,
        'transaction_id', p_journal_entry->>'transaction_id'
    );
END;
$$ LANGUAGE plpgsql;
