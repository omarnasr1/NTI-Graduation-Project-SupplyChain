CREATE TABLE [bronze].[fact_shipping_performance] (

	[shipping_performance_key] varchar(400) NULL, 
	[order_key] varchar(400) NULL, 
	[days_for_shipping_real] int NULL, 
	[days_for_shipment_scheduled] int NULL, 
	[delay_between_real_scheduled] int NULL, 
	[late_delivery_risk] int NULL
);