-- 2. Create Dimension Tables
CREATE TABLE Dim_Patients (
    PatientID INT IDENTITY(1,1) PRIMARY KEY,
    MRN VARCHAR(50) NOT NULL, -- Medical Record Number (Business Key)
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    DateOfBirth DATE,
    Gender VARCHAR(20),
    ZipCode VARCHAR(10),
    CreatedDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Dim_Providers (
    ProviderID INT IDENTITY(1,1) PRIMARY KEY,
    NPI VARCHAR(20) NOT NULL, -- National Provider Identifier
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Specialty VARCHAR(100) NOT NULL,
    StaffStatus VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE Dim_Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName VARCHAR(100) NOT NULL,
    TotalBeds INT NOT NULL,
    ICU_Flag CHAR(1) CHECK (ICU_Flag IN ('Y', 'N'))
);

-- 3. Create Fact Tables
CREATE TABLE Fact_Encounters (
    EncounterID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT FOREIGN KEY REFERENCES Dim_Patients(PatientID),
    PrimaryProviderID INT FOREIGN KEY REFERENCES Dim_Providers(ProviderID),
    AdmitDepartmentID INT FOREIGN KEY REFERENCES Dim_Departments(DepartmentID),
    AdmissionType VARCHAR(50), -- Emergency, Urgent, Elective, Newborn
    AdmitDateTime DATETIME NOT NULL,
    DischargeDateTime DATETIME NULL, -- NULL indicates currently admitted
    PrimaryDiagnosisCode VARCHAR(20), -- ICD-10 Code
    DischargeDisposition VARCHAR(100) -- Home, Transferred, Deceased
);

CREATE TABLE Fact_Bed_Movements (
    MovementID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterID INT FOREIGN KEY REFERENCES Fact_Encounters(EncounterID),
    PatientID INT FOREIGN KEY REFERENCES Dim_Patients(PatientID),
    DepartmentID INT FOREIGN KEY REFERENCES Dim_Departments(DepartmentID),
    BedNumber VARCHAR(20),
    StartDateTime DATETIME NOT NULL,
    EndDateTime DATETIME NULL -- NULL indicates the patient is currently in this bed
);

CREATE TABLE Fact_Billing_Transactions (
    TxID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterID INT FOREIGN KEY REFERENCES Fact_Encounters(EncounterID),
    PatientID INT FOREIGN KEY REFERENCES Dim_Patients(PatientID),
    TransactionDate DATE NOT NULL,
    ChargeAmount DECIMAL(18,2) NOT NULL,
    InsurancePaid DECIMAL(18,2) DEFAULT 0.00,
    PatientPaid DECIMAL(18,2) DEFAULT 0.00,
    AdjustmentAmount DECIMAL(18,2) DEFAULT 0.00
);
GO

USE HealthcareFlowDB;
GO


-- =======================================================
-- STEP 0: CLEAN SLATE (Clear existing records in correct reverse order)
-- =======================================================
PRINT 'Cleaning existing tables...';
DELETE FROM Fact_Billing_Transactions;
DELETE FROM Fact_Bed_Movements;
DELETE FROM Fact_Encounters;
DELETE FROM Dim_Patients;
DELETE FROM Dim_Providers;
DELETE FROM Dim_Departments;
GO

-- =======================================================
-- STEP 1: LOAD DIMENSIONS (The structural building blocks)
-- =======================================================

-- 1. Departments
PRINT 'Loading Dim_Departments...';
IF OBJECT_ID('tempdb..#Stage_Departments') IS NOT NULL DROP TABLE #Stage_Departments;
CREATE TABLE #Stage_Departments (Col1 INT, DepartmentName VARCHAR(100), TotalBeds INT, ICU_Flag CHAR(1));

BULK INSERT #Stage_Departments FROM 'C:\Users\Anurag Srivastava\Downloads\dim_departments.csv' WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a' );

SET IDENTITY_INSERT Dim_Departments ON;
INSERT INTO Dim_Departments (DepartmentID, DepartmentName, TotalBeds, ICU_Flag)
SELECT Col1, DepartmentName, TotalBeds, ICU_Flag FROM #Stage_Departments;
SET IDENTITY_INSERT Dim_Departments OFF;

-- 2. Providers
PRINT 'Loading Dim_Providers...';
IF OBJECT_ID('tempdb..#Stage_Providers') IS NOT NULL DROP TABLE #Stage_Providers;
CREATE TABLE #Stage_Providers (Col1 INT, NPI VARCHAR(20), FirstName VARCHAR(100), LastName VARCHAR(100), Specialty VARCHAR(100), StaffStatus VARCHAR(20));

BULK INSERT #Stage_Providers FROM 'C:\Users\Anurag Srivastava\Downloads\dim_providers.csv' WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a' );

SET IDENTITY_INSERT Dim_Providers ON;
INSERT INTO Dim_Providers (ProviderID, NPI, FirstName, LastName, Specialty, StaffStatus)
SELECT Col1, NPI, FirstName, LastName, Specialty, StaffStatus FROM #Stage_Providers;
SET IDENTITY_INSERT Dim_Providers OFF;

-- 3. Patients
PRINT 'Loading Dim_Patients...';
IF OBJECT_ID('tempdb..#Stage_Patients') IS NOT NULL DROP TABLE #Stage_Patients;
CREATE TABLE #Stage_Patients (Col1 INT, MRN VARCHAR(50), FirstName VARCHAR(100), LastName VARCHAR(100), DateOfBirth DATE, Gender VARCHAR(20), ZipCode VARCHAR(10));

BULK INSERT #Stage_Patients FROM 'C:\Users\Anurag Srivastava\Downloads\dim_patients.csv' WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a' );

SET IDENTITY_INSERT Dim_Patients ON;
INSERT INTO Dim_Patients (PatientID, MRN, FirstName, LastName, DateOfBirth, Gender, ZipCode)
SELECT Col1, MRN, FirstName, LastName, DateOfBirth, Gender, ZipCode FROM #Stage_Patients;
SET IDENTITY_INSERT Dim_Patients OFF;
GO

-- =======================================================
-- STEP 2: LOAD MAIN FACT TABLE (Must happen before child fact tables)
-- =======================================================

-- 4. Encounters
PRINT 'Loading Fact_Encounters...';
IF OBJECT_ID('tempdb..#Stage_Encounters') IS NOT NULL DROP TABLE #Stage_Encounters;
CREATE TABLE #Stage_Encounters (Col1 INT, PatientID INT, PrimaryProviderID INT, AdmitDepartmentID INT, AdmissionType VARCHAR(50), AdmitDateTime DATETIME, DischargeDateTime VARCHAR(50), PrimaryDiagnosisCode VARCHAR(20), DischargeDisposition VARCHAR(100));

BULK INSERT #Stage_Encounters FROM 'C:\Users\Anurag Srivastava\Downloads\fact_encounters.csv' WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a' );

SET IDENTITY_INSERT Fact_Encounters ON;
INSERT INTO Fact_Encounters (EncounterID, PatientID, PrimaryProviderID, AdmitDepartmentID, AdmissionType, AdmitDateTime, DischargeDateTime, PrimaryDiagnosisCode, DischargeDisposition)
SELECT 
    Col1, PatientID, PrimaryProviderID, AdmitDepartmentID, AdmissionType, AdmitDateTime, 
    CASE WHEN TRIM(DischargeDateTime) = '' OR DischargeDateTime IS NULL THEN NULL ELSE CAST(DischargeDateTime AS DATETIME) END, 
    PrimaryDiagnosisCode, DischargeDisposition 
FROM #Stage_Encounters;
SET IDENTITY_INSERT Fact_Encounters OFF;
GO

-- =======================================================
-- STEP 3: LOAD SUB-FACT TABLES (Dependent on dimensions and encounters)
-- =======================================================

-- 5. Bed Movements
PRINT 'Loading Fact_Bed_Movements...';
IF OBJECT_ID('tempdb..#Stage_Bed_Movements') IS NOT NULL DROP TABLE #Stage_Bed_Movements;
CREATE TABLE #Stage_Bed_Movements (Col1 INT, EncounterID INT, PatientID INT, DepartmentID INT, BedNumber VARCHAR(20), StartDateTime DATETIME, EndDateTime VARCHAR(50));

BULK INSERT #Stage_Bed_Movements FROM 'C:\Users\Anurag Srivastava\Downloads\fact_bed_movements.csv' WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a' );

SET IDENTITY_INSERT Fact_Bed_Movements ON;
INSERT INTO Fact_Bed_Movements (MovementID, EncounterID, PatientID, DepartmentID, BedNumber, StartDateTime, EndDateTime)
SELECT 
    Col1, EncounterID, PatientID, DepartmentID, BedNumber, StartDateTime, 
    CASE WHEN TRIM(EndDateTime) = '' OR EndDateTime IS NULL THEN NULL ELSE CAST(EndDateTime AS DATETIME) END
FROM #Stage_Bed_Movements;
SET IDENTITY_INSERT Fact_Bed_Movements OFF;

-- 6. Billing Transactions
PRINT 'Loading Fact_Billing_Transactions...';
IF OBJECT_ID('tempdb..#Stage_Billing') IS NOT NULL DROP TABLE #Stage_Billing;
CREATE TABLE #Stage_Billing (Col1 INT, EncounterID INT, PatientID INT, TransactionDate DATE, ChargeAmount DECIMAL(18,2), InsurancePaid DECIMAL(18,2), PatientPaid DECIMAL(18,2), AdjustmentAmount DECIMAL(18,2));

BULK INSERT #Stage_Billing FROM 'C:\Users\Anurag Srivastava\Downloads\fact_billing_transactions.csv' WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a' );

SET IDENTITY_INSERT Fact_Billing_Transactions ON;
INSERT INTO Fact_Billing_Transactions (TxID, EncounterID, PatientID, TransactionDate, ChargeAmount, InsurancePaid, PatientPaid, AdjustmentAmount)
SELECT Col1, EncounterID, PatientID, TransactionDate, ChargeAmount, InsurancePaid, PatientPaid, AdjustmentAmount FROM #Stage_Billing;
SET IDENTITY_INSERT Fact_Billing_Transactions OFF;
GO

-- =======================================================
-- STEP 4: FINAL DATABASE VERIFICATION
-- =======================================================
PRINT 'Verifying load metrics...';
SELECT 'Dim_Departments' AS TableName, COUNT(*) AS RecordCount FROM Dim_Departments
UNION ALL
SELECT 'Dim_Providers', COUNT(*) FROM Dim_Providers
UNION ALL
SELECT 'Dim_Patients', COUNT(*) FROM Dim_Patients
UNION ALL
SELECT 'Fact_Encounters', COUNT(*) FROM Fact_Encounters
UNION ALL
SELECT 'Fact_Bed_Movements', COUNT(*) FROM Fact_Bed_Movements
UNION ALL
SELECT 'Fact_Billing_Transactions', COUNT(*) FROM Fact_Billing_Transactions;