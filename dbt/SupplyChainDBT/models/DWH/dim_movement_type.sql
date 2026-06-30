--dim_movement_type.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'movement_type_key',
        incremental_strategy = 'merge'
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

select * from surrogate

{% if is_incremental() %}
    where movement_type_key not in (select movement_type_key from {{ this }})
{% endif %}