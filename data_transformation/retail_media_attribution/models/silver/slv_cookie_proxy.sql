{{ config(materialized='table') }}

select
    flybuys_cookie_token,
    proxy_token,
    first_seen_timestamp,
    last_seen_timestamp,
    observed_rows,
    observed_days
from {{ ref('bnz_cookie_proxy') }}
where cookie_occurrence_rank = 1