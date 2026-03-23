import pandas as pd
import numpy as np
import random
import os
from datetime import datetime, timedelta

# Configuration
BASE_DIR = "/Users/jevaughnnewman/Desktop/AIFRE_Project"
RAW_DIR = os.path.join(BASE_DIR, "RAW Sources")

def generate_enterprise_ledger(n=100000):
    identity_path = os.path.join(RAW_DIR, 'AIFRE_Identity_Registry_RAW.csv')
    output_path = os.path.join(RAW_DIR, 'AIFRE_Ledger_Registry_RAW.csv')
    os.makedirs(RAW_DIR, exist_ok=True)

    mcc_map = {
        "Medical Clinic": "8011",
        "Pharmacy": "5912",
        "Legal Services": "8111",
        "Towing Service": "7549",
        "Auto Rental": "7512",
        "Medical Equipment": "5047"
    }

    # 1. CREATE THE "LONG TAIL" VENDOR POOL (1,000+ Vendors)
    # This simulates a real city like Toronto/Ottawa
    standard_vendors = [f"Vendor_Service_Node_{i:04d}" for i in range(1, 1001)]
    
    # The "Dirty Dozen" - High-frequency suspects for your Gold Marts
    suspicious_merchants = [
        "GTA REHAB CENTER", "NORTH YORK LEGAL HUB", "BRAMPTON PHYSIO INC", 
        "JANE ST ASSESSMENTS", "MILNER MEDICAL GROUP", "SCARBOROUGH CLINIC"
    ]

    try:
        id_df = pd.read_csv(identity_path)
        all_app_ids = id_df['APP_ID'].unique().tolist()
        
        # Identify the "Hotspot" claimants from our Identity script
        hotspot_ids = id_df[id_df['POSTAL_CODE'].isin(['M3N 1Y8', 'L6Y 2A1', 'M1B 5P1'])]['APP_ID'].tolist()
        fraud_sin_ids = id_df[id_df['SIN'].str.contains('999', na=False)]['APP_ID'].tolist()

        data = []
        print(f"Generating {n} Ledger records across 1,000+ vendors...")

        for i in range(n):
            app_id = random.choice(all_app_ids)
            entry_mode = random.choices(["CHIP_AND_PIN", "TAP", "MANUAL_KEY_IN"], weights=[0.7, 0.2, 0.1])[0]
            
            # --- THE "POWER LAW" DISTRIBUTION ---
            # If the claimant is in a hotspot, they have a 40% chance of being funneled to a mill
            if app_id in hotspot_ids and random.random() < 0.40:
                merchant_name = random.choice(suspicious_merchants)
                cat = "Medical Clinic" if "REHAB" in merchant_name or "CLINIC" in merchant_name else "Legal Services"
                amount = round(random.uniform(1900, 2450), 2) # Typical high-end "staged" bill
            else:
                # 90% chance of a standard vendor, 10% chance of a random suspicious one
                merchant_name = random.choice(standard_vendors)
                cat = random.choice(list(mcc_map.keys()))
                amount = round(random.uniform(25, 1200), 2) # Normal distribution

            mcc = mcc_map.get(cat, "8011")

            # Known Fraud Pool Behavior
            if app_id in fraud_sin_ids:
                amount = round(random.uniform(5000, 9500), 2)
                entry_mode = "MANUAL_KEY_IN"

            # DQ Outliers
            if i % 3000 == 0: amount = 0.00
            if i % 7000 == 0: amount = 99999.99

            data.append({
                "TXN_ID": f"TXN-{i+1:07d}",
                "APP_ID": app_id,
                "TIMESTAMP": (datetime.now() - timedelta(minutes=random.randint(0, 150000))).strftime('%Y-%m-%d %H:%M:%S'),
                "AMOUNT": amount,
                "MERCHANT_NAME": merchant_name,
                "MERCHANT_CAT": cat,
                "MCC_CODE": mcc,
                "ENTRY_MODE": entry_mode,
                "STATUS": "COMPLETED"
            })

        df = pd.DataFrame(data)
        
        # Duplicate Records (Simulating double-billing fraud)
        dupes = df.sample(300).copy() 
        df = pd.concat([df, dupes], ignore_index=True)

        df.to_csv(output_path, index=False)
        print(f"SUCCESS: Created ledger with {len(df['MERCHANT_NAME'].unique())} unique vendors.")

    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    generate_enterprise_ledger(100000)