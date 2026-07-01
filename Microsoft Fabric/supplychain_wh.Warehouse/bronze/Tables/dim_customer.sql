CREATE TABLE [bronze].[dim_customer] (

	[customer_key] varchar(400) NULL, 
	[customer_geography_key] varchar(400) NULL, 
	[customer_fname] varchar(8000) NULL, 
	[customer_lname] varchar(8000) NULL, 
	[customer_street] varchar(8000) NULL, 
	[customer_country] varchar(8000) NULL, 
	[customer_email] varchar(8000) NULL, 
	[customer_password] varchar(8000) NULL, 
	[customer_segment] varchar(8000) NULL
);