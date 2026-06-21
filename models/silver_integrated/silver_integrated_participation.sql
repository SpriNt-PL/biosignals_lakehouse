{{ config(
    materialized='external',  
    location='s3://silver-integrated/participation/data.parquet'
)
}}

WITH source_data AS (
    SELECT * FROM {{ ref('silver_clean_participation') }}
)

SELECT
    participation_id,
    participant_id,
    session_id
FROM source_data