{{ config(materialized='table') }}

with pipeline_counts as (
    -- Collect row-level volume differences across the Medallion layers
    select
        'impressions' as source_table,
        (select count(*) from {{ ref('bnz_impressions') }}) as bronze_row_count,
        (select count(*) from {{ ref('slv_impressions') }}) as silver_row_count,
        (select count(*) from {{ ref('bnz_impressions') }} where impression_occurrence_rank > 1) as flagged_duplicate_count

    union all

    select
        'cookie_proxy' as source_table,
        (select count(*) from {{ ref('bnz_cookie_proxy') }}) as bronze_row_count,
        (select count(*) from {{ ref('slv_cookie_proxy') }}) as silver_row_count,
        (select count(*) from {{ ref('bnz_cookie_proxy') }} where cookie_occurrence_rank > 1) as flagged_duplicate_count

    union all

    select
        'ttd_match' as source_table,
        (select count(*) from {{ ref('bnz_ttd_match') }}) as bronze_row_count,
        (select count(*) from {{ ref('slv_ttd_match') }}) as silver_row_count,
        (select count(*) from {{ ref('bnz_ttd_match') }} where ttd_occurrence_rank > 1) as flagged_duplicate_count

    union all

    select
        'device_match' as source_table,
        (select count(*) from {{ ref('bnz_device_match') }}) as bronze_row_count,
        (select count(*) from {{ ref('slv_device_match') }}) as silver_row_count,
        (select count(*) from {{ ref('bnz_device_match') }} where device_occurrence_rank > 1) as flagged_duplicate_count

    union all

    select
        'purchases' as source_table,
        (select count(*) from {{ ref('bnz_purchases') }}) as bronze_row_count,
        (select count(*) from {{ ref('slv_purchases') }}) as silver_row_count,
        (select count(*) from {{ ref('bnz_purchases') }} where purchase_occurrence_rank > 1) as flagged_duplicate_count
)

select
    source_table,
    bronze_row_count,
    silver_row_count,
    -- Metric A: Total rows removed during the Silver transformation step
    (bronze_row_count - silver_row_count) as total_rows_removed,
    -- Metric B: Pure duplicate records caught by our flag logic
    flagged_duplicate_count,
    -- Percentage of the landed file volume that consisted of true duplicates
    ((flagged_duplicate_count::numeric / nullif(bronze_row_count, 0)) * 100)::numeric(10,2) as duplicate_volume_percentage
from pipeline_counts