CREATE TABLE [bronze].[dim_customer_geography] (

	[customer_geography_key] varchar(400) NULL, 
	[customer_street] varchar(8000) NULL, 
	[customer_state] varchar(8000) NULL, 
	[customer_zipcode] int NULL, 
	[customer_country] varchar(8000) NULL, 
	[customer_city] varchar(8000) NULL
);