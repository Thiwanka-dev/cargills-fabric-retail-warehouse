CREATE SECURITY POLICY Security.SalesRegionFilter
ADD FILTER PREDICATE Security.fn_region_access(region)
ON dbo.gold_sales_fact
WITH (STATE = ON);