CREATE TABLE [bronze].[fact_inventory_movement] (

	[inventory_movement_key] varchar(400) NULL, 
	[order_item_key] varchar(400) NULL, 
	[product_key] varchar(400) NULL, 
	[warehouse_key] varchar(400) NULL, 
	[movement_date_key] int NULL, 
	[movement_type_key] varchar(400) NULL, 
	[quantity_moved] int NULL, 
	[unit_cost_at_movement] decimal(18,2) NULL, 
	[stock_on_hand_after_movement] int NULL
);