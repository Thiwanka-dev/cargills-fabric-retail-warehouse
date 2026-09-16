-- Verify that the Gold reporting state remains unchanged
-- after a failed validation batch.

SELECT
    COUNT(*) AS gold_row_count,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM dbo.gold_sales_fact;