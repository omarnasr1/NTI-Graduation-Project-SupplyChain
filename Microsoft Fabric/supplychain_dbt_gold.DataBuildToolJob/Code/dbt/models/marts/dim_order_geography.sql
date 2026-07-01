-- dim_order_geography.sql
{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append'
    )
}}

with source as (

    select
        order_city,
        order_state,
        order_country,
        order_region,
        order_zipcode,
        market,
        latitude,
        longitude,
        row_number() over (
            partition by order_city, order_state, order_country, order_region, order_zipcode
            order by order_city
        ) as rn
    from {{ ref('stg_supply_chain') }}

),

deduped as (

    select
        order_city,
        order_state,
        order_country,
        order_region,
        order_zipcode,
        market,
        latitude,
        longitude
    from source
    where rn = 1

),

surrogate as (

    select
        {{ dbt_utils.generate_surrogate_key(['order_city', 'order_state', 'order_country', 'order_region', 'order_zipcode']) }} as order_geography_key,
        order_city,
        order_state,
        order_country,
        order_region,
        order_zipcode,
        market,
        latitude,
        longitude
    from deduped

)

select s.*
from surrogate s
{% if is_incremental() %}
left join {{ this }} t
    on s.order_geography_key = t.order_geography_key
where t.order_geography_key is null
{% endif %}