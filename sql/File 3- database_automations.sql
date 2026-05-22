--===========================================================
-- Step 3: Advanced Operations (Stored Procedures & Triggers)
--===========================================================
--=========================================================================
--Step 3.a: Production Stored Procedure: Live Departmental Capacity Tracker
--=========================================================================
CREATE OR ALTER PROCEDURE sp_GetLiveDepartmentOccupancy
    @TargetDepartmentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        d.DepartmentID,
        d.DepartmentName,
        d.TotalBeds,
        COUNT(f.EncounterID) AS ActivePatientsCount,
        d.TotalBeds - COUNT(f.EncounterID) AS AvailableBeds,
        ROUND((COUNT(f.EncounterID) * 100.0) / d.TotalBeds, 2) AS OccupancyPercentage
    FROM Dim_Departments d
    LEFT JOIN Fact_Encounters f 
        ON d.DepartmentID = f.AdmitDepartmentID 
        AND f.DischargeDateTime IS NULL -- If discharge date is NULL, they are still inside the hospital
    WHERE (@TargetDepartmentID IS NULL OR d.DepartmentID = @TargetDepartmentID)
    GROUP BY d.DepartmentID, d.DepartmentName, d.TotalBeds;
END;
GO

-- Test execution command:
EXEC sp_GetLiveDepartmentOccupancy;


--====================================================================
--Step 3.b: Forensic Audit Control: Automated Billing Security Trigger
--====================================================================
-- Create the history table structure
CREATE TABLE Audit_Billing_Adjustments (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    TxID INT,
    OldAdjustment DECIMAL(18,2),
    NewAdjustment DECIMAL(18,2),
    ModifiedByUserName VARCHAR(100) DEFAULT SYSTEM_USER,
    ChangedTimestamp DATETIME DEFAULT GETDATE()
);
GO

-- Instantiate the security trigger engine
CREATE OR ALTER TRIGGER trg_AuditBillingAdjustments
ON Fact_Billing_Transactions
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(AdjustmentAmount)
    BEGIN
        INSERT INTO Audit_Billing_Adjustments (TxID, OldAdjustment, NewAdjustment)
        SELECT 
            i.TxID,
            d.AdjustmentAmount,
            i.AdjustmentAmount
        FROM inserted i
        JOIN deleted d ON i.TxID = d.TxID;
    END
END;
GO





--Optimization
-- =======================================================
-- INDEX 1: Optimize the 30-Day Readmission Query
-- =======================================================
-- Speed up calculations that look for historical visits by Patient and Date.
-- The INCLUDE clause creates a "Covering Index", meaning SQL Server can answer 
-- the entire query directly from the index without looking back at the main table.
CREATE NONCLUSTERED INDEX IX_FactEncounters_Patient_Dates
ON Fact_Encounters (PatientID, AdmitDateTime)
INCLUDE (EncounterID, DischargeDateTime, PrimaryDiagnosisCode);
GO

-- =======================================================
-- INDEX 2: Optimize the Rolling Length of Stay (LOS) Query
-- =======================================================
-- Optimize department-based time-series analytics and filters.
CREATE NONCLUSTERED INDEX IX_FactEncounters_Dept_Dates
ON Fact_Encounters (AdmitDepartmentID, AdmitDateTime)
INCLUDE (DischargeDateTime);
GO

-- =======================================================
-- INDEX 3: Optimize Active Bed Tracking Lookups
-- =======================================================
-- Speed up our Stored Procedure that filters for live/non-discharged patients.
CREATE NONCLUSTERED INDEX IX_FactEncounters_ActivePatients
ON Fact_Encounters (DischargeDateTime)
INCLUDE (EncounterID, AdmitDepartmentID);
GO

--======================================
--Verification script
--======================================
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Run your analytical query here to see the new performance stats
-- (Check the 'Messages' tab in SSMS after running)
WITH SequentialVisits AS (
    SELECT 
        PatientID, EncounterID, AdmitDateTime, DischargeDateTime, PrimaryDiagnosisCode,
        LAG(DischargeDateTime, 1) OVER (PARTITION BY PatientID ORDER BY AdmitDateTime) AS PreviousDischargeDateTime,
        LAG(PrimaryDiagnosisCode, 1) OVER (PARTITION BY PatientID ORDER BY AdmitDateTime) AS PreviousDiagnosis
    FROM Fact_Encounters
)
SELECT * FROM SequentialVisits
WHERE PreviousDischargeDateTime IS NOT NULL 
  AND DATEDIFF(DAY, PreviousDischargeDateTime, AdmitDateTime) <= 30;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO