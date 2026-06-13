{{ config(materialized='table') }}

with raw_data as (
    select
        {{ dbt_utils.generate_surrogate_key(['"TRANSACTION_TOKEN"', '"LINE_ITEM_NUMBER"']) }} as purchase_line_item_id,
        "TRANSACTION_DATE"::date as transaction_date,
        "ITEM_SCAN_TIMESTAMP"::timestamp as item_scan_timestamp,
        "TRANSACTION_TOKEN" as transaction_token,
        "LINE_ITEM_NUMBER"::int as line_item_number,
        "STORE_ID"::int as store_id,
        "CHANNEL_TYPE" as channel_type,
        "PRODUCT_TOKEN" as product_token,
        "TOTAL_BASKET_QUANTITY"::numeric as total_basket_quantity,
        "TOTAL_SALES_AMOUNT"::numeric(10,2) as total_sales_amount,
        
        case 
            when "TOTAL_DISCOUNT_AMOUNT" = 'NaN' or "TOTAL_DISCOUNT_AMOUNT" = '' then 0.00
            else "TOTAL_DISCOUNT_AMOUNT"::numeric(10,2)
        end as total_discount_amount,
        
        case 
            when "TOTAL_MARKDOWN_AMOUNT" = 'NaN' or "TOTAL_MARKDOWN_AMOUNT" = '' then 0.00
            else "TOTAL_MARKDOWN_AMOUNT"::numeric(10,2)
        end as total_markdown_amount,
        
        "MEMBER_TOKEN" as member_token,
        ingested_at::timestamp as ingested_at,
        file_source_name
    from {{ source('raw_source', 'purchases') }}
)

select
    *,
    -- Flagging the retail ledger grain: Rank occurrences of identical transaction line items
    row_number() over (
        partition by transaction_token, line_item_number 
        order by item_scan_timestamp desc, ingested_at asc
    ) as purchase_occurrence_rank
from raw_data