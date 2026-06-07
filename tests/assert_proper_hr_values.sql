SELECT *
FROM {{ ref('silver_clean_biosignals') }}
WHERE hr < 0 OR hr > 250