-- dim_customer_geography.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
    )
}}

with source as (

    select distinct
        customer_street,
        customer_state,
        customer_zipcode,
        customer_country,
        customer_city
    from {{ ref('stg_supply_chain') }}

),

surrogate as (

    select
        {{ dbt_utils.generate_surrogate_key(['customer_street', 'customer_state', 'customer_zipcode', 'customer_country', 'customer_city']) }} as customer_geography_key,
        customer_street,
        customer_state,
        customer_zipcode,
        customer_country,
        customer_city
    from source

)

select s.*
from surrogate s
{% if is_incremental() %}
left join {{ this }} t
    on s.customer_geography_key = t.customer_geography_key
where t.customer_geography_key is null
{% endif %}