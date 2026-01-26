# backend/app.py - OPTIMIZED VERSION
from fastapi import FastAPI, Request
import time
import psycopg2
import os
import json

app = FastAPI()
DB_URL = os.getenv("DATABASE_URL")

# --- PERFORMANCE LOGGER MIDDLEWARE ---
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

def get_db_connection():
    return psycopg2.connect(DB_URL)

@app.get("/")
def read_root():
    return {"message": "System Online. Performance: OPTIMIZED."}

# --- OPTIMIZED: Indexed Date Search ---
@app.get("/shipments/by-date")
def get_by_date(date: str):
    conn = get_db_connection()
    cur = conn.cursor()
    # OPTIMIZED: Use proper date comparison with indexed column
    # Convert LIKE pattern to proper date range
    cur.execute("""
        SELECT * FROM shipments 
        WHERE created_at >= %s::timestamp 
        AND created_at < (%s::timestamp + INTERVAL '1 month')
        LIMIT 1000
    """, (date + '-01', date + '-01'))
    rows = cur.fetchall()
    conn.close()
    return rows

# --- OPTIMIZED: Normalized Driver Search ---
@app.get("/shipments/driver/{name}")
def get_by_driver(name: str):
    conn = get_db_connection()
    cur = conn.cursor()
    # OPTIMIZED: Use normalized drivers table with indexed join
    cur.execute("""
        SELECT s.* 
        FROM shipments s
        JOIN drivers d ON s.driver_id = d.driver_id
        WHERE d.driver_name ILIKE %s
        LIMIT 1000
    """, (f"%{name}%",))
    rows = cur.fetchall()
    conn.close()
    return rows

# --- OPTIMIZED: JSONB Query with Index ---
@app.get("/finance/high-value-invoices")
def get_high_value():
    conn = get_db_connection()
    cur = conn.cursor()
    # OPTIMIZED: Use JSONB column with indexed expression
    cur.execute("""
        SELECT * FROM finance_invoices 
        WHERE (invoice_data->>'amount_cents')::INTEGER > 50000
        LIMIT 1000
    """)
    rows = cur.fetchall()
    conn.close()
    return rows

# --- OPTIMIZED: Partitioned Telemetry Query ---
@app.get("/telemetry/truck/{plate}")
def get_truck_history(plate: str):
    conn = get_db_connection()
    cur = conn.cursor()
    # OPTIMIZED: Partitioning + composite index automatically limits scan
    cur.execute("""
        SELECT * FROM truck_telemetry 
        WHERE truck_license_plate = %s 
        ORDER BY timestamp DESC 
        LIMIT 100
    """, (plate,))
    rows = cur.fetchall()
    conn.close()
    return rows

# --- OPTIMIZED: Materialized View for Analytics ---
@app.get("/analytics/daily-stats")
def get_stats():
    conn = get_db_connection()
    cur = conn.cursor()
    # OPTIMIZED: Read from pre-computed materialized view
    cur.execute("""
        SELECT 
            delivered_count as delivered,
            avg_speed,
            total_revenue_cents as revenue
        FROM analytics_dashboard
        LIMIT 1
    """)
    rows = cur.fetchall()
    
    # Refresh materialized views periodically (async in production)
    # For demo purposes, we check if data is stale
    cur.execute("""
        SELECT 
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - snapshot_time)) as age_seconds
        FROM analytics_dashboard
        LIMIT 1
    """)
    result = cur.fetchone()
    
    # Refresh if older than 5 minutes (300 seconds)
    if result and result[0] > 300:
        cur.execute("REFRESH MATERIALIZED VIEW analytics_dashboard")
        conn.commit()
    
    conn.close()
    return rows