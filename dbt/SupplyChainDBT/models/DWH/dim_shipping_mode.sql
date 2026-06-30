--dim_shipping_mode.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'shipping_mode_key',
        incremental_strategy = 'merge'
    )
}}

with source as (

    select distinct
        shipping_mode
    from {{ ref('stg_supply_chain') }}

),

surrogate as (

    select
        {{ dbt_utils.generate_surrogate_key(['shipping_mode']) }} as shipping_mode_key,
        shipping_mode
    from source

)

select * from surrogate

{% if is_incremental() %}
    where shipping_mode_key not in (select shipping_mode_key from {{ this }})
{% endif %}