{{
    config(
        materialized='incremental',
        unique_key='impression_id',
        incremental_strategy='append'
    )
}}

with raw_source_data as (
    select
        -- Force Postgres to match the strict uppercase raw columns via double quotes
        {{ dbt_utils.generate_surrogate_key([
            '"REQ_TIME"',
            '"FLYBUYS_COOKIE_TOKEN"',
            '"TTD_ID_TOKEN"',
            '"DEVICE_ID_TOKEN"'
        ]) }} as impression_id,
        
        "REQ_TIME"::timestamp as request_timestamp,
        "CAMPAIGNID" as campaign_id,
        
        -- Keep this as text to allow values like 'NEWSCORP' and 'NaN' to load without crashing
        "PARTNERID" as partner_id,
        
        "CREATIVE" as creative_id,
        "SITENAME" as site_name,
        "PLATFORM" as platform,
        "SOURCEFILE" as source_file,
        "ADGROUPID" as ad_group_id,
        "DEVICETYPE" as device_type,
        
        "FLYBUYS_COOKIE_TOKEN" as flybuys_cookie_token,
        "TTD_ID_TOKEN" as ttd_id_token,
        "DEVICE_ID_TOKEN" as device_id_token,
        
        case when "HAS_FLYBUYS_COOKIE" = '1' then 1 else 0 end::int as has_flybuys_cookie,
        case when "HAS_TTD_ID" = '1' then 1 else 0 end::int as has_ttd_id,
        case when "HAS_DEVICE_ID" = '1' then 1 else 0 end::int as has_device_id,
        
        ingested_at::timestamp as ingested_at,
        file_source_name
    from {{ source('raw_source', 'impressions') }}

    {% if is_incremental() %}
        where ingested_at::timestamp > (select max(ingested_at) from {{ this }})
    {% endif %}
)

select
    *,
    row_number() over (
        partition by request_timestamp, flybuys_cookie_token, ttd_id_token, device_id_token
        order by ingested_at asc
    ) as impression_occurrence_rank
from raw_source_data