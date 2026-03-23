import json
import random
import os
import uuid
from datetime import datetime, timedelta

# Path Configuration
BASE_DIR = "/Users/jevaughnnewman/Desktop/AIFRE_Project"
RAW_DIR = os.path.join(BASE_DIR, "RAW Sources")

def generate_enterprise_logs(n=150000):
    output_path = os.path.join(RAW_DIR, 'AIFRE_Logs_RAW.json')
    os.makedirs(RAW_DIR, exist_ok=True)
    
    # Fingerprinting Pool
    browsers = ["Chrome", "Safari", "Firefox", "Edge", "PostmanRuntime", "Python-Requests"]
    devices = [f"DEV-{uuid.uuid4().hex[:6].upper()}" for _ in range(5000)] 
    
    # 1. HIGH-RISK PROXY POOL
    # These IPs represent a 'Fraud Farm' or a compromised VPN
    proxy_ips = ["192.168.1.50", "45.33.22.11", "10.0.0.99"]
    fraud_device = "DEV-FRAUD-RING-001"

    start_date = datetime(2026, 1, 1)
    print(f"Generating {n} Logs with Digital Triangulation...")

    with open(output_path, 'w') as f:
        for i in range(n):
            roll = random.random()
            app_num = random.randint(1, 50000)
            app_id = f"APP-{app_num:06d}"
            
            # --- COORDINATED ATTACK LOGIC ---
            # If the APP_ID is part of our 'Hotspot' (divisible by 12, matching our Ledger/Identity)
            if app_num % 12 == 0:
                ip_address = random.choice(proxy_ips)
                device_id = fraud_device
                browser = "Python-Requests" # Bots don't use Chrome
                seconds_on_page = random.randint(1, 3)
                proxy_detected = True
            else:
                ip_address = f"{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}"
                device_id = random.choice(devices)
                browser = random.choices(browsers, weights=[60, 20, 10, 5, 3, 2])[0]
                seconds_on_page = random.randint(30, 300)
                proxy_detected = False

            # --- DATA CHAOS (Preserving your logic) ---
            session_id = f"SESS-{uuid.uuid4().hex[:8].upper()}"
            if roll < 0.05: session_id = session_id.lower()
            if roll < 0.01: seconds_on_page = -99 

            ts = (start_date + timedelta(seconds=random.randint(0, 5184000)))
            event_time = ts.isoformat() if roll > 0.10 else str(int(ts.timestamp()))

            log_entry = {
                "session_id": session_id,
                "app_id": app_id,
                "device_id": device_id,
                "browser": browser,
                "seconds_on_page": seconds_on_page,
                "ip_address": ip_address,
                "proxy_detected": proxy_detected,
                "event_time": event_time,
                "request_path": random.choice(["/apply", "/submit_OCF1", "/check_status"]),
                "response_code": random.choice([200, 200, 403, 500])
            }
            
            # The "Michael Smith" Critical Outlier
            if i == 0:
                log_entry["app_id"] = "APP-CRITICAL-999"
                log_entry["ip_address"] = "192.168.1.50"
                log_entry["device_id"] = fraud_device
                log_entry["browser"] = "PostmanRuntime"

            f.write(json.dumps(log_entry) + "\n")

    print(f"SUCCESS: Created {output_path}")

if __name__ == "__main__":
    generate_enterprise_logs(150000)