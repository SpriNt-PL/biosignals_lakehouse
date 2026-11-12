{{ config(
    materialized='external',  
    location='s3://silver-integrated/session/data.parquet'
)
}}

WITH source_data AS (
    SELECT * FROM {{ ref('silver_clean_session') }}
)

SELECT
    session_id,
    location,
    experiment_type,
    start_time,
    end_time
FROM source_data