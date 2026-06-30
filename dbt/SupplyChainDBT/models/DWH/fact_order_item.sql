-- fact_order_item.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'order_item_key',
        incremental_strategy = 'merge'
    )
}}

with stg as (

    select * from {{ ref('stg_supply_chain') }}

),

prod as (
    select * from {{ ref('dim_product') }}
),

ord as (
    select order_id, order_key from {{ ref('dim_order') }}
),

joined as (

    select
        {{ dbt_utils.generate_surrogate_key(['stg.order_item_id']) }} as order_item_key,
        stg.order_item_id,
        ord.order_key,
        prod.product_key,
        stg.product_price,
        stg.sales,
        stg.sales_per_customer,
        stg.order_item_quantity,
        stg.order_item_product_price,
        stg.order_item_discount,
        stg.order_item_discount_rate,
        stg.order_item_total,
        stg.order_item_profit_ratio,
        stg.order_profit_per_order,
        stg.benefit_per_order
    from stg
    left join prod
        on stg.product_name        = prod.product_name
       and stg.product_description = prod.product_description
       and stg.product_image       = prod.product_image
       and stg.product_status      = prod.product_status
    left join ord
        on stg.order_id = ord.order_id

)

select * from joined

{% if is_incremental() %}
    where order_item_key not in (select order_item_key from {{ this }})
{% endif %}