-- ============================================
-- MIGRATION SCRIPT - ALTER EXISTING TABLES & ADD NEW ONES
-- ============================================
-- Run this script to migrate from old schema to new enhanced schema
-- BACKUP YOUR DATABASE FIRST!

-- ============================================
-- STEP 1: CREATE NEW TABLES (if not exist)
-- ============================================

-- Create DEPARTMENTS table if it doesn't exist
CREATE TABLE IF NOT EXISTS departments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert default departments if empty
INSERT INTO departments (name, description) 
SELECT 'Unassigned', 'Default department for unassigned users'
WHERE NOT EXISTS (SELECT 1 FROM departments WHERE name = 'Unassigned');

-- ============================================
-- STEP 2: ALTER EXISTING USERS TABLE
-- ============================================

-- Add new columns to users table if they don't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS user_id VARCHAR(50) UNIQUE AFTER id;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS department_id INT AFTER role;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS supervisor_id INT AFTER department_id;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS status ENUM('active', 'inactive', 'suspended') DEFAULT 'active' AFTER supervisor_id;

-- Add foreign key constraints if they don't exist
-- Note: These will error if they already exist, which is fine
ALTER TABLE users 
ADD CONSTRAINT fk_users_department 
FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT;

ALTER TABLE users 
ADD CONSTRAINT fk_users_supervisor 
FOREIGN KEY (supervisor_id) REFERENCES users(id) ON DELETE SET NULL;

-- Update existing users with default department if NULL
UPDATE users SET department_id = (SELECT id FROM departments WHERE name = 'Unassigned') WHERE department_id IS NULL;

-- Make department_id NOT NULL after setting defaults
ALTER TABLE users 
MODIFY COLUMN department_id INT NOT NULL;

-- ============================================
-- STEP 3: ALTER/CREATE SUPPLIERS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS suppliers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL UNIQUE,
    code VARCHAR(50) UNIQUE,
    contact_person VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    country VARCHAR(50),
    payment_terms VARCHAR(100),
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================
-- STEP 4: ALTER EXISTING MATERIALS TABLE
-- ============================================

-- Add new columns to materials if they don't exist
ALTER TABLE materials 
ADD COLUMN IF NOT EXISTS code_frs VARCHAR(50) AFTER reference;

ALTER TABLE materials 
ADD COLUMN IF NOT EXISTS category VARCHAR(100) AFTER code_frs;

ALTER TABLE materials 
ADD COLUMN IF NOT EXISTS supplier_id INT AFTER category;

ALTER TABLE materials 
ADD COLUMN IF NOT EXISTS min_quantity INT DEFAULT 1 AFTER unit_of_measure;

ALTER TABLE materials 
ADD COLUMN IF NOT EXISTS max_quantity INT DEFAULT 100 AFTER min_quantity;

ALTER TABLE materials 
ADD COLUMN IF NOT EXISTS reorder_quantity INT DEFAULT 0 AFTER max_quantity;

-- Rename or ensure unit_price_eur column exists
ALTER TABLE materials 
ADD COLUMN IF NOT EXISTS unit_price_eur DECIMAL(10, 2) NOT NULL DEFAULT 0 AFTER reorder_quantity;

-- Add status if not exists
ALTER TABLE materials 
ADD COLUMN IF NOT EXISTS status ENUM('active', 'discontinued', 'obsolete') DEFAULT 'active' AFTER unit_price_eur;

-- Add supplier foreign key if not exists
ALTER TABLE materials 
ADD CONSTRAINT IF NOT EXISTS fk_materials_supplier 
FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT;

-- Add indexes for performance
ALTER TABLE materials 
ADD INDEX IF NOT EXISTS idx_reference (reference);

ALTER TABLE materials 
ADD INDEX IF NOT EXISTS idx_supplier (supplier_id);

-- ============================================
-- STEP 5: CREATE STOCK LOCATIONS TABLE (if not exists)
-- ============================================

CREATE TABLE IF NOT EXISTS stock_locations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    location_code VARCHAR(20) NOT NULL UNIQUE,
    location_name VARCHAR(100) NOT NULL,
    warehouse_zone VARCHAR(50),
    capacity INT,
    current_usage INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================
-- STEP 6: ALTER/CREATE INVENTORY TABLE
-- ============================================

-- If inventory table exists, alter it
ALTER TABLE inventory 
ADD COLUMN IF NOT EXISTS location_id INT AFTER material_id;

ALTER TABLE inventory 
ADD COLUMN IF NOT EXISTS quantity_reserved INT DEFAULT 0 AFTER quantity_on_hand;

ALTER TABLE inventory 
ADD COLUMN IF NOT EXISTS status ENUM('good', 'damaged', 'expired', 'quarantine') DEFAULT 'good' AFTER quantity_reserved;

ALTER TABLE inventory 
ADD COLUMN IF NOT EXISTS last_count_date TIMESTAMP NULL AFTER status;

-- Add foreign key for location if not exists
ALTER TABLE inventory 
ADD CONSTRAINT IF NOT EXISTS fk_inventory_location 
FOREIGN KEY (location_id) REFERENCES stock_locations(id) ON DELETE RESTRICT;

-- ============================================
-- STEP 7: ALTER/CREATE PURCHASE ORDERS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS purchase_orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    po_number VARCHAR(50) NOT NULL UNIQUE,
    material_id INT NOT NULL,
    supplier_id INT NOT NULL,
    quantity_ordered INT NOT NULL,
    unit_price_eur DECIMAL(10, 2) NOT NULL,
    order_date DATE NOT NULL,
    expected_delivery DATE,
    actual_delivery DATE,
    status ENUM('pending', 'confirmed', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    created_by_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE RESTRICT,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by_id) REFERENCES users(id),
    INDEX idx_po_number (po_number),
    INDEX idx_status (status),
    INDEX idx_material (material_id)
);

-- ============================================
-- STEP 8: ALTER/CREATE SPARE PARTS DEMANDS TABLE
-- ============================================

-- Assuming spare_parts_demands exists, alter it
ALTER TABLE spare_parts_demands 
ADD COLUMN IF NOT EXISTS requested_by_id INT AFTER id;

ALTER TABLE spare_parts_demands 
ADD COLUMN IF NOT EXISTS department_id INT AFTER requested_by_id;

ALTER TABLE spare_parts_demands 
ADD COLUMN IF NOT EXISTS required_by_date DATE AFTER request_date;

ALTER TABLE spare_parts_demands 
ADD COLUMN IF NOT EXISTS notes TEXT AFTER demand_status;

-- Add foreign key constraints
ALTER TABLE spare_parts_demands 
ADD CONSTRAINT IF NOT EXISTS fk_demands_requested_by 
FOREIGN KEY (requested_by_id) REFERENCES users(id) ON DELETE RESTRICT;

ALTER TABLE spare_parts_demands 
ADD CONSTRAINT IF NOT EXISTS fk_demands_department 
FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT;

-- Add indexes
ALTER TABLE spare_parts_demands 
ADD INDEX IF NOT EXISTS idx_demand_number (demand_number);

ALTER TABLE spare_parts_demands 
ADD INDEX IF NOT EXISTS idx_status (demand_status);

ALTER TABLE spare_parts_demands 
ADD INDEX IF NOT EXISTS idx_requested_by (requested_by_id);

ALTER TABLE spare_parts_demands 
ADD INDEX IF NOT EXISTS idx_created_date (created_at);

-- ============================================
-- STEP 9: CREATE DEMAND APPROVALS TABLE (NEW)
-- ============================================

CREATE TABLE IF NOT EXISTS demand_approvals (
    id INT PRIMARY KEY AUTO_INCREMENT,
    demand_id INT NOT NULL,
    approval_level ENUM('supervisor', 'stock_agent', 'admin') NOT NULL,
    approved_by_id INT NOT NULL,
    approval_status ENUM('approved', 'rejected', 'pending') DEFAULT 'pending',
    approval_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rejection_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (demand_id) REFERENCES spare_parts_demands(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by_id) REFERENCES users(id) ON DELETE RESTRICT,
    INDEX idx_demand (demand_id),
    INDEX idx_approved_by (approved_by_id)
);

-- ============================================
-- STEP 10: CREATE STOCK MOVEMENTS TABLE (NEW)
-- ============================================

CREATE TABLE IF NOT EXISTS stock_movements (
    id INT PRIMARY KEY AUTO_INCREMENT,
    material_id INT NOT NULL,
    location_id INT NOT NULL,
    movement_type ENUM('receipt', 'issue', 'adjustment', 'return', 'transfer', 'damage', 'expired') NOT NULL,
    quantity_change INT NOT NULL,
    reference_number VARCHAR(100),
    reference_type VARCHAR(50),
    initiated_by_id INT NOT NULL,
    approved_by_id INT,
    notes TEXT,
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE RESTRICT,
    FOREIGN KEY (location_id) REFERENCES stock_locations(id) ON DELETE RESTRICT,
    FOREIGN KEY (initiated_by_id) REFERENCES users(id),
    FOREIGN KEY (approved_by_id) REFERENCES users(id),
    INDEX idx_material (material_id),
    INDEX idx_movement_date (movement_date),
    INDEX idx_initiated_by (initiated_by_id)
);

-- ============================================
-- STEP 11: CREATE STOCK ALERTS TABLE (NEW)
-- ============================================

CREATE TABLE IF NOT EXISTS stock_alerts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    material_id INT NOT NULL,
    alert_type ENUM('low_stock', 'overstock', 'expired_soon', 'damaged', 'missing') NOT NULL,
    alert_status ENUM('active', 'acknowledged', 'resolved') DEFAULT 'active',
    description TEXT,
    acknowledged_by_id INT,
    acknowledged_date TIMESTAMP NULL,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE,
    FOREIGN KEY (acknowledged_by_id) REFERENCES users(id),
    INDEX idx_material (material_id),
    INDEX idx_status (alert_status)
);

-- ============================================
-- STEP 12: VERIFY MIGRATION
-- ============================================

-- Show table structure verification
-- Uncomment to verify after migration:
/*
SHOW COLUMNS FROM users;
SHOW COLUMNS FROM materials;
SHOW COLUMNS FROM spare_parts_demands;
SHOW TABLES LIKE '%approval%';
SHOW TABLES LIKE '%movement%';
SHOW TABLES LIKE '%alert%';

-- Check data integrity
SELECT COUNT(*) as user_count FROM users;
SELECT COUNT(*) as material_count FROM materials;
SELECT COUNT(*) as department_count FROM departments;
SELECT COUNT(*) as demand_count FROM spare_parts_demands;
*/

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- Next steps:
-- 1. Verify all tables and columns are in place
-- 2. Update your models to match new schema
-- 3. Test all functionality
-- 4. Run sample data imports if needed
