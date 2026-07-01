-- dim_delivery_status.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
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

select s.*
from surrogate s
{% if is_incremental() %}
left join {{ this }} t
    on s.delivery_status_key = t.delivery_status_key
where t.delivery_status_key is null
{% endif %}