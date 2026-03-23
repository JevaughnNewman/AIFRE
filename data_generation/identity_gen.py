import pandas as pd
import numpy as np
import random
import os
from datetime import datetime, timedelta

# Path Configuration - Keep your local path
BASE_DIR = "/Users/jevaughnnewman/Desktop/AIFRE_Project"
RAW_DIR = os.path.join(BASE_DIR, "RAW Sources")

def get_dirty_date(base_date):
    formats = ['%Y-%m-%d', '%d/%m/%Y', '%m-%d-%Y', '%b %d, %Y']
    fmt = random.choice(formats)
    return base_date.strftime(fmt)

def generate_enterprise_identity(n=50000):
    output_path = os.path.join(RAW_DIR, 'AIFRE_Identity_Registry_RAW.csv')
    os.makedirs(RAW_DIR, exist_ok=True)
    
    # 1. NEW: Targeted High-Risk Clusters (GTA Hotspots)
    # Brampton (L6Y, L6P), North York (M3N), Scarborough (M1B)
    hotspots = [
        {"city": "Brampton", "pc": "L6Y 2A1", "addr": "123 Sandalwood Pkwy"},
        {"city": "North York", "pc": "M3N 1Y8", "addr": "4000 Jane St"}, # Famous high-frequency address
        {"city": "Scarborough", "pc": "M1B 5P1", "addr": "250 Milner Ave"},
        {"city": "Etobicoke", "pc": "M9V 3S9", "addr": "100 Humber College Blvd"}
    ]
    
    cities = ["Toronto", "Ottawa", "Mississauga", "Brampton", "Hamilton", "London", "Markham"]
    first_names = ["James", "Mary", "Robert", "Patricia", "Michael", "Linda", "William", "Elizabeth"]
    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis"]
    
    data = []
    print(f"Generating {n} Identity records with Geographic Collision Rings...")

    for i in range(n):
        roll = random.random()
        
        # 2. INJECTING CLUSTERS (The "Collision Ring" Signal)
        # 10% of the population will be forced into 4 specific buildings/blocks
        if roll < 0.10:
            spot = random.choice(hotspots)
            city = spot["city"]
            postal_code = spot["pc"]
            address = f"{random.randint(10, 50)} - {spot['addr']}" # Multiple units in one building
        else:
            city = random.choice(cities)
            postal_code = f"{random.choice(['M', 'L', 'K'])}{random.randint(1,9)}{random.choice(['A', 'B', 'C'])} {random.randint(1,9)}{random.choice(['X', 'Y', 'Z'])}{random.randint(1,9)}"
            address = f"{random.randint(1, 999)} {random.choice(['Main St', 'Bay St', 'King St', 'Dundas St'])}"

        f_name = random.choice(first_names)
        l_name = random.choice(last_names)
        full_name = f"{f_name} {l_name}"
        
        # --- Metadata & Chaos (Preserving your logic) ---
        phone_type = random.choices(["MOBILE", "LANDLINE", "VOIP"], weights=[0.7, 0.2, 0.1])[0]
        kyc_status = random.choices(["VERIFIED", "PENDING", "EXPIRED"], weights=[0.8, 0.1, 0.1])[0]
        kyc_date = get_dirty_date(datetime.now() - timedelta(days=random.randint(0, 2500)))

        if roll < 0.05: full_name = full_name.upper()
        if roll < 0.05: city = f"  {city}  "
        
        age = random.randint(18, 85)
        if i % 5000 == 0: age = 300 # Outlier
        
        sin = f"{random.randint(100,799)}-{random.randint(100,999)}-{random.randint(100,999)}"
        if roll < 0.15: sin = sin.replace("-", "") 
        
        score = random.randint(300, 850) if roll > 0.15 else None

        # Anchor for APP-CRITICAL-999
        if i == 0:
            app_id, full_name, sin, postal_code = "APP-CRITICAL-999", "Michael Smith", "999-999-999", "M3N 1Y8"
        else:
            app_id = f"APP-{i+1:06d}"

        data.append({
            "APP_ID": app_id,
            "FULL_NAME": full_name,
            "SIN": sin,
            "ADDRESS": address,
            "CITY": city,
            "POSTAL_CODE": postal_code,
            "AGE": age,
            "OCCUPATION": random.choice(["Adjuster", "Nurse", "Engineer", "Driver", "Contractor"]),
            "PHONE_NUMBER": f"416-{random.randint(100, 999)}-{random.randint(1000, 9999)}",
            "PHONE_TYPE": phone_type,
            "KYC_STATUS": kyc_status,
            "KYC_LAST_VERIFIED_DATE": kyc_date,
            "CREDIT_SCORE": score
        })

    df = pd.DataFrame(data)

    # 3. FUZZY DUPLICATES
    dupe_row = df.iloc[0].copy()
    dupe_row["APP_ID"], dupe_row["FULL_NAME"], dupe_row["CITY"] = "APP-DUP-001", "m smith", "markham"
    df = pd.concat([df, pd.DataFrame([dupe_row])], ignore_index=True)

    df.to_csv(output_path, index=False)
    print(f"SUCCESS: Created {output_path} with 10% Targeted Clusters.")

if __name__ == "__main__":
    generate_enterprise_identity(50000)