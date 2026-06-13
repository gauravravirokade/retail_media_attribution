{{ config(materialized='table') }}

select
    impression_id,
    request_timestamp,
    campaign_id,
    partner_id,
    creative_id,
    site_name,
    platform,
    source_file,
    ad_group_id,
    device_type,
    flybuys_cookie_token,
    ttd_id_token,
    device_id_token,
    has_flybuys_cookie,
    has_ttd_id,
    has_device_id
from {{ ref('bnz_impressions') }}
where impression_occurrence_rank = 1