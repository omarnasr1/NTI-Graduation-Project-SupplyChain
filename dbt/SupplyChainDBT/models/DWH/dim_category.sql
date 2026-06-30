-- dim_category.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'category_key',
        incremental_strategy = 'merge'
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

select * from surrogate

{% if is_incremental() %}
    where category_key not in (select category_key from {{ this }})
{% endif %}