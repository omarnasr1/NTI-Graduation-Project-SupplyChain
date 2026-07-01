CREATE TABLE [bronze].[dim_product] (

	[product_key] varchar(400) NULL, 
	[product_name] varchar(8000) NULL, 
	[product_description] varchar(8000) NULL, 
	[product_image] varchar(8000) NULL, 
	[product_status] int NULL, 
	[category_key] varchar(400) NULL, 
	[department_key] varchar(400) NULL
);