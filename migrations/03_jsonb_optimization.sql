-- Migration 03: Convert JSON to JSONB and Add GIN Index
-- This dramatically speeds up JSON queries

-- Step 1: Add new JSONB column
ALTER TABLE finance_invoices 
ADD COLUMN IF NOT EXISTS invoice_data JSONB;

-- Step 2: Convert existing TEXT JSON to JSONB
UPDATE finance_invoices 
SET invoice_data = raw_invoice_data::JSONB
WHERE invoice_data IS NULL;

-- Step 3: Create GIN index for fast JSON key searches
CREATE INDEX IF NOT EXISTS idx_finance_invoices_jsonb 
ON finance_invoices USING GIN (invoice_data);

-- Step 4: Create specific index for amount_cents searches (most common query)
CREATE INDEX IF NOT EXISTS idx_finance_invoices_amount 
ON finance_invoices ((CAST(invoice_data->>'amount_cents' AS INTEGER)));

-- Step 5: Add index for shipment_uuid lookups
CREATE INDEX IF NOT EXISTS idx_finance_invoices_shipment 
ON finance_invoices(shipment_uuid);

-- Step 6: Add index for issued_date
CREATE INDEX IF NOT EXISTS idx_finance_invoices_date 
ON finance_invoices(issued_date);

-- Optional: Drop old TEXT column to save space (uncomment if needed)
-- ALTER TABLE finance_invoices DROP COLUMN IF EXISTS raw_invoice_data;

-- Update statistics
ANALYZE finance_invoices;