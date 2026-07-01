-- dim_category.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
    )
}}

with source as (

    select distinct
        category_name
    from {{ ref('stg_supply_chain') }}

),

surrogate as (

    select
        {{ dbt_utils.generate_surrogate_key(['category_name']) }} as category_key,
        category_name
    from source

)

select s.*
from surrogate s
{% if is_incremental() %}
left join {{ this }} t
    on s.category_key = t.category_key
where t.category_key is null
{% endif %}