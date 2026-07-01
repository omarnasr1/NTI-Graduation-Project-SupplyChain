{{ config(materialized='table') }}

with year_bounds as (

    select
        min(year_val) - 5 as min_year,
        max(year_val) + 5 as max_year
    from (
        select datepart(year, order_date) as year_val from {{ ref('stg_supply_chain') }} where order_date is not null
        union
        select datepart(year, shipping_date) as year_val from {{ ref('stg_supply_chain') }} where shipping_date is not null
        union
        select datepart(year, movement_date) as year_val from {{ ref('stg_supply_chain') }} where movement_date is not null
    ) as combined_years

),

bounds_as_dates as (

    select
        datefromparts(min_year, 1, 1)   as start_date,
        datefromparts(max_year, 12, 31) as end_date,
        datediff(day, datefromparts(min_year, 1, 1), datefromparts(max_year, 12, 31)) + 1 as total_days
    from year_bounds

),

-- Builds a set of sequential integers (0, 1, 2, ... up to ~8000) using pure
-- cross joins of small digit sets (10 x 10 x 10 x 8 = 8000 max rows).
-- This avoids recursion entirely, which Fabric Warehouse does not support
-- with an unbounded depth.
numbers as (

    select
        a.n + b.n * 10 + c.n * 100 + d.n * 1000 as num
    from
        (select 0 as n union select 1 union select 2 union select 3 union select 4
         union select 5 union select 6 union select 7 union select 8 union select 9) a
    cross join
        (select 0 as n union select 1 union select 2 union select 3 union select 4
         union select 5 union select 6 union select 7 union select 8 union select 9) b
    cross join
        (select 0 as n union select 1 union select 2 union select 3 union select 4
         union select 5 union select 6 union select 7 union select 8 union select 9) c
    cross join
        (select 0 as n union select 1 union select 2 union select 3 union select 4
         union select 5 union select 6 union select 7) d

),

date_spine as (

    select
        dateadd(day, numbers.num, bounds_as_dates.start_date) as full_date
    from numbers
    cross join bounds_as_dates
    where numbers.num < bounds_as_dates.total_days

),

calendar as (

    select
        cast(format(full_date, 'yyyyMMdd') as int)         as date_key,
        full_date,
        datepart(day, full_date)                            as day,
        datepart(month, full_date)                          as month,
        datepart(quarter, full_date)                         as quarter,
        datepart(year, full_date)                            as year,
        cast(format(full_date, 'ddd') as varchar(3))         as day_name,
        cast(format(full_date, 'MMM') as varchar(3))         as month_name
    from date_spine

)

select * from calendar