--dim_order_status.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'order_status_key',
        incremental_strategy = 'merge'
    )
}}

with source as (

    select distinct
        order_status
    from {{ ref('stg_supply_chain') }}

),

surrogate as (

    select
        {{ dbt_utils.generate_surrogate_key(['order_status']) }} as order_status_key,
        order_status
    from source

)

select * from surrogate

{% if is_incremental() %}
    where order_status_key not in (select order_status_key from {{ this }})
{% endif %}