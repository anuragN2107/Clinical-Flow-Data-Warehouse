USE HealthcareFlowDB;
GO
-- =======================================================
-- Step 1: The Data Cleaning & Profiling Pipeline
-- =======================================================
-- STEP 1.a: CREATE A ROUTING MAP FOR RE-MAPPING
-- =======================================================
-- This identifies the original correct ID (the lowest ID for an MRN) and pairs it with the duplicate IDs that need to be removed.
IF OBJECT_ID('tempdb..#DuplicateIDMap') IS NOT NULL DROP TABLE #DuplicateIDMap;

SELECT 
    MRN,
    PatientID AS DuplicateID,
    FIRST_VALUE(PatientID) OVER (PARTITION BY MRN ORDER BY PatientID ASC) AS OriginalCorrectID
INTO #DuplicateIDMap
FROM Dim_Patients;

-- Filter out the rows where the original matches the duplicate (these are fine)
DELETE FROM #DuplicateIDMap WHERE DuplicateID = OriginalCorrectID;

-- =======================================================
-- STEP 1.b: RE-MAP ALL THE FACT TABLES (Safely update child rows)
-- =======================================================
PRINT 'Re-mapping foreign keys in fact tables...';

-- Update main encounter records pointing to duplicate patients
UPDATE fe
SET fe.PatientID = map.OriginalCorrectID
FROM Fact_Encounters fe
JOIN #DuplicateIDMap map ON fe.PatientID = map.DuplicateID;

-- Update bed tracking records pointing to duplicate patients
UPDATE fbm
SET fbm.PatientID = map.OriginalCorrectID
FROM Fact_Bed_Movements fbm
JOIN #DuplicateIDMap map ON fbm.PatientID = map.DuplicateID;

-- Update billing transactions pointing to duplicate patients
UPDATE fbt
SET fbt.PatientID = map.OriginalCorrectID
FROM Fact_Billing_Transactions fbt
JOIN #DuplicateIDMap map ON fbt.PatientID = map.DuplicateID;

-- =======================================================
-- STEP 1.c: PURGE DUPLICATES Safely
-- =======================================================
PRINT 'Deleting orphan duplicate patient rows...';

DELETE FROM Dim_Patients
WHERE PatientID IN (SELECT DuplicateID FROM #DuplicateIDMap);

-- Clean up staging resources
DROP TABLE #DuplicateIDMap;
PRINT 'Deduplication completely finished with clean relational integrity.';
GO

--========================================================
--Step 2: Intermediate Analytics (CTEs & Window Functions)--
-- =======================================================

------------------------------------------------------------
-- Step 2.a: Rolling 7-Day Average Length of Stay (LOS) per Department
------------------------------------------------------------
WITH EncounterDurations AS (
    SELECT 
        AdmitDepartmentID,
        CAST(AdmitDateTime AS DATE) AS AdmissionDate,
        DATEDIFF(HOUR, AdmitDateTime, DischargeDateTime) / 24.0 AS LengthOfStayDays
    FROM Fact_Encounters
    WHERE DischargeDateTime IS NOT NULL
)
SELECT DISTINCT
    d.DepartmentName,
    e.AdmissionDate,
    AVG(e.LengthOfStayDays) OVER (
        PARTITION BY e.AdmitDepartmentID 
        ORDER BY e.AdmissionDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS Rolling7DayAvg_LOS_Days
FROM EncounterDurations e
JOIN Dim_Departments d ON e.AdmitDepartmentID = d.DepartmentID
ORDER BY d.DepartmentName, e.AdmissionDate;


-- =======================================================
--Step 2.b: The 30-Day Patient Readmission Tracker
-- =======================================================
WITH SequentialVisits AS (
    SELECT 
        PatientID,
        EncounterID,
        AdmitDateTime,
        DischargeDateTime,
        PrimaryDiagnosisCode, -- Making sure the base column is explicitly grabbed here
        LAG(DischargeDateTime, 1) OVER (PARTITION BY PatientID ORDER BY AdmitDateTime) AS PreviousDischargeDateTime,
        LAG(PrimaryDiagnosisCode, 1) OVER (PARTITION BY PatientID ORDER BY AdmitDateTime) AS PreviousDiagnosis
    FROM Fact_Encounters
)
SELECT 
    PatientID,
    EncounterID,
    PreviousDischargeDateTime,
    AdmitDateTime AS ReadmissionDateTime,
    DATEDIFF(DAY, PreviousDischargeDateTime, AdmitDateTime) AS DaysBetweenVisits,
    PreviousDiagnosis,
    PrimaryDiagnosisCode AS CurrentDiagnosis
FROM SequentialVisits
WHERE PreviousDischargeDateTime IS NOT NULL 
  AND DATEDIFF(DAY, PreviousDischargeDateTime, AdmitDateTime) <= 30
ORDER BY PatientID, ReadmissionDateTime;
GO
