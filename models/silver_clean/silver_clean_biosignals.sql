-- later it should be changed from external into incremental
{{ config(
    materialized='external',  
    location='s3://silver-clean/biosignals/data.parquet'
)
}}

WITH raw_data AS (
    SELECT * FROM read_json_auto('s3://biosignals-bucket/topics/biosignal-data/partition=0/*.json')
)

-- TEMPORARY as we do not have data concerining sessions and participants
-- so we can not create PARTICIPATION for now and in the result we do not have
-- participation_id. 
SELECT DISTINCT
    CAST(student_id AS VARCHAR) AS participation_id, -- TO BE CHANGED
    epoch_ms(CAST(ts AS BIGINT)) AS timestamp,
    CAST(gsr AS FLOAT) AS gsr,
    CAST(ppg AS FLOAT) AS ppg,
    CAST(hr AS FLOAT) AS hr
FROM raw_data

WHERE ts IS NOT NULL
  AND student_id IS NOT NULL
  AND gsr IS NOT NULL AND gsr >= 0
  AND ppg IS NOT NULL AND ppg >= 0
  AND hr IS NOT NULL AND hr BETWEEN 0 AND 250