-- later it should be changed from external into incremental
{{ config(
    materialized='external',  
    location='s3://silver-clean/emotions/data.parquet'
)
}}

WITH raw_data AS (
    SELECT * FROM read_json_auto('s3://emotions-bucket/topics/face-emotions/partition=0/*.json')
)

-- TEMPORARY as we do not have data concerining sessions and participants
-- so we can not create PARTICIPATION for now and in the result we do not have
-- participation_id.
SELECT DISTINCT
    CAST(participation_id AS VARCHAR) AS participation_id, -- TO BE CHANGED
    epoch_ms(CAST(ts AS BIGINT)) AS timestamp,
    CAST(emotions.HAPPY AS FLOAT) AS emotion_happy,
    CAST(emotions.SAD AS FLOAT) AS emotion_sad,
    CAST(emotions.ANGRY AS FLOAT) AS emotion_angry,
    CAST(emotions.SURPRISE AS FLOAT) AS emotion_surprise,
    CAST(emotions.DISGUST AS FLOAT) AS emotion_disgust,
    CAST(emotions.NEUTRAL AS FLOAT) AS emotion_neutral,
    CAST(dominant AS VARCHAR) AS dominant,
    CAST(confidence AS FLOAT) AS confidence
FROM raw_data

WHERE ts IS NOT NULL
  AND participation_id IS NOT NULL
  AND emotions.HAPPY BETWEEN 0.0 AND 1.0
  AND emotions.SAD BETWEEN 0.0 AND 1.0
  AND emotions.ANGRY BETWEEN 0.0 AND 1.0
  AND emotions.SURPRISE BETWEEN 0.0 AND 1.0
  AND emotions.DISGUST BETWEEN 0.0 AND 1.0
  AND emotions.NEUTRAL BETWEEN 0.0 AND 1.0
--   AND (emotions.HAPPY + emotions.SAD + emotions.ANGRY + emotions.SURPRISE + emotions.DISGUST + emotions.NEUTRAL) = 1
  AND (emotions.HAPPY + emotions.SAD + emotions.ANGRY + emotions.SURPRISE + emotions.DISGUST + emotions.NEUTRAL) BETWEEN 0.99 AND 1.01
  AND confidence BETWEEN 0.0 AND 1.0 