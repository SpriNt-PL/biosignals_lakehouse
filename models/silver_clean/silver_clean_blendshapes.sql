-- later it should be changed from external into incremental
{{ config(
    materialized='external',  
    location='s3://silver-clean/blendshapes/data.parquet'
)
}}

WITH raw_data AS (
    SELECT * FROM read_json_auto('s3://landmarks-bucket/topics/face-landmarks/partition=0/*.json')
)

-- TEMPORARY as we do not have data concerining sessions and participants
-- so we can not create PARTICIPATION for now and in the result we do not have
-- participation_id.
SELECT DISTINCT
    CAST(student_id AS VARCHAR) AS participation_id, -- TO BE CHANGED
    epoch_ms(CAST(ts AS BIGINT)) AS timestamp,
    CAST(blendshapes."_neutral" AS FLOAT) AS blendshape_neutral,
    CAST(blendshapes.browDownLeft AS FLOAT) AS blendshape_browDownLeft,
    CAST(blendshapes.browDownRight AS FLOAT) AS blendshape_browDownRight,
    CAST(blendshapes.browInnerUp AS FLOAT) AS blendshape_browInnerUp,
    CAST(blendshapes.browOuterUpLeft AS FLOAT) AS blendshape_browOuterUpLeft,
    CAST(blendshapes.browOuterUpRight AS FLOAT) AS blendshape_browOuterUpRight,
    CAST(blendshapes.cheekPuff AS FLOAT) AS blendshape_cheekPuff,
    CAST(blendshapes.cheekSquintLeft AS FLOAT) AS blendshape_cheekSquintLeft,
    CAST(blendshapes.cheekSquintRight AS FLOAT) AS blendshape_cheekSquintRight,
    CAST(blendshapes.eyeBlinkLeft AS FLOAT) AS blendshape_eyeBlinkLeft,
    CAST(blendshapes.eyeBlinkRight AS FLOAT) AS blendshape_eyeBlinkRight,
    CAST(blendshapes.eyeLookDownLeft AS FLOAT) AS blendshape_eyeLookDownLeft,
    CAST(blendshapes.eyeLookDownRight AS FLOAT) AS blendshape_eyeLookDownRight,
    CAST(blendshapes.eyeLookInLeft AS FLOAT) AS blendshape_eyeLookInLeft,
    CAST(blendshapes.eyeLookInRight AS FLOAT) AS blendshape_eyeLookInRight,
    CAST(blendshapes.eyeLookOutLeft AS FLOAT) AS blendshape_eyeLookOutLeft,
    CAST(blendshapes.eyeLookOutRight AS FLOAT) AS blendshape_eyeLookOutRight,
    CAST(blendshapes.eyeLookUpLeft AS FLOAT) AS blendshape_eyeLookUpLeft,
    CAST(blendshapes.eyeLookUpRight AS FLOAT) AS blendshape_eyeLookUpRight,
    CAST(blendshapes.eyeSquintLeft AS FLOAT) AS blendshape_eyeSquintLeft,
    CAST(blendshapes.eyeSquintRight AS FLOAT) AS blendshape_eyeSquintRight,
    CAST(blendshapes.eyeWideLeft AS FLOAT) AS blendshape_eyeWideLeft,
    CAST(blendshapes.eyeWideRight AS FLOAT) AS blendshape_eyeWideRight,
    CAST(blendshapes.jawForward AS FLOAT) AS blendshape_jawForward,
    CAST(blendshapes.jawLeft AS FLOAT) AS blendshape_jawLeft,
    CAST(blendshapes.jawOpen AS FLOAT) AS blendshape_jawOpen,
    CAST(blendshapes.jawRight AS FLOAT) AS blendshape_jawRight,
    CAST(blendshapes.mouthClose AS FLOAT) AS blendshape_mouthClose,
    CAST(blendshapes.mouthDimpleLeft AS FLOAT) AS blendshape_mouthDimpleLeft,
    CAST(blendshapes.mouthDimpleRight AS FLOAT) AS blendshape_mouthDimpleRight,
    CAST(blendshapes.mouthFrownLeft AS FLOAT) AS blendshape_mouthFrownLeft,
    CAST(blendshapes.mouthFrownRight AS FLOAT) AS blendshape_mouthFrownRight,
    CAST(blendshapes.mouthFunnel AS FLOAT) AS blendshape_mouthFunnel,
    CAST(blendshapes.mouthLeft AS FLOAT) AS blendshape_mouthLeft,
    CAST(blendshapes.mouthLowerDownLeft AS FLOAT) AS blendshape_mouthLowerDownLeft,
    CAST(blendshapes.mouthLowerDownRight AS FLOAT) AS blendshape_mouthLowerDownRight,
    CAST(blendshapes.mouthPressLeft AS FLOAT) AS blendshape_mouthPressLeft,
    CAST(blendshapes.mouthPressRight AS FLOAT) AS blendshape_mouthPressRight,
    CAST(blendshapes.mouthPucker AS FLOAT) AS blendshape_mouthPucker,
    CAST(blendshapes.mouthRight AS FLOAT) AS blendshape_mouthRight,
    CAST(blendshapes.mouthRollLower AS FLOAT) AS blendshape_mouthRollLower,
    CAST(blendshapes.mouthRollUpper AS FLOAT) AS blendshape_mouthRollUpper,
    CAST(blendshapes.mouthShrugLower AS FLOAT) AS blendshape_mouthShrugLower,
    CAST(blendshapes.mouthShrugUpper AS FLOAT) AS blendshape_mouthShrugUpper,
    CAST(blendshapes.mouthSmileLeft AS FLOAT) AS blendshape_mouthSmileLeft,
    CAST(blendshapes.mouthSmileRight AS FLOAT) AS blendshape_mouthSmileRight,
    CAST(blendshapes.mouthStretchLeft AS FLOAT) AS blendshape_mouthStretchLeft,
    CAST(blendshapes.mouthStretchRight AS FLOAT) AS blendshape_mouthStretchRight,
    CAST(blendshapes.mouthUpperUpLeft AS FLOAT) AS blendshape_mouthUpperUpLeft,
    CAST(blendshapes.mouthUpperUpRight AS FLOAT) AS blendshape_mouthUpperUpRight,
    CAST(blendshapes.noseSneerLeft AS FLOAT) AS blendshape_noseSneerLeft,
    CAST(blendshapes.noseSneerRight AS FLOAT) AS blendshape_noseSneerRight
FROM raw_data

WHERE ts IS NOT NULL
  AND student_id IS NOT NULL