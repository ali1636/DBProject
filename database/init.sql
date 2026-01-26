-- database/init.sql
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS truck_telemetry;
DROP TABLE IF EXISTS finance_invoices;

-- 1. OPS: The Monolith
CREATE TABLE shipments (
    id SERIAL PRIMARY KEY,
    tracking_uuid TEXT,
    origin_country TEXT,
    destination_country TEXT,
    driver_details TEXT,
    truck_details TEXT,
    status TEXT,
    created_at TEXT
);

-- 2. IOT: The Time-Series Trap
CREATE TABLE truck_telemetry (
    id SERIAL PRIMARY KEY,
    truck_license_plate TEXT,
    latitude FLOAT,
    longitude FLOAT,
    elevation INT,
    speed INT,
    engine_temp FLOAT,
    fuel_level FLOAT,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- 3. FINANCE: The JSON Dump
CREATE TABLE finance_invoices (
    id SERIAL PRIMARY KEY,
    shipment_uuid TEXT,
    raw_invoice_data TEXT, 
    issued_date DATE
);