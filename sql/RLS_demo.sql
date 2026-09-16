-- Verify the rows visible to the currently authenticated SQL identity.
-- SQL RLS should restrict the result to the user's authorized region.

SELECT
    region,
    COUNT(*) AS row_count,
    SUM(sales) AS total_sales
FROM dbo.gold_sales_fact
GROUP BY region
ORDER BY region;