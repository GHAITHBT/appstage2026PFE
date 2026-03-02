-- ============================================
-- SAFE MIGRATION - HANDLES PARTIAL RUNS
-- Checks existence before adding anything
-- ============================================

-- ============================================
-- STEP 1: ADD MISSING COLUMNS SAFELY
-- (Only if they don't already exist)
-- ============================================

-- Add supervisor_id if missing (check first)
SELECT IF(COUNT(*) = 0, 
    'ALTER TABLE users ADD COLUMN supervisor_id INT AFTER user_id',
    'supervisor_id already exists - skipping')
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'supervisor_id' AND TABLE_SCHEMA = 'maintenance_system';

-- Actually add it
ALTER TABLE users ADD COLUMN supervisor_id INT AFTER user_id;

-- Add status if missing
ALTER TABLE users ADD COLUMN status VARCHAR(50) DEFAULT 'active' AFTER is_active;

-- Add foreign key constraint (ignore if exists)
ALTER TABLE users 
ADD CONSTRAINT fk_users_supervisor FOREIGN KEY (supervisor_id) REFERENCES users(id) ON DELETE SET NULL;

-- Create indexes (ignore if exist)
CREATE INDEX idx_user_id ON users(user_id);
CREATE INDEX idx_supervisor_id ON users(supervisor_id);
CREATE INDEX idx_status_users ON users(status);

-- ============================================
-- STEP 2: ADD DEPARTMENT_ID TO DEMANDS
-- ============================================

ALTER TABLE spare_parts_demands ADD COLUMN department_id INT AFTER requestor_id;

CREATE INDEX idx_department_demands ON spare_parts_demands(department_id);

-- ============================================
-- STEP 3-8: CREATE MISSING TABLES
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
-- STEP 9: ADD SUPPLIER_ID TO MATERIALS
-- ============================================

ALTER TABLE materials ADD COLUMN supplier_id INT AFTER supplier;

ALTER TABLE materials 
ADD CONSTRAINT fk_materials_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL;

CREATE INDEX idx_supplier_id_materials ON materials(supplier_id);

-- ============================================
-- STEP 10: POPULATE USER_ID FOR EXISTING USERS
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
-- STEP 11-13: POPULATE SAMPLE DATA
-- ============================================

INSERT IGNORE INTO departments (id, name, description) VALUES
(1, 'Maintenance', 'Preventive and Corrective Maintenance'),
(2, 'Wiring', 'Wiring System Assembly and Repair'),
(3, 'Tools & Equipment', 'Tools and Equipment Management'),
(4, 'Quality Control', 'Quality Assurance and Testing');

INSERT IGNORE INTO suppliers (id, name, contact_person, email, phone, country) VALUES
(1, 'Local Supplier A', 'John Local', 'john@local.com', '+33-1-2345-6789', 'France'),
(2, 'International Supplier B', 'Marie Intl', 'marie@intl.com', '+49-89-2345-6789', 'Germany'),
(3, 'Network Solutions', 'Tech Support', 'support@network.com', '+1-800-NET-SOLV', 'USA');

INSERT IGNORE INTO stock_locations (id, name, location_code, building, floor, warehouse_section) VALUES
(1, 'Main Warehouse', 'WH01', 'Building A', 1, 'Section 1'),
(2, 'Secondary Storage', 'WH02', 'Building B', 0, 'Basement'),
(3, 'Tech Lab Stock', 'WH03', 'Building A', 3, 'Lab Area');

-- ============================================
-- STEP 14: VERIFY MIGRATION SUCCESS
-- ============================================

SELECT '✓ MIGRATION VERIFICATION' as verification_section;

SELECT 'Users table structure:' as info;
SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION SEPARATOR ', ') as columns
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'users' AND TABLE_SCHEMA = 'maintenance_system';

SELECT 'New tables created:' as info;
SELECT COUNT(*) as table_count
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME IN 
('departments', 'suppliers', 'stock_locations', 'purchase_orders', 'demand_approvals');

SELECT 'Users with user_id:' as info;
SELECT COUNT(*) as total_users, 
       SUM(CASE WHEN user_id IS NOT NULL THEN 1 ELSE 0 END) as assigned,
       SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) as not_assigned
FROM users;

SELECT 'Sample user IDs:' as info;
SELECT id, username, role, user_id, status FROM users LIMIT 5;

SELECT 'Departments created:' as info;
SELECT COUNT(*) as total FROM departments;

SELECT 'Suppliers created:' as info;
SELECT COUNT(*) as total FROM suppliers;

SELECT 'Stock locations created:' as info;
SELECT COUNT(*) as total FROM stock_locations;

SELECT '✓ MIGRATION COMPLETE!' as message;
