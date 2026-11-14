-- later it should be changed from external into incremental
{{ config(
    materialized='external',  
    location='s3://silver-clean/session/data.parquet'
)
}}

WITH raw_data AS (
    SELECT * FROM {{ ref('bronze_session') }}
)

SELECT DISTINCT
    CAST(sessionid AS INT) AS session_id,
    CAST(location AS VARCHAR) AS location,
    CAST(experiment_type AS VARCHAR) AS experiment_type,
    CAST(start_time AS DATETIME) AS start_time,
    CAST(end_time AS DATETIME) AS end_time
FROM raw_data
    WHERE sessionid IS NOT NULL
  