CREATE TRIGGER trg_AuditSalaryChange
ON SalaryHistory
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON

    INSERT INTO AuditLogs
    (
        TableName,
        ActionType,
        RecordID,
        OldValue,
        NewValue,
        ChangedBy,
        ChangedAt
    )
    SELECT
        'SalaryHistory',
        'UPDATE',
        CAST(i.SalaryID AS NVARCHAR(50)),
        CONCAT('BaseSalary=', d.BaseSalary),
        CONCAT('BaseSalary=', i.BaseSalary),
        SUSER_SNAME(),
        GETDATE()
    FROM inserted i
    INNER JOIN deleted d
        ON i.SalaryID = d.SalaryID
    WHERE i.BaseSalary <> d.BaseSalary
END
GO

UPDATE SalaryHistory
SET BaseSalary = BaseSalary + 1000
WHERE SalaryID = 1
GO

SELECT *
FROM AuditLogs
GO

CREATE TRIGGER trg_PreventClosedPayrollEdit
ON PayrollDetails
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON

    IF EXISTS
    (
        SELECT 1
        FROM deleted d
        INNER JOIN PayrollPeriods p
            ON d.PeriodID = p.PeriodID
        WHERE p.PeriodStatus = 'Closed'
    )
    BEGIN
        RAISERROR(
            N'ไม่สามารถแก้ไขหรือลบข้อมูลเงินเดือนของงวดที่ปิดแล้วได้',
            16,
            1
        )
        ROLLBACK TRANSACTION
        RETURN
    END
END
GO

UPDATE PayrollPeriods
SET PeriodStatus = 'Closed'
WHERE PeriodID = 1
GO

UPDATE PayrollDetails
SET NetSalary = NetSalary + 100
WHERE PeriodID = 1
GO

CREATE TRIGGER trg_PreventClosedOTEdit
ON OTRequests
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON

    IF EXISTS
    (
        SELECT 1
        FROM deleted d
        INNER JOIN PayrollPeriods p
            ON d.OTDate BETWEEN p.StartDate AND p.EndDate
        WHERE p.PeriodStatus = 'Closed'
    )
    BEGIN
        RAISERROR(
            N'ไม่สามารถแก้ไขหรือลบข้อมูล OT ของงวดที่ปิดแล้วได้',
            16,
            1
        )
        ROLLBACK TRANSACTION
        RETURN
    END
END
GO

SELECT
    name AS TriggerName,
    OBJECT_NAME(parent_id) AS TableName,
    create_date AS CreateDate
FROM sys.triggers
WHERE name IN
(
    'trg_AuditSalaryChange',
    'trg_PreventClosedPayrollEdit',
    'trg_PreventClosedOTEdit'
)
GO

SELECT name
FROM sys.triggers
WHERE name = 'trg_PreventClosedPayrollEdit'
GO

CREATE TRIGGER trg_PreventClosedPayrollEdit
ON PayrollDetails
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON

    IF EXISTS
    (
        SELECT 1
        FROM deleted d
        INNER JOIN PayrollPeriods p
            ON d.PeriodID = p.PeriodID
        WHERE p.PeriodStatus = 'Closed'
    )
    BEGIN
        ROLLBACK TRANSACTION

        RAISERROR(
            N'ไม่สามารถแก้ไขหรือลบข้อมูลเงินเดือนของงวดที่ปิดแล้วได้',
            16,
            1
        )

        RETURN
    END
END
GO

SELECT
    name AS TriggerName,
    OBJECT_NAME(parent_id) AS TableName
FROM sys.triggers
WHERE name = 'trg_PreventClosedPayrollEdit'
GO

SELECT
    name AS TriggerName,
    OBJECT_NAME(parent_id) AS TableName,
    create_date AS CreateDate
FROM sys.triggers
WHERE name IN
(
    'trg_AuditSalaryChange',
    'trg_PreventClosedPayrollEdit',
    'trg_PreventClosedOTEdit'
)
