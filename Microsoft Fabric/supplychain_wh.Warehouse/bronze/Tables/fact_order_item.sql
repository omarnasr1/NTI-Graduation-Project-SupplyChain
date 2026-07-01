CREATE TABLE [bronze].[fact_order_item] (

	[order_item_key] varchar(400) NULL, 
	[order_item_id] int NULL, 
	[order_key] varchar(400) NULL, 
	[product_key] varchar(400) NULL, 
	[product_price] decimal(18,2) NULL, 
	[sales] decimal(18,2) NULL, 
	[sales_per_customer] decimal(18,2) NULL, 
	[order_item_quantity] int NULL, 
	[order_item_product_price] decimal(18,2) NULL, 
	[order_item_discount] decimal(18,2) NULL, 
	[order_item_discount_rate] decimal(18,4) NULL, 
	[order_item_total] decimal(18,2) NULL, 
	[order_item_profit_ratio] decimal(18,4) NULL, 
	[order_profit_per_order] decimal(18,2) NULL, 
	[benefit_per_order] decimal(18,2) NULL
);