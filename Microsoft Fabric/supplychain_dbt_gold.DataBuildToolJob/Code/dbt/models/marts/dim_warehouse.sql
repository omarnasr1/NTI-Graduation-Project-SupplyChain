-- dim_warehouse.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
    )
}}

with source as (

    select distinct
        warehouse_name,
        warehouse_type,
        warehouse_city,
        warehouse_country,
        warehouse_capacity
    from {{ ref('stg_supply_chain') }}

),

surrogate as (

    select
        {{ dbt_utils.generate_surrogate_key(['warehouse_name', 'warehouse_city', 'warehouse_country']) }} as warehouse_key,
        warehouse_name,
        warehouse_type,
        warehouse_city,
        warehouse_country,
        warehouse_capacity
    from source

)

select s.*
from surrogate s
{% if is_incremental() %}
left join {{ this }} t
    on s.warehouse_key = t.warehouse_key
where t.warehouse_key is null
{% endif %}