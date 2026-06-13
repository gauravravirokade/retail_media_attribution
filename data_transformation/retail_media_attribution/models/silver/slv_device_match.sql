{{ config(materialized='table') }}

select
    device_id_token,
    proxy_token
from {{ ref('bnz_device_match') }}
where device_occurrence_rank = 1