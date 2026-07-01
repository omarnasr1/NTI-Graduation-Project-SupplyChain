-- dim_shipping_mode.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
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

select s.*
from surrogate s
{% if is_incremental() %}
left join {{ this }} t
    on s.shipping_mode_key = t.shipping_mode_key
where t.shipping_mode_key is null
{% endif %}