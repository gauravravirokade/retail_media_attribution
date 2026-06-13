{{ config(materialized='table') }}

select
    proxy_token,
    member_token
from {{ ref('bnz_member_proxy') }}