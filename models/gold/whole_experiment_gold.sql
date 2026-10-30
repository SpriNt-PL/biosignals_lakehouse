{{ config(
    materialized='external',  
    location='s3://gold/whole_experiment_gold/data.parquet'
)
}}

WITH participant_data AS (
    SELECT * FROM {{ ref('silver_integrated_participant') }}
),
WITH session_data AS (
    SELECT * FROM {{ ref('silver_integrated_session') }}
),
WITH biosignals_data AS (
    SELECT * FROM {{ ref('silver_integrated_biosignals') }}
),
WITH blendshapes_data AS (
    SELECT * FROM {{ ref('silver_integrated_blendshapes') }}
),
WITH emotions_data AS (
    SELECT * FROM {{ ref('silver_integrated_emotions') }}
),