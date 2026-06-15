-- later it should be changed from external into incremental
{{ config(
    materialized='external',  
    location='s3://silver-clean/participant/data.parquet'
)
}}

WITH raw_data AS (
    SELECT * FROM read_parquet('s3://metadata-bucket/participant/*.parquet')
)

SELECT DISTINCT
    CAST(participantid AS INT) AS participation_id,
    CAST(name AS VARCHAR) AS name,
    CAST(birthday AS DATE) AS birthday,
    UPPER(TRIM(CAST(gender AS VARCHAR))) AS gender
FROM raw_data
    WHERE participantid IS NOT NULL
  