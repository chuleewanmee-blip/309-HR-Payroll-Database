CREATE DATABASE HR_Payroll_DB
GO

USE HR_Payroll_DB
GO

SELECT name
FROM sys.databases
WHERE name = 'HR_Payroll_DB'

CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName VARCHAR(100) NOT NULL UNIQUE
)
GO

CREATE TABLE Positions (
    PositionID INT PRIMARY KEY IDENTITY(1,1),
    PositionName VARCHAR(100) NOT NULL UNIQUE
)
GO

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeCode VARCHAR(10) NOT NULL UNIQUE,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Gender NVARCHAR(10),
    BirthDate DATE,
    HireDate DATE NOT NULL,
    DepartmentID INT NOT NULL,
    PositionID INT NOT NULL,
    Email VARCHAR(100) UNIQUE,
    BankAccount VARBINARY(MAX),
    EmployeeStatus VARCHAR(20) DEFAULT 'Active',

    CONSTRAINT FK_Employees_Departments
    FOREIGN KEY (DepartmentID)
    REFERENCES Departments(DepartmentID),

    CONSTRAINT FK_Employees_Positions
    FOREIGN KEY (PositionID)
    REFERENCES Positions(PositionID),

    CONSTRAINT CK_Employees_Status
    CHECK (EmployeeStatus IN ('Active','Resigned'))
)
GO

CREATE TABLE SalaryHistory (
    SalaryID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT NOT NULL,
    BaseSalary DECIMAL(12,2) NOT NULL,
    EffectiveDate DATE NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_SalaryHistory_Employees
    FOREIGN KEY (EmployeeID)
    REFERENCES Employees(EmployeeID),

    CONSTRAINT CK_Salary_Positive
    CHECK (BaseSalary > 0)
)
GO

CREATE TABLE Attendance (
    AttendanceID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT NOT NULL,
    WorkDate DATE NOT NULL,
    CheckIn TIME,
    CheckOut TIME,
    LateMinutes INT DEFAULT 0,

    CONSTRAINT FK_Attendance_Employees
    FOREIGN KEY (EmployeeID)
    REFERENCES Employees(EmployeeID),

    CONSTRAINT UQ_Attendance
    UNIQUE (EmployeeID, WorkDate),

    CONSTRAINT CK_LateMinutes
    CHECK (LateMinutes >= 0)
)
GO

CREATE TABLE LeaveRequests (
    LeaveID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT NOT NULL,
    LeaveType VARCHAR(20) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    TotalDays DECIMAL(5,2) NOT NULL,
    Reason NVARCHAR(255),
    ApprovalStatus VARCHAR(20) DEFAULT 'Pending',
    ApprovedBy INT NULL,

    CONSTRAINT FK_Leave_Employees
    FOREIGN KEY (EmployeeID)
    REFERENCES Employees(EmployeeID),

    CONSTRAINT FK_Leave_Approver
    FOREIGN KEY (ApprovedBy)
    REFERENCES Employees(EmployeeID),

    CONSTRAINT CK_Leave_Type
    CHECK (LeaveType IN ('Annual','Personal')),

    CONSTRAINT CK_Leave_Status
    CHECK (ApprovalStatus IN ('Pending','Approved','Rejected')),

    CONSTRAINT CK_Leave_Dates
    CHECK (EndDate >= StartDate AND TotalDays > 0)
)
GO

CREATE TABLE OTRequests (
    OTID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT NOT NULL,
    OTDate DATE NOT NULL,
    OTHours DECIMAL(5,2) NOT NULL,
    OTType VARCHAR(20) NOT NULL,
    ApprovalStatus VARCHAR(20) DEFAULT 'Pending',
    ApprovedBy INT NULL,

    CONSTRAINT FK_OT_Employees
    FOREIGN KEY (EmployeeID)
    REFERENCES Employees(EmployeeID),

    CONSTRAINT FK_OT_Approver
    FOREIGN KEY (ApprovedBy)
    REFERENCES Employees(EmployeeID),

    CONSTRAINT CK_OT_Hours
    CHECK (OTHours > 0),

    CONSTRAINT CK_OT_Type
    CHECK (OTType IN ('WorkingDay','Holiday')),

    CONSTRAINT CK_OT_Status
    CHECK (ApprovalStatus IN ('Pending','Approved','Rejected'))
)
GO

CREATE TABLE PayrollPeriods (
    PeriodID INT PRIMARY KEY IDENTITY(1,1),
    PeriodMonth INT NOT NULL,
    PeriodYear INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    PeriodStatus VARCHAR(20) DEFAULT 'Open',
    ClosedAt DATETIME NULL,

    CONSTRAINT UQ_Payroll_Period
    UNIQUE (PeriodMonth, PeriodYear),

    CONSTRAINT CK_Period_Month
    CHECK (PeriodMonth BETWEEN 1 AND 12),

    CONSTRAINT CK_Period_Status
    CHECK (PeriodStatus IN ('Open','Closed')),

    CONSTRAINT CK_Period_Dates
    CHECK (EndDate >= StartDate)
)
GO

CREATE TABLE PayrollDetails (
    PayrollID INT PRIMARY KEY IDENTITY(1,1),
    PeriodID INT NOT NULL,
    EmployeeID INT NOT NULL,
    BaseSalary DECIMAL(12,2) NOT NULL,
    OTAmount DECIMAL(12,2) DEFAULT 0,
    LateDeduction DECIMAL(12,2) DEFAULT 0,
    LeaveDeduction DECIMAL(12,2) DEFAULT 0,
    SocialSecurity DECIMAL(12,2) DEFAULT 0,
    TaxAmount DECIMAL(12,2) DEFAULT 0,
    NetSalary DECIMAL(12,2) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Payroll_Period
    FOREIGN KEY (PeriodID)
    REFERENCES PayrollPeriods(PeriodID),

    CONSTRAINT FK_Payroll_Employee
    FOREIGN KEY (EmployeeID)
    REFERENCES Employees(EmployeeID),

    CONSTRAINT UQ_Payroll_Employee
    UNIQUE (PeriodID, EmployeeID),

    CONSTRAINT CK_Payroll_Amount
    CHECK (
        BaseSalary > 0
        AND OTAmount >= 0
        AND LateDeduction >= 0
        AND LeaveDeduction >= 0
        AND SocialSecurity >= 0
        AND TaxAmount >= 0
        AND NetSalary >= 0
    )
)
GO

CREATE TABLE PayrollParameters (
    ParameterID INT PRIMARY KEY IDENTITY(1,1),
    EffectiveDate DATE NOT NULL,
    SocialSecurityRate DECIMAL(5,4) NOT NULL,
    SocialSecurityCap DECIMAL(12,2) NOT NULL,
    TaxRate DECIMAL(5,4) NOT NULL,
    LateRatePerMinute DECIMAL(10,2) NOT NULL,

    CONSTRAINT CK_Social_Rate
    CHECK (SocialSecurityRate BETWEEN 0 AND 1),

    CONSTRAINT CK_Tax_Rate
    CHECK (TaxRate BETWEEN 0 AND 1),

    CONSTRAINT CK_Social_Cap
    CHECK (SocialSecurityCap >= 0),

    CONSTRAINT CK_Late_Rate
    CHECK (LateRatePerMinute >= 0),

    CONSTRAINT UQ_Parameter_Date
    UNIQUE (EffectiveDate)
)
GO

CREATE TABLE AuditLogs (
    AuditID INT PRIMARY KEY IDENTITY(1,1),
    TableName VARCHAR(100) NOT NULL,
    ActionType VARCHAR(20) NOT NULL,
    RecordID INT,
    OldValue NVARCHAR(MAX),
    NewValue NVARCHAR(MAX),
    ChangedBy NVARCHAR(100),
    ChangedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT CK_Audit_Action
    CHECK (ActionType IN ('INSERT','UPDATE','DELETE'))
)
GO

SELECT
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME

EXEC sp_help 'Employees'
GO

EXEC sp_help 'PayrollDetails'
GO