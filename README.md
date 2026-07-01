# Supply Chain Data Engineering & Intelligence Solution

End-to-end supply chain analytics Solution spanning batch ETL, real-time streaming, dual-cloud data warehousing (Snowflake & Microsoft Fabric), a conformed star-schema data model, an interactive Power BI layer, Agentic AI, and an AI-powered conversational analyst delivered through a cross-platform Flutter application.

---

## Table of Contents

- [Overview](#overview)
- [Solution Pillars](#solution-pillars)
- [High-Level Architecture](#high-level-architecture)
- [Technology Stack](#technology-stack)
- [Data Model — Star Schema](#data-model--star-schema)
- [Pipeline 1 — Batch ETL (AWS / Snowflake)](#pipeline-1--batch-etl-aws--snowflake)
- [Pipeline 2 — Real-Time Streaming (Kafka)](#pipeline-2--real-time-streaming-kafka)
- [Microsoft Fabric workspace](#Microsoft-Fabric-workspace)
- [Pipeline 3 — Batch ETL (Microsoft Fabric)](#pipeline-3--batch-etl-microsoft-fabric)
- [Pipeline 4 — Real-Time Streaming (Microsoft Fabric)](#pipeline-4--real-time-streaming-microsoft-fabric)
- [Pipeline 5 — Cross-Platform Sync (Fabric → Snowflake CDC)](#pipeline-5--cross-platform-sync-fabric--snowflake-cdc)
- [Power BI Dashboard](#power-bi-dashboard)
- [AI Analyst & Flutter Application](#ai-analyst--flutter-application)
- [Directory Structure](#directory-structure)
- [How to Run — End to End](#how-to-run--end-to-end)
- [Security & Credential Management](#security--credential-management)
- [Glossary](#glossary)
- [Dependencies](#dependencies)

---

## Overview

Modern supply chains generate enormous volumes of transactional data across order management, inventory, shipping, and customer operations. Without a unified analytical solution, decision-makers are left working with fragmented spreadsheets, delayed reports, and manual processes — leading to poor visibility, missed delivery commitments, and unrealized profitability.

This project builds a fully automated, dual-cloud data platform that ingests, transforms, models, visualizes, and exposes supply-chain data through both traditional BI and an Agentic AI interface — implemented twice, in parallel, on two different stacks (AWS + Snowflake + DBT + Airflow, and Microsoft Fabric), and finally unified through a cross-platform Change Data Capture sync between them.

## Solution Pillars

| Pillar | Description |
|---|---|
| **Batch ETL** (Local & Fabric) | pipelines that ingests raw CSV data through AWS S3 → Snowflake, or through a Microsoft Fabric Lakehouse → Warehouse, then transforms it through dbt into a conformed star-schema data mart. |
| **Real-Time Streaming** | Apache Kafka (Local path) and Azure Service Bus + Fabric Eventstream (Fabric path) capture new orders from a live API and feed them into the same raw table within seconds. |
| **Interactive BI Dashboard** | A Power BI semantic model surfaces supply-chain KPIs — OTIF %, late-delivery risk, revenue, and inventory movements — through the shared star schema built by dbt. |
| **AI Analyst & Mobile App** | An n8n AI agent translates questions into SQL, queries Snowflake, and returns charts and text instantly; A Flutter app lets business users submit real-time orders and ask supply-chain questions in natural language. |

## High-Level Architecture

The Solution is organized into parallel ingestion pipelines (batch and streaming, on two cloud platforms) that share a single dbt transformation project and converge on a unified Power BI semantic model. A final cross-platform CDC sync keeps the Fabric Warehouse and Snowflake aligned.

<img src="Screen%20shots/Local/Solution%20Architecture.png" alt="System Architecture" width="900">

| Stage | Layer | Description |
|---|---|---|
| 1 | Batch Ingestion (Local) | Local CSV → AWS S3 |
| 2 | Batch Ingestion (Local) | AWS S3 → Snowflake raw table |
| 3 | Transformation | Snowflake raw → dbt staging → dbt DWH (dimensions & facts) |
| 4 | Streaming (Local) | Live API → Kafka → S3 → Snowflake raw table |
| 5 | Batch Ingestion (Fabric) | CSV → Lakehouse → Warehouse → Fabric dbt job (gold layer) |
| 6 | Streaming (Fabric) | Live API → Notebook → Service Bus → Eventstream → Lakehouse → pipeline → Warehouse → dbt |
| 7 | Cross-Platform Sync | Fabric Warehouse → CDC → Snowflake Warehouse |
| 8 | Consumption | Warehouse / Snowflake star schema → Power BI semantic model |

## Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Batch Ingestion | boto3, AWS S3 | CSV to cloud storage, Snowflake `COPY INTO` |
| Message Broker | Apache Kafka (KRaft mode) | Real-time order streaming (Local path) |
| Event Streaming (Fabric) | Azure Service Bus + Fabric Eventstream | Real-time streaming on Microsoft Fabric |
| Data Warehouse (Local path) | Snowflake | Cloud analytical store |
| Data Platform (Fabric) | Microsoft Fabric (Lakehouse + Warehouse) | Fabric-native re-platforming |
| Transformation | dbt Core | SQL-based ELT models, shared across platforms |
| Orchestration (Local path) | Apache Airflow (Astronomer) | DAG scheduling & monitoring |
| Orchestration (Fabric) | Fabric Data Factory Pipelines | Fabric-native pipeline orchestration & CDC sync |
| BI & Reporting | Microsoft Power BI | Semantic model + interactive dashboards |
| Backend API | FastAPI (Python) | REST endpoints, Kafka publisher |
| Persistence | Supabase (PostgreSQL) | Transactional order storage |
| AI Workflow | n8n + LLM (Gemini) | Text-to-SQL, chart generation |
| Mobile / Web App | Flutter & Dart | Cross-platform front-end |
| Charts | fl_chart (Flutter) | Dynamic bar/line/pie charts |

---

## Data Model — Star Schema

A classic star-schema design is shared across all ingestion platforms (Snowflake and Fabric Warehouse). Three fact tables form the measurable core; fourteen dimension tables provide contextual attributes.

<img src="Screen%20shots/Local/Data%20model.png" alt="Data Model" width="900">

### Fact Tables

| Fact Table | Grain & Purpose | Key Columns |
|---|---|---|
| `fact_order_item` | One row per order item. Financial measures: sales, discounts, quantity, profit, revenue. | `order_item_key` (PK), `order_key` (FK), `product_key` (FK), `sales`, `order_item_quantity`, `order_item_discount`, `order_profit_per_order`, `benefit_per_order` |
| `fact_shipping_performance` | One row per order. Shipping timing measures: actual vs scheduled days, delay delta, late-delivery flag. | `shipping_performance_key` (PK), `order_key` (FK, unique), `days_for_shipping_real`, `days_for_shipment_scheduled`, `delay_between_real_scheduled`, `late_delivery_risk` |
| `fact_inventory_movement` | One row per movement event. Stock-on-hand changes across warehouses over time. | `inventory_movement_key` (PK), `warehouse_key` (FK), `movement_type_key` (FK), `date_key` (FK), `quantity_moved`, `unit_cost_at_movement`, `stock_on_hand_after_movement` |

### Dimension Tables

| Dimension | Description |
|---|---|
| `dim_customer` | Customer master; surrogate key hashed from name + address. |
| `dim_customer_geography` | Customer location; deduplicated on street/state/zip/country/city. |
| `dim_order` | Order-level header; bridges `fact_order_item` to order-level context. |
| `dim_order_geography` | Order location; mojibake-repaired city/state/country fields. |
| `dim_product` | Product attributes; surrogate key hashed from name/description/image/status. |
| `dim_category` | Product category, deduplicated on category name. |
| `dim_department` | Department, deduplicated on department name. |
| `dim_shipping_mode` | Shipping method (Standard Class, First Class, etc.). |
| `dim_delivery_status` | Delivery outcome (on time, late, advance). |
| `dim_order_status` | Order processing status. |
| `dim_payment` | Payment / order type (DEBIT, TRANSFER, CASH). |
| `dim_warehouse` | Warehouse master; deduplicated on name/city/country. |
| `dim_movement_type` | Inventory movement type and direction (in/out). |
| `dim_date` | Calendar dimension; `date_key` = integer `YYYYMMDD`, dynamically ranged from staging data ±5 years. |

### Surrogate Key Strategy

All surrogate keys (except `dim_date`) are generated using `dbt_utils.generate_surrogate_key()`, producing a deterministic MD5 hash from natural business keys. This ensures:

- **Idempotent builds** — re-running dbt produces identical keys.
- **No dependency on auto-increment sequences** (unavailable in Snowflake views).
- **Stable FK joins** even when source IDs are absent (e.g. customer, product).

`dim_date` uses an integer `YYYYMMDD` key by deliberate design — naturally sortable, human-readable, and enables efficient range-filter pushdown in both Snowflake and Fabric Warehouse.

### Data Quality & Cleansing Notes

| Issue | Resolution Applied |
|---|---|
| Mojibake character repair | `order_city`, `order_state`, `order_country` repaired with `REPLACE()` for known corrupted byte sequences; `order_country` additionally maps ~40 corrupted Spanish country names to clean values. |
| Country normalization | `'EE. UU.'` → `'United States'` in `customer_country`. |
| Numeric state codes | Rows where `customer_state` held a numeric value are set to `NULL`. |
| Null `product_description` | 100% null in source; replaced with `'No description available'`. |
| Null `order_zipcode` | ~155,679 rows have no zip code; column is nullable. |
| Broken `product_image` URLs | Retained as-is for schema completeness; known to be non-functional. |
| Masked PII fields | `customer_email` and `customer_password` are placeholder values from the source dataset. |

---

## Pipeline 1 — Batch ETL (Local Path)

Ingests the historical supply chain dataset from a local CSV file into Snowflake, using AWS S3 as a staging/landing area, then transforms the raw data through dbt into the conformed star schema. Orchestrated by Apache Airflow (Astronomer).

### Stage 1 — Local File to AWS S3 (`To_S3.py`)

- Loads AWS credentials/config from environment variables via `.env`.
- Creates an S3 client using `boto3`.
- Creates the target bucket.
- Uploads the local CSV (`DataCoSupplyChainDatasetResult.csv`) to the configured bucket/key.

### Stage 2 — AWS S3 to Snowflake Raw Table (`from_S3_to_Snowflake.py`)

**Manual prerequisite** (run once in the Snowflake query editor):
- Create the virtual warehouse `SupplyChain_wh`, stage, and CSV file format.
- Create the `SupplyChain_db` database and `raw` schema.

**Automated script steps:**
- Connects to Snowflake via `snowflake-connector-python` using environment-variable credentials.
- Creates (or replaces) the `raw_supplyChain` table with a wide schema covering order, customer, product, category, department, shipping, and warehouse/inventory movement fields.
- Creates a CSV file format object (`my_csv_format`) with header skipping, null handling, and double-quote enclosure.
- Creates an external stage (`my_s3_stage`) pointing at the S3 bucket/prefix, bound to the CSV file format.
- Runs `COPY INTO` command.
- Prints the load result and final row count for verification.

### Stage 3 — dbt Transformation (Staging → DWH → Star Schema)

The dbt project is the transformation backbone of the entire solution — it runs once, and its output (the conformed star schema) is shared by **every** ingestion path in this project (AWS batch, AWS streaming, Fabric batch, Fabric streaming).

#### Staging Layer — `stg_supply_chain`

Reads from `raw_data.raw_supplyChain` and applies:
- Materialized as **incremental** with a merge strategy on `order_item_id` — re-runs only process new/changed rows.
- Type casting: dates → `DATE`, financial columns → `DECIMAL(18,2)`, discount rates → `DECIMAL(18,4)`, with `COALESCE` to 0 on failed casts.
- String trimming on all `VARCHAR` columns.
- Country/state standardization and mojibake repair.
- `product_description` (100% null) replaced with placeholder text.

<img src="Screen%20shots/Local/DBT%20Staging%20Initial%20Load.png" alt="DBT Staging Initial Load" width="900">

#### DWH Layer — Dimensions & Facts

17 models total (14 dimensions + 3 facts), materialized as **tables** for query performance. All follow the same pattern: deduplicate on natural keys → generate a hashed surrogate key via `dbt_utils.generate_surrogate_key()` → incremental merge on the surrogate key.

<img src="Screen%20shots/Local/DBT%20DWH%20Initial%20Load.png" alt="DBT DWH Initial Load" width="900">

#### dbt Lineage

`raw_data.raw_supplyChain` → `stg_supply_chain` → fans out to all 14 dimensions in parallel → `dim_order` (built last, depends on most other dimensions for FK resolution) → 3 fact tables (built last, after all dimensions complete).

<img src="Screen%20shots/Local/dbt%20Lineage.png" alt="dbt Lineage" width="900">

### Airflow DAG Orchestration

DAG: `dags/my_dag.py` — `start_date=2026-06-01`, `schedule=None`, `catchup=False`.

| Task | Description |
|---|---|
| `check_row_count` | `PythonOperator`. Connects via `SnowflakeHook` (connection ID: `snowflake_conn`) and runs `COUNT(*)` on `RAW_SUPPLYCHAIN`. Fails if the table is empty, preventing downstream transforms from running on stale data. |
| `dbt_staging_run` | `BashOperator`: `dbt run --select path:models/staging --profiles-dir .` |
| `dbt_staging_test` | `BashOperator`: `dbt test --select path:models/staging --profiles-dir .` — validates `not_null` and `accepted_values` constraints. |
| `dbt_marts_run` | `BashOperator`: `dbt run --select path:models/DWH --profiles-dir .` — builds all 14 dimensions and 3 facts. |
| `dbt_marts_test` | `BashOperator`: `dbt test --select path:models/DWH --profiles-dir .` — validates `unique`, `not_null`, and referential integrity constraints. |

<img src="Screen%20shots/Local/Airflow%20Dag.png" alt="Airflow Dag" width="900">

---

## Pipeline 2 — Real-Time Streaming (Kafka)

Parallel to the batch path, captures new orders as they arrive using Apache Kafka as the message backbone. Writes to the same `raw_supplyChain` Snowflake table, ensuring both batch historical data and near-real-time orders are served by the same dbt project.

### Infrastructure — Kafka (`docker-compose.yaml`)

- Single-node Kafka broker using the Confluent `cp-kafka` image (v7.8.3), running in **KRaft mode** (no Zookeeper required).
- Exposed on `localhost:9092`, persistent storage via a named Docker volume (`kafka_kraft`).

### Producer (`producer.py`)

- Polls the FastAPI endpoint `/api/v1/orders/pending` every 10 seconds.
- On startup, fetches the current latest order to initialize a baseline — only genuinely new orders are published, never historical backlog.
- Tracks the last-seen `Order_Item_Id` in memory; publishes only on a new ID, preventing duplicates.
- Publishes each new order as a JSON-encoded message to the Kafka topic `orders` via `confluent_kafka.Producer`.
- Uses a delivery-report callback to confirm successful delivery (or log failures).
- Handles graceful shutdown on keyboard interrupt, flushing pending messages before closing.

<img src="Screen%20shots/Local/Producer.png" alt="Producer" width="900">

### Consumer (`consumer.py`)

- Subscribes to the `orders` topic with consumer group `order-tracker`, `auto.offset.reset='latest'`.
- For each message: parses the JSON payload and maps it into the full raw table's column list (absent fields filled with `None`).
- Writes the single order as a one-row CSV (`order_{Order_Item_Id}.csv`) via pandas.
- Uploads the CSV to S3 (bucket: `raw-supplychain-data`, key prefix: `SupplyChain/`) via `s3_utils.py`.
- Immediately loads the uploaded file into `raw_supplyChain` via `COPY INTO` (`snowflake_loader.py`) — same external stage as the batch path.
- Deletes the local temporary CSV once upload and load complete.

<img src="Screen%20shots/Local/Consumer.png" alt="Consumer" width="900">

**Role in pipeline:** Live API → Kafka → per-order CSV → S3 → Snowflake raw table. Near-real-time order ingestion alongside the bulk historical batch load. Both paths converge on `raw_supplyChain`, feeding the shared dbt project.

---
## Microsoft Fabric workspace 

<img src="Microsoft%20Fabric/SupplyChain%20Workspace.png" alt="SupplyChain Workspace" width="900">

---
## Pipeline 3 — Batch ETL (Microsoft Fabric)

A Fabric Data Factory pipeline re-implements the batch path natively on Microsoft Fabric, replacing S3 + Snowflake with Lakehouse + Warehouse, following a standard **medallion architecture** (Bronze → Silver → Gold), while reusing the exact same dbt project for the gold layer.

<img src="Screen%20shots/Fabric/Batch%20Fabric.png" alt="Batch Fabric" width="900">

| Step | Activity | Description |
|---|---|---|
| Bronze Layer | `Copy data: bronze_Layer` | Reads raw CSV from the Lakehouse file store and writes it as a managed Lakehouse table — raw, untransformed landing layer. |
| Silver Layer | `Copy data: silver_Layer` | Copies the Lakehouse bronze table into the Fabric Warehouse under the `bronze` schema — analogous to the `raw` schema on the Snowflake side. |
| Gold Layer | Fabric dbt job: `Gold_Layer` | Runs the same dbt project (staging → dims/facts) as a Fabric dbt job targeting the Fabric Warehouse. |

Running the Gold Layer dbt job against the Fabric Warehouse populates the same conformed star schema — all 14 dimensions and 3 facts — this time living in the Fabric Warehouse rather than Snowflake.

---

## Pipeline 4 — Real-Time Streaming (Microsoft Fabric)

A Fabric-native equivalent of the Kafka streaming path, using Azure Service Bus and Fabric Eventstream in place of Kafka, and an event-driven Fabric pipeline in place of the Python consumer.


<img src="Screen%20shots/Fabric/Streaming%20Fabric.png" alt="Streaming Fabric" width="900">
<img src="Screen%20shots/Fabric/EventStream.png" alt="EventStream" width="900">

| Component | Role |
|---|---|
| Fabric Notebook (`SC_Notebook`) | Polls the same API, tracks `Order_Item_Id`, and publishes new orders as JSON to an Azure Service Bus queue using the `azure.servicebus` SDK. |
| Fabric Eventstream (`Supply_Chain_ES`) | Reads from the Service Bus queue and writes events directly into a Lakehouse table — ingestion and landing in a single managed step. |
| Event-Triggered Pipeline | Fires automatically when a new record arrives in the Lakehouse table (via a OneLake file-event trigger). Copies the record to the Warehouse raw layer, then runs the same dbt gold-layer job. |

---

## Pipeline 5 — Cross-pipeline Sync (Fabric → Snowflake CDC)

A final integration step consolidates the two parallel platforms (Fabric Warehouse and Snowflake) into a unified data source. This pipeline uses **Change Data Capture (CDC)** to identify and propagate newly inserted and updated records from the Fabric Warehouse to the Snowflake Warehouse, ensuring data consistency and synchronization across both platforms.

<img src="Screen%20shots/Fabric/CDC%20Pipleine.png" alt="CDC Pipeline" width="900">

The pipeline runs a `Copy data` activity for each conformed dimension and fact table — `CDC_Dim_category`, `CDC_Dim_customer`, `CDC_Dim_customer_geography`, `CDC_Dim_Date`, `CDC_Dim_delivery_status`, `CDC_Dim_Department`, `CDC_Dim_movement_type`, `CDC_Dim_order`, `CDC_Dim_Order_Geography`, `CDC_Dim_Order_Status`, `CDC_Dim_Payment`, `CDC_Dim_Product`, `CDC_Dim_shipping_mode`, `CDC_Dim_warehouse`, `CDC_fact_inventory_movement`, `CDC_Fact_order_item`, `CDC_Fact_shipping_performance` — detecting and propagating only inserted/updated rows from the Fabric Warehouse into their Snowflake counterparts.

**Role in pipeline:** Fabric Warehouse (bronze/gold star schema) → CDC detection → Snowflake Warehouse, keeping both analytical platforms in sync without re-running the full dbt project on either side.

---

## Power BI Dashboard

The Power BI dashboard connects directly to the Snowflake analytical layer (or Fabric Warehouse) and provides interactive visibility into four supply-chain domains. The model uses a mixed storage mode (Import + DirectQuery). At the time of writing, the semantic model and its relationships are built; report visuals are a planned next step.

<img src="Power%20BI/power%20BI%20page1.png" alt="power BI page1" width="900">
---
<img src="Power%20BI/power%20BI%20page2.png" alt="power BI page2" width="900">
---
<img src="Power%20BI/power%20BI%20page3.png" alt="power BI page3" width="900">
---
<img src="Power%20BI/power%20BI%20page4.png" alt="power BI page4" width="900">

### Semantic Model Relationships

- `dim_order` is the central order-grain dimension, linked to `dim_customer`, `dim_order_geography`, `dim_order_status`, `dim_payment`, `dim_date` (order date), `dim_shipping_mode`, and `dim_delivery_status`.
- `fact_order_item` links to `dim_order` and `dim_product` (item-grain financial measures).
- `fact_shipping_performance` links to `dim_order` (shipping/delay/late-risk metrics at order grain).
- `fact_inventory_movement` links to `dim_product`, `dim_warehouse`, `dim_date` (movement date), and `dim_movement_type`.
- `dim_product` links out to `dim_category` and `dim_department`.
- `dim_customer` links out to `dim_customer_geography`.

<img src="Power%20BI/Semantic%20model.png" alt="Semantic model" width="900">

### Report Pages

| Page | Content & KPIs |
|---|---|
| 1 — Overview | High-level executive summary. KPI cards for Total Orders, Revenue, OTIF %, OTD %, Cancelled Orders %. Trend line and segment breakdown. |
| 2 — Shipping | Shipping performance deep-dive. Late delivery risk, shipping mode analysis, scheduled vs actual days, regional heat map. |
| 3 — Inventory | Warehouse stock levels, movement type breakdown (in/out), inventory turnover trend, warehouse capacity utilization. |
| 4 — Profitability | Revenue, discount impact, AOV, profit margin, and revenue per customer — sliced by product category, segment, market, and time period. |

### DAX Measures

| Measure | Category | Logic |
|---|---|---|
| Total Orders | Volume | `COUNTROWS(fact_order_item)` |
| Revenue | Finance | `SUMX(fact_order_item, [sales])` |
| OTIF % | Performance | Orders delivered On Time In Full ÷ Total Orders |
| OTD % | Performance | Orders delivered On Time ÷ Total Orders |
| Cancelled Orders % | Operations | Cancelled orders ÷ Total Orders |
| Revenue per Order | Finance | `DIVIDE([Revenue], [Total Orders])` |
| AOV | Finance | Average Order Value — Revenue ÷ distinct order count |
| Avg Profit per Order | Finance | `AVERAGEX(VALUES(fact_order_item[order_key]), CALCULATE(SUM(order_profit_per_order)))` |
| Revenue per Customer | Finance | `DIVIDE([Revenue], DISTINCTCOUNT(dim_customer[customer_key]))` |

---

## AI Analyst & Flutter Application

A cross-platform enterprise dashboard running on mobile, tablet, and desktop (web), built with Flutter. Provides two core capabilities: an Order Entry module for submitting real-time supply-chain transactions, and an AI Analyst chatbot for natural-language querying of the Snowflake data warehouse.

<img src="AI%20Agent/app.png" alt="app" width="900">

### Responsive Design System

| Breakpoint | Layout Behavior |
|---|---|
| Mobile (< 600px) | Single-column layout, bottom `NavigationBar`, slide-out drawer for chat history. |
| Desktop (≥ 960px) | Two-column multi-card grid for the order form, persistent sidebar with profile cards, side-by-side chat layout. |

**Color system:** Primary `#2563EB`, Secondary `#0D9488`, Sidebar `#0F172A`. **Typography:** Inter (Google Fonts). Micro-animations on the login panel, gradient headers, shadow cards.

### Module 1 — Order Entry

A validated multi-field form for submitting supply-chain order transactions. On submission, the payload is sent to FastAPI → persisted in Supabase → published to Kafka. Renders as a two-column card grid on desktop.

### Module 2 — AI Analyst Chatbot

Users ask supply-chain questions in plain English. The app maintains multiple independent chat sessions, each with isolated LLM memory via a unique `session_id` passed to n8n.

<img src="AI%20Agent/chatbot.png" alt="chatbot" width="900">

### n8n AI Agent Workflow

The n8n workflow receives the user's question via webhook, routes it through an AI Agent node (Gemini LLM), executes the generated SQL on Snowflake, and returns a structured JSON response with `bot_message`, `chart_type`, and `chart_data`.

<img src="AI%20Agent/n8n%20workflow.png" alt="n8n workflow" width="900">

| `chart_type` | Rendered Output |
|---|---|
| `bar` | Horizontal or vertical bar chart for category comparisons (e.g. revenue by segment). |
| `line` | Time-series line chart for trend analysis (e.g. monthly orders). |
| `pie` | Proportional pie chart for share analysis (e.g. shipping mode distribution). |
| *(none)* | Graceful text-only fallback if `chart_type` is absent or `chart_data` is empty. |

### Error Handling Architecture

- **Network resilience** — distinguishes connection timeout, receive timeout, and `SocketException` (offline).
- **FastAPI 422 parsing** — extracts array-level validation errors as field-specific bullet messages.
- **AI quota limiting (429)** — intercepts Gemini rate-limit responses from n8n with a friendly retry alert.
- **Critical failures** — `showErrorDialog()`: scrollable modal with full error detail.
- **Mild notifications** — `showErrorSnackbar()` / `showSuccessSnackbar()` floating banners.

---

## Directory Structure

```
NTI-Graduation-Project-SupplyChain/
├── dags/                                   # Airflow DAG definitions
│   └── my_dag.py                           # Main pipeline DAG
├── include/scripts/                        # Custom Python helpers
│   └── check_raw_SupplyChain.py            # Raw data health check
├── .astro/                                 # Astronomer CLI project config
│   ├── config.yaml
│   ├── dag_integrity_exceptions.txt
│   └── test_dag_integrity_default.py
├── tests/dags/
│   └── test_dag_example.py
├── dbt/SupplyChainDBT/                     # dbt project root
│   ├── models/staging/                     # stg_supply_chain.sql + schema_stg_test.yml
│   ├── models/DWH/                         # 14 dims + 3 facts + schema_marts_test.yml
│   ├── models/sources.yml
│   ├── macros/generate_schema_name.sql
│   ├── dbt_project.yml
│   ├── packages.yml
│   ├── package-lock.yml
│   └── .user.yml                           # (no profiles.yml committed)
├── Source_to_snowflake_Scripts/            # Raw ingestion scripts
│   ├── 1.To_S3.py                          # Upload CSV to S3
│   └── 2.from_S3_to_Snowflake.py           # COPY INTO Snowflake
├── Kafka Streaming/                        # ← these live in a subfolder, not repo root
│   ├── producer.py
│   ├── consumer.py
│   ├── s3_utils.py
│   ├── snowflake_loader.py
│   └── docker-compose.yaml
├── Data/
│   └── Link of kagle dataset.txt           # link only — raw CSV is not committed
├── Microsoft Fabric/
│   └── Screen shots           # screen shot of the project
├── Power BI/                              
│   ├── Supply Chain New.pbix
│   ├── Semantic model.png
│   └── power BI page1–4.png
├── AI Agent/                              
│   ├── supplyApp.zip                       # Flutter app, zipped
│   ├── n8n workflow.png
│   ├── chatbot.png
│   └── app.png
├── Documetnation and presentaion/          
│   ├── Supply_Chain_Intelligence_Platform.pptx
│   └── Supply_Chain_Platform_Documentation_v2.docx
├── Screen shots/
│   ├── Local/   (8 architecture/DAG/dbt screenshots)
│   └── Fabric/  (4 screenshots)
├── Dockerfile
├── airflow_settings.yaml
├── packages.txt
└── requirements.txt
```

> Update this tree to match the actual repository layout before publishing.

---

## How to Run — End to End

| Step | Action |
|---|---|
| 1 | Configure the Airflow Snowflake connection (ID: `snowflake_conn`) via the Airflow UI or environment variable. |
| 2 | Set AWS and Snowflake credentials in a `.env` file. Run `python Source_to_snowflake_Scripts/1.To_S3.py` to upload the source CSV to S3. |
| 3 | Run `python Source_to_snowflake_Scripts/2.from_S3_to_Snowflake.py` to create the raw table and `COPY INTO` Snowflake. |
| 4 | Trigger the Airflow DAG from the UI or Astronomer CLI: `astro dev run dags trigger my_dag` |
| 5 | Monitor the DAG in the Airflow UI. On success, all tasks show green. |
| 6 *(streaming)* | Start Kafka: `docker compose up -d`. Run `producer.py`, then `consumer.py`. New orders from the API flow automatically into Snowflake within seconds. |
| 7 *(validate)* | Run dbt tests manually if needed: `dbt test --select path:models/staging --profiles-dir .` and `dbt test --select path:models/marts --profiles-dir .` |
| 8 *(Fabric batch)* | In Microsoft Fabric, run the Bronze → Silver → Gold pipeline to populate the Fabric Warehouse star schema. |
| 9 *(Fabric streaming)* | Schedule/run `SC_Notebook`, publish to Service Bus, confirm `Supply_Chain_ES` Eventstream is active, and publish the event-triggered pipeline. |
| 10 *(cross-platform sync)* | Run the CDC pipeline to propagate new/updated Fabric Warehouse records into Snowflake. |
| 11 *(BI)* | Open the Power BI semantic model and connect to either the Snowflake or Fabric Warehouse star schema. |

---

> ⚠️ Before pushing this repository to GitHub, ensure `.env`, `profiles.yml`, and any notebook cells containing connection strings are excluded via `.gitignore` and that all exposed credentials listed above have been rotated.

---



<p align="center"><em>Supply Chain Data Engineering &amp; Intelligence Solution — NTI Training Project</em></p>
