CREATE TABLE [bronze].[dim_order] (

	[order_key] varchar(400) NULL, 
	[order_id] int NULL, 
	[customer_key] varchar(400) NULL, 
	[order_geography_key] varchar(400) NULL, 
	[shipping_mode_key] varchar(400) NULL, 
	[delivery_status_key] varchar(400) NULL, 
	[order_status_key] varchar(400) NULL, 
	[order_date_key] int NULL, 
	[shipping_date_key] int NULL, 
	[payment_key] varchar(400) NULL
);