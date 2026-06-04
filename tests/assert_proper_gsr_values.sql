SELECT *
FROM {{ ref('silver_clean_biosignals') }}
WHERE ppg_value < 0