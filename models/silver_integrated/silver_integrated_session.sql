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
    session_date,
    location,
    experiment_type
FROM source_data