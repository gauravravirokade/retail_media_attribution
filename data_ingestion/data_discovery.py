import os
import json
import pandas as pd

# Define data directory
DATA_DIR = "/Users/gauravrokade/Downloads/retail_media_attribution/data"

# Exact filename mapping from your directory
files_map = {
    "impressions": "RECRUITMENT_IMPRESSION_SAMPLE_202605202052.csv",
    "cookie_proxy": "RECRUITMENT_COOKIE_PROXY_SAMPLE_202605202053.csv",
    "ttd_match": "RECRUITMENT_TTD_MATCH_SAMPLE_202605202053.csv",
    "device_match": "RECRUITMENT_DEVICE_MATCH_SAMPLE_202605202053.csv",
    "member_proxy": "RECRUITMENT_MEMBER_PROXY_SAMPLE_202605202054.csv",
    "purchases": "RECRUITMENT_SKU_PURCHASES_SAMPLE_202605202054.csv"
}

def check_for_json(series):
    """Checks if a column contains valid JSON strings."""
    # Drop nulls and check the first non-null value
    sample_val = series.dropna().iloc[0] if not series.dropna().empty else None
    if isinstance(sample_val, str):
        sample_val = sample_val.strip()
        if (sample_val.startswith('{') and sample_val.endswith('}')) or \
           (sample_val.startswith('[') and sample_val.endswith(']')):
            try:
                json.loads(sample_val)
                return True
            except ValueError:
                return False
    return False

# Loop through and display diagnostics for all files at once
for key, file_name in files_map.items():
    file_path = os.path.join(DATA_DIR, file_name)
    
    if not os.path.exists(file_path):
        print(f"⚠️ File not found: {file_name}\n")
        continue
        
    print("=" * 80)
    print(f"📋 PREVIEWING FILE: {file_name} (Table Reference: staging.{key})")
    print("=" * 80)
    
    # Load 5 sample rows
    df = pd.read_csv(file_path, nrows=5)
    
    # 1. Display Schema / Data Types
    print("\n🔹 Column Names & Inferred Data Types:")
    schema_df = pd.DataFrame({
        'Inferred Type': df.dtypes.astype(str),
        'Has Nulls in Sample': df.isna().any()
    })
    print(schema_df)
    
    # 2. Run JSON structural check
    json_cols = [col for col in df.columns if check_for_json(df[col])]
    if json_cols:
        print(f"\n🚨 ALERT: Potential Nested JSON detected in these columns: {json_cols}")
    else:
        print("\n✅ Structure Check: No obvious nested JSON text blocks found in the sample.")
        
    # 3. Print Top 5 Records
    print("\n🔹 Top 5 Rows:")
    # Displaying transposed version makes it much cleaner to read if columns are wide
    print(df.to_string(index=False)) 
    print("\n" + "_"*80 + "\n")