-- dim_movement_type.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
    )
}}

with source as (

    select distinct
        movement_type_name,
        movement_direction
    from {{ ref('stg_supply_chain') }}

),

surrogate as (

    select
        {{ dbt_utils.generate_surrogate_key(['movement_type_name', 'movement_direction']) }} as movement_type_key,
        movement_type_name,
        movement_direction
    from source

)

select s.*
from surrogate s
{% if is_incremental() %}
left join {{ this }} t
    on s.movement_type_key = t.movement_type_key
where t.movement_type_key is null
{% endif %}