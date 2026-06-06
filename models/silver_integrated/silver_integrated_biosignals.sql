{{ config(
    materialized='external',  
    location='s3://silver-integrated/biosignals/data.parquet'
)
}}

WITH source_data AS (
    SELECT * FROM read_parquet('s3://silver-clean/biosignals/data.parquet')
),

session_start AS (
    SELECT
        participation_id,
        MIN(timestamp) AS first_timestamp
    FROM source_data
    GROUP BY participation_id
),

integrated_buckets AS (
    SELECT
        d.participation_id,
        d.timestamp,
        d.gsr,
        d.ppg,
        d.hr,
        epoch_ms(d.timestamp)-epoch_ms(s.first_timestamp) AS ms_from_start,
        floor((epoch_ms(d.timestamp)-epoch_ms(s.first_timestamp))/300)*300 AS bucket_ms,
        to_timestamp(epoch_ms(s.first_timestamp) + CAST(floor((epoch_ms(d.timestamp) - epoch_ms(s.first_timestamp)) / 300) * 300 AS BIGINT)) AS integrated_timestamp
    FROM source_data d
    JOIN session_start s ON d.participation_id=s.participation_id
)

SELECT
    participation_id,
    integrated_timestamp AS timestamp,
    ROUND(AVG(gsr),3) AS gsr,
    ROUND(AVG(ppg),3) AS ppg,
    ROUND(AVG(hr),3) AS hr
FROM integrated_buckets
GROUP BY participation_id, integrated_timestamp
ORDER BY participation_id, integrated_timestamp