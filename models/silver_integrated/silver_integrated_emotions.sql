{{ config(
    materialized='external',  
    location='s3://silver-integrated/emotions/data.parquet'
)
}}

WITH source_data AS (
    SELECT * FROM {{ ref('silver_clean_emotions') }}
),

times_data AS (
    SELECT session_id, start_time, end_time FROM {{ ref('silver_integrated_session') }}
),

participation AS (
    SELECT * FROM {{ ref('silver_integrated_participation') }}
),

session_bound AS (
    SELECT
        sou.participation_id,
        se.start_time AS first_timestamp,
        se.end_time AS last_timestamp,
        date_sub('second', se.start_time, se.end_time) AS total_duration_s
    FROM source_data sou
    JOIN participation p ON sou.participation_id=p.participation_id
    JOIN times_data se ON se.session_id=p.session_id
    GROUP BY sou.participation_id, se.start_time, se.end_time
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
        SUM(emotion_happy) AS emotion_happy_sum,
        SUM(emotion_sad) AS emotion_sad_sum,
        SUM(emotion_angry) AS emotion_angry_sum,
        SUM(emotion_surprise) AS emotion_surprise_sum,
        SUM(emotion_disgust) AS emotion_disgust_sum,
        SUM(emotion_neutral) AS emotion_neutral_sum,
        MAX(dominant) AS dominant,
        SUM(confidence) AS confidence_sum,
        COUNT(*) AS record_count
    FROM integrated_buckets
    GROUP BY participation_id, integrated_timestamp
),

create_nulls AS (
    SELECT
        g.participation_id,
        g.integrated_timestamp,
        a.emotion_happy_sum,
        a.emotion_sad_sum,
        a.emotion_angry_sum,
        a.emotion_surprise_sum,
        a.emotion_disgust_sum,
        a.emotion_neutral_sum,
        a.dominant,
        a.confidence_sum,
        COALESCE(a.record_count, 0) AS record_count
    FROM time_grid g
    LEFT JOIN aggregations a ON g.participation_id=a.participation_id AND g.integrated_timestamp=a.timestamp
)

SELECT
    participation_id,
    integrated_timestamp AS timestamp,
    ROUND(COALESCE(emotion_happy_sum, LAST_VALUE(emotion_happy_sum IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_happy_sum,
    ROUND(COALESCE(emotion_sad_sum, LAST_VALUE(emotion_sad_sum IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_sad_sum,
    ROUND(COALESCE(emotion_angry_sum, LAST_VALUE(emotion_angry_sum IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_angry_sum,
    ROUND(COALESCE(emotion_surprise_sum, LAST_VALUE(emotion_surprise_sum IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_surprise_sum,
    ROUND(COALESCE(emotion_disgust_sum, LAST_VALUE(emotion_disgust_sum IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_disgust_sum,
    ROUND(COALESCE(emotion_neutral_sum, LAST_VALUE(emotion_neutral_sum IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS emotion_neutral_sum,
    COALESCE(dominant, LAST_VALUE(dominant IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS dominant,
    ROUND(COALESCE(confidence_sum, LAST_VALUE(confidence_sum IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS confidence_sum,
    record_count
FROM create_nulls
ORDER BY participation_id, timestamp