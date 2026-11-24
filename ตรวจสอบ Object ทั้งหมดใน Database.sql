USE HR_Payroll_DB
GO

-- Stored Procedures
SELECT 
    name AS ObjectName,
    create_date,
    modify_date
FROM sys.objects
WHERE type = 'P'
ORDER BY name
GO

-- Triggers
SELECT 
    name AS TriggerName,
    create_date,
    modify_date
FROM sys.triggers
WHERE parent_class = 1
ORDER BY name
GO

-- Functions
SELECT 
    name AS FunctionName,
    create_date,
    modify_date
FROM sys.objects
WHERE type IN ('FN', 'IF', 'TF')
ORDER BY name
GO

-- Views
SELECT 
    name AS ViewName,
    create_date,
    modify_date
FROM sys.views
ORDER BY name
GO