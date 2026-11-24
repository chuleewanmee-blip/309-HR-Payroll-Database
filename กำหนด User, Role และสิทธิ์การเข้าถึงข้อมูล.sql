USE HR_Payroll_DB
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'EmployeeRole')
    CREATE ROLE EmployeeRole
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'DepartmentHeadRole')
    CREATE ROLE DepartmentHeadRole
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'HRRole')
    CREATE ROLE HRRole
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'PayrollRole')
    CREATE ROLE PayrollRole
GO

GRANT SELECT ON Departments TO EmployeeRole
GRANT SELECT ON Positions TO EmployeeRole
GO

GRANT SELECT ON Departments TO DepartmentHeadRole
GRANT SELECT ON Positions TO DepartmentHeadRole
GO

GRANT SELECT, INSERT, UPDATE
ON Employees TO HRRole
GO

GRANT SELECT
ON Departments TO HRRole
GO

GRANT SELECT
ON Positions TO HRRole
GO

GRANT SELECT
ON vw_EmployeeDetails TO HRRole
GO

GRANT EXECUTE
ON sp_AddEmployee TO HRRole
GO

GRANT SELECT
ON vw_PayrollDetails TO PayrollRole
GO

GRANT SELECT
ON vw_DepartmentPayrollSummary TO PayrollRole
GO

GRANT EXECUTE
ON sp_ProcessPayroll TO PayrollRole
GO

SELECT
    name AS RoleName,
    type_desc AS RoleType
FROM sys.database_principals
WHERE type = 'R'
AND name IN
(
    'EmployeeRole',
    'DepartmentHeadRole',
    'HRRole',
    'PayrollRole'
)
GO

ALTER ROLE EmployeeRole
ADD MEMBER [ชื่อผู้ใช้งาน]
GO

USE HR_Payroll_DB
GO

SELECT
    name AS UserName,
    type_desc AS UserType
FROM sys.database_principals
WHERE type IN ('S','U','G')
GO

CREATE USER EmployeeUser WITHOUT LOGIN
GO

CREATE USER HeadUser WITHOUT LOGIN
GO

CREATE USER HRUser WITHOUT LOGIN
GO

CREATE USER PayrollUser WITHOUT LOGIN
GO

ALTER ROLE EmployeeRole
ADD MEMBER EmployeeUser
GO

ALTER ROLE DepartmentHeadRole
ADD MEMBER HeadUser
GO

ALTER ROLE HRRole
ADD MEMBER HRUser
GO

ALTER ROLE PayrollRole
ADD MEMBER PayrollUser
GO

SELECT
    dp.name AS UserName,
    rp.name AS RoleName
FROM sys.database_role_members drm
INNER JOIN sys.database_principals rp
    ON drm.role_principal_id = rp.principal_id
INNER JOIN sys.database_principals dp
    ON drm.member_principal_id = dp.principal_id
WHERE rp.name IN
(
    'EmployeeRole',
    'DepartmentHeadRole',
    'HRRole',
    'PayrollRole'
)
GO