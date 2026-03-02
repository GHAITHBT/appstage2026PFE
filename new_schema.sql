-- ============================================
-- DEPARTMENTS TABLE
-- ============================================
CREATE TABLE departments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================
-- USERS TABLE (Updated with Department & Supervisor)
-- ============================================
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'supervisor', 'technician', 'stock_agent', 'operator') NOT NULL DEFAULT 'operator',
    department_id INT NOT NULL,
    supervisor_id INT,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT,
    FOREIGN KEY (supervisor_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================
-- SUPPLIERS TABLE
-- ============================================
CREATE TABLE suppliers (
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
-- MATERIALS/PRODUCTS TABLE
-- ============================================
CREATE TABLE materials (
    id INT PRIMARY KEY AUTO_INCREMENT,
    reference VARCHAR(50) NOT NULL UNIQUE,
    designation VARCHAR(255) NOT NULL,
    code_frs VARCHAR(50),
    category VARCHAR(100),
    supplier_id INT NOT NULL,
    unit_of_measure VARCHAR(20) DEFAULT 'PCS',
    min_quantity INT NOT NULL DEFAULT 1,
    max_quantity INT NOT NULL DEFAULT 100,
    reorder_quantity INT DEFAULT 0,
    unit_price_eur DECIMAL(10, 2) NOT NULL,
    status ENUM('active', 'discontinued', 'obsolete') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    INDEX idx_reference (reference),
    INDEX idx_supplier (supplier_id)
);

-- ============================================
-- STOCK LOCATIONS TABLE
-- ============================================
CREATE TABLE stock_locations (
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
-- INVENTORY TABLE
-- ============================================
CREATE TABLE inventory (
    id INT PRIMARY KEY AUTO_INCREMENT,
    material_id INT NOT NULL,
    location_id INT NOT NULL,
    quantity_on_hand INT NOT NULL DEFAULT 0,
    quantity_reserved INT NOT NULL DEFAULT 0,
    quantity_available INT GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED,
    last_count_date TIMESTAMP,
    status ENUM('good', 'damaged', 'expired', 'quarantine') DEFAULT 'good',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_material_location (material_id, location_id),
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES stock_locations(id) ON DELETE RESTRICT,
    INDEX idx_material (material_id),
    INDEX idx_quantity (quantity_on_hand)
);

-- ============================================
-- PURCHASE ORDERS TABLE
-- ============================================
CREATE TABLE purchase_orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    po_number VARCHAR(50) NOT NULL UNIQUE,
    material_id INT NOT NULL,
    supplier_id INT NOT NULL,
    quantity_ordered INT NOT NULL,
    unit_price_eur DECIMAL(10, 2) NOT NULL,
    total_eur DECIMAL(12, 2) GENERATED ALWAYS AS (quantity_ordered * unit_price_eur) STORED,
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
-- SPARE PARTS DEMANDS TABLE
-- ============================================
CREATE TABLE spare_parts_demands (
    id INT PRIMARY KEY AUTO_INCREMENT,
    demand_number VARCHAR(50) NOT NULL UNIQUE,
    material_id INT NOT NULL,
    quantity_requested INT NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    requested_by_id INT NOT NULL,
    department_id INT NOT NULL,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    required_by_date DATE,
    demand_status ENUM('pending', 'supervisor_review', 'approved_supervisor', 'stock_agent_review', 'approved_stock_agent', 'fulfilled', 'rejected', 'cancelled') DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE RESTRICT,
    FOREIGN KEY (requested_by_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT,
    INDEX idx_demand_number (demand_number),
    INDEX idx_status (demand_status),
    INDEX idx_requested_by (requested_by_id)
);

-- ============================================
-- DEMAND APPROVALS HISTORY TABLE
-- ============================================
CREATE TABLE demand_approvals (
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
-- STOCK MOVEMENTS HISTORY TABLE
-- ============================================
CREATE TABLE stock_movements (
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
-- STOCK ALERTS TABLE
-- ============================================
CREATE TABLE stock_alerts (
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
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_demand_created_date ON spare_parts_demands(created_at);
CREATE INDEX idx_movement_type ON stock_movements(movement_type);
CREATE INDEX idx_user_department ON users(department_id);
