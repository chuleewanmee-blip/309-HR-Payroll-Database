USE HR_Payroll_DB
GO

CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'HrPayroll@2026Secure!'
GO

CREATE CERTIFICATE HRPayrollCertificate
WITH SUBJECT = 'HR Payroll Data Protection'
GO

CREATE SYMMETRIC KEY HRPayrollKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE HRPayrollCertificate
GO

USE HR_Payroll_DB
GO

-- สร้าง Master Key ถ้ายังไม่มี
IF NOT EXISTS
(
    SELECT 1
    FROM sys.symmetric_keys
    WHERE name = '##MS_DatabaseMasterKey##'
)
BEGIN
    CREATE MASTER KEY
    ENCRYPTION BY PASSWORD = 'HrPayroll@2026Secure!'
END
GO

-- สร้าง Certificate ถ้ายังไม่มี
IF NOT EXISTS
(
    SELECT 1
    FROM sys.certificates
    WHERE name = 'HRPayrollCertificate'
)
BEGIN
    CREATE CERTIFICATE HRPayrollCertificate
    WITH SUBJECT = 'HR Payroll Data Protection'
END
GO

-- สร้าง Symmetric Key ถ้ายังไม่มี
IF NOT EXISTS
(
    SELECT 1
    FROM sys.symmetric_keys
    WHERE name = 'HRPayrollKey'
)
BEGIN
    CREATE SYMMETRIC KEY HRPayrollKey
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE HRPayrollCertificate
END
GO

IF COL_LENGTH('SalaryHistory', 'BaseSalaryEncrypted') IS NULL
BEGIN
    ALTER TABLE SalaryHistory
    ADD BaseSalaryEncrypted VARBINARY(MAX)
END
GO

OPEN SYMMETRIC KEY HRPayrollKey
DECRYPTION BY CERTIFICATE HRPayrollCertificate
GO

UPDATE SalaryHistory
SET BaseSalaryEncrypted =
    ENCRYPTBYKEY(
        KEY_GUID('HRPayrollKey'),
        CONVERT(VARCHAR(30), BaseSalary)
    )
WHERE BaseSalaryEncrypted IS NULL
GO

CLOSE SYMMETRIC KEY HRPayrollKey
GO

OPEN SYMMETRIC KEY HRPayrollKey
DECRYPTION BY CERTIFICATE HRPayrollCertificate
GO

SELECT
    SalaryID,
    EmployeeID,
    CONVERT(
        VARCHAR(30),
        DECRYPTBYKEY(BaseSalaryEncrypted)
    ) AS DecryptedSalary
FROM SalaryHistory
GO

CLOSE SYMMETRIC KEY HRPayrollKey
GO

ALTER TABLE SalaryHistory
ALTER COLUMN BaseSalary
ADD MASKED WITH (FUNCTION = 'default()')
GO

ALTER TABLE Employees
ALTER COLUMN Email
ADD MASKED WITH (FUNCTION = 'email()')
GO

SELECT
    OBJECT_NAME(object_id) AS TableName,
    name AS ColumnName,
    masking_function AS MaskingType
FROM sys.masked_columns
GO

UPDATE SalaryHistory
SET BaseSalary = BaseSalary + 500
WHERE SalaryID = 1
GO

SELECT *
FROM AuditLogs
ORDER BY ChangedAt DESC
GO

-- ตรวจสอบ Master Key
SELECT name
FROM sys.symmetric_keys
GO

-- ตรวจสอบ Certificate
SELECT name
FROM sys.certificates
GO

-- ตรวจสอบ Symmetric Key
SELECT name
FROM sys.symmetric_keys
WHERE name = 'HRPayrollKey'
GO

-- ตรวจสอบ Data Masking
SELECT *
FROM sys.masked_columns
GO

-- ตรวจสอบ Audit Log
SELECT *
FROM AuditLogs
GO