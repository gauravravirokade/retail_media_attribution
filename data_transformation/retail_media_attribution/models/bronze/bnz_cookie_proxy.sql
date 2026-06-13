{{ config(materialized='table') }}

with raw_data as (
    select
        "FLYBUYS_COOKIE_TOKEN" as flybuys_cookie_token,
        "PROXY_TOKEN" as proxy_token,
        "FIRST_SEEN_REQ_TIME"::timestamp as first_seen_timestamp,
        "LAST_SEEN_REQ_TIME"::timestamp as last_seen_timestamp,
        "OBSERVED_ROWS"::int as observed_rows,
        "OBSERVED_DAYS"::int as observed_days,
        ingested_at::timestamp as ingested_at,
        file_source_name
    from {{ source('raw_source', 'cookie_proxy') }}
)

select
    *,
    -- Flagging the grain: Rank occurrences of the same cookie token
    row_number() over (
        partition by flybuys_cookie_token 
        order by last_seen_timestamp desc, observed_rows desc, ingested_at asc
    ) as cookie_occurrence_rank
from raw_data