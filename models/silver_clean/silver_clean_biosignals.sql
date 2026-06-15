-- later it should be changed from external into incremental
{{ config(
    materialized='external',  
    location='s3://silver-clean/biosignals/data.parquet'
)
}}

WITH raw_data AS (
    SELECT * FROM read_json_auto('s3://biosignals-bucket/topics/biosignal-data/partition=0/*.json')
)

SELECT DISTINCT
    CAST(participation_id AS VARCHAR) AS participation_id, -- ALREADY CHANGED, PROPER ID
    epoch_ms(CAST(ts AS BIGINT)) AS timestamp,
    CAST(gsr AS FLOAT) AS gsr,
    CAST(ppg AS FLOAT) AS ppg,
    CAST(hr AS FLOAT) AS hr
FROM raw_data

WHERE ts IS NOT NULL
  AND participation_id IS NOT NULL
  AND gsr IS NOT NULL AND gsr >= 0
  AND ppg IS NOT NULL AND ppg >= 0
  AND hr IS NOT NULL AND hr BETWEEN 0 AND 250