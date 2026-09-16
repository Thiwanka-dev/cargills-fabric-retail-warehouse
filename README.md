

Cargills_Retail_Analytics_README.md


Cargills Retail Analytics --- Microsoft Fabric Data Engineering Assessment
End-to-end retail data engineering solution built with Microsoft
Fabric, PySpark, Delta Lake, SQL Row-Level Security, and Power BI.



📌 Project Overview
This project implements a production-oriented retail analytics
foundation on Microsoft Fabric for processing periodic transactional
sales CSV batches arriving from a public web source.

The solution addresses four core requirements:

Reliable batch ingestion without manual file downloads/uploads

Incremental and repeatable processing with duplicate prevention and
correction handling

Automated data-quality validation before data reaches reporting

Data-layer security so regional users only access permitted sales
data

The solution follows a Bronze → Silver → Gold architecture and
exposes the secured Gold layer to Power BI for regional sales and
profitability analysis.

🏗️ Architecture
Public GitHub CSV Source
          │
          │ HTTP
          ▼
┌────────────────────────────┐
│ Microsoft Fabric Pipeline  │
│ pl_Cargills_Master         │
└─────────────┬──────────────┘
              │
              ▼
┌────────────────────────────┐
│ Bronze                     │
│ Raw records + metadata     │
│ bronze_sales               │
└─────────────┬──────────────┘
              │
              ▼
┌────────────────────────────┐
│ Silver                     │
│ Schema + DQ + Dedup        │
│ Current-state processing   │
└─────────────┬──────────────┘
              │
       ┌──────┴─────────┐
       │                │
       ▼                ▼
Rejected records    Processing logs
       │
       ▼
┌────────────────────────────┐
│ Gold                       │
│ Fact + Dimensions          │
└─────────────┬──────────────┘
              │
              ▼
┌────────────────────────────┐
│ SQL Analytics Endpoint     │
│ Data-layer RLS             │
└─────────────┬──────────────┘
              │
              ▼
┌────────────────────────────┐
│ Power BI                   │
│ Regional Retail Analytics  │
└────────────────────────────┘
Master pipeline
Copy_Batch_To_Bronze
        │
        ▼
NB_Bronze_Ingestion
        │
        ▼
NB_Silver_Processing
        │
        ├── Success ──► NB_Gold_Transformation
        │
        └── Failure ──► Notify_Validation_Failure
🧰 Technology Stack
Technology Purpose

Microsoft Fabric End-to-end data engineering platform
Fabric Data Pipeline Batch orchestration
Fabric Lakehouse Layered Delta storage
PySpark Transformation, validation, deduplication and MERGE
Delta Lake ACID storage and current-state processing
SQL Analytics Endpoint Analytical access and security boundary
SQL Row-Level Security Regional data access control
Power BI Business reporting
GitHub Source control and documentation

📂 Repository Structure
Cargills-Retail-Analytics/
│
├── 01_Notebooks/
│   ├── NB_Bronze_Ingestion.ipynb
│   ├── NB_Silver_Processing.ipynb
│   └── NB_Gold_Transformation.ipynb
│
├── 02_SQL/
│   ├── 01_table_definitions.sql
│   ├── 02_load_logic.sql
│   ├── 03_security_mapping.sql
│   ├── 04_rls_policy.sql
│   └── 05_demo_validation_queries.sql
│
├── 03_PowerBI/
│   └── Cargills_Retail_Analytics.pbix
│
├── 04_Screenshots/
│   ├── 01_master_pipeline_dependencies.png
│   ├── 02_successful_batch_run.png
│   ├── 03_batch3_validation_failure.png
│   ├── 04_batch3_rejected_records.png
│   ├── 05_batch3_failure_email.png
│   ├── 06_gold_unchanged_after_batch3.png
│   ├── 07_powerbi_rls.png
│   └── 08_direct_sql_rls.png
│
├── 05_Demo/
│   └── Cargills_DE_Demo.mp4
│
├── 06_Documentation/
│   ├── Cargills_DE_One_Page_Architecture_Summary.pdf
│   └── Cargills_DE_Architecture_and_Design_Decisions.docx
│
└── README.md
Public repository: never commit passwords, tokens, secrets,
private connection strings, workspace credentials, or real customer
PII. Replace assessment-specific identities with safe placeholders
where necessary.

🔄 Data Flow
Each source CSV is treated as a separate arriving batch.

The master pipeline uses the parameter:

batch_file_name
Example values:

batch_01_history.csv
batch_02_incremental.csv
batch_03_incremental.csv
The filename is passed dynamically to the HTTP Copy Activity rather than
hardcoded into the pipeline.

This allows the same orchestration to process different batches without
modifying the pipeline definition.

🥉 Bronze Layer
Table
bronze_sales
Bronze preserves the incoming source records and adds ingestion
metadata:

source_file_name
load_run_id
ingestion_timestamp
Batch identity vs execution identity
source_file_name = logical batch identity
load_run_id      = pipeline execution identity
This distinction makes processing traceable across repeated executions.

The CSV reader explicitly handles quoted and escaped fields so values
containing commas, such as product names, are parsed correctly.

Idempotent batch ingestion
Bronze processing replaces the existing stored copy for the same source
batch rather than appending another copy of the batch.

🥈 Silver Layer
Silver is responsible for:

Schema validation

Data type standardization

Record-level data-quality validation

Rejection/quarantine of invalid records

Duplicate detection

Deduplication

Incremental current-state updates

Processing audit logging

🔑 Business Key
The selected business key is:

row_id
Why row_id?
The supplied data was profiled before implementation.

Batch 1 contains unique Row IDs.

Batch 2 contains corrected versions of existing Row IDs.

Row ID therefore provides a stable record-level identifier across
the supplied batches.

order_id was not selected because one order can contain multiple
products and therefore does not uniquely identify an individual sales
record.

♻️ Incremental Processing & Corrections
The Silver current-state table is maintained using row_id as the
matching key.

Incoming Row ID
       │
       ├── New ──────────────► INSERT
       │
       └── Existing ─────────► UPDATE
For example:

Batch 1: row_id=12345, sales=100
Batch 2: row_id=12345, sales=120
The current-state Silver record becomes:

row_id=12345, sales=120
This handles later corrections without creating duplicate current-state
records.

🧪 Data Quality
Validation occurs before data is promoted to Gold.

Schema validation
Structural changes such as unexpected or missing columns cause the batch
to fail.

This prevents unexpected source changes from silently entering
reporting.

Record-level validation
The implemented assessment rules identify issues including:

Missing Row ID
Missing Order ID
Missing Customer ID
Missing Region
Missing Sales
Sales <= 0
Invalid records are stored in:

silver_sales_rejected
Each rejection retains its reason so data-quality problems can be
investigated.

The Sales <= 0 rule was selected after profiling the supplied
assessment batches. In a production system, the source contract would
determine whether negative sales are legitimate business events such
as returns.

🚨 Batch Failure Protection
A failed validation must not partially update reporting.

The processing flow is:

Incoming Batch
      │
      ▼
Schema Validation
      │
      ├── FAIL ──► Log failure
      │             │
      │             └──► Send notification
      │
      └── PASS ──► DQ + Dedup
                    │
                    ▼
                 MERGE Silver
                    │
                    ▼
                 Gold update
When Batch 3 fails schema validation:

rejected records are captured

the Silver processing log records the failure

the failure branch sends an alert

Gold transformation is not executed

the reporting layer remains on the last known good state

📊 Observed Batch Profiling
The supplied files were profiled before implementation.

Batch Physical Rows Key Findings

Batch 1 6,675 Clean baseline

Batch 2 3,384 Duplicate Row IDs and
corrected existing
records

Batch 3 included:

an additional order_channel column

missing Order IDs

missing Customer IDs

missing Regions

missing Sales

negative Sales values

duplicate Row IDs

This batch was used to demonstrate the validation-failure path.

🥇 Gold Layer
Fact
gold_sales_fact
Fact grain
One current sales record per row_id.

Dimensions
gold_dim_date
gold_dim_product
gold_dim_region
The Gold layer follows a star-schema approach for analytical reporting.

The fact contains business measures such as:

sales
quantity
discount
profit
and analytical attributes such as date, product and geography.

A deterministic geo_key represents the Region + State + City
combination for dimensional modelling. It is a modelling key, not the
security rule itself.

🔐 Data Privacy
The source contains customer-related information, including:

Customer names

Postal codes

These are treated as personal data.

The reporting Gold model does not expose customer names or postal codes
because regional sales analysis does not require identifying customer
details.

This follows a least-exposure principle: sensitive attributes are not
propagated into reporting unless required.

🛡️ Row-Level Security
Regional access is enforced at the SQL data layer.

The mapping table is:

security_user_region
Conceptually:

User
  │
  ▼
security_user_region
  │
  ▼
Permitted Region
  │
  ▼
SQL Row-Level Security
  │
  ▼
gold_sales_fact
The security policy filters sales rows according to the authenticated
user's mapped region.

Why data-layer RLS?
The assessment requires regional restrictions to be enforced at the data
layer rather than relying only on Power BI report roles.

Power BI connects to the secured SQL Analytics Endpoint, so the
reporting layer inherits the underlying data restriction.

📈 Power BI
Power BI connects to the Gold layer through the Fabric SQL Analytics
Endpoint.

Page 1 --- Sales Overview
Includes:

Total Sales

Total Profit

Profit Margin

Total Quantity

Transaction Count

Sales trend

Top products

Page 2 --- Regional Performance
Includes:

Current permitted region

Sales by region

Profit by region

Category/product breakdown

Regional performance metrics

Page 3 --- Regional Comparison
Provides regional comparison when the appropriate security mapping is
available.

Security and metric correctness are prioritized over visual
complexity.

📋 Audit & Observability
Bronze log
bronze_ingestion_log
Tracks:

run_id
batch_file_name
ingestion_start_time
ingestion_end_time
status
rows_received
rows_written
failure_reason
Silver log
silver_processing_log
Tracks:

run_id
batch_file_name
processing_start_time
processing_end_time
status
rows_received
rows_passed
rows_rejected
rows_after_deduplication
rows_written
failure_reason
These logs provide execution-level traceability and support failure
investigation.

🔁 Idempotency
The pipeline is designed so rerunning the same batch does not create
duplicate current-state records.

The key invariant is:

COUNT(*) = COUNT(DISTINCT row_id)
for the current-state sales dataset.

A repeated Batch 2 execution therefore updates/matches the same business
keys instead of creating another copy.

🚨 Failure Notification
The master pipeline contains a failure branch:

NB_Silver_Processing
       │
       ├── Success ──► NB_Gold_Transformation
       │
       └── Failure ──► Notify_Validation_Failure
The notification communicates that the incoming batch failed validation
and that Gold/reporting was not executed.

This provides operational visibility in addition to the pipeline run
history and processing logs.

⚖️ Key Design Decisions
Decision Selected Approach Rationale

Architecture Bronze → Silver → Gold Clear separation of
raw, validated and
analytical data

Processing PySpark Flexible DQ,
deduplication and Delta
MERGE

Storage Delta tables ACID and reliable
current-state
processing

Business key row_id Stable record-level
identifier in supplied
data

Duplicate handling Row ID deduplication Prevent duplicate
current-state records

Corrections Delta MERGE Later batches replace
stale records

Schema failures Stop batch Protect downstream
reporting

Bad records Quarantine Preserve rejected rows
and reasons

Sensitive fields Exclude from reporting Minimize exposure
Gold

Security SQL data-layer RLS Security is not
dependent only on Power
BI

Reporting Power BI Business-facing
analytics

⚖️ Technology Trade-offs
PySpark vs Dataflows Gen2
PySpark was selected because the assessment requires explicit
control over:

record-level validation

duplicate handling

Delta MERGE

current-state management

schema checks

repeatable processing

Dataflows Gen2 would be a reasonable choice for lower-code
transformation scenarios, but PySpark provides more direct control over
this stateful processing pattern.

DirectQuery vs Direct Lake / Import
The report uses the secured SQL Analytics Endpoint.

This design makes the SQL data-layer security boundary explicit and
demonstrable, including direct SQL access.

Direct Lake or Import could provide different performance
characteristics, but the selected serving approach aligns with the
assessment's requirement to enforce regional security at the data layer.

📈 Scaling to 100M Rows/Day
For a workload approaching 100 million rows per day, the architecture
would require additional performance engineering.

Storage
Partition large Delta tables appropriately

Control small-file generation

Keep processing incremental

Optimize file layout

Spark
Partition data for parallel execution

Optimize joins and MERGE operations

Avoid unnecessary full-table scans

Tune compute/resource sizing

Delta
Monitor file sizes and table statistics

Optimize MERGE keys

Use appropriate maintenance/optimization strategies

Serving
Keep Gold tables narrow and analytical

Consider pre-aggregations where appropriate

Monitor DirectQuery concurrency

Evaluate dedicated warehouse/serving patterns as workload grows

Likely bottlenecks would include MERGE performance, file management,
compute requirements and concurrent analytical access.

🧪 Demonstration Scenarios
1️⃣ Batch 1 --- Baseline
Copy          ✓
Bronze        ✓
Silver        ✓
Gold          ✓
Power BI      ✓
2️⃣ Batch 2 --- Incremental + Corrections
New Row IDs
   → INSERT

Existing Row IDs
   → UPDATE

Duplicate current-state records
   → None
3️⃣ Batch 3 --- Validation Failure
Copy                         ✓
Bronze                       ✓
Silver validation            ✗
Rejected records             ✓
Processing log               ✓
Failure notification         ✓
Gold transformation          Not executed
Reporting layer              Unchanged
4️⃣ Batch 2 --- Idempotent Rerun
Rerunning Batch 2 should leave the current-state business-key count
unchanged and should not create duplicate row_id values.

🔎 Example Validation Queries
Current row count and key uniqueness
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT row_id) AS distinct_row_ids
FROM gold_sales_fact;
Reporting totals
SELECT
    COUNT(*) AS row_count,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM gold_sales_fact;
Regional access
SELECT DISTINCT region
FROM gold_sales_fact;
Rejected records
SELECT TOP 20 *
FROM silver_sales_rejected;
Processing history
SELECT TOP 20 *
FROM silver_processing_log
ORDER BY processing_end_time DESC;
📸 Evidence
The repository can contain screenshots demonstrating:

Master pipeline dependencies

Successful Batch 1 run

Batch 3 validation failure

Batch 3 rejected records

Failure notification

Gold/reporting state unchanged after Batch 3

Power BI regional RLS

Direct SQL regional RLS

🚀 Reproduction
The solution was developed in a Microsoft Fabric workspace.
Authentication details and private connection configuration are
intentionally excluded from the public repository.

High-level setup:

1. Create a Microsoft Fabric workspace
2. Create a Lakehouse
3. Configure the source HTTP connection
4. Import the Bronze, Silver and Gold notebooks
5. Configure the master pipeline
6. Add batch_file_name as the pipeline parameter
7. Configure Notebook Activity Base parameters
8. Create/configure the required Delta tables
9. Configure the security mapping table
10. Apply SQL Row-Level Security
11. Connect Power BI to the secured SQL Analytics Endpoint
12. Run the demonstration batches
13. Validate success, failure and idempotency scenarios





🤖 AI Disclosure
AI-assisted development and online technical references were used during
development for:

understanding Microsoft Fabric concepts

exploring implementation approaches

debugging and explaining code

reviewing architecture and trade-offs

improving documentation





👨‍💻 Author
Thiwanka Madhusanka

BSc (Hons) Information Technology --- Data Science

Areas of interest:

Data Engineering · Data Analytics · Data Warehousing ·
Microsoft Fabric · SQL · Python · Power BI

⭐ Project Highlights
✓ Parameterized HTTP batch ingestion
✓ Bronze / Silver / Gold architecture
✓ Raw-data preservation
✓ Delta Lake processing
✓ Schema validation
✓ Data-quality validation
✓ Rejected-record quarantine
✓ Business-key deduplication
✓ Incremental MERGE processing
✓ Correction handling
✓ Idempotent reruns
✓ Processing audit logs
✓ Failure branching
✓ Failure notification
✓ Gold star schema
✓ Sensitive-data protection
✓ SQL data-layer RLS
✓ Power BI regional analytics
✓ 100M rows/day scaling considerations
End-to-end Microsoft Fabric data engineering solution designed
around reliability, data quality, security, and analytical
usability.

