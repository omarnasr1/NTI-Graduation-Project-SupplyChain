--dim_department.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'department_key',
        incremental_strategy = 'merge'
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

select * from surrogate

{% if is_incremental() %}
    where department_key not in (select department_key from {{ this }})
{% endif %}