-- dim_order.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'order_key',
        incremental_strategy = 'merge'
    )
}}

with stg as (

    select * from {{ ref('stg_supply_chain') }}

),

-- one row per order_id: every column below is verified constant per order
-- (customer, geography, shipping mode, statuses, dates, payment type)
dedup as (

    select
        order_id,
        customer_fname,
        customer_lname,
        customer_segment,
        customer_street,
        customer_country,
        order_city,
        order_state,
        order_country,
        order_region,
        order_zipcode,
        shipping_mode,
        delivery_status,
        order_status,
        order_date,
        shipping_date,
        order_type,
        row_number() over (
            partition by order_id
            order by order_item_id
        ) as rn
    from stg

),

cust as (
    select * from {{ ref('dim_customer') }}
),

order_geo as (
    select * from {{ ref('dim_order_geography') }}
),

ship_mode as (
    select * from {{ ref('dim_shipping_mode') }}
),

delivery as (
    select * from {{ ref('dim_delivery_status') }}
),

ord_status as (
    select * from {{ ref('dim_order_status') }}
),

order_date_dim as (
    select * from {{ ref('dim_date') }}
),

shipping_date_dim as (
    select * from {{ ref('dim_date') }}
),

payment as (
    select * from {{ ref('dim_payment') }}
),

joined as (

    select
        {{ dbt_utils.generate_surrogate_key(['dedup.order_id']) }} as order_key,
        dedup.order_id,
        cust.customer_key,
        order_geo.order_geography_key,
        ship_mode.shipping_mode_key,
        delivery.delivery_status_key,
        ord_status.order_status_key,
        order_date_dim.date_key    as order_date_key,
        shipping_date_dim.date_key as shipping_date_key,
        payment.payment_key
    from dedup
    left join cust
        on dedup.customer_fname   = cust.customer_fname
       and dedup.customer_lname   = cust.customer_lname
       and dedup.customer_segment = cust.customer_segment
       and dedup.customer_street  = cust.customer_street
       and dedup.customer_country = cust.customer_country
    left join order_geo
        on dedup.order_city    = order_geo.order_city
        and dedup.order_state   = order_geo.order_state
        and dedup.order_country = order_geo.order_country
        and dedup.order_region  = order_geo.order_region
        and equal_null(dedup.order_zipcode, order_geo.order_zipcode)
    left join ship_mode
        on dedup.shipping_mode = ship_mode.shipping_mode
    left join delivery
        on dedup.delivery_status = delivery.delivery_status
    left join ord_status
        on dedup.order_status = ord_status.order_status
    left join order_date_dim
        on dedup.order_date = order_date_dim.full_date
    left join shipping_date_dim
        on dedup.shipping_date = shipping_date_dim.full_date
    left join payment
        on dedup.order_type = payment.type
    where dedup.rn = 1

)

select * from joined

{% if is_incremental() %}
    where order_key not in (select order_key from {{ this }})
{% endif %}