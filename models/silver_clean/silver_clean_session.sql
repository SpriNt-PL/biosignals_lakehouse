-- later it should be changed from external into incremental
{{ config(
    materialized='external',  
    location='s3://silver-clean/session/data.parquet'
)
}}

WITH raw_data AS (
    SELECT * FROM read_parquet('s3://metadata-bucket/session/*.parquet')
)

SELECT DISTINCT
    CAST(sessionid AS INT) AS session_id,
    CAST(session_date AS DATETIME) AS session_date,
    CAST(location AS VARCHAR) AS location,
    CAST(experiment_type AS VARCHAR) AS experiment_type,
FROM raw_data
    WHERE sessionid IS NOT NULL
  