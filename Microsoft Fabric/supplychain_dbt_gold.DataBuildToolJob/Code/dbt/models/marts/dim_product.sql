-- dim_product.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
    )
}}

with stg as (

    select distinct
        product_name,
        product_description,
        product_image,
        product_status,
        category_name,
        department_name
    from {{ ref('stg_supply_chain') }}

),

cat as (
    select * from {{ ref('dim_category') }}
),

dept as (
    select * from {{ ref('dim_department') }}
),

joined as (

    select
        {{ dbt_utils.generate_surrogate_key(['stg.product_name', 'stg.product_description', 'stg.product_image', 'stg.product_status']) }} as product_key,
        stg.product_name,
        stg.product_description,
        stg.product_image,
        stg.product_status,
        cat.category_key,
        dept.department_key
    from stg
    left join cat
        on stg.category_name = cat.category_name
    left join dept
        on stg.department_name = dept.department_name

)

select j.*
from joined j
{% if is_incremental() %}
left join {{ this }} t
    on j.product_key = t.product_key
where t.product_key is null
{% endif %}