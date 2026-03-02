-- ============================================
-- PRE-MIGRATION DIAGNOSTIC
-- Check what tables exist and what's missing
-- ============================================
-- Run this BEFORE running MIGRATION_FINAL.sql
-- This tells you exactly what needs to be created

-- Check 1: Which new tables are MISSING?
SELECT 'MISSING TABLES' as status;
SELECT table_name FROM (
    SELECT 'departments' as table_name
    UNION ALL SELECT 'suppliers'
    UNION ALL SELECT 'stock_locations'
    UNION ALL SELECT 'purchase_orders'
    UNION ALL SELECT 'demand_approvals'
) needed_tables
WHERE table_name NOT IN (
    SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'maintenance_system'
);

-- Check 2: Which new COLUMNS are missing from users table?
SELECT 'MISSING USERS COLUMNS' as status;
SELECT column_needed FROM (
    SELECT 'user_id' as column_needed
    UNION ALL SELECT 'supervisor_id'
    UNION ALL SELECT 'status'
) needed_cols
WHERE column_needed NOT IN (
    SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'users' AND TABLE_SCHEMA = 'maintenance_system'
);

-- Check 3: Does spare_parts_demands have department_id?
SELECT 'MISSING DEMANDS COLUMNS' as status;
SELECT 'department_id' as column_needed
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'spare_parts_demands' 
  AND COLUMN_NAME = 'department_id'
  AND TABLE_SCHEMA = 'maintenance_system'
HAVING COUNT(*) = 0;

-- Check 4: What tables DO exist?
SELECT 'EXISTING TABLES' as status;
SELECT TABLE_NAME, TABLE_ROWS as record_count
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system'
ORDER BY TABLE_NAME;

-- Check 5: Current users that will get user_id
SELECT 'CURRENT USERS' as status;
SELECT id, username, role, 
       CASE 
           WHEN user_id IS NOT NULL THEN CONCAT('✓ ', user_id)
           ELSE '✗ NEEDS user_id'
       END as status
FROM users
ORDER BY role;
