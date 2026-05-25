SELECT *
FROM {{ ref('silver_biosignals') }}
WHERE ppg_value < 0