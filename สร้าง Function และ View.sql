CREATE FUNCTION fn_CalculateAge
(
    @BirthDate DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @Age INT

    SET @Age = DATEDIFF(YEAR, @BirthDate, GETDATE())

    IF DATEADD(YEAR, @Age, @BirthDate) > GETDATE()
        SET @Age = @Age - 1

    RETURN @Age
END
GO

SELECT
    EmployeeCode,
    FirstName,
    LastName,
    dbo.fn_CalculateAge(BirthDate) AS Age
FROM Employees
GO

CREATE FUNCTION fn_CalculateOT
(
    @BaseSalary DECIMAL(12,2),
    @OTHours DECIMAL(5,2),
    @OTType NVARCHAR(20)
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @Rate DECIMAL(5,2)
    DECLARE @OTAmount DECIMAL(12,2)

    SET @Rate =
        CASE
            WHEN @OTType = 'WorkingDay' THEN 1.5
            WHEN @OTType = 'Holiday' THEN 3.0
            ELSE 0
        END

    SET @OTAmount =
        (@BaseSalary / 30 / 8) * @OTHours * @Rate

    RETURN @OTAmount
END
GO

SELECT dbo.fn_CalculateOT(30000, 2, 'WorkingDay') AS OTAmount
GO

CREATE OR ALTER VIEW vw_EmployeeDetails
AS
SELECT
    e.EmployeeID,
    e.EmployeeCode,
    e.FirstName,
    e.LastName,
    d.DepartmentName,
    p.PositionName,
    e.Email,
    e.EmployeeStatus
FROM Employees e
INNER JOIN Departments d
    ON e.DepartmentID = d.DepartmentID
INNER JOIN Positions p
    ON e.PositionID = p.PositionID
GO

SELECT *
FROM vw_EmployeeDetails
GO

CREATE VIEW vw_DepartmentPayrollSummary
AS
SELECT
    d.DepartmentName,
    COUNT(pd.EmployeeID) AS TotalEmployees,
    SUM(pd.BaseSalary) AS TotalSalary,
    SUM(pd.OTAmount) AS TotalOT,
    SUM(pd.SocialSecurity) AS TotalSocialSecurity,
    SUM(pd.TaxAmount) AS TotalTax,
    SUM(pd.NetSalary) AS TotalNetSalary
FROM PayrollDetails pd
INNER JOIN Employees e
    ON pd.EmployeeID = e.EmployeeID
INNER JOIN Departments d
    ON e.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentName
GO

SELECT * FROM vw_DepartmentPayrollSummary
GO

CREATE VIEW vw_LeaveOTSummary
AS
SELECT
    e.EmployeeCode,
    e.FirstName,
    e.LastName,

    (SELECT COUNT(*)
     FROM LeaveRequests l
     WHERE l.EmployeeID = e.EmployeeID
       AND l.ApprovalStatus = 'Approved') AS ApprovedLeave,

    (SELECT COUNT(*)
     FROM OTRequests o
     WHERE o.EmployeeID = e.EmployeeID
       AND o.ApprovalStatus = 'Approved') AS ApprovedOT,

    (SELECT ISNULL(SUM(o.OTHours), 0)
     FROM OTRequests o
     WHERE o.EmployeeID = e.EmployeeID
       AND o.ApprovalStatus = 'Approved') AS TotalOTHours

FROM Employees e
GO

SELECT * FROM vw_LeaveOTSummary
GO

SELECT
    name AS ObjectName,
    type_desc AS ObjectType
FROM sys.objects
WHERE name IN
(
    'fn_CalculateAge',
    'fn_CalculateOT',
    'vw_EmployeeDetails',
    'vw_PayrollDetails',
    'vw_DepartmentPayrollSummary',
    'vw_LeaveOTSummary'
)
ORDER BY type_desc
GO