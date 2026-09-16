-- Show records rejected during Batch 3 validation.
-- Use the actual source/batch column present in silver_sales_rejected.

SELECT TOP 100 *
FROM dbo.silver_sales_rejected;