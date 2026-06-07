{{ config(
    materialized='external',  
    location='s3://silver-integrated/emotions/data.parquet'
)
}}

WITH source_data AS (
    SELECT * FROM read_parquet('s3://silver-clean/emotions/data.parquet')
),

session_bound AS (
    SELECT
        participation_id,
        MIN(timestamp) AS first_timestamp,
        MAX(timestamp) AS last_timestamp,
        date_sub('ms', MIN(timestamp), MAX(timestamp)) AS total_duration_ms
    FROM source_data
    GROUP BY participation_id
),

time_grid AS (
    SELECT
        b.participation_id,
        b.first_timestamp + CAST(steps.step AS BIGINT) * INTERVAL '300 ms' AS integrated_timestamp
    FROM session_bound b
    CROSS JOIN (
        SELECT generate_series AS step
        FROM generate_series(
            0, 
            (SELECT CAST(MAX(total_duration_ms) / 300 AS BIGINT) FROM session_bound)
        )
    ) steps
    WHERE b.first_timestamp+ INTERVAL (steps.step*300) MILLISECOND <= b.last_timestamp
),

integrated_buckets AS (
    SELECT
        d.participation_id,
        d.timestamp,
        d.emotion_happy,
        d.emotion_sad,
        d.emotion_angry,
        d.emotion_surprise,
        d.emotion_disgust,
        d.emotion_neutral,
        d.dominant,
        d.confidence,
        floor((date_sub('ms', s.first_timestamp, d.timestamp)) / 300) * 300 AS bucket_ms,
        s.first_timestamp + INTERVAL (floor((date_sub('ms', s.first_timestamp, d.timestamp)) / 300) * 300) MILLISECOND AS integrated_timestamp
    FROM source_data d
    JOIN session_bound s ON d.participation_id=s.participation_id
),

aggregations AS (
    SELECT
        participation_id,
        integrated_timestamp AS timestamp,
        AVG(emotion_happy) AS emotion_happy,
        AVG(emotion_sad) AS emotion_sad,
        AVG(emotion_angry) AS emotion_angry,
        AVG(emotion_surprise) AS emotion_surprise,
        AVG(emotion_disgust) AS emotion_disgust,
        AVG(emotion_neutral) AS emotion_neutral,
        MAX(dominant) AS dominant,
        AVG(confidence) AS confidence
    FROM integrated_buckets
    GROUP BY participation_id, integrated_timestamp
),

create_nulls AS (
    SELECT
        g.participation_id,
        g.integrated_timestamp,
        a.emotion_happy,
        a.emotion_sad,
        a.emotion_angry,
        a.emotion_surprise,
        a.emotion_disgust,
        a.emotion_neutral,
        a.dominant,
        a.confidence
    FROM time_grid g
    LEFT JOIN aggregations a ON g.participation_id=a.participation_id AND g.integrated_timestamp=a.timestamp
)

SELECT
    participation_id,
    integrated_timestamp AS timestamp,
    ROUND(COALESCE(emotion_happy, LAST_VALUE(emotion_happy IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_happy,
    ROUND(COALESCE(emotion_sad, LAST_VALUE(emotion_sad IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_sad,
    ROUND(COALESCE(emotion_angry, LAST_VALUE(emotion_angry IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_angry,
    ROUND(COALESCE(emotion_surprise, LAST_VALUE(emotion_surprise IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_surprise,
    ROUND(COALESCE(emotion_disgust, LAST_VALUE(emotion_disgust IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_disgust,
    ROUND(COALESCE(emotion_neutral, LAST_VALUE(emotion_neutral IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_neutral,
    COALESCE(dominant, LAST_VALUE(dominant IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS dominant,
    ROUND(COALESCE(confidence, LAST_VALUE(confidence IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS confidence
FROM create_nulls
ORDER BY participation_id, timestamp