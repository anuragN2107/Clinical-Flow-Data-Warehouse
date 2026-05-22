# 🏥 Clinical-Flow-Data-Warehouse & Enterprise Datamart

<p align="left">
  <img src="https://img.shields.io/badge/Database-MS%20SQL%20Server%202022-red?style=for-the-badge&logo=microsoft-sql-server&logoColor=white" alt="SQL Server" />
  <img src="https://img.shields.io/badge/Language-T--SQL%20%2F%20Advanced-blue?style=for-the-badge&logo=databricks&logoColor=white" alt="T-SQL" />
  <img src="https://img.shields.io/badge/Pipeline-Python%203.11-blueviolet?style=for-the-badge&logo=python&logoColor=white" alt="Python" />
  <img src="https://img.shields.io/badge/Data%20Modeling-Hybrid%20Star%20%2F%20Snowflake-success?style=for-the-badge" alt="Architecture" />
  <img src="https://img.shields.io/badge/Optimization-Covering%20Indexes%20%26%20Execution%20Plans-orange?style=for-the-badge" alt="Optimization" />
</p>

## 📌 Executive Business Overview
In modern healthcare systems, operational bottlenecks in **Patient Flow Management** directly impact clinical outcomes, patient safety, and hospital financial health. Staffing shortages, unoptimized bed allocations, and high re-admission penalty rates cause massive operational friction.

This repository implements a production-grade relational data warehouse in **MS SQL Server** designed to track patient movement, calculate length-of-stay velocity trends, and audit billing metrics. The database processes **10,000+ transactional records** injected with realistic operational anomalies (duplicates, casing issues, logical date paradoxes) to demonstrate robust data cleaning, high-performance analytics, and advanced database automation.

---

## 🏗️ Relational Architecture & Dimensional Modeling

The data warehouse implements a hybrid **Star/Snowflake Schema** centered around clinical encounters, ensuring third normal form (3NF) compliance for operational efficiency while remaining optimized for high-throughput business intelligence reporting.

### Logical Entity-Relationship Mapping (ASCII ERD)
```text
           [Dim_Providers]             [Dim_Departments]
                 |                             |
                 | (1:N)                       | (1:N)
                 v                             v
[Dim_Patients] ----(1:N)----> [Fact_Encounters] <----(1:1)----> [Fact_Billing_Transactions]
                                     |
                                     | (1:N)
                                     v
                           [Fact_Bed_Movements]
