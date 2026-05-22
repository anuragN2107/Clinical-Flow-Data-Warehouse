# 🏥 Clinical-Flow Data Warehouse & Enterprise Datamart
> **An End-to-End Operational Healthcare Engineering, Database Architecture & Business Intelligence Ecosystem**

<p align="left">
  <img src="https://img.shields.io/badge/Database-MS%20SQL%20Server%202022-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white" alt="SQL Server" />
  <img src="https://img.shields.io/badge/Language-T--SQL%20%2F%20Advanced-007ACC?style=for-the-badge&logo=databricks&logoColor=white" alt="T-SQL" />
  <img src="https://img.shields.io/badge/Pipeline-Python%203.11-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python" />
  <img src="https://img.shields.io/badge/Data%20Modeling-Hybrid%20Star%20%2F%20Snowflake-28A745?style=for-the-badge" alt="Architecture" />
  <img src="https://img.shields.io/badge/Optimization-Covering%20Indexes-FF8C00?style=for-the-badge" alt="Optimization" />
  <img src="https://img.shields.io/badge/BI%20Analytics-Power%20BI%20Enterprise-F2C811?style=for-the-badge&logo=powerbi&logoColor=black" alt="Power BI" />
</p>

---

## 📌 Executive Business Overview
In modern healthcare systems, operational bottlenecks in **Patient Flow Management** directly impact clinical outcomes, patient safety, and hospital financial health. Staffing shortages, unoptimized bed allocations, and high re-admission penalty rates cause massive operational friction.

This repository implements a production-grade relational data warehouse in **MS SQL Server** designed to track patient movement, calculate length-of-stay velocity trends, and audit billing metrics. The database processes **10,000+ transactional records** injected with realistic operational anomalies (duplicates, casing issues, logical date paradoxes) to demonstrate robust data cleaning, high-performance analytics, and advanced database automation. 

The ecosystem culminates in a production-ready, interactive **Power BI Enterprise Application** that maps raw warehouse telemetry into executive analytical interfaces using advanced **DAX modeling** and targeted data visualization.

---

## 🛠️ Enterprise Tool & Technology Stack

The complete lifecycle of this project was engineered using industry-standard enterprise tools, categorized below by their operational layer:

```text
  [ LAYER ]                [ TOOL UTILITY ]                      [ KEY FUNCTION ]
  
  Ingestion    ➔   🐍 Python 3.11 (Pandas & NumPy)     ➔   Data Generation & Defect Injection
  Storage      ➔   🛢️ MS SQL Server 2022                ➔   Relational Warehousing & T-SQL Core
  Modeling     ➔   📐 Star / Snowflake Hybrid Schema    ➔   Unidirectional Fact-Dimension Mapping
  Tuning       ➔   ⚡ Non-Clustered Covering Indexes    ➔   Query Acceleration & Scan Elimination
  Analytics    ➔   📊 Power BI Desktop Enterprise      ➔   Advanced DAX Engine & UI Report Layer
