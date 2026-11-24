USE HR_Payroll_DB
GO

SELECT
    name AS DatabaseName,
    state_desc AS Status
FROM sys.databases
WHERE name = 'HR_Payroll_DB'
GO