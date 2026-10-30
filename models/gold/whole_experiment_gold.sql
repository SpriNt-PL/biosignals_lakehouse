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
    MIN(timestamp) AS start_time,
    MAX(timestamp) AS end_time,
    MIN(CAST(timestamp AS DATE)) AS experiment_date
    FROM {{ ref('silver_integrated_biosignals') }}
    GROUP BY participation_id
),
blendshapes_data AS (
    SELECT * FROM {{ ref('silver_integrated_blendshapes') }}
),
emotions_data AS (
    SELECT * FROM {{ ref('silver_integrated_emotions') }}
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
s.experiment_type
FROM participation_data pr 
LEFT JOIN participant_data p ON p.participant_id=pr.participant_id
LEFT JOIN session_data s ON s.session_id=pr.session_id
LEFT JOIN biosignals_data bi ON pr.participation_id=bi.participation_id
LEFT JOIN blendshapes_data bl ON pr.participation_id=bl.participation_id
LEFT JOIN emotions_data e ON e.participation_id=pr.participation_id