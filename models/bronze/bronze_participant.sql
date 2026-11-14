{{ config(
    materialized='external',
    location='s3://metadata-bucket/participant/data.parquet',
    format='parquet'
) }}

SELECT
    *,
    current_timestamp AS _bronze_extracted_at
FROM postgres_meta.public.participant