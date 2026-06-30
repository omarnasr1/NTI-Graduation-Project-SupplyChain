-- dim_customer_geography.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'customer_geography_key',
        incremental_strategy = 'merge'
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

-- omar , dirut , 

select * from surrogate

{% if is_incremental() %}
    where customer_geography_key not in (select customer_geography_key from {{ this }})
{% endif %}