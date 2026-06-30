-- dim_payment.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'payment_key',
        incremental_strategy = 'merge'
    )
}}

with source as (

    select distinct
        order_type as type
    from {{ ref('stg_supply_chain') }}

),

surrogate as (

    select
        {{ dbt_utils.generate_surrogate_key(['type']) }} as payment_key,
        type
    from source

)

select * from surrogate

{% if is_incremental() %}
    where payment_key not in (select payment_key from {{ this }})
{% endif %}