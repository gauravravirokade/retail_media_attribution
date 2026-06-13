{{ config(materialized='table') }}

select
    -- Composite key required: A proxy can link to multiple members (e.g., household tracking)
    {{ dbt_utils.generate_surrogate_key(['"PROXY_TOKEN"', '"MEMBER_TOKEN"']) }} as member_proxy_id,
    "PROXY_TOKEN" as proxy_token,
    "MEMBER_TOKEN" as member_token,
    ingested_at::timestamp as ingested_at,
    file_source_name
from {{ source('raw_source', 'member_proxy') }}