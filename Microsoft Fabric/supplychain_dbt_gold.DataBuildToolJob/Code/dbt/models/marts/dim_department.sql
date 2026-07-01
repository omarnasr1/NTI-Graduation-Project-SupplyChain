-- dim_department.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
    )
}}

with source as (

    select distinct
        department_name
    from {{ ref('stg_supply_chain') }}

),

surrogate as (

    select
        {{ dbt_utils.generate_surrogate_key(['department_name']) }} as department_key,
        department_name
    from source

)

select s.*
from surrogate s
{% if is_incremental() %}
left join {{ this }} t
    on s.department_key = t.department_key
where t.department_key is null
{% endif %}