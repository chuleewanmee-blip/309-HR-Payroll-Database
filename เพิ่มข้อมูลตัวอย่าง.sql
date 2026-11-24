USE HR_Payroll_DB
GO

INSERT INTO Departments (DepartmentName)
VALUES
(N'ฝ่ายบุคคล'),
(N'ฝ่ายบัญชี'),
(N'ฝ่ายการเงิน'),
(N'ฝ่าย IT'),
(N'ฝ่ายขาย'),
(N'ฝ่ายการตลาด')
GO

INSERT INTO Positions (PositionName)
VALUES
(N'ผู้จัดการ'),
(N'หัวหน้าแผนก'),
(N'เจ้าหน้าที่ HR'),
(N'เจ้าหน้าที่บัญชี'),
(N'เจ้าหน้าที่การเงิน'),
(N'โปรแกรมเมอร์'),
(N'นักวิเคราะห์ระบบ'),
(N'พนักงานขาย'),
(N'เจ้าหน้าที่การตลาด'),
(N'พนักงานทั่วไป')
GO

;WITH EmployeeNumbers AS
(
    SELECT TOP (150)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Num
    FROM sys.all_objects A
    CROSS JOIN sys.all_objects B
)
INSERT INTO Employees
(
    EmployeeCode,
    FirstName,
    LastName,
    Gender,
    BirthDate,
    HireDate,
    DepartmentID,
    PositionID,
    Email,
    EmployeeStatus
)
SELECT
    'EMP' + RIGHT('000' + CAST(Num AS VARCHAR(3)), 3),
    N'พนักงาน',
    N'คนที่ ' + CAST(Num AS NVARCHAR(3)),
    CASE
        WHEN Num % 2 = 0 THEN N'ชาย'
        ELSE N'หญิง'
    END,
    DATEADD(YEAR, -25, CAST('2026-01-01' AS DATE)),
    DATEADD(DAY, Num, CAST('2020-01-01' AS DATE)),
    ((Num - 1) % 6) + 1,
    ((Num - 1) % 10) + 1,
    'emp' + CAST(Num AS VARCHAR(3)) + '@company.com',
    'Active'
FROM EmployeeNumbers
GO

SELECT COUNT(*) AS TotalEmployees
FROM Employees
GO

INSERT INTO SalaryHistory
(EmployeeID, BaseSalary, EffectiveDate)
SELECT
    EmployeeID,
    CASE
        WHEN PositionID = 1 THEN 50000
        WHEN PositionID = 2 THEN 40000
        WHEN PositionID = 3 THEN 28000
        WHEN PositionID = 4 THEN 27000
        WHEN PositionID = 5 THEN 27000
        WHEN PositionID = 6 THEN 35000
        WHEN PositionID = 7 THEN 32000
        WHEN PositionID = 8 THEN 23000
        WHEN PositionID = 9 THEN 25000
        ELSE 18000
    END,
    '2026-01-01'
FROM Employees
GO

SELECT * FROM SalaryHistory
GO

INSERT INTO PayrollPeriods
(
    PeriodMonth,
    PeriodYear,
    StartDate,
    EndDate,
    PeriodStatus
)
VALUES
(10, 2026, '2026-10-01', '2026-10-31', 'Open')
GO

INSERT INTO PayrollParameters
(
    EffectiveDate,
    SocialSecurityRate,
    SocialSecurityCap,
    TaxRate,
    LateRatePerMinute
)
VALUES
('2026-01-01', 0.05, 750, 0.03, 5)
GO

INSERT INTO Attendance
(
    EmployeeID,
    WorkDate,
    CheckIn,
    CheckOut,
    LateMinutes
)
SELECT
    E.EmployeeID,
    D.WorkDate,
    CASE
        WHEN E.EmployeeID % 4 = 0 THEN '09:20'
        WHEN E.EmployeeID % 4 = 1 THEN '09:10'
        ELSE '09:00'
    END,
    '17:00',
    CASE
        WHEN E.EmployeeID % 4 = 0 THEN 20
        WHEN E.EmployeeID % 4 = 1 THEN 10
        ELSE 0
    END
FROM Employees E
CROSS JOIN
(
    SELECT CAST('2026-10-01' AS DATE) AS WorkDate
    UNION ALL SELECT '2026-10-02'
    UNION ALL SELECT '2026-10-03'
    UNION ALL SELECT '2026-10-04'
    UNION ALL SELECT '2026-10-05'
) D
GO

SELECT COUNT(*) AS TotalAttendance
FROM Attendance
GO

INSERT INTO LeaveRequests
(
    EmployeeID,
    LeaveType,
    StartDate,
    EndDate,
    TotalDays,
    Reason,
    ApprovalStatus,
    ApprovedBy
)
SELECT
    Num,
    CASE
        WHEN Num % 2 = 0 THEN 'Annual'
        ELSE 'Personal'
    END,
    DATEADD(DAY, Num % 20, CAST('2026-10-01' AS DATE)),
    DATEADD(DAY, Num % 20, CAST('2026-10-01' AS DATE)),
    1,
    N'ขอลาหยุดงาน',
    CASE
        WHEN Num % 3 = 0 THEN 'Pending'
        WHEN Num % 3 = 1 THEN 'Approved'
        ELSE 'Rejected'
    END,
    CASE
        WHEN Num % 3 = 1 THEN 1
        WHEN Num % 3 = 2 THEN 1
        ELSE NULL
    END
FROM
(
    SELECT TOP (30)
        ROW_NUMBER() OVER (ORDER BY EmployeeID) AS Num
    FROM Employees
) AS X
GO

INSERT INTO OTRequests
(
    EmployeeID,
    OTDate,
    OTHours,
    OTType,
    ApprovalStatus,
    ApprovedBy
)
SELECT
    Num,
    DATEADD(DAY, Num % 20, CAST('2026-10-01' AS DATE)),
    CASE
        WHEN Num % 3 = 0 THEN 2
        WHEN Num % 3 = 1 THEN 3
        ELSE 4
    END,
    CASE
        WHEN Num % 2 = 0 THEN 'WorkingDay'
        ELSE 'Holiday'
    END,
    CASE
        WHEN Num % 3 = 0 THEN 'Pending'
        WHEN Num % 3 = 1 THEN 'Approved'
        ELSE 'Rejected'
    END,
    CASE
        WHEN Num % 3 = 0 THEN NULL
        ELSE 1
    END
FROM
(
    SELECT TOP (50)
        ROW_NUMBER() OVER (ORDER BY EmployeeID) AS Num
    FROM Employees
) AS X
GO

INSERT INTO PayrollDetails
(
    PeriodID,
    EmployeeID,
    BaseSalary,
    OTAmount,
    LateDeduction,
    LeaveDeduction,
    SocialSecurity,
    TaxAmount,
    NetSalary
)
SELECT
    1,
    E.EmployeeID,
    S.BaseSalary,
    0,
    0,
    0,
    750,
    0,
    S.BaseSalary - 750
FROM Employees E
INNER JOIN SalaryHistory S
    ON E.EmployeeID = S.EmployeeID
GO

SELECT 'Departments' AS TableName, COUNT(*) AS Total FROM Departments
UNION ALL
SELECT 'Positions', COUNT(*) FROM Positions
UNION ALL
SELECT 'Employees', COUNT(*) FROM Employees
UNION ALL
SELECT 'SalaryHistory', COUNT(*) FROM SalaryHistory
UNION ALL
SELECT 'Attendance', COUNT(*) FROM Attendance
UNION ALL
SELECT 'LeaveRequests', COUNT(*) FROM LeaveRequests
UNION ALL
SELECT 'OTRequests', COUNT(*) FROM OTRequests
UNION ALL
SELECT 'PayrollPeriods', COUNT(*) FROM PayrollPeriods
UNION ALL
SELECT 'PayrollDetails', COUNT(*) FROM PayrollDetails
UNION ALL
SELECT 'PayrollParameters', COUNT(*) FROM PayrollParameters
UNION ALL
SELECT 'AuditLogs', COUNT(*) FROM AuditLogs
GO

