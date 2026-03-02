-- ============================================
-- FINAL MIGRATION SCRIPT - CUSTOMIZED
-- Based on actual database inspection
-- ============================================
-- Database has GOOD foundation - just needs these additions
-- Run this script step-by-step in MySQL Workbench

-- ============================================
-- STEP 1: BACKUP BEFORE RUNNING
-- ============================================
-- Option A: Via MySQL Workbench
-- 1. Right-click database → "Data Export"
-- 2. Select all tables → Export to file
-- 3. Wait for completion before proceeding

-- Option B: Via command line (if available)
-- mysqldump -u root -p maintenance_system > backup_$(date +%Y%m%d_%H%M%S).sql

-- ============================================
-- STEP 2: ADD MISSING COLUMNS TO USERS TABLE
-- ============================================

-- Add user_id column (format: TECH001, SUP001, etc)
ALTER TABLE users 
ADD COLUMN user_id VARCHAR(50) UNIQUE AFTER id;
COMMENT ON COLUMN users.user_id = 'Unique identifier like TECH001, SUP001, stock_001';

-- Add supervisor_id (self-referential foreign key)
ALTER TABLE users 
ADD COLUMN supervisor_id INT AFTER user_id;

-- Add constraint for supervisor_id
ALTER TABLE users 
ADD CONSTRAINT fk_users_supervisor 
FOREIGN KEY (supervisor_id) REFERENCES users(id) ON DELETE SET NULL;

-- Add status column for active/inactive profiles
ALTER TABLE users 
ADD COLUMN status VARCHAR(50) DEFAULT 'active' AFTER is_active;

-- Create index for user_id lookups
CREATE INDEX idx_user_id ON users(user_id);

-- Create index for supervisor_id lookups
CREATE INDEX idx_supervisor_id ON users(supervisor_id);

-- Create index for status
CREATE INDEX idx_status_users ON users(status);

-- ============================================
-- STEP 3: ADD DEPARTMENT_ID TO DEMANDS TABLE
-- ============================================

-- Add department_id as foreign key
ALTER TABLE spare_parts_demands 
ADD COLUMN department_id INT AFTER requestor_id;

-- Create index for department lookups
CREATE INDEX idx_department_demands ON spare_parts_demands(department_id);

-- ============================================
-- STEP 4: CREATE DEPARTMENTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS departments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    budget_allocated DECIMAL(15,2) DEFAULT 0,
    budget_remaining DECIMAL(15,2) DEFAULT 0,
    manager_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_department_name (name),
    INDEX idx_manager_id (manager_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 5: CREATE SUPPLIERS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS suppliers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL UNIQUE,
    contact_person VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    country VARCHAR(50),
    payment_terms VARCHAR(100),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_supplier_name (name),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 6: CREATE STOCK LOCATIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS stock_locations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    location_code VARCHAR(50) UNIQUE,
    building VARCHAR(50),
    floor INT,
    warehouse_section VARCHAR(100),
    capacity INT,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_location_code (location_code),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 7: CREATE PURCHASE ORDERS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS purchase_orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    po_number VARCHAR(50) UNIQUE NOT NULL,
    supplier_id INT NOT NULL,
    material_id INT NOT NULL,
    quantity_ordered INT NOT NULL,
    unit_price DECIMAL(10,2),
    total_cost DECIMAL(15,2),
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    status ENUM('draft','ordered','received','cancelled') DEFAULT 'draft',
    notes TEXT,
    created_by_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_po_number (po_number),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_material_id (material_id),
    INDEX idx_status (status),
    INDEX idx_order_date (order_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 8: CREATE DEMAND_APPROVALS TABLE (AUDIT TRAIL)
-- ============================================

CREATE TABLE IF NOT EXISTS demand_approvals (
    id INT PRIMARY KEY AUTO_INCREMENT,
    demand_id INT NOT NULL,
    approval_level VARCHAR(50) NOT NULL,
    approver_id INT,
    approval_status ENUM('pending','approved','rejected') DEFAULT 'pending',
    approval_date DATETIME,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (demand_id) REFERENCES spare_parts_demands(id) ON DELETE CASCADE,
    FOREIGN KEY (approver_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_demand_id (demand_id),
    INDEX idx_approver_id (approver_id),
    INDEX idx_approval_level (approval_level),
    INDEX idx_approval_status (approval_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 9: UPDATE MATERIALS TABLE REFERENCES
-- ============================================

-- Add supplier_id as foreign key (instead of just supplier name)
ALTER TABLE materials 
ADD COLUMN supplier_id INT AFTER supplier;

-- Create foreign key relationship
ALTER TABLE materials 
ADD CONSTRAINT fk_materials_supplier 
FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL;

-- Create index
CREATE INDEX idx_supplier_id_materials ON materials(supplier_id);

-- ============================================
-- STEP 10: POPULATE USER_ID FOR EXISTING USERS
-- ============================================

-- Generate user_id based on role and id
-- Format: TECH001, SUP001, ADM001, STOCK001
UPDATE users 
SET user_id = CONCAT(
    CASE role
        WHEN 'technician' THEN 'TECH'
        WHEN 'supervisor' THEN 'SUP'
        WHEN 'admin' THEN 'ADM'
        WHEN 'stock_agent' THEN 'STOCK'
        ELSE 'USR'
    END,
    LPAD(id, 3, '0')
)
WHERE user_id IS NULL;

-- ============================================
-- STEP 11: CREATE SAMPLE DEPARTMENTS
-- ============================================

INSERT INTO departments (name, description, manager_id) VALUES
('Maintenance', 'Preventive and Corrective Maintenance', NULL),
('Wiring', 'Wiring System Assembly and Repair', NULL),
('Tools & Equipment', 'Tools and Equipment Management', NULL),
('Quality Control', 'Quality Assurance and Testing', NULL)
ON DUPLICATE KEY UPDATE name = name;

-- ============================================
-- STEP 12: CREATE SAMPLE SUPPLIERS
-- ============================================

INSERT INTO suppliers (name, contact_person, email, phone, country) VALUES
('Local Supplier A', 'John Local', 'john@local.com', '+33-1-2345-6789', 'France'),
('International Supplier B', 'Marie Intl', 'marie@intl.com', '+49-89-2345-6789', 'Germany'),
('Network Solutions', 'Tech Support', 'support@network.com', '+1-800-NET-SOLV', 'USA')
ON DUPLICATE KEY UPDATE name = name;

-- ============================================
-- STEP 13: CREATE SAMPLE STOCK LOCATIONS
-- ============================================

INSERT INTO stock_locations (name, location_code, building, floor, warehouse_section) VALUES
('Main Warehouse', 'WH01', 'Building A', 1, 'Section 1'),
('Secondary Storage', 'WH02', 'Building B', 0, 'Basement'),
('Tech Lab Stock', 'WH03', 'Building A', 3, 'Lab Area')
ON DUPLICATE KEY UPDATE name = name;

-- ============================================
-- STEP 14: VERIFY MIGRATION SUCCESS
-- ============================================

-- Check 1: Users table has new columns
SELECT 'Users table structure:' as check_name;
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'users' AND TABLE_SCHEMA = 'maintenance_system'
ORDER BY ORDINAL_POSITION;

-- Check 2: Demands table has department_id
SELECT 'Demands table has department_id:' as check_name;
SELECT COUNT(*) as has_department_id 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'spare_parts_demands' AND COLUMN_NAME = 'department_id';

-- Check 3: All new tables exist
SELECT 'New tables status:' as check_name;
SELECT COUNT(*) as new_tables_created
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME IN 
('departments', 'suppliers', 'stock_locations', 'purchase_orders', 'demand_approvals');

-- Check 4: Sample data populated
SELECT 'Sample data counts:' as check_name;
SELECT 'departments' as table_name, COUNT(*) as record_count FROM departments
UNION ALL SELECT 'suppliers', COUNT(*) FROM suppliers
UNION ALL SELECT 'stock_locations', COUNT(*) FROM stock_locations
UNION ALL SELECT 'users_with_user_id', COUNT(*) FROM users WHERE user_id IS NOT NULL;

-- Check 5: User IDs generated successfully
SELECT 'User IDs assigned:' as check_name;
SELECT id, username, role, user_id FROM users LIMIT 5;

-- ============================================
-- MIGRATION COMPLETE!
-- ============================================
-- Next steps:
-- 1. Update Flask models (copy updated_models.py)
-- 2. Update routes to use new columns
-- 3. Edit migration_populate_data.sql with your actual org structure
-- 4. Run migration_populate_data.sql to customize

-- ============================================
-- ROLLBACK (if something goes wrong)
-- ============================================
-- Restore from backup:
-- 1. In MySQL Workbench, right-click database
-- 2. Select "Data Import/Restore"
-- 3. Choose backup file you created in STEP 1
-- 4. Click "Start Import"
