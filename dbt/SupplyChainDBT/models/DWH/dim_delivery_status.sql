-- dim_delivary_status.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'delivery_status_key',
        incremental_strategy = 'merge'
    )
}}

with source as (

    select distinct
        delivery_status
    from {{ ref('stg_supply_chain') }}

),

surrogate as (

    select
        {{ dbt_utils.generate_surrogate_key(['delivery_status']) }} as delivery_status_key,
        delivery_status
    from source

)

select * from surrogate

{% if is_incremental() %}
    where delivery_status_key not in (select delivery_status_key from {{ this }})
{% endif %}