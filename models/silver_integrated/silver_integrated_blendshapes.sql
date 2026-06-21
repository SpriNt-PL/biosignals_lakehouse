{{ config(
    materialized='external',  
    location='s3://silver-integrated/blendshapes/data.parquet'
)
}}

WITH source_data AS (
    SELECT * FROM {{ ref('silver_clean_blendshapes') }}
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
        d.blendshape_neutral, d.blendshape_browDownLeft, d.blendshape_browDownRight, d.blendshape_browInnerUp, d.blendshape_browOuterUpLeft, d.blendshape_browOuterUpRight,
        d.blendshape_cheekPuff, d.blendshape_cheekSquintLeft, d.blendshape_cheekSquintRight, d.blendshape_eyeBlinkLeft, d.blendshape_eyeBlinkRight,
        d.blendshape_eyeLookDownLeft, d.blendshape_eyeLookDownRight, d.blendshape_eyeLookInLeft, d.blendshape_eyeLookInRight, d.blendshape_eyeLookOutLeft, d.blendshape_eyeLookOutRight,
        d.blendshape_eyeLookUpLeft, d.blendshape_eyeLookUpRight, d.blendshape_eyeSquintLeft, d.blendshape_eyeSquintRight, d.blendshape_eyeWideLeft, d.blendshape_eyeWideRight,
        d.blendshape_jawForward, d.blendshape_jawLeft, d.blendshape_jawOpen, d.blendshape_jawRight, d.blendshape_mouthClose, d.blendshape_mouthDimpleLeft, d.blendshape_mouthDimpleRight,
        d.blendshape_mouthFrownLeft, d.blendshape_mouthFrownRight, d.blendshape_mouthFunnel, d.blendshape_mouthLeft, d.blendshape_mouthLowerDownLeft, d.blendshape_mouthLowerDownRight,
        d.blendshape_mouthPressLeft, d.blendshape_mouthPressRight, d.blendshape_mouthPucker, d.blendshape_mouthRight, d.blendshape_mouthRollLower, d.blendshape_mouthRollUpper,
        d.blendshape_mouthShrugLower, d.blendshape_mouthShrugUpper, d.blendshape_mouthSmileLeft, d.blendshape_mouthSmileRight, d.blendshape_mouthStretchLeft, d.blendshape_mouthStretchRight,
        d.blendshape_mouthUpperUpLeft, d.blendshape_mouthUpperUpRight, d.blendshape_noseSneerLeft, d.blendshape_noseSneerRight,
        date_trunc('second', d.timestamp) AS integrated_timestamp
    JOIN session_bound s ON d.participation_id=s.participation_id
),

aggregations AS (
    SELECT
        participation_id,
        integrated_timestamp AS timestamp,
        AVG(blendshape_neutral) AS blendshape_neutral, AVG(blendshape_browDownLeft) AS blendshape_browDownLeft, AVG(blendshape_browDownRight) AS blendshape_browDownRight, AVG(blendshape_browInnerUp) AS blendshape_browInnerUp, AVG(blendshape_browOuterUpLeft) AS blendshape_browOuterUpLeft, AVG(blendshape_browOuterUpRight) AS blendshape_browOuterUpRight,
        AVG(blendshape_cheekPuff) AS blendshape_cheekPuff, AVG(blendshape_cheekSquintLeft) AS blendshape_cheekSquintLeft, AVG(blendshape_cheekSquintRight) AS blendshape_cheekSquintRight, AVG(blendshape_eyeBlinkLeft) AS blendshape_eyeBlinkLeft, AVG(blendshape_eyeBlinkRight) AS blendshape_eyeBlinkRight,
        AVG(blendshape_eyeLookDownLeft) AS blendshape_eyeLookDownLeft, AVG(blendshape_eyeLookDownRight) AS blendshape_eyeLookDownRight, AVG(blendshape_eyeLookInLeft) AS blendshape_eyeLookInLeft, AVG(blendshape_eyeLookInRight) AS blendshape_eyeLookInRight, AVG(blendshape_eyeLookOutLeft) AS blendshape_eyeLookOutLeft, AVG(blendshape_eyeLookOutRight) AS blendshape_eyeLookOutRight,
        AVG(blendshape_eyeLookUpLeft) AS blendshape_eyeLookUpLeft, AVG(blendshape_eyeLookUpRight) AS blendshape_eyeLookUpRight, AVG(blendshape_eyeSquintLeft) AS blendshape_eyeSquintLeft, AVG(blendshape_eyeSquintRight) AS blendshape_eyeSquintRight, AVG(blendshape_eyeWideLeft) AS blendshape_eyeWideLeft, AVG(blendshape_eyeWideRight) AS blendshape_eyeWideRight,
        AVG(blendshape_jawForward) AS blendshape_jawForward, AVG(blendshape_jawLeft) AS blendshape_jawLeft, AVG(blendshape_jawOpen) AS blendshape_jawOpen, AVG(blendshape_jawRight) AS blendshape_jawRight, AVG(blendshape_mouthClose) AS blendshape_mouthClose, AVG(blendshape_mouthDimpleLeft) AS blendshape_mouthDimpleLeft, AVG(blendshape_mouthDimpleRight) AS blendshape_mouthDimpleRight,
        AVG(blendshape_mouthFrownLeft) AS blendshape_mouthFrownLeft, AVG(blendshape_mouthFrownRight) AS blendshape_mouthFrownRight, AVG(blendshape_mouthFunnel) AS blendshape_mouthFunnel, AVG(blendshape_mouthLeft) AS blendshape_mouthLeft, AVG(blendshape_mouthLowerDownLeft) AS blendshape_mouthLowerDownLeft, AVG(blendshape_mouthLowerDownRight) AS blendshape_mouthLowerDownRight,
        AVG(blendshape_mouthPressLeft) AS blendshape_mouthPressLeft, AVG(blendshape_mouthPressRight) AS blendshape_mouthPressRight, AVG(blendshape_mouthPucker) AS blendshape_mouthPucker, AVG(blendshape_mouthRight) AS blendshape_mouthRight, AVG(blendshape_mouthRollLower) AS blendshape_mouthRollLower, AVG(blendshape_mouthRollUpper) AS blendshape_mouthRollUpper,
        AVG(blendshape_mouthShrugLower) AS blendshape_mouthShrugLower, AVG(blendshape_mouthShrugUpper) AS blendshape_mouthShrugUpper, AVG(blendshape_mouthSmileLeft) AS blendshape_mouthSmileLeft, AVG(blendshape_mouthSmileRight) AS blendshape_mouthSmileRight, AVG(blendshape_mouthStretchLeft) AS blendshape_mouthStretchLeft, AVG(blendshape_mouthStretchRight) AS blendshape_mouthStretchRight,
        AVG(blendshape_mouthUpperUpLeft) AS blendshape_mouthUpperUpLeft, AVG(blendshape_mouthUpperUpRight) AS blendshape_mouthUpperUpRight, AVG(blendshape_noseSneerLeft) AS blendshape_noseSneerLeft, AVG(blendshape_noseSneerRight) AS blendshape_noseSneerRight,
        COUNT(*) AS record_count
    FROM integrated_buckets
    GROUP BY participation_id, integrated_timestamp
),

create_nulls AS (
    SELECT
        g.participation_id,
        g.integrated_timestamp,
        a.blendshape_neutral, a.blendshape_browDownLeft, a.blendshape_browDownRight, a.blendshape_browInnerUp, a.blendshape_browOuterUpLeft, a.blendshape_browOuterUpRight,
        a.blendshape_cheekPuff, a.blendshape_cheekSquintLeft, a.blendshape_cheekSquintRight, a.blendshape_eyeBlinkLeft, a.blendshape_eyeBlinkRight,
        a.blendshape_eyeLookDownLeft, a.blendshape_eyeLookDownRight, a.blendshape_eyeLookInLeft, a.blendshape_eyeLookInRight, a.blendshape_eyeLookOutLeft, a.blendshape_eyeLookOutRight,
        a.blendshape_eyeLookUpLeft, a.blendshape_eyeLookUpRight, a.blendshape_eyeSquintLeft, a.blendshape_eyeSquintRight, a.blendshape_eyeWideLeft, a.blendshape_eyeWideRight,
        a.blendshape_jawForward, a.blendshape_jawLeft, a.blendshape_jawOpen, a.blendshape_jawRight, a.blendshape_mouthClose, a.blendshape_mouthDimpleLeft, a.blendshape_mouthDimpleRight,
        a.blendshape_mouthFrownLeft, a.blendshape_mouthFrownRight, a.blendshape_mouthFunnel, a.blendshape_mouthLeft, a.blendshape_mouthLowerDownLeft, a.blendshape_mouthLowerDownRight,
        a.blendshape_mouthPressLeft, a.blendshape_mouthPressRight, a.blendshape_mouthPucker, a.blendshape_mouthRight, a.blendshape_mouthRollLower, a.blendshape_mouthRollUpper,
        a.blendshape_mouthShrugLower, a.blendshape_mouthShrugUpper, a.blendshape_mouthSmileLeft, a.blendshape_mouthSmileRight, a.blendshape_mouthStretchLeft, a.blendshape_mouthStretchRight,
        a.blendshape_mouthUpperUpLeft, a.blendshape_mouthUpperUpRight, a.blendshape_noseSneerLeft, a.blendshape_noseSneerRight,
        COALESCE(a.record_count, 0) AS record_count
    FROM time_grid g
    LEFT JOIN aggregations a ON g.participation_id=a.participation_id AND g.integrated_timestamp=a.timestamp
)

SELECT
    participation_id,
    integrated_timestamp AS timestamp,
    ROUND(COALESCE(blendshape_neutral, LAST_VALUE(blendshape_neutral IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_neutral,
    ROUND(COALESCE(blendshape_browDownLeft, LAST_VALUE(blendshape_browDownLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_browDownLeft,
    ROUND(COALESCE(blendshape_browDownRight, LAST_VALUE(blendshape_browDownRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_browDownRight,
    ROUND(COALESCE(blendshape_browInnerUp, LAST_VALUE(blendshape_browInnerUp IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_browInnerUp,
    ROUND(COALESCE(blendshape_browOuterUpLeft, LAST_VALUE(blendshape_browOuterUpLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_browOuterUpLeft,
    ROUND(COALESCE(blendshape_browOuterUpRight, LAST_VALUE(blendshape_browOuterUpRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_browOuterUpRight,
    ROUND(COALESCE(blendshape_cheekPuff, LAST_VALUE(blendshape_cheekPuff IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_cheekPuff,
    ROUND(COALESCE(blendshape_cheekSquintLeft, LAST_VALUE(blendshape_cheekSquintLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_cheekSquintLeft,
    ROUND(COALESCE(blendshape_cheekSquintRight, LAST_VALUE(blendshape_cheekSquintRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_cheekSquintRight,
    ROUND(COALESCE(blendshape_eyeBlinkLeft, LAST_VALUE(blendshape_eyeBlinkLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeBlinkLeft,
    ROUND(COALESCE(blendshape_eyeBlinkRight, LAST_VALUE(blendshape_eyeBlinkRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeBlinkRight,
    ROUND(COALESCE(blendshape_eyeLookDownLeft, LAST_VALUE(blendshape_eyeLookDownLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeLookDownLeft,
    ROUND(COALESCE(blendshape_eyeLookDownRight, LAST_VALUE(blendshape_eyeLookDownRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeLookDownRight,
    ROUND(COALESCE(blendshape_eyeLookInLeft, LAST_VALUE(blendshape_eyeLookInLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeLookInLeft,
    ROUND(COALESCE(blendshape_eyeLookInRight, LAST_VALUE(blendshape_eyeLookInRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeLookInRight,
    ROUND(COALESCE(blendshape_eyeLookOutLeft, LAST_VALUE(blendshape_eyeLookOutLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeLookOutLeft,
    ROUND(COALESCE(blendshape_eyeLookOutRight, LAST_VALUE(blendshape_eyeLookOutRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeLookOutRight,
    ROUND(COALESCE(blendshape_eyeLookUpLeft, LAST_VALUE(blendshape_eyeLookUpLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeLookUpLeft,
    ROUND(COALESCE(blendshape_eyeLookUpRight, LAST_VALUE(blendshape_eyeLookUpRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeLookUpRight,
    ROUND(COALESCE(blendshape_eyeSquintLeft, LAST_VALUE(blendshape_eyeSquintLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeSquintLeft,
    ROUND(COALESCE(blendshape_eyeSquintRight, LAST_VALUE(blendshape_eyeSquintRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeSquintRight,
    ROUND(COALESCE(blendshape_eyeWideLeft, LAST_VALUE(blendshape_eyeWideLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeWideLeft,
    ROUND(COALESCE(blendshape_eyeWideRight, LAST_VALUE(blendshape_eyeWideRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_eyeWideRight,
    ROUND(COALESCE(blendshape_jawForward, LAST_VALUE(blendshape_jawForward IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_jawForward,
    ROUND(COALESCE(blendshape_jawLeft, LAST_VALUE(blendshape_jawLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_jawLeft,
    ROUND(COALESCE(blendshape_jawOpen, LAST_VALUE(blendshape_jawOpen IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_jawOpen,
    ROUND(COALESCE(blendshape_jawRight, LAST_VALUE(blendshape_jawRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_jawRight,
    ROUND(COALESCE(blendshape_mouthClose, LAST_VALUE(blendshape_mouthClose IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthClose,
    ROUND(COALESCE(blendshape_mouthDimpleLeft, LAST_VALUE(blendshape_mouthDimpleLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthDimpleLeft,
    ROUND(COALESCE(blendshape_mouthDimpleRight, LAST_VALUE(blendshape_mouthDimpleRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthDimpleRight,
    ROUND(COALESCE(blendshape_mouthFrownLeft, LAST_VALUE(blendshape_mouthFrownLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthFrownLeft,
    ROUND(COALESCE(blendshape_mouthFrownRight, LAST_VALUE(blendshape_mouthFrownRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthFrownRight,
    ROUND(COALESCE(blendshape_mouthFunnel, LAST_VALUE(blendshape_mouthFunnel IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthFunnel,
    ROUND(COALESCE(blendshape_mouthLeft, LAST_VALUE(blendshape_mouthLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthLeft,
    ROUND(COALESCE(blendshape_mouthLowerDownLeft, LAST_VALUE(blendshape_mouthLowerDownLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthLowerDownLeft,
    ROUND(COALESCE(blendshape_mouthLowerDownRight, LAST_VALUE(blendshape_mouthLowerDownRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthLowerDownRight,
    ROUND(COALESCE(blendshape_mouthPressLeft, LAST_VALUE(blendshape_mouthPressLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthPressLeft,
    ROUND(COALESCE(blendshape_mouthPressRight, LAST_VALUE(blendshape_mouthPressRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthPressRight,
    ROUND(COALESCE(blendshape_mouthPucker, LAST_VALUE(blendshape_mouthPucker IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthPucker,
    ROUND(COALESCE(blendshape_mouthRight, LAST_VALUE(blendshape_mouthRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthRight,
    ROUND(COALESCE(blendshape_mouthRollLower, LAST_VALUE(blendshape_mouthRollLower IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthRollLower,
    ROUND(COALESCE(blendshape_mouthRollUpper, LAST_VALUE(blendshape_mouthRollUpper IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthRollUpper,
    ROUND(COALESCE(blendshape_mouthShrugLower, LAST_VALUE(blendshape_mouthShrugLower IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthShrugLower,
    ROUND(COALESCE(blendshape_mouthShrugUpper, LAST_VALUE(blendshape_mouthShrugUpper IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthShrugUpper,
    ROUND(COALESCE(blendshape_mouthSmileLeft, LAST_VALUE(blendshape_mouthSmileLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthSmileLeft,
    ROUND(COALESCE(blendshape_mouthSmileRight, LAST_VALUE(blendshape_mouthSmileRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthSmileRight,
    ROUND(COALESCE(blendshape_mouthStretchLeft, LAST_VALUE(blendshape_mouthStretchLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthStretchLeft,
    ROUND(COALESCE(blendshape_mouthStretchRight, LAST_VALUE(blendshape_mouthStretchRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthStretchRight,
    ROUND(COALESCE(blendshape_mouthUpperUpLeft, LAST_VALUE(blendshape_mouthUpperUpLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthUpperUpLeft,
    ROUND(COALESCE(blendshape_mouthUpperUpRight, LAST_VALUE(blendshape_mouthUpperUpRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_mouthUpperUpRight,
    ROUND(COALESCE(blendshape_noseSneerLeft, LAST_VALUE(blendshape_noseSneerLeft IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_noseSneerLeft,
    ROUND(COALESCE(blendshape_noseSneerRight, LAST_VALUE(blendshape_noseSneerRight IGNORE NULLS) OVER (PARTITION BY participation_id ORDER BY integrated_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)), 3) AS blendshape_noseSneerRight,
    record_count
FROM create_nulls
ORDER BY participation_id, timestamp