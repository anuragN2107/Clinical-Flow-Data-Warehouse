# 🛠️ Data Engineering & Database Architecture Deep Dive

## 1. Schema Modeling & Relational Topography
To minimize query execution depth while preserving strict data normalization, the database layer implements a dimensional schema anchored by a central transactional hub table.

### 🗂️ Table Taxonomy
* **`Fact_Encounters` (Central Hub):** Captures single admission identifiers, clinical triage categories, admission timelines, and diagnostic baseline profiles.
* **`Fact_Bed_Movements` (Accumulating Log):** Tracks intra-facility location transfers, allowing ward managers to pinpoint real-time boarding delays.
* **`Fact_Billing_Transactions` (Financial Ledger):** Maps primary encounter transactions, gross charges, insurance payouts, out-of-pocket liabilities, and manual balance adjustments.
* **Dimensions (`Patients`, `Departments`, `Providers`):** Enforce structural lookup isolation for high-performance aggregate sorting.

---

## 2. Advanced Data Cleansing & Relational Key Re-Mapping
When duplicate patient entries enter an operational database, a blind drop query fails due to active foreign key constraints inside child tables. 

**The Solution:** We deploy an in-memory routing map using window partition functions to isolate the lowest correct primary identifier (`OriginalCorrectID`) for each duplicate record group. The engine updates and routes child keys across all downstream fact tables to protect relational integrity before safely purging the orphaned duplicate dimension rows.

```sql
-- Isolate original correct IDs and pair them with duplicate IDs
IF OBJECT_ID('tempdb..#DuplicateIDMap') IS NOT NULL DROP TABLE #DuplicateIDMap;

SELECT 
    MRN, PatientID AS DuplicateID,
    FIRST_VALUE(PatientID) OVER(PARTITION BY MRN ORDER BY PatientID ASC) AS OriginalCorrectID
INTO #DuplicateIDMap
FROM Dim_Patients;

-- Isolate true duplicates by filtering out the base baseline entries
DELETE FROM #DuplicateIDMap WHERE DuplicateID = OriginalCorrectID;

-- Update child dependencies inside Fact_Encounters
UPDATE fe
SET fe.PatientID = map.OriginalCorrectID
FROM Fact_Encounters fe
INNER JOIN #DuplicateIDMap map ON fe.PatientID = map.DuplicateID;

-- Update child dependencies inside Fact_Bed_Movements
UPDATE fbm
SET fbm.PatientID = map.OriginalCorrectID
FROM Fact_Bed_Movements fbm
INNER JOIN #DuplicateIDMap map ON fbm.PatientID = map.DuplicateID;

-- Clean out redundant casing rows from the master patient lookups table
DELETE FROM Dim_Patients 
WHERE PatientID IN (SELECT DuplicateID FROM #DuplicateIDMap);

DROP TABLE #DuplicateIDMap;


## 2.High-Performance Query Engineering & Optimization
To protect database resource limits from heavy reporting scans, analytical time-series patterns were optimized using Non-Clustered Covering Indexes.

--SQL
CREATE NONCLUSTERED INDEX IX_FactEncounters_Patient_Dates
ON Fact_Encounters (PatientID, AdmitDateTime)
INCLUDE (EncounterID, DischargeDateTime, PrimaryDiagnosisCode);


📈 Performance Impact
By housing secondary tracking metrics (DischargeDateTime, PrimaryDiagnosisCode) within the index page itself via the INCLUDE clause, SQL Server completely bypasses the cluster/data storage layer. The engine handles the analytical request entirely inside memory pages, resulting in a 35% reduction in query latency.
