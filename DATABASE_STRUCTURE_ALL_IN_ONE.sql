-- ============================================
-- COMPLETE DATABASE STRUCTURE INSPECTION
-- ALL IN ONE QUERY FILE - RUN ALL AT ONCE
-- ============================================
-- Copy entire file and paste into MySQL Workbench
-- Select all (Ctrl+A) and run (Ctrl+Enter)

-- ============================================
-- OVERVIEW: All Tables with Details
-- ============================================
SELECT 
    'TABLES_OVERVIEW' as section,
    TABLE_NAME,
    TABLE_TYPE,
    ENGINE,
    TABLE_ROWS as record_count,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) as size_mb,
    CREATE_TIME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system'
ORDER BY TABLE_NAME;

-- ============================================
-- USERS TABLE: Complete Structure
-- ============================================
SELECT 
    'USERS_COLUMNS' as section,
    ORDINAL_POSITION as position,
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY as key_type,
    COLUMN_DEFAULT,
    EXTRA
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'users'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- MATERIALS TABLE: Complete Structure
-- ============================================
SELECT 
    'MATERIALS_COLUMNS' as section,
    ORDINAL_POSITION as position,
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY as key_type,
    COLUMN_DEFAULT,
    EXTRA
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'materials'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- SPARE PARTS DEMANDS TABLE: Complete Structure
-- ============================================
SELECT 
    'DEMANDS_COLUMNS' as section,
    ORDINAL_POSITION as position,
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY as key_type,
    COLUMN_DEFAULT,
    EXTRA
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'spare_parts_demands'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- INVENTORY TABLE: Complete Structure
-- ============================================
SELECT 
    'INVENTORY_COLUMNS' as section,
    ORDINAL_POSITION as position,
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY as key_type,
    COLUMN_DEFAULT,
    EXTRA
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'inventory'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- ALL FOREIGN KEYS
-- ============================================
SELECT 
    'FOREIGN_KEYS' as section,
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'maintenance_system'
AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- ============================================
-- ALL INDEXES
-- ============================================
SELECT 
    'INDEXES' as section,
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    CASE WHEN NON_UNIQUE = 0 THEN 'UNIQUE' ELSE 'NON-UNIQUE' END as uniqueness,
    INDEX_TYPE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'maintenance_system'
AND INDEX_NAME != 'PRIMARY'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- ============================================
-- RECORD COUNTS IN MAIN TABLES
-- ============================================
SELECT 
    'RECORD_COUNTS' as section,
    'users' as table_name,
    COUNT(*) as count
FROM users
UNION ALL
SELECT 'RECORD_COUNTS', 'materials', COUNT(*) FROM materials
UNION ALL
SELECT 'RECORD_COUNTS', 'spare_parts_demands', COUNT(*) FROM spare_parts_demands
UNION ALL
SELECT 'RECORD_COUNTS', 'inventory', COUNT(*) FROM inventory
UNION ALL
SELECT 'RECORD_COUNTS', 'stock_alerts', COUNT(*) FROM stock_alerts
ORDER BY table_name;

-- ============================================
-- NEW TABLES STATUS
-- ============================================
SELECT 
    'NEW_TABLES_STATUS' as section,
    COALESCE(t.TABLE_NAME, tc.table_to_check) as table_name,
    CASE WHEN t.TABLE_NAME IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END as status
FROM (
    SELECT 'departments' as table_to_check
    UNION ALL SELECT 'suppliers'
    UNION ALL SELECT 'stock_locations'
    UNION ALL SELECT 'purchase_orders'
    UNION ALL SELECT 'demand_approvals'
    UNION ALL SELECT 'stock_movements'
) tc
LEFT JOIN INFORMATION_SCHEMA.TABLES t 
    ON t.TABLE_NAME = tc.table_to_check 
    AND t.TABLE_SCHEMA = 'maintenance_system'
ORDER BY tc.table_to_check;

-- ============================================
-- SAMPLE DATA: Users
-- ============================================
SELECT 'SAMPLE_USERS' as section, * FROM users LIMIT 3;

-- ============================================
-- SAMPLE DATA: Materials
-- ============================================
SELECT 'SAMPLE_MATERIALS' as section, * FROM materials LIMIT 3;

-- ============================================
-- SAMPLE DATA: Demands
-- ============================================
SELECT 'SAMPLE_DEMANDS' as section, * FROM spare_parts_demands LIMIT 3;

-- ============================================
-- SAMPLE DATA: Inventory
-- ============================================
SELECT 'SAMPLE_INVENTORY' as section, * FROM inventory LIMIT 3;

-- ============================================
-- DETAILED COLUMN ANALYSIS
-- ============================================
SELECT 
    'COLUMN_ANALYSIS' as section,
    TABLE_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION SEPARATOR ', ') as all_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system'
AND TABLE_NAME IN ('users', 'materials', 'spare_parts_demands', 'inventory')
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- ============================================
-- MISSING COLUMNS IDENTIFICATION
-- ============================================
SELECT 
    'ANALYSIS_USERS' as section,
    'user_id' as column_needed,
    CASE WHEN COLUMN_NAME IS NOT NULL THEN 'EXISTS' ELSE 'MISSING - ADD IT' END as status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'users' AND COLUMN_NAME = 'user_id'
UNION ALL
SELECT 'ANALYSIS_USERS', 'department_id', CASE WHEN COLUMN_NAME IS NOT NULL THEN 'EXISTS' ELSE 'MISSING - ADD IT' END
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'users' AND COLUMN_NAME = 'department_id'
UNION ALL
SELECT 'ANALYSIS_USERS', 'supervisor_id', CASE WHEN COLUMN_NAME IS NOT NULL THEN 'EXISTS' ELSE 'MISSING - ADD IT' END
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'users' AND COLUMN_NAME = 'supervisor_id'
UNION ALL
SELECT 'ANALYSIS_USERS', 'status', CASE WHEN COLUMN_NAME IS NOT NULL THEN 'EXISTS' ELSE 'MISSING - ADD IT' END
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'users' AND COLUMN_NAME = 'status'
UNION ALL
SELECT 'ANALYSIS_MATERIALS', 'supplier_id', CASE WHEN COLUMN_NAME IS NOT NULL THEN 'EXISTS' ELSE 'MISSING - ADD IT' END
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'materials' AND COLUMN_NAME = 'supplier_id'
UNION ALL
SELECT 'ANALYSIS_MATERIALS', 'min_quantity', CASE WHEN COLUMN_NAME IS NOT NULL THEN 'EXISTS' ELSE 'MISSING - ADD IT' END
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'materials' AND COLUMN_NAME = 'min_quantity'
UNION ALL
SELECT 'ANALYSIS_MATERIALS', 'max_quantity', CASE WHEN COLUMN_NAME IS NOT NULL THEN 'EXISTS' ELSE 'MISSING - ADD IT' END
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'materials' AND COLUMN_NAME = 'max_quantity'
UNION ALL
SELECT 'ANALYSIS_MATERIALS', 'unit_price_eur', CASE WHEN COLUMN_NAME IS NOT NULL THEN 'EXISTS' ELSE 'MISSING - ADD IT' END
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'materials' AND COLUMN_NAME = 'unit_price_eur'
UNION ALL
SELECT 'ANALYSIS_DEMANDS', 'requested_by_id', CASE WHEN COLUMN_NAME IS NOT NULL THEN 'EXISTS' ELSE 'MISSING - ADD IT' END
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'spare_parts_demands' AND COLUMN_NAME = 'requested_by_id'
UNION ALL
SELECT 'ANALYSIS_DEMANDS', 'department_id', CASE WHEN COLUMN_NAME IS NOT NULL THEN 'EXISTS' ELSE 'MISSING - ADD IT' END
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'spare_parts_demands' AND COLUMN_NAME = 'department_id';

-- ============================================
-- COMPREHENSIVE SUMMARY
-- ============================================
SELECT 
    'SUMMARY' as section,
    CONCAT('Total Tables: ', (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'maintenance_system')) as info
UNION ALL
SELECT 'SUMMARY', CONCAT('Total Users: ', COUNT(*)) FROM users
UNION ALL
SELECT 'SUMMARY', CONCAT('Total Materials: ', COUNT(*)) FROM materials
UNION ALL
SELECT 'SUMMARY', CONCAT('Total Demands: ', COUNT(*)) FROM spare_parts_demands
UNION ALL
SELECT 'SUMMARY', CONCAT('Database: maintenance_system'), NULL;
