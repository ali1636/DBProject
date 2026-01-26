-- Migration 01: Create Strategic Indexes
-- This fixes the Sequential Scan problems on frequently queried columns

-- 1. Index for date-based searches
-- Fixes the /shipments/by-date endpoint
CREATE INDEX IF NOT EXISTS idx_shipments_created_at ON shipments(created_at);

-- 2. Index for status searches (common filter)
CREATE INDEX IF NOT EXISTS idx_shipments_status ON shipments(status);

-- 3. Composite index for origin and destination queries
CREATE INDEX IF NOT EXISTS idx_shipments_origin_dest ON shipments(origin_country, destination_country);

-- 4. Index for tracking UUID lookups
CREATE INDEX IF NOT EXISTS idx_shipments_tracking_uuid ON shipments(tracking_uuid);

-- Run ANALYZE to update statistics
ANALYZE shipments;