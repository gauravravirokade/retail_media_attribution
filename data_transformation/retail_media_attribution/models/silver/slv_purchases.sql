{{ config(materialized='table') }}

select
    purchase_line_item_id,
    transaction_date,
    item_scan_timestamp,
    transaction_token,
    line_item_number,
    store_id,
    channel_type,
    product_token,
    total_basket_quantity,
    total_sales_amount,
    total_discount_amount,
    total_markdown_amount,
    member_token
from {{ ref('bnz_purchases') }}
where purchase_occurrence_rank = 1