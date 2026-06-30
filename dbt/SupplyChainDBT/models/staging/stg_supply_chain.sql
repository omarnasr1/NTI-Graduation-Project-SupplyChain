-- stg_supply_chain.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'order_item_id',
        incremental_strategy = 'merge'
    )
}}

with source as (

    select * from {{ source('raw_data', 'raw_supplyChain') }}
),

Cleansed as (

    select
        Type                                                     as order_type,
        Days_for_shipping_real                                   as days_for_shipping_real,
        Days_for_shipment_scheduled                              as days_for_shipment_scheduled,
        coalesce(cast(Benefit_per_order as decimal(18,2)), 0)     as benefit_per_order,
        coalesce(cast(Sales_per_customer as decimal(18,2)), 0)    as sales_per_customer,
        Delivery_Status                                          as delivery_status,
        Late_delivery_risk                                       as late_delivery_risk,
        trim(Category_Name)                                      as category_name,
        trim(Customer_City)                                      as customer_city,
        case
            when upper(trim(Customer_Country)) = 'EE. UU.' then 'United States'
            else trim(Customer_Country)
        end                                                        as customer_country,
        
        Customer_Email                                           as customer_email,
        trim(Customer_Fname)                                     as customer_fname,
        trim(Customer_Lname)                                     as customer_lname,
        Customer_Password                                       as customer_password,
        trim(Customer_Segment)                                   as customer_segment,

        case
            when Customer_State rlike '^[0-9]+$' then null
            else trim(Customer_State)
        end                                                         as customer_state,

        trim(Customer_Street)                                    as customer_street,
        Customer_Zipcode                                         as customer_zipcode,
        trim(Department_Name)                                    as department_name,
        Latitude                                                 as latitude,
        Longitude                                                as longitude,
        trim(Market)                                              as market,

        replace(replace(trim(Order_City), 'ï؟½', 'ã'), '?', '@') as order_city,
        case trim(Order_Country)
            when 'Panamï؟½' then 'Panama'
            when 'Mï؟½xico' then 'Mexico'
            when 'Repï؟½blica Dominicana' then 'Republica Dominicana'
            when 'Perï؟½' then 'Peru'
            when 'Haitï؟½' then 'Haiti'
            when 'Espaï؟½a' then 'Espana'
            when 'Bï؟½lgica' then 'Belgica'
            when 'Paï؟½ses Bajos' then 'Paises Bajos'
            when 'Japï؟½n' then 'Japon'
            when 'Pakistï؟½n' then 'Pakistan'
            when 'Bangladï؟½s' then 'Banglades'
            when 'Papï؟½a Nueva Guinea' then 'Papua Nueva Guinea'
            when 'Afganistï؟½n' then 'Afganistan'
            when 'Taiwï؟½n' then 'Taiwan'
            when 'Irï؟½n' then 'Iran'
            when 'Turquï؟½a' then 'Turquia'
            when 'Sudï؟½n' then 'Sudan'
            when 'Arabia Saudï؟½' then 'Arabia Saudi'
            when 'Repï؟½blica Democrï؟½tica del Congo' then 'Republica Democratica del Congo'
            when 'Azerbaiyï؟½n' then 'Azerbaiyan'
            when 'Repï؟½blica Checa' then 'Republica Checa'
            when 'Camerï؟½n' then 'Camerun'
            when 'Uzbekistï؟½n' then 'Uzbekistan'
            when 'Kazajistï؟½n' then 'Kazajistan'
            when 'Turkmenistï؟½n' then 'Turkmenistan'
            when 'Benï؟½n' then 'Benin'
            when 'Hungrï؟½a' then 'Hungria'
            when 'Tï؟½nez' then 'Tunez'
            when 'Emiratos ï؟½rabes Unidos' then 'Emiratos Arabes Unidos'
            when 'Kirguistï؟½n' then 'Kirguistan'
            when 'Nï؟½ger' then 'Niger'
            when 'Repï؟½blica Centroafricana' then 'Republica Centroafricana'
            when 'Gabï؟½n' then 'Gabon'
            when 'Repï؟½blica del Congo' then 'Republica del Congo'
            when 'Repï؟½blica de Gambia' then 'Republica de Gambia'
            when 'Etiopï؟½a' then 'Etiopía'
            when 'Barï؟½in' then 'Barein'
            when 'Lï؟½bano' then 'Libano'
            when 'Tayikistï؟½n' then 'Tayikistan'
            when 'Omï؟½n' then 'Oman'
            when 'Sudï؟½n del Sur' then 'Sudan del Sur'
            when 'Butï؟½n' then 'Butan'
            when 'Sï؟½hara Occidental' then 'Sahara Occidental'
            else trim(Order_Country)
            end                                                     as order_country,

        to_date(to_timestamp(order_date,    'MM/DD/YYYY HH24:MI')) as order_date,
        Order_Id                                                 as order_id,
        coalesce(cast(Order_Item_Discount as decimal(18,2)), 0)   as order_item_discount,
        coalesce(cast(Order_Item_Discount_Rate as decimal(18,4)), 0)          as order_item_discount_rate,
        Order_Item_Id                                             as order_item_id,
        coalesce(cast(Order_Item_Product_Price as decimal(18,2)), 0)         as order_item_product_price,
        coalesce(cast(Order_Item_Profit_Ratio as decimal(18,4)), 0)           as order_item_profit_ratio,
        Order_Item_Quantity                                      as order_item_quantity,

        coalesce(cast(Sales as decimal(18,2)), 0)                             as sales,
        coalesce(cast(Order_Item_Total as decimal(18,2)), 0)                  as order_item_total,
        coalesce(cast(Order_Profit_Per_Order as decimal(18,2)), 0)            as order_profit_per_order,

        trim(Order_Region)                                       as order_region,
        replace(replace(trim(Order_State), 'ï؟½', 'ã'), '?', '@') as order_state,
        trim(Order_Status)                                       as order_status,

        Order_Zipcode                                            as order_zipcode,

        coalesce(trim(Product_Description), 'No description available') as product_description,
        trim(Product_Image)                                      as product_image,
        trim(Product_Name)                                       as product_name,
        coalesce(cast(Product_Price as decimal(18,2)), 0)                     as product_price,
        Product_Status                                           as product_status,

        to_date(to_timestamp(shipping_date, 'MM/DD/YYYY HH24:MI')) as shipping_date,
        trim(Shipping_Mode)                                      as shipping_mode,
 
        to_date(to_timestamp(movement_date, 'MM/DD/YYYY'))         as movement_date,
        Quantity_Moved                                           as quantity_moved,
        coalesce(cast(Unit_Cost_At_Movement as decimal(18,2)), 0)             as unit_cost_at_movement,
        Stock_On_Hand_After_Movement                             as stock_on_hand_after_movement,
        trim(Movement_Type_Name)                                 as movement_type_name,
        trim(Movement_Direction)                                 as movement_direction,

        trim(Warehouse_Name)                                     as warehouse_name,
        trim(Warehouse_Type)                                     as warehouse_type,
        trim(Warehouse_City)                                     as warehouse_city,
        trim(Warehouse_Country)                                  as warehouse_country,
        Warehouse_Capacity                                       as warehouse_capacity

    from source

)

select * from Cleansed