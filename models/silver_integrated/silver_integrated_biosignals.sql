{{ config(
    materialized='external',  
    location='s3://silver-integrated/biosignals/data.parquet'
)
}}

WITH source_data AS (
    SELECT * FROM {{ ref('silver_clean_biosignals') }}
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
        d.gsr,
        d.ppg,
        d.hr,
        floor((date_sub('ms', s.first_timestamp, d.timestamp)) / 300) * 300 AS bucket_ms,
        s.first_timestamp + INTERVAL (floor((date_sub('ms', s.first_timestamp, d.timestamp)) / 300) * 300) MILLISECOND AS integrated_timestamp
    FROM source_data d
    JOIN session_bound s ON d.participation_id=s.participation_id
),

aggregations AS (
    SELECT
        participation_id,
        integrated_timestamp AS timestamp,
        AVG(gsr) AS gsr,
        AVG(ppg) AS ppg,
        AVG(hr) AS hr
    FROM integrated_buckets
    GROUP BY participation_id, integrated_timestamp
),

create_nulls AS (
    SELECT
        g.participation_id,
        g.integrated_timestamp,
        a.gsr,
        a.ppg,
        a.hr
    FROM time_grid g
    LEFT JOIN aggregations a ON g.participation_id=a.participation_id AND g.integrated_timestamp=a.timestamp
)

SELECT
    participation_id,
    integrated_timestamp AS timestamp,
    ROUND(
        COALESCE(gsr, LAST_VALUE(gsr IGNORE NULLS) OVER (
            PARTITION BY participation_id 
            ORDER BY integrated_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )), 3
    ) AS gsr,
    ROUND(
        COALESCE(ppg, LAST_VALUE(ppg IGNORE NULLS) OVER (
            PARTITION BY participation_id 
            ORDER BY integrated_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )), 3
    ) AS ppg,
    ROUND(
        COALESCE(hr, LAST_VALUE(hr IGNORE NULLS) OVER (
            PARTITION BY participation_id 
            ORDER BY integrated_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )), 3
    ) AS hr
FROM create_nulls
ORDER BY participation_id, timestamp