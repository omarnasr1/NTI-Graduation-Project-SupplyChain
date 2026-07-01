-- fact_shipping_performance.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
    )
}}

with stg as (

    select * from {{ ref('stg_supply_chain') }}

),

dedup as (

    select
        order_id,
        days_for_shipping_real,
        days_for_shipment_scheduled,
        late_delivery_risk,
        row_number() over (
            partition by order_id
            order by order_item_id
        ) as rn
    from stg

),

ord as (
    select order_id, order_key from {{ ref('dim_order') }}
),

joined as (

    select
        {{ dbt_utils.generate_surrogate_key(['dedup.order_id']) }} as shipping_performance_key,
        ord.order_key,
        dedup.days_for_shipping_real,
        dedup.days_for_shipment_scheduled,
        dedup.days_for_shipment_scheduled - dedup.days_for_shipping_real as delay_between_real_scheduled,
        dedup.late_delivery_risk
    from dedup
    left join ord
        on dedup.order_id = ord.order_id
    where dedup.rn = 1

)

select j.*
from joined j
{% if is_incremental() %}
left join {{ this }} t
    on j.shipping_performance_key = t.shipping_performance_key
where t.shipping_performance_key is null
{% endif %}