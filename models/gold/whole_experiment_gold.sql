{{ config(
    materialized='external',  
    location='s3://gold/whole-experiment-gold/data.parquet'
)
}}

WITH participant_data AS (
    SELECT * FROM {{ ref('silver_integrated_participant') }}
),
session_data AS (
    SELECT * FROM {{ ref('silver_integrated_session') }}
),
biosignals_data AS (
    SELECT 
    participation_id,
    CAST(MIN(timestamp) AS TIME) AS start_time,
    CAST(MAX(timestamp) AS TIME) AS end_time,
    MIN(CAST(timestamp AS DATE)) AS experiment_date,
    SUM(gsr*record_count) AS sum_gsr,
    SUM(record_count) AS count_gsr,
    ROUND((sum_gsr/count_gsr),2) AS avg_gsr,
    SUM(ppg*record_count) AS sum_ppg,
    SUM(record_count) AS count_ppg,
    ROUND((sum_ppg/count_ppg),2) AS avg_ppg,
    SUM(hr*record_count) AS sum_hr,
    SUM(record_count) AS count_hr,
    ROUND((sum_hr/count_hr),2) AS avg_hr
    FROM {{ ref('silver_integrated_biosignals') }}
    GROUP BY participation_id
),
blendshapes_data AS (
    SELECT * FROM {{ ref('silver_integrated_blendshapes') }}
),
emotions_data AS (
    SELECT
    participation_id,
    COUNT(CASE WHEN UPPER(dominant) = 'HAPPY' THEN 1 END) AS emotion_happy_seconds,
    COUNT(CASE WHEN UPPER(dominant) = 'SAD' THEN 1 END) AS emotion_sad_seconds,
    COUNT(CASE WHEN UPPER(dominant) = 'ANGRY' THEN 1 END) AS emotion_angry_seconds,
    COUNT(CASE WHEN UPPER(dominant) = 'SURPRISE' THEN 1 END) AS emotion_surprise_seconds,
    COUNT(CASE WHEN UPPER(dominant) = 'DISGUST' THEN 1 END) AS emotion_disgust_seconds,
    COUNT(CASE WHEN UPPER(dominant) = 'NEUTRAL' THEN 1 END) AS emotion_neutral_seconds
    FROM {{ ref('silver_integrated_emotions') }}
    GROUP BY participation_id
),
participation_data AS (
    SELECT * FROM {{ ref('silver_integrated_participation') }}
)

SELECT 
uuid() AS id,
bi.experiment_date,
bi.start_time,
bi.end_time,
p.name,
p.gender,
p.birthday,
s.session_id,
s.location,
s.experiment_type,
bi.sum_gsr,
bi.count_gsr,
bi.avg_gsr,
bi.sum_ppg,
bi.count_ppg,
bi.avg_ppg,
bi.sum_hr,
bi.count_hr,
bi.avg_hr,
e.emotion_happy_seconds,
e.emotion_sad_seconds,
e.emotion_angry_seconds,
e.emotion_surprise_seconds,
e.emotion_disgust_seconds,
e.emotion_neutral_seconds
FROM participation_data pr 
LEFT JOIN participant_data p ON p.participant_id=pr.participant_id
LEFT JOIN session_data s ON s.session_id=pr.session_id
LEFT JOIN biosignals_data bi ON pr.participation_id=bi.participation_id
LEFT JOIN blendshapes_data bl ON pr.participation_id=bl.participation_id
LEFT JOIN emotions_data e ON e.participation_id=pr.participation_id