-- Migration 05: Create Materialized Views for Analytics
-- Pre-compute expensive aggregations

-- Step 1: Create materialized view for daily statistics
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_stats AS
SELECT 
    COUNT(*) FILTER (WHERE status='DELIVERED') as delivered_count,
    COUNT(*) FILTER (WHERE status='IN_TRANSIT') as in_transit_count,
    COUNT(*) FILTER (WHERE status='NEW') as new_count,
    COUNT(*) as total_shipments,
    CURRENT_TIMESTAMP as last_updated
FROM shipments;

-- Step 2: Create index on the materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_stats_updated 
ON daily_stats(last_updated);

-- Step 3: Create materialized view for telemetry aggregates
CREATE MATERIALIZED VIEW IF NOT EXISTS telemetry_stats AS
SELECT 
    AVG(speed) as avg_speed,
    MAX(speed) as max_speed,
    AVG(engine_temp) as avg_engine_temp,
    AVG(fuel_level) as avg_fuel_level,
    COUNT(*) as total_readings,
    CURRENT_TIMESTAMP as last_updated
FROM truck_telemetry;

-- Step 4: Create materialized view for revenue calculations
CREATE MATERIALIZED VIEW IF NOT EXISTS revenue_stats AS
SELECT 
    SUM(CAST(invoice_data->>'amount_cents' AS INTEGER)) as total_revenue_cents,
    AVG(CAST(invoice_data->>'amount_cents' AS INTEGER)) as avg_invoice_cents,
    COUNT(*) as total_invoices,
    COUNT(DISTINCT invoice_data->>'currency') as currency_count,
    CURRENT_TIMESTAMP as last_updated
FROM finance_invoices
WHERE invoice_data IS NOT NULL;

-- Step 5: Create combined analytics view
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics_dashboard AS
SELECT 
    ds.delivered_count,
    ds.in_transit_count,
    ds.new_count,
    ds.total_shipments,
    ts.avg_speed,
    ts.max_speed,
    rs.total_revenue_cents,
    rs.avg_invoice_cents,
    rs.total_invoices,
    CURRENT_TIMESTAMP as snapshot_time
FROM daily_stats ds
CROSS JOIN telemetry_stats ts
CROSS JOIN revenue_stats rs;

-- Refresh all materialized views
REFRESH MATERIALIZED VIEW daily_stats;
REFRESH MATERIALIZED VIEW telemetry_stats;
REFRESH MATERIALIZED VIEW revenue_stats;
REFRESH MATERIALIZED VIEW analytics_dashboard;