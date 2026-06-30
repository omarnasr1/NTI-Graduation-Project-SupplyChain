--dim_date
{{
    config(
        materialized = 'table'
    )
}}

with year_bounds as (

    select
        min(year_val)-5 as min_year,
        max(year_val)+5 as max_year
    from (
        select extract(year from order_date) as year_val from {{ ref('stg_supply_chain') }} where order_date is not null
        union
        select extract(year from shipping_date) as year_val from {{ ref('stg_supply_chain') }} where shipping_date is not null
        union
        select extract(year from movement_date) as year_val from {{ ref('stg_supply_chain') }} where movement_date is not null
    )

),

all_date_with_no_gaps as (

    select
        dateadd(
            day,
            row_number() over (order by seq4()) - 1,
            to_date(min_year || '-01-01')
        ) as full_date
    from year_bounds,
         table(generator(rowcount => 5000))
    qualify full_date <= to_date(max_year || '-12-31')
),

calendar as (

    select
        cast(to_char(full_date, 'YYYYMMDD') as int) as date_key,
        full_date,
        extract(day from full_date)                  as day,
        extract(month from full_date)                 as month,
        extract(quarter from full_date)                as quarter,
        extract(year from full_date)                   as year,
        to_char(full_date, 'DY')                        as day_name,
        to_char(full_date, 'MON')                       as month_name
    from all_date_with_no_gaps

)

select * from calendar