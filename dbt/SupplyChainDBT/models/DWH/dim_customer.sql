--- dim_customer
{{
    config(
        materialized = 'incremental',
        unique_key = 'customer_key',
        incremental_strategy = 'merge'
    )
}}

with stg as (

    select
        customer_fname,
        customer_lname,
        customer_email,
        customer_password,
        customer_segment,
        customer_street,
        customer_state,
        customer_zipcode,
        customer_country,
        customer_city,
        row_number() over (
            partition by customer_fname, customer_lname, customer_segment, customer_street, customer_country
            order by customer_fname
        ) as rn
    from {{ ref('stg_supply_chain') }}

),

deduped as (

    select
        customer_fname,
        customer_lname,
        customer_email,
        customer_password,
        customer_segment,
        customer_street,
        customer_state,
        customer_zipcode,
        customer_country,
        customer_city
    from stg
    where rn = 1

),

geo as (

    select * from {{ ref('dim_customer_geography') }}

),

joined as (

    select
        {{ dbt_utils.generate_surrogate_key(['deduped.customer_fname', 'deduped.customer_lname', 'deduped.customer_segment', 'deduped.customer_street', 'deduped.customer_country']) }} as customer_key,
        geo.customer_geography_key,
        deduped.customer_fname,
        deduped.customer_lname,
        deduped.customer_street,
        deduped.customer_country,
        deduped.customer_email,
        deduped.customer_password,
        deduped.customer_segment
    from deduped
    left join geo
        on deduped.customer_street    = geo.customer_street
       and deduped.customer_state     = geo.customer_state
       and deduped.customer_zipcode   = geo.customer_zipcode
       and deduped.customer_country   = geo.customer_country
       and deduped.customer_city      = geo.customer_city

)

select * from joined

{% if is_incremental() %}
    where customer_key not in (select customer_key from {{ this }})
{% endif %}