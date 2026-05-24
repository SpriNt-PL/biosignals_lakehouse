import duckdb
import pandas

con = duckdb.connect()

con.execute("INSTALL httpfs;")
con.execute("LOAD httpfs;")

con.execute("""
            CREATE SECRET minio_secret (
                TYPE S3,
                KEY_ID 'admin',
                SECRET 'password123',       
                ENDPOINT 'localhost:9005', 
                URL_STYLE 'path',
                USE_SSL false
            );
            """)

query = """
    SELECT * FROM read_json_auto('s3://biosignals-bucket/topics/biosignal-data/partition=0/*.json')
    LIMIT 10;
"""

try:
    df = con.execute(query).fetch_df()
    print(df)

except Exception as e:
    print(f"Read error: {e}")