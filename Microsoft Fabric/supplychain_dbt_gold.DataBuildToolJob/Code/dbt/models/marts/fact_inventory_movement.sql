-- fact_inventory_movement.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
    )
}}

with stg as (

    select * from {{ ref('stg_supply_chain') }}

),

order_item as (
    select order_item_id, order_item_key from {{ ref('fact_order_item') }}
),

prod as (
    select * from {{ ref('dim_product') }}
),

wh as (
    select * from {{ ref('dim_warehouse') }}
),

movement_date_dim as (
    select * from {{ ref('dim_date') }}
),

mvmt_type as (
    select * from {{ ref('dim_movement_type') }}
),

joined as (

    select
        {{ dbt_utils.generate_surrogate_key(['stg.order_item_id', 'stg.movement_date', 'stg.warehouse_name']) }} as inventory_movement_key,
        order_item.order_item_key,
        prod.product_key,
        wh.warehouse_key,
        movement_date_dim.date_key as movement_date_key,
        mvmt_type.movement_type_key,
        stg.quantity_moved,
        stg.unit_cost_at_movement,
        stg.stock_on_hand_after_movement
    from stg
    left join order_item
        on stg.order_item_id = order_item.order_item_id
    left join prod
        on stg.product_name        = prod.product_name
       and stg.product_description = prod.product_description
       and stg.product_image       = prod.product_image
       and stg.product_status      = prod.product_status
    left join wh
        on stg.warehouse_name    = wh.warehouse_name
       and stg.warehouse_city    = wh.warehouse_city
       and stg.warehouse_country = wh.warehouse_country
    left join movement_date_dim
        on stg.movement_date = movement_date_dim.full_date
    left join mvmt_type
        on stg.movement_type_name = mvmt_type.movement_type_name
       and stg.movement_direction = mvmt_type.movement_direction

)

select j.*
from joined j
{% if is_incremental() %}
left join {{ this }} t
    on j.inventory_movement_key = t.inventory_movement_key
where t.inventory_movement_key is null
{% endif %}