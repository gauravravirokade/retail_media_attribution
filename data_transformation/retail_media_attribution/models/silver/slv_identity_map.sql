{{ config(materialized='table') }}

with unified_token_proxies as (
    -- Path A: Resolve Cookie Tokens to Proxies
    select 
        flybuys_cookie_token as token_identifier, 
        'cookie' as token_type, 
        proxy_token 
    from {{ ref('slv_cookie_proxy') }}
    
    union
    
    -- Path B: Resolve TTD Tokens to Proxies
    select 
        ttd_id_token as token_identifier, 
        'ttd' as token_type, 
        proxy_token 
    from {{ ref('slv_ttd_match') }}
    
    union
    
    -- Path C: Resolve Physical Device Tokens to Proxies
    select 
        device_id_token as token_identifier, 
        'device' as token_type, 
        proxy_token 
    from {{ ref('slv_device_match') }}
)

select
    u.token_identifier,
    u.token_type,
    u.proxy_token,
    m.member_token
from unified_token_proxies u
-- Left join ensures we capture tokens even if they haven't registered as registered members yet
left join {{ ref('slv_member_proxy') }} m 
    on u.proxy_token = m.proxy_token