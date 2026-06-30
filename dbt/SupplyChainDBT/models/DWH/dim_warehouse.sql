-- dim_warehouse.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'warehouse_key',
        incremental_strategy = 'merge'
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

select * from surrogate

{% if is_incremental() %}
    where warehouse_key not in (select warehouse_key from {{ this }})
{% endif %}