-- Migration 04: Partition Telemetry Table by Time Range
-- This reduces scan size from 2M rows to ~200K per partition

-- Step 1: Rename existing table
ALTER TABLE truck_telemetry RENAME TO truck_telemetry_old;

-- Step 2: Create new partitioned table
CREATE TABLE truck_telemetry (
    id SERIAL,
    truck_license_plate VARCHAR(50),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    elevation INT,
    speed INT,
    engine_temp DOUBLE PRECISION,
    fuel_level DOUBLE PRECISION,
    timestamp TIMESTAMP NOT NULL
) PARTITION BY RANGE (timestamp);

-- Step 3: Create partitions for each month
-- Adjust these dates based on your actual data range
CREATE TABLE truck_telemetry_2024_01 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE truck_telemetry_2024_02 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE truck_telemetry_2024_03 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

CREATE TABLE truck_telemetry_2024_04 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');

CREATE TABLE truck_telemetry_2024_05 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');

CREATE TABLE truck_telemetry_2024_06 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');

CREATE TABLE truck_telemetry_2024_07 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');

CREATE TABLE truck_telemetry_2024_08 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');

CREATE TABLE truck_telemetry_2024_09 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');

CREATE TABLE truck_telemetry_2024_10 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');

CREATE TABLE truck_telemetry_2024_11 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');

CREATE TABLE truck_telemetry_2024_12 PARTITION OF truck_telemetry
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

-- Default partition for any data outside these ranges
CREATE TABLE truck_telemetry_default PARTITION OF truck_telemetry DEFAULT;

-- Step 4: Copy data from old table to new partitioned table
INSERT INTO truck_telemetry 
SELECT * FROM truck_telemetry_old;

-- Step 5: Create indexes on partitioned table
CREATE INDEX IF NOT EXISTS idx_telemetry_truck_plate 
ON truck_telemetry(truck_license_plate);

CREATE INDEX IF NOT EXISTS idx_telemetry_timestamp 
ON truck_telemetry(timestamp);

CREATE INDEX IF NOT EXISTS idx_telemetry_truck_timestamp 
ON truck_telemetry(truck_license_plate, timestamp DESC);

-- Step 6: Drop old table
DROP TABLE truck_telemetry_old;

-- Update statistics
ANALYZE truck_telemetry;