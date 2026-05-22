# 🏥 Clinical-Flow-Data-Warehouse

<p align="left">
  <img src="https://img.shields.io/badge/Database-MS%20SQL%20Server-red?style=for-the-badge&logo=microsoft-sql-server&logoColor=white" alt="SQL Server" />
  <img src="https://img.shields.io/badge/Language-T--SQL-blue?style=for-the-badge&logo=databricks&logoColor=white" alt="T-SQL" />
  <img src="https://img.shields.io/badge/Pipeline-Python%203-blueviolet?style=for-the-badge&logo=python&logoColor=white" alt="Python" />
  <img src="https://img.shields.io/badge/Architecture-Star%20%2F%20Snowflake-success?style=for-the-badge" alt="Architecture" />
</p>

An enterprise-grade relational database architecture designed to track patient flow, optimize bed occupancy velocity, and resolve operational bottlenecks within a multi-specialty healthcare network. 

This repository implements an end-to-end operational data warehouse containing **10,000+ transactional records**, featuring an automated Python data pipeline, structural T-SQL cleaning transactions, high-performance analytical metrics, and automated database security objects.

---

## 🗺️ System Architecture & Schema Design

The data engine utilizes a hybrid **Star/Snowflake Schema** optimized for high-throughput transactional grouping and clinical event auditing:

```text
Clinical-Flow-Data-Warehouse/
├── data/             <-- 6 Source Datasets (3 Dimensions, 3 Core Facts)
├── pipelines/        <-- Python Data Ingestion & Synthetic Anomaly Engine
└── sql/              <-- Database Scripts (DDL, Data Cleaning, Analytics, Automations)
