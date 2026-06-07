SELECT *
FROM {{ ref('silver_clean_emotions') }}
WHERE (emotion_happy + emotion_sad + emotion_angry + emotion_surprise + emotion_disgust + emotion_neutral) <= 0.95 
   OR (emotion_happy + emotion_sad + emotion_angry + emotion_surprise + emotion_disgust + emotion_neutral) >= 1.05