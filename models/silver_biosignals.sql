{{ config(
    materialized='external',
    location='s3://silver-test/biosignals_clean/parquet_test.parquet'
)
}}

WITH raw_data AS (
    SELECT * FROM read_json_auto('s3://biosignals-bucket/topics/biosignal-data/partition=0/*.json')
)

SELECT DISTINCT
    
    epoch_ms(CAST(ts AS BIGINT)) AS timestamp,
    
    student_id AS subject_id,
    
    CAST(gsr AS FLOAT) AS gsr_value,
    CAST(ppg AS FLOAT) AS ppg_value,
    CAST(hr AS FLOAT) AS heart_rate

FROM raw_data

WHERE ts IS NOT NULL 
  AND gsr IS NOT NULL