import duckdb

con = duckdb.connect()
con.execute("INSTALL httpfs; LOAD httpfs;")
con.execute("INSTALL postgres; LOAD postgres;")

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

print("Connecting to PostgreSQL...")
con.execute("ATTACH 'dbname=experiment_db user=admin password=password123 host=localhost port=5432' AS postgres_meta (TYPE POSTGRES);")

print("Extracting PARTICIPANT to Bronze...")
con.execute("COPY postgres_meta.public.participant TO 's3://metadata-bucket/participant/data.parquet' (FORMAT PARQUET);")

print("Extracting SESSION to Bronze...")
con.execute("COPY postgres_meta.public.session TO 's3://metadata-bucket/session/data.parquet' (FORMAT PARQUET);")

print("Extracting STATION to Bronze...")
con.execute("COPY postgres_meta.public.station TO 's3://metadata-bucket/station/data.parquet' (FORMAT PARQUET);")

print("Extracting PARTICIPATION to Bronze...")
con.execute("COPY postgres_meta.public.participation TO 's3://metadata-bucket/participation/data.parquet' (FORMAT PARQUET);")
print("Extraction complete! Metadata is now in the Bronze layer.")