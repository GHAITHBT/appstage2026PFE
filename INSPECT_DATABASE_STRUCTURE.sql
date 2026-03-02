-- ============================================
-- QUERY TO VIEW CURRENT DATABASE STRUCTURE
-- ============================================
-- Run these queries in MySQL Workbench to see your current schema

-- ============================================
-- 1. LIST ALL TABLES IN DATABASE
-- ============================================
SELECT 
    TABLE_NAME,
    TABLE_TYPE,
    TABLE_COLLATION,
    ENGINE,
    TABLE_ROWS,
    DATA_LENGTH,
    INDEX_LENGTH,
    CREATE_TIME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system'
ORDER BY TABLE_NAME;

-- ============================================
-- 2. SHOW DETAILED STRUCTURE OF EACH TABLE
-- ============================================
-- Users Table Structure
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY,
    EXTRA,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'users'
ORDER BY ORDINAL_POSITION;

-- Materials Table Structure
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY,
    EXTRA,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'materials'
ORDER BY ORDINAL_POSITION;

-- Spare Parts Demands Table Structure
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY,
    EXTRA,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'spare_parts_demands'
ORDER BY ORDINAL_POSITION;

-- Inventory Table Structure
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY,
    EXTRA,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'inventory'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- 3. SHOW ALL FOREIGN KEYS IN DATABASE
-- ============================================
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'maintenance_system'
AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- ============================================
-- 4. SHOW ALL INDEXES
-- ============================================
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    NON_UNIQUE,
    INDEX_TYPE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'maintenance_system'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- ============================================
-- 5. DATA RECORD COUNTS
-- ============================================
SELECT 
    'users' as table_name,
    COUNT(*) as record_count
FROM users
UNION ALL
SELECT 
    'materials',
    COUNT(*) 
FROM materials
UNION ALL
SELECT 
    'spare_parts_demands',
    COUNT(*) 
FROM spare_parts_demands
UNION ALL
SELECT 
    'inventory',
    COUNT(*) 
FROM inventory
UNION ALL
SELECT 
    'stock_alerts',
    COUNT(*) 
FROM stock_alerts
ORDER BY table_name;

-- ============================================
-- 6. SHOW CREATE TABLE STATEMENTS
-- ============================================
-- This shows the exact CREATE TABLE syntax
SHOW CREATE TABLE users\G
SHOW CREATE TABLE materials\G
SHOW CREATE TABLE spare_parts_demands\G
SHOW CREATE TABLE inventory\G

-- ============================================
-- 7. CHECK EXISTING COLUMNS IN EACH TABLE
-- ============================================
-- Quickly check if specific columns already exist
SELECT 
    TABLE_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY COLUMN_NAME) as existing_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system'
AND TABLE_NAME IN ('users', 'materials', 'spare_parts_demands', 'inventory')
GROUP BY TABLE_NAME;

-- ============================================
-- 8. CHECK IF NEW TABLES ALREADY EXIST
-- ============================================
SELECT 
    'departments' as table_name,
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END as status
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'departments'
UNION ALL
SELECT 
    'suppliers',
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'suppliers'
UNION ALL
SELECT 
    'stock_locations',
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'stock_locations'
UNION ALL
SELECT 
    'purchase_orders',
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'purchase_orders'
UNION ALL
SELECT 
    'demand_approvals',
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'demand_approvals'
UNION ALL
SELECT 
    'stock_movements',
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'stock_movements'
UNION ALL
SELECT 
    'stock_alerts',
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'stock_alerts';

-- ============================================
-- 9. SAMPLE DATA FROM KEY TABLES
-- ============================================
-- See sample of users
SELECT * FROM users LIMIT 5;

-- See sample of materials
SELECT * FROM materials LIMIT 5;

-- See sample of demands
SELECT * FROM spare_parts_demands LIMIT 5;

-- See sample of inventory
SELECT * FROM inventory LIMIT 5;
