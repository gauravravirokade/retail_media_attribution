{{ config(materialized='table') }}

with raw_data as (
    select
        "TTD_ID_TOKEN" as ttd_id_token,
        "PROXY_TOKEN" as proxy_token,
        ingested_at::timestamp as ingested_at,
        file_source_name
    from {{ source('raw_source', 'ttd_match') }}
)

select
    *,
    -- Flagging the grain: Rank occurrences of the same TTD token
    row_number() over (
        partition by ttd_id_token 
        order by ingested_at asc
    ) as ttd_occurrence_rank
from raw_data