-- later it should be changed from external into incremental
{{ config(
    materialized='external',  
    location='s3://silver-clean/participation/data.parquet'
)
}}

WITH raw_data AS (
    SELECT * FROM read_parquet('s3://metadata-bucket/participation/*.parquet')
)

SELECT DISTINCT
    CAST(participationid AS VARCHAR) AS participation_id,
    CAST(participantid AS INT) AS participant_id,
    CAST(sessionid AS INT) AS session_id,
FROM raw_data
    WHERE participationid IS NOT NULL
    AND participantid IS NOT NULL
    AND sessionid IS NOT NULL