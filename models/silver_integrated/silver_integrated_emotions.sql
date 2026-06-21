{{ config(
    materialized='external',  
    location='s3://silver-integrated/emotions/data.parquet'
)
}}

WITH source_data AS (
    SELECT * FROM {{ ref('silver_clean_emotions') }}
),

session_bound AS (
    SELECT
        participation_id,
        date_trunc('second', MIN(timestamp)) AS first_timestamp,
        date_trunc('second', MAX(timestamp)) AS last_timestamp,
        date_sub('second', date_trunc('second', MIN(timestamp)), date_trunc('second', MAX(timestamp))) AS total_duration_s
    FROM source_data
    GROUP BY participation_id
),

time_grid AS (
    SELECT
        b.participation_id,
        b.first_timestamp + CAST(steps.step AS BIGINT) * INTERVAL '1 second' AS integrated_timestamp
    FROM session_bound b
    CROSS JOIN (
        SELECT range AS step FROM range(0, 1000000)
    ) steps
    WHERE steps.step <= b.total_duration_s
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
        date_trunc('second', d.timestamp) AS integrated_timestamp
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
        AVG(confidence) AS confidence,
        COUNT(*) AS record_count
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
        a.confidence,
        COALESCE(a.record_count, 0) AS record_count
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
    ROUND(COALESCE(confidence, LAST_VALUE(confidence IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS confidence,
    record_count
FROM create_nulls
ORDER BY participation_id, timestamp