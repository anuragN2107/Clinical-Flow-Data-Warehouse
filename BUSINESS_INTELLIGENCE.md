# 📊 Business Intelligence Layer & Operational Insights

## 1. Enterprise Data Model Layout Design
The Power BI front-end template ingestion pipeline avoids generic configurations by connecting directly to the server via an optimized **Import Mode** connection.

### Relational Model Verification Steps
1. Navigate to the **Model View** pane on the far-left control sidebar.
2. Arrange lookups along the upper horizontal quadrant, with transactions aligned below.
3. Establish 5 precise structural relationships, ensuring all filtering directions flow **unidirectionally downward** to keep the semantic layer clean and performant:

```text
* Dim_Patients [PatientID]          (1) ---> (*) Fact_Encounters [PatientID]           | Filter: Single
* Dim_Departments [DepartmentID]    (1) ---> (*) Fact_Encounters [AdmitDepartmentID]   | Filter: Single
* Dim_Providers [ProviderID]        (1) ---> (*) Fact_Encounters [PrimaryProviderID]   | Filter: Single
* Fact_Encounters [EncounterID]     (1) ---> (*) Fact_Bed_Movements [EncounterID]      | Filter: Single
* Fact_Encounters [EncounterID]     (1) ---> (1) Fact_Billing_Transactions [EncounterID]| Filter: Single
2. Production-Grade DAX Calculation Library
To build a highly efficient report, we isolate our formulas inside a custom container table named _Measures. This completely bypasses default column drag-and-drop habits.

⏱️ Active Facility Volume Count
Counts active beds currently occupied by filtering out records that have already registered a historical discharge timestamp.

Code snippet
Active Patients Volume = 
CALCULATE(
    COUNT(Fact_Encounters[EncounterID]),
    ISBLANK(Fact_Encounters[DischargeDateTime])
)
🛏️ Departmental Bed Occupancy Utilization Index
Evaluates live utilization margins by dividing active patient volumes by maximum available physical assets.

Code snippet
Regional Occupancy Rate % = 
DIVIDE(
    [Active Patients Volume], 
    MAX(Dim_Departments[TotalBeds]), 
    0
)
💰 Revenue Collections Efficiency Score
Measures transactional health by mapping true monetary cash captures against total billed hospital balances.

Code snippet
Financial Collection Efficiency % = 
DIVIDE(
    SUM(Fact_Billing_Transactions[InsurancePaid]) + SUM(Fact_Billing_Transactions[PatientPaid]),
    SUM(Fact_Billing_Transactions[ChargeAmount]),
    0
)
