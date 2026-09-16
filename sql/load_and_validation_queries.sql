-- Silver processing audit log
-- Records every successful or failed Silver processing run.

CREATE TABLE silver_processing_log (
    run_id STRING,
    batch_file_name STRING,
    processing_start_time TIMESTAMP,
    processing_end_time TIMESTAMP,
    status STRING,
    rows_received BIGINT,
    rows_passed BIGINT,
    rows_rejected BIGINT,
    rows_after_deduplication BIGINT,
    rows_written BIGINT,
    failure_reason STRING
);