-- dim_order_status.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
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

select s.*
from surrogate s
{% if is_incremental() %}
left join {{ this }} t
    on s.order_status_key = t.order_status_key
where t.order_status_key is null
{% endif %}