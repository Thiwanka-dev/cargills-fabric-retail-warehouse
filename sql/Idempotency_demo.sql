-- Verify that current-state Silver contains one record per Row ID.
-- This is used to demonstrate that rerunning a batch does not create duplicates.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT row_id) AS distinct_row_ids
FROM dbo.silver_sales_current;