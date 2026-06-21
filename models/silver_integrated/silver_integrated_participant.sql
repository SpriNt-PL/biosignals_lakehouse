{{ config(
    materialized='external',  
    location='s3://silver-integrated/participant/data.parquet'
)
}}

WITH source_data AS (
    SELECT * FROM {{ ref('silver_clean_participant') }}
)

SELECT
    participant_id,
    name,
    birthday,
    gender
FROM source_data