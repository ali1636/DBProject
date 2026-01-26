-- Migration 02: Database Normalization
-- Extract driver and truck data into separate tables

-- Step 1: Create drivers table
CREATE TABLE IF NOT EXISTS drivers (
    driver_id SERIAL PRIMARY KEY,
    driver_name VARCHAR(255) NOT NULL,
    driver_phone VARCHAR(50),
    UNIQUE(driver_name, driver_phone)
);

-- Step 2: Create trucks table
CREATE TABLE IF NOT EXISTS trucks (
    truck_id SERIAL PRIMARY KEY,
    license_plate VARCHAR(50) NOT NULL UNIQUE,
    truck_model VARCHAR(100),
    capacity_tons INT
);

-- Step 3: Extract and insert unique drivers
-- Parse the driver_details column (format: "name,phone,plate")
INSERT INTO drivers (driver_name, driver_phone)
SELECT DISTINCT 
    SPLIT_PART(driver_details, ',', 1) as driver_name,
    SPLIT_PART(driver_details, ',', 2) as driver_phone
FROM shipments
WHERE driver_details IS NOT NULL
ON CONFLICT (driver_name, driver_phone) DO NOTHING;

-- Step 4: Extract and insert unique trucks
-- Parse truck_details column (format: "plate,model,capacity")
INSERT INTO trucks (license_plate, truck_model, capacity_tons)
SELECT DISTINCT 
    SPLIT_PART(truck_details, ',', 1) as license_plate,
    SPLIT_PART(truck_details, ',', 2) as truck_model,
    CAST(REGEXP_REPLACE(SPLIT_PART(truck_details, ',', 3), '[^0-9]', '', 'g') AS INT) as capacity_tons
FROM shipments
WHERE truck_details IS NOT NULL
ON CONFLICT (license_plate) DO NOTHING;

-- Step 5: Add foreign key columns to shipments
ALTER TABLE shipments 
ADD COLUMN IF NOT EXISTS driver_id INT,
ADD COLUMN IF NOT EXISTS truck_id INT;

-- Step 6: Update shipments with driver_id
UPDATE shipments s
SET driver_id = d.driver_id
FROM drivers d
WHERE SPLIT_PART(s.driver_details, ',', 1) = d.driver_name
  AND SPLIT_PART(s.driver_details, ',', 2) = d.driver_phone;

-- Step 7: Update shipments with truck_id
UPDATE shipments s
SET truck_id = t.truck_id
FROM trucks t
WHERE SPLIT_PART(s.truck_details, ',', 1) = t.license_plate;

-- Step 8: Add foreign key constraints
ALTER TABLE shipments
ADD CONSTRAINT fk_shipments_driver 
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
ADD CONSTRAINT fk_shipments_truck 
    FOREIGN KEY (truck_id) REFERENCES trucks(truck_id);

-- Step 9: Create indexes on the new foreign keys
CREATE INDEX IF NOT EXISTS idx_shipments_driver_id ON shipments(driver_id);
CREATE INDEX IF NOT EXISTS idx_shipments_truck_id ON shipments(truck_id);
CREATE INDEX IF NOT EXISTS idx_drivers_name ON drivers(driver_name);
CREATE INDEX IF NOT EXISTS idx_trucks_plate ON trucks(license_plate);

-- Step 10: Drop old redundant columns (optional - uncomment if you want to save space)
-- ALTER TABLE shipments DROP COLUMN IF EXISTS driver_details;
-- ALTER TABLE shipments DROP COLUMN IF EXISTS truck_details;

-- Reclaim space and update statistics
VACUUM ANALYZE shipments;
VACUUM ANALYZE drivers;
VACUUM ANALYZE trucks;