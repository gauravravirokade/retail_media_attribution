{{ config(materialized='table') }}

with total_universe as (
    -- Identify every customer in our database
    select distinct member_token from {{ ref('slv_member_proxy') }}
),

attributed_sales as (
    -- Extract unique purchase amounts successfully attributed to a campaign exposure
    select 
        purchase_line_item_id,
        transaction_token,
        total_sales_amount,
        member_token
    from {{ ref('gld_attributed_conversions') }}
),

unattributed_sales as (
    -- Extract baseline purchases from customers buying organically with no campaign exposure
    select
        p.purchase_line_item_id,
        p.transaction_token,
        p.total_sales_amount,
        p.member_token
    from {{ ref('slv_purchases') }} p
    left join attributed_sales a 
        on p.purchase_line_item_id = a.purchase_line_item_id
    where a.purchase_line_item_id is null
),

customer_cohort_metrics as (
    -- Group metrics for the EXPOSED cohort
    select
        'Exposed Cohort' as consumer_segment,
        count(distinct member_token) as total_customers,
        count(distinct transaction_token) as total_orders,
        sum(total_sales_amount) as total_revenue
    from attributed_sales

    union all

    -- Group metrics for the NON-EXPOSED (Control/Organic) cohort
    select
        'Non-Exposed Cohort' as consumer_segment,
        count(distinct u.member_token) as total_customers,
        count(distinct u.transaction_token) as total_orders,
        sum(u.total_sales_amount) as total_revenue
    from unattributed_sales u
)

select
    consumer_segment,
    total_customers,
    total_orders,
    total_revenue,
    
    -- 1. Average Order Value (Basket Value)
    (total_revenue / nullif(total_orders, 0))::numeric(10,2) as average_order_value,
    
    -- 2. Purchase Frequency (Basket Velocity)
    (total_orders::numeric / nullif(total_customers, 0))::numeric(10,3) as purchase_frequency,
    
    -- 3. Total Financial Value per Customer
    (total_revenue / nullif(total_customers, 0))::numeric(10,2) as revenue_per_customer
from customer_cohort_metrics