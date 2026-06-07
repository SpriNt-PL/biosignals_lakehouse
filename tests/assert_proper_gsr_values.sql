SELECT *
FROM {{ ref('silver_clean_biosignals') }}
WHERE ppg < 0