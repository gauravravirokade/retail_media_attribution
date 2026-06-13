{{ config(materialized='table') }}

select
    ttd_id_token,
    proxy_token
from {{ ref('bnz_ttd_match') }}
where ttd_occurrence_rank = 1