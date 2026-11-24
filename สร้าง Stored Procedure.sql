USE HR_Payroll_DB
GO

CREATE PROCEDURE sp_AddEmployee
    @EmployeeCode VARCHAR(10),
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Gender NVARCHAR(10),
    @BirthDate DATE,
    @HireDate DATE,
    @DepartmentID INT,
    @PositionID INT,
    @Email VARCHAR(100),
    @BaseSalary DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        IF EXISTS (
            SELECT 1
            FROM Employees
            WHERE EmployeeCode = @EmployeeCode
        )
        BEGIN
            THROW 50001, 'Employee code already exists', 1
        END

        IF NOT EXISTS (
            SELECT 1 FROM Departments
            WHERE DepartmentID = @DepartmentID
        )
        BEGIN
            THROW 50002, 'Department not found', 1
        END

        IF NOT EXISTS (
            SELECT 1 FROM Positions
            WHERE PositionID = @PositionID
        )
        BEGIN
            THROW 50003, 'Position not found', 1
        END

        INSERT INTO Employees
        (
            EmployeeCode, FirstName, LastName,
            Gender, BirthDate, HireDate,
            DepartmentID, PositionID, Email,
            EmployeeStatus
        )
        VALUES
        (
            @EmployeeCode, @FirstName, @LastName,
            @Gender, @BirthDate, @HireDate,
            @DepartmentID, @PositionID, @Email,
            'Active'
        )

        DECLARE @NewEmployeeID INT

        SET @NewEmployeeID = SCOPE_IDENTITY()

        INSERT INTO SalaryHistory
        (
            EmployeeID, BaseSalary, EffectiveDate
        )
        VALUES
        (
            @NewEmployeeID, @BaseSalary, @HireDate
        )

        COMMIT TRANSACTION

        PRINT 'Add employee successfully'
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        THROW
    END CATCH
END
GO

'วิธีทดสอบ'

EXEC sp_AddEmployee
    'EMP151',
    N'ทดสอบ',
    N'ระบบงาน',
    N'หญิง',
    '2000-01-01',
    '2026-11-01',
    4,
    6,
    'emp151@company.com',
    30000
GO

SELECT *
FROM Employees
WHERE EmployeeCode = 'EMP151'
GO

SELECT *
FROM SalaryHistory
WHERE EmployeeID = 151
GO

CREATE PROCEDURE sp_ApproveOT
    @OTID INT,
    @ApprovedBy INT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        IF NOT EXISTS (
            SELECT 1
            FROM Employees
            WHERE EmployeeID = @ApprovedBy
              AND EmployeeStatus = 'Active'
        )
        BEGIN
            THROW 50004, 'Approver not found', 1
        END

        IF NOT EXISTS (
            SELECT 1
            FROM OTRequests
            WHERE OTID = @OTID
              AND ApprovalStatus = 'Pending'
        )
        BEGIN
            THROW 50005, 'OT request not found or already processed', 1
        END

        UPDATE OTRequests
        SET
            ApprovalStatus = 'Approved',
            ApprovedBy = @ApprovedBy
        WHERE OTID = @OTID

        COMMIT TRANSACTION

        PRINT 'OT approved successfully'
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        THROW
    END CATCH
END
GO

EXEC sp_ApproveOT
    @OTID = 4,
    @ApprovedBy = 1
GO

SELECT *
FROM OTRequests
WHERE OTID = 4
GO

SELECT *
FROM OTRequests
WHERE OTID = 4
GO

CREATE PROCEDURE sp_ProcessPayroll
    @PeriodID INT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        DECLARE
            @StartDate DATE,
            @EndDate DATE,
            @SocialRate DECIMAL(5,4),
            @SocialCap DECIMAL(12,2),
            @TaxRate DECIMAL(5,4),
            @LateRate DECIMAL(10,2)

        -- ตรวจสอบงวดเงินเดือน
        SELECT
            @StartDate = StartDate,
            @EndDate = EndDate
        FROM PayrollPeriods WITH (UPDLOCK, HOLDLOCK)
        WHERE PeriodID = @PeriodID
          AND PeriodStatus = 'Open'

        IF @StartDate IS NULL
        BEGIN
            THROW 50006, 'Payroll period not found or closed', 1
        END

        -- ตรวจสอบว่ามีการประมวลผลแล้วหรือไม่
        IF EXISTS (
            SELECT 1
            FROM PayrollDetails
            WHERE PeriodID = @PeriodID
        )
        BEGIN
            THROW 50007, 'Payroll already processed', 1
        END

        -- ดึงอัตราที่มีผลใช้ในงวด
        SELECT TOP 1
            @SocialRate = SocialSecurityRate,
            @SocialCap = SocialSecurityCap,
            @TaxRate = TaxRate,
            @LateRate = LateRatePerMinute
        FROM PayrollParameters
        WHERE EffectiveDate <= @EndDate
        ORDER BY EffectiveDate DESC

        IF @SocialRate IS NULL
        BEGIN
            THROW 50008, 'Payroll parameters not found', 1
        END

        ;WITH CurrentSalary AS
        (
            SELECT
                S.EmployeeID,
                S.BaseSalary,
                ROW_NUMBER() OVER (
                    PARTITION BY S.EmployeeID
                    ORDER BY S.EffectiveDate DESC, S.SalaryID DESC
                ) AS RN
            FROM SalaryHistory S
            WHERE S.EffectiveDate <= @EndDate
        ),
        OTData AS
        (
            SELECT
                EmployeeID,
                SUM(
                    OTHours *
                    (CASE
                        WHEN OTType = 'WorkingDay' THEN 1.5
                        WHEN OTType = 'Holiday' THEN 3
                    END)
                ) AS OTMultiplierHours
            FROM OTRequests
            WHERE OTDate BETWEEN @StartDate AND @EndDate
              AND ApprovalStatus = 'Approved'
            GROUP BY EmployeeID
        ),
        LateData AS
        (
            SELECT
                EmployeeID,
                SUM(
                    CASE
                        WHEN LateMinutes > 15 THEN LateMinutes
                        ELSE 0
                    END
                ) AS TotalLateMinutes
            FROM Attendance
            WHERE WorkDate BETWEEN @StartDate AND @EndDate
            GROUP BY EmployeeID
        ),
        LeaveData AS
        (
            SELECT
                E.EmployeeID,

                SUM(
                    CASE
                        WHEN L.LeaveType = 'Annual'
                         AND L.EndDate >= @StartDate
                         AND L.StartDate <= @EndDate
                        THEN L.TotalDays
                        ELSE 0
                    END
                ) AS AnnualDays,

                SUM(
                    CASE
                        WHEN L.LeaveType = 'Personal'
                         AND L.EndDate >= @StartDate
                         AND L.StartDate <= @EndDate
                        THEN L.TotalDays
                        ELSE 0
                    END
                ) AS PersonalDays

            FROM Employees E
            LEFT JOIN LeaveRequests L
                ON E.EmployeeID = L.EmployeeID
                AND L.ApprovalStatus = 'Approved'
                AND L.EndDate >= @StartDate
                AND L.StartDate <= @EndDate
            GROUP BY E.EmployeeID
        ),
        PayrollCalculation AS
        (
            SELECT
                E.EmployeeID,
                S.BaseSalary,

                ISNULL(O.OTMultiplierHours, 0)
                    * (S.BaseSalary / 30.0 / 8.0)
                    AS OTAmount,

                ISNULL(L.TotalLateMinutes, 0)
                    * @LateRate
                    AS LateDeduction,

                CASE
                    WHEN ISNULL(V.AnnualDays, 0) > 10
                    THEN (V.AnnualDays - 10)
                         * S.BaseSalary / 30.0
                    ELSE 0
                END
                +
                CASE
                    WHEN ISNULL(V.PersonalDays, 0) > 3
                    THEN (V.PersonalDays - 3)
                         * S.BaseSalary / 30.0
                    ELSE 0
                END AS LeaveDeduction

            FROM Employees E
            INNER JOIN CurrentSalary S
                ON E.EmployeeID = S.EmployeeID
                AND S.RN = 1

            LEFT JOIN OTData O
                ON E.EmployeeID = O.EmployeeID

            LEFT JOIN LateData L
                ON E.EmployeeID = L.EmployeeID

            LEFT JOIN LeaveData V
                ON E.EmployeeID = V.EmployeeID

            WHERE E.EmployeeStatus = 'Active'
        )
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
            @PeriodID,
            EmployeeID,
            BaseSalary,
            OTAmount,
            LateDeduction,
            LeaveDeduction,

            CASE
                WHEN BaseSalary * @SocialRate > @SocialCap
                THEN @SocialCap
                ELSE BaseSalary * @SocialRate
            END,

            (BaseSalary + OTAmount
                - LateDeduction
                - LeaveDeduction)
                * @TaxRate,

            BaseSalary + OTAmount
                - LateDeduction
                - LeaveDeduction
                - CASE
                    WHEN BaseSalary * @SocialRate > @SocialCap
                    THEN @SocialCap
                    ELSE BaseSalary * @SocialRate
                  END
                - ((BaseSalary + OTAmount
                    - LateDeduction
                    - LeaveDeduction) * @TaxRate)

        FROM PayrollCalculation

        -- ตรวจสอบว่าเงินเดือนสุทธิไม่ติดลบ
        IF EXISTS (
            SELECT 1
            FROM PayrollDetails
            WHERE PeriodID = @PeriodID
              AND NetSalary < 0
        )
        BEGIN
            THROW 50009, 'Net salary cannot be negative', 1
        END

        COMMIT TRANSACTION

        PRINT 'Payroll processed successfully'
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        THROW
    END CATCH
END
GO

DELETE FROM PayrollDetails
WHERE PeriodID = 1
GO

EXEC sp_ProcessPayroll
    @PeriodID = 1
GO

SELECT *
FROM PayrollDetails
WHERE PeriodID = 1
ORDER BY EmployeeID
GO

SELECT COUNT(*) AS TotalPayroll
FROM PayrollDetails
WHERE PeriodID = 1
GO

SELECT
    name AS ProcedureName,
    create_date AS CreateDate
FROM sys.procedures
WHERE name IN (
    'sp_AddEmployee',
    'sp_ApproveOT',
    'sp_ProcessPayroll'
)
GO

