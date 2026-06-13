{{ config(materialized='table') }}

with raw_data as (
    select
        "DEVICE_ID_TOKEN" as device_id_token,
        "PROXY_TOKEN" as proxy_token,
        ingested_at::timestamp as ingested_at,
        file_source_name
    from {{ source('raw_source', 'device_match') }}
)

select
    *,
    -- Flagging the grain: Rank occurrences of the same Device token
    row_number() over (
        partition by device_id_token 
        order by ingested_at asc
    ) as device_occurrence_rank
from raw_data