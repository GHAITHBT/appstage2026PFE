-- ============================================
-- SMART MIGRATION - ONLY ADDS WHAT'S MISSING
-- Safe to run multiple times
-- ============================================

-- ============================================
-- STEP 1: CHECK WHAT ALREADY EXISTS
-- ============================================
SELECT 'CURRENT STATE' as section;

-- Check users table columns
SELECT 'Users columns:' as info;
SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION SEPARATOR ', ') as existing_columns
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'users' AND TABLE_SCHEMA = 'maintenance_system';

-- Check existing tables
SELECT 'Tables that exist:' as info;
SELECT GROUP_CONCAT(TABLE_NAME ORDER BY TABLE_NAME SEPARATOR ', ') as existing_tables
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME IN 
('departments', 'suppliers', 'stock_locations', 'purchase_orders', 'demand_approvals');

-- ============================================
-- STEP 2: ADD MISSING COLUMNS TO USERS (if not exists)
-- ============================================

-- Add supervisor_id if missing
ALTER TABLE users ADD COLUMN supervisor_id INT AFTER user_id;

-- Add status if missing
ALTER TABLE users ADD COLUMN status VARCHAR(50) DEFAULT 'active' AFTER is_active;

-- Add foreign key constraint if not exists
ALTER TABLE users 
ADD CONSTRAINT fk_users_supervisor FOREIGN KEY (supervisor_id) REFERENCES users(id) ON DELETE SET NULL;

-- Create indexes if not exists
CREATE INDEX idx_user_id ON users(user_id);
CREATE INDEX idx_supervisor_id ON users(supervisor_id);
CREATE INDEX idx_status_users ON users(status);

-- ============================================
-- STEP 3: ADD DEPARTMENT_ID TO DEMANDS (if missing)
-- ============================================

-- Add department_id to spare_parts_demands if missing
ALTER TABLE spare_parts_demands ADD COLUMN department_id INT AFTER requestor_id;

-- Create index
CREATE INDEX idx_department_demands ON spare_parts_demands(department_id);

-- ============================================
-- STEP 4: CREATE DEPARTMENTS TABLE (if missing)
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
-- STEP 5: CREATE SUPPLIERS TABLE (if missing)
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
-- STEP 6: CREATE STOCK_LOCATIONS TABLE (if missing)
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
-- STEP 7: CREATE PURCHASE_ORDERS TABLE (if missing)
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
-- STEP 8: CREATE DEMAND_APPROVALS TABLE (if missing)
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
-- STEP 9: ADD SUPPLIER_ID TO MATERIALS (if missing)
-- ============================================

ALTER TABLE materials ADD COLUMN supplier_id INT AFTER supplier;

-- Create foreign key if not exists
ALTER TABLE materials 
ADD CONSTRAINT fk_materials_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL;

-- Create index
CREATE INDEX idx_supplier_id_materials ON materials(supplier_id);

-- ============================================
-- STEP 10: POPULATE USER_ID FOR EXISTING USERS (if not already done)
-- ============================================

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
-- STEP 11: POPULATE DEPARTMENTS (if empty)
-- ============================================

INSERT IGNORE INTO departments (id, name, description) VALUES
(1, 'Maintenance', 'Preventive and Corrective Maintenance'),
(2, 'Wiring', 'Wiring System Assembly and Repair'),
(3, 'Tools & Equipment', 'Tools and Equipment Management'),
(4, 'Quality Control', 'Quality Assurance and Testing');

-- ============================================
-- STEP 12: POPULATE SUPPLIERS (if empty)
-- ============================================

INSERT IGNORE INTO suppliers (id, name, contact_person, email, phone, country) VALUES
(1, 'Local Supplier A', 'John Local', 'john@local.com', '+33-1-2345-6789', 'France'),
(2, 'International Supplier B', 'Marie Intl', 'marie@intl.com', '+49-89-2345-6789', 'Germany'),
(3, 'Network Solutions', 'Tech Support', 'support@network.com', '+1-800-NET-SOLV', 'USA');

-- ============================================
-- STEP 13: POPULATE STOCK LOCATIONS (if empty)
-- ============================================

INSERT IGNORE INTO stock_locations (id, name, location_code, building, floor, warehouse_section) VALUES
(1, 'Main Warehouse', 'WH01', 'Building A', 1, 'Section 1'),
(2, 'Secondary Storage', 'WH02', 'Building B', 0, 'Basement'),
(3, 'Tech Lab Stock', 'WH03', 'Building A', 3, 'Lab Area');

-- ============================================
-- STEP 14: VERIFY MIGRATION SUCCESS
-- ============================================

SELECT '✓ MIGRATION VERIFICATION' as section;

-- Verify users columns
SELECT 'Users table columns:' as verification;
SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION SEPARATOR ', ') as columns
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'users' AND TABLE_SCHEMA = 'maintenance_system';

-- Verify new tables exist
SELECT 'New tables created:' as verification;
SELECT COUNT(*) as table_count, GROUP_CONCAT(TABLE_NAME ORDER BY TABLE_NAME SEPARATOR ', ') as tables
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME IN 
('departments', 'suppliers', 'stock_locations', 'purchase_orders', 'demand_approvals');

-- Verify user_ids assigned
SELECT 'Users with user_id:' as verification;
SELECT COUNT(*) as total, 
       SUM(CASE WHEN user_id IS NOT NULL THEN 1 ELSE 0 END) as with_id,
       SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) as without_id
FROM users;

-- Sample user_ids
SELECT 'Sample user IDs:' as verification;
SELECT id, username, role, user_id FROM users LIMIT 5;

-- Sample data counts
SELECT 'Sample data:' as verification;
SELECT 'departments' as table_name, COUNT(*) as records FROM departments
UNION ALL SELECT 'suppliers', COUNT(*) FROM suppliers
UNION ALL SELECT 'stock_locations', COUNT(*) FROM stock_locations
UNION ALL SELECT 'purchase_orders', COUNT(*) FROM purchase_orders
UNION ALL SELECT 'demand_approvals', COUNT(*) FROM demand_approvals;

-- Material-supplier linkage
SELECT 'Materials with suppliers linked:' as verification;
SELECT 
    COUNT(*) as total_materials,
    SUM(CASE WHEN supplier_id IS NOT NULL THEN 1 ELSE 0 END) as linked,
    SUM(CASE WHEN supplier_id IS NULL THEN 1 ELSE 0 END) as unlinked
FROM materials;

-- ============================================
-- ✓ MIGRATION IS NOW COMPLETE!
-- ============================================
-- Next: Run DATA_POPULATION.sql to customize your org
