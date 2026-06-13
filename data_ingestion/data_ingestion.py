import os
import pandas as pd
from sqlalchemy import create_engine, text

# 1. Directory and Exact File Configurations
DATA_DIR = "/Users/gauravrokade/Downloads/retail_media_attribution/data"

files_map = {
    "impressions": "RECRUITMENT_IMPRESSION_SAMPLE_202605202052.csv",
    "cookie_proxy": "RECRUITMENT_COOKIE_PROXY_SAMPLE_202605202053.csv",
    "ttd_match": "RECRUITMENT_TTD_MATCH_SAMPLE_202605202053.csv",
    "device_match": "RECRUITMENT_DEVICE_MATCH_SAMPLE_202605202053.csv",
    "member_proxy": "RECRUITMENT_MEMBER_PROXY_SAMPLE_202605202054.csv",
    "purchases": "RECRUITMENT_SKU_PURCHASES_SAMPLE_202605202054.csv"
}

# 2. Database Connection Setup
DB_URL = "postgresql://postgres:postgres@localhost:5432/retail_media_attribution"
engine = create_engine(DB_URL)


# 3. Create the RAW Isolation Schema cleanly using a transaction block
with engine.begin() as conn:
    conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw;"))
print("✓ Initialized 'raw' schema in PostgreSQL.")

print("=" * 70)
print("🚀 STARTING RAW DATA INGESTION WITH WATERMARKS")
print("=" * 70)

# Capture a single static timestamp for the batch run
current_ingestion_ts = pd.Timestamp.now(tz='UTC')

# 4. Ingestion Loop
for table_name, file_name in files_map.items():
    file_path = os.path.join(DATA_DIR, file_name)
    
    if not os.path.exists(file_path):
        print(f"⚠️ File missing, skipping: {file_name}")
        continue
        
    print(f"Streaming {file_name} into raw.{table_name}...")
    
    # CASE A: Handle the 1.51 GB impressions file safely using chunks
    if table_name == "impressions":
        chunk_size = 200000
        is_first_chunk = True
        
        with pd.read_csv(file_path, chunksize=chunk_size, dtype=str) as reader:
            for idx, chunk in enumerate(reader):
                # Add our lineage watermarks directly to the dataframe chunk
                chunk['ingested_at'] = str(current_ingestion_ts)
                chunk['file_source_name'] = file_name
                
                if_exists_behavior = 'replace' if is_first_chunk else 'append'
                
                chunk.to_sql(
                    name=table_name,
                    con=engine,
                    schema='raw',
                    if_exists=if_exists_behavior,
                    index=False
                )
                is_first_chunk = False
                print(f"   -> Successfully loaded chunk {idx + 1} with watermarks...")
                
    # CASE B: Handle lookup maps and purchases (reads entirely in one go)
    else:
        df = pd.read_csv(file_path, dtype=str)
        
        # Add identical watermarks to the smaller tables
        df['ingested_at'] = str(current_ingestion_ts)
        df['file_source_name'] = file_name
        
        df.to_sql(
            name=table_name,
            con=engine,
            schema='raw',
            if_exists='replace',
            index=False
        )
        print(f"✓ Successfully loaded raw.{table_name} with watermarks ({len(df)} rows).")

print("=" * 70)
print("🎉 ELT INGESTION COMPLETE: Data landed safely with metadata lineage columns!")
print("=" * 70)