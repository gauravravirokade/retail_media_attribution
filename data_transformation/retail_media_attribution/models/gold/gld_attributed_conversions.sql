{{ config(materialized='table', schema='gold') }}

with member_exposures as (
    -- Step 1: Optimized sequential join paths instead of using heavy 'OR' blocks
    select
        imp.impression_id,
        imp.request_timestamp as exposure_timestamp,
        imp.campaign_id,
        imp.partner_id,
        imp.creative_id,
        imp.site_name,
        imp.platform,
        -- Coalesce checks individual, indexed columns step-by-step
        coalesce(map_cookie.member_token, map_ttd.member_token, map_device.member_token) as member_token
    from {{ ref('slv_impressions') }} imp
    
    -- Linear, narrow lookup joins that Postgres can resolve instantly in memory
    left join {{ ref('slv_identity_map') }} map_cookie
        on imp.flybuys_cookie_token = map_cookie.token_identifier 
        and map_cookie.token_type = 'cookie'
        
    left join {{ ref('slv_identity_map') }} map_ttd
        on imp.ttd_id_token = map_ttd.token_identifier 
        and map_ttd.token_type = 'ttd'
        
    left join {{ ref('slv_identity_map') }} map_device
        on imp.device_id_token = map_device.token_identifier 
        and map_device.token_type = 'device'
        
    -- Only keep exposures that actually map back to a valid customer account
    where (map_cookie.member_token is not null 
       or map_ttd.member_token is not null 
       or map_device.member_token is not null)
),

conversion_window_matching as (
    -- Step 2: Form our 14-day lookback window ledger
    select
        p.purchase_line_item_id,
        p.transaction_token,
        p.item_scan_timestamp,
        p.product_token,
        p.total_sales_amount,
        p.member_token,
        e.impression_id,
        e.exposure_timestamp,
        e.campaign_id,
        e.partner_id,
        e.creative_id,
        p.item_scan_timestamp - e.exposure_timestamp as touch_latency,
        row_number() over (
            partition by p.purchase_line_item_id
            order by e.exposure_timestamp desc
        ) as attribution_rank
    from {{ ref('slv_purchases') }} p
    inner join member_exposures e
        on p.member_token = e.member_token
    where e.exposure_timestamp <= p.item_scan_timestamp
      and e.exposure_timestamp >= p.item_scan_timestamp - interval '14 days'
)

select
    purchase_line_item_id,
    transaction_token,
    item_scan_timestamp,
    product_token,
    total_sales_amount,
    member_token,
    impression_id,
    exposure_timestamp,
    campaign_id,
    partner_id,
    creative_id,
    touch_latency
from conversion_window_matching
where attribution_rank = 1