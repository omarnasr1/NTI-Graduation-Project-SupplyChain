CREATE TABLE [bronze].[dim_date] (

	[date_key] int NULL, 
	[full_date] date NULL, 
	[day] int NULL, 
	[month] int NULL, 
	[quarter] int NULL, 
	[year] int NULL, 
	[day_name] varchar(3) NULL, 
	[month_name] varchar(3) NULL
);