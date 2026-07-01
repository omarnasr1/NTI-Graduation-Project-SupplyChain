CREATE TABLE [bronze].[dim_order_geography] (

	[order_geography_key] varchar(400) NULL, 
	[order_city] varchar(8000) NULL, 
	[order_state] varchar(8000) NULL, 
	[order_country] varchar(8000) NULL, 
	[order_region] varchar(8000) NULL, 
	[order_zipcode] varchar(8000) NULL, 
	[market] varchar(8000) NULL, 
	[latitude] float NULL, 
	[longitude] float NULL
);