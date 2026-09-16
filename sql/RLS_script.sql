-- Create the schema used for data-layer security.
CREATE SCHEMA Security;
GO

-- Map the authenticated SQL user to their authorized region.
CREATE FUNCTION Security.fn_region_access
(
    @region VARCHAR(50)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS result
    FROM dbo.security_user_region AS s
    WHERE s.user_principal = USER_NAME()
      AND s.region = @region
);
GO

-- Enforce regional filtering at the SQL data layer.
CREATE SECURITY POLICY Security.SalesRegionFilter
ADD FILTER PREDICATE Security.fn_region_access(region)
ON dbo.gold_sales_fact
WITH (STATE = ON);