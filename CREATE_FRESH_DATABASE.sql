-- ============================================
-- COMPLETE DATABASE CREATION FROM SCRATCH
-- Fresh database with all tables and data
-- ============================================
-- Run this script to create brand new database
-- No cleanup needed - creates everything fresh

-- ============================================
-- STEP 1: DROP OLD DATABASE (if it exists)
-- ============================================
DROP DATABASE IF EXISTS maintenance_system_v2;

-- ============================================
-- STEP 2: CREATE NEW DATABASE
-- ============================================
CREATE DATABASE maintenance_system_v2 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE maintenance_system_v2;

-- ============================================
-- STEP 3: CREATE USERS TABLE
-- ============================================
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(50) UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role ENUM('admin','supervisor','technician','stock_agent') NOT NULL DEFAULT 'technician',
    department VARCHAR(100),
    zone VARCHAR(100),
    is_active TINYINT(1) DEFAULT 1,
    status VARCHAR(50) DEFAULT 'active',
    supervisor_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supervisor_id) REFERENCES users(id) ON DELETE SET NULL,
    KEY idx_user_id (user_id),
    KEY idx_supervisor_id (supervisor_id),
    KEY idx_status_users (status),
    KEY idx_role (role),
    KEY idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 4: CREATE DEPARTMENTS TABLE
-- ============================================
CREATE TABLE departments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    budget_allocated DECIMAL(15,2) DEFAULT 0,
    budget_remaining DECIMAL(15,2) DEFAULT 0,
    manager_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE SET NULL,
    KEY idx_department_name (name),
    KEY idx_manager_id (manager_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 5: CREATE ZONES TABLE
-- ============================================
CREATE TABLE zones (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_by_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL,
    KEY ix_zones_name (name),
    KEY created_by_id (created_by_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 6: CREATE MACHINES TABLE
-- ============================================
CREATE TABLE machines (
    id INT PRIMARY KEY AUTO_INCREMENT,
    machine_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(200),
    description TEXT,
    location VARCHAR(200),
    department VARCHAR(100),
    model VARCHAR(100),
    manufacturer VARCHAR(100),
    purchase_date DATE,
    installation_date DATE,
    status VARCHAR(50) DEFAULT 'operational',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_department (department),
    KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 7: CREATE SUPPLIERS TABLE
-- ============================================
CREATE TABLE suppliers (
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
    KEY idx_supplier_name (name),
    KEY idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 8: CREATE MATERIALS TABLE
-- ============================================
CREATE TABLE materials (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    unit VARCHAR(50),
    min_stock INT DEFAULT 10,
    max_stock INT DEFAULT 100,
    current_stock INT DEFAULT 0,
    reorder_point INT,
    unit_cost DECIMAL(10,2),
    supplier VARCHAR(100),
    supplier_id INT,
    last_restocked TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
    KEY idx_category (category),
    KEY idx_stock_level (current_stock),
    KEY idx_supplier_id_materials (supplier_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 9: CREATE STOCK_LOCATIONS TABLE
-- ============================================
CREATE TABLE stock_locations (
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
    KEY idx_location_code (location_code),
    KEY idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 10: CREATE MAINTENANCE_TEMPLATES TABLE
-- ============================================
CREATE TABLE maintenance_templates (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(150),
    description TEXT,
    frequency INT,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    KEY idx_name (name),
    KEY created_by (created_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 11: CREATE MAINTENANCE_SCHEDULES TABLE
-- ============================================
CREATE TABLE maintenance_schedules (
    id INT PRIMARY KEY AUTO_INCREMENT,
    machine_id INT NOT NULL,
    schedule_type VARCHAR(50),
    frequency_days INT,
    scheduled_date DATE NOT NULL,
    description TEXT,
    estimated_duration_hours INT,
    assigned_supervisor_id INT NOT NULL,
    status VARCHAR(50) DEFAULT 'scheduled',
    priority VARCHAR(50) DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (machine_id) REFERENCES machines(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_supervisor_id) REFERENCES users(id) ON DELETE CASCADE,
    KEY idx_machine_id (machine_id),
    KEY idx_scheduled_date (scheduled_date),
    KEY idx_status (status),
    KEY assigned_supervisor_id (assigned_supervisor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 12: CREATE MAINTENANCE_REPORTS TABLE
-- ============================================
CREATE TABLE maintenance_reports (
    id INT PRIMARY KEY AUTO_INCREMENT,
    schedule_id INT NOT NULL,
    technician_id INT NOT NULL,
    machine_name VARCHAR(200),
    actual_start_time DATETIME,
    actual_end_time DATETIME,
    actual_duration_hours FLOAT,
    work_description TEXT,
    findings TEXT,
    actions_taken TEXT,
    issues_found TINYINT(1) DEFAULT 0,
    issue_description TEXT,
    components_replaced TEXT,
    next_maintenance_recommendation TEXT,
    report_type VARCHAR(50) DEFAULT 'standard',
    report_status VARCHAR(50) DEFAULT 'draft',
    technician_zone VARCHAR(100),
    machine_condition VARCHAR(50),
    machine_condition_after VARCHAR(50),
    environmental_conditions TEXT,
    safety_observations TEXT,
    tools_used TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (schedule_id) REFERENCES maintenance_schedules(id) ON DELETE CASCADE,
    FOREIGN KEY (technician_id) REFERENCES users(id) ON DELETE CASCADE,
    KEY schedule_id (schedule_id),
    KEY idx_technician_id (technician_id),
    KEY idx_status (report_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 13: CREATE SPARE_PARTS_DEMANDS TABLE
-- ============================================
CREATE TABLE spare_parts_demands (
    id INT PRIMARY KEY AUTO_INCREMENT,
    demand_number VARCHAR(50) NOT NULL UNIQUE,
    maintenance_report_id INT,
    requestor_id INT NOT NULL,
    department_id INT,
    material_id INT NOT NULL,
    quantity_requested INT NOT NULL,
    priority ENUM('low','medium','high','urgent') DEFAULT 'medium',
    reason TEXT,
    supervisor_id INT,
    supervisor_approval ENUM('pending','approved','rejected') DEFAULT 'pending',
    supervisor_approval_date DATETIME,
    supervisor_notes TEXT,
    stock_agent_id INT,
    stock_agent_approval ENUM('pending','approved','rejected','partial') DEFAULT 'pending',
    stock_agent_approval_date DATETIME,
    quantity_allocated INT,
    stock_agent_notes TEXT,
    quantity_returned INT DEFAULT 0,
    return_date DATETIME,
    return_notes TEXT,
    demand_status ENUM('pending','supervisor_review','approved_supervisor','stock_agent_review','approved_stock_agent','rejected','partial_allocated','fulfilled') DEFAULT 'pending',
    fulfilled_date DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (maintenance_report_id) REFERENCES maintenance_reports(id) ON DELETE SET NULL,
    FOREIGN KEY (requestor_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE,
    FOREIGN KEY (supervisor_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (stock_agent_id) REFERENCES users(id) ON DELETE SET NULL,
    KEY idx_created_at (created_at),
    KEY idx_demands_status (demand_status),
    KEY idx_material_id (material_id),
    KEY requestor_id (requestor_id),
    KEY supervisor_id (supervisor_id),
    KEY stock_agent_id (stock_agent_id),
    KEY idx_department_demands (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 14: CREATE DEMAND_APPROVALS TABLE (AUDIT TRAIL)
-- ============================================
CREATE TABLE demand_approvals (
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
    KEY idx_demand_id (demand_id),
    KEY idx_approver_id (approver_id),
    KEY idx_approval_level (approval_level),
    KEY idx_approval_status (approval_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 15: CREATE MATERIAL_RETURNS TABLE
-- ============================================
CREATE TABLE material_returns (
    id INT PRIMARY KEY AUTO_INCREMENT,
    demand_id INT,
    material_id INT,
    quantity_returned INT NOT NULL,
    return_condition VARCHAR(100),
    reason_for_return TEXT,
    returned_by_id INT,
    received_by_id INT,
    return_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (demand_id) REFERENCES spare_parts_demands(id) ON DELETE SET NULL,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE SET NULL,
    FOREIGN KEY (returned_by_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (received_by_id) REFERENCES users(id) ON DELETE SET NULL,
    KEY ix_material_returns_created_at (created_at),
    KEY ix_material_returns_demand_id (demand_id),
    KEY ix_material_returns_status (return_status),
    KEY material_id (material_id),
    KEY received_by_id (received_by_id),
    KEY returned_by_id (returned_by_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 16: CREATE STOCK_MOVEMENTS TABLE
-- ============================================
CREATE TABLE stock_movements (
    id INT PRIMARY KEY AUTO_INCREMENT,
    material_id INT NOT NULL,
    user_id INT,
    movement_type VARCHAR(50) NOT NULL,
    quantity INT NOT NULL,
    reference_id VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    KEY idx_created_at (created_at),
    KEY idx_material_id (material_id),
    KEY idx_movement_type (movement_type),
    KEY idx_stock_movements_material (material_id),
    KEY user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 17: CREATE STOCK_ALERTS TABLE
-- ============================================
CREATE TABLE stock_alerts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    material_id INT NOT NULL,
    alert_type VARCHAR(50),
    alert_message TEXT,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE,
    KEY idx_created_at (created_at),
    KEY idx_is_read (is_read),
    KEY idx_material_id (material_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 18: CREATE PURCHASE_ORDERS TABLE
-- ============================================
CREATE TABLE purchase_orders (
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
    KEY idx_po_number (po_number),
    KEY idx_supplier_id (supplier_id),
    KEY idx_material_id (material_id),
    KEY idx_status (status),
    KEY idx_order_date (order_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 19: CREATE DASHBOARD_KPIS TABLE
-- ============================================
CREATE TABLE dashboard_kpis (
    id INT PRIMARY KEY AUTO_INCREMENT,
    kpi_name VARCHAR(100),
    kpi_value INT,
    kpi_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_kpi_name (kpi_name),
    KEY idx_kpi_date (kpi_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 20: INSERT SAMPLE USERS
-- ============================================
INSERT INTO users (user_id, username, password, email, first_name, last_name, role, status, is_active) VALUES
('ADM001', 'admin', 'pbkdf2:sha256:260000$XXXXX', 'admin@company.com', 'Admin', 'User', 'admin', 'active', 1),
('SUP001', 'supervisor1', 'pbkdf2:sha256:260000$XXXXX', 'supervisor1@company.com', 'Jean', 'Dupont', 'supervisor', 'active', 1),
('TECH001', 'technician1', 'pbkdf2:sha256:260000$XXXXX', 'tech1@company.com', 'Pierre', 'Martin', 'technician', 'active', 1),
('STOCK001', 'stocking', 'pbkdf2:sha256:260000$XXXXX', 'stock@company.com', 'Marie', 'Garcia', 'stock_agent', 'active', 1);

-- ============================================
-- STEP 21: INSERT SAMPLE DEPARTMENTS
-- ============================================
INSERT INTO departments (name, description, budget_allocated, budget_remaining) VALUES
('Maintenance', 'Preventive and Corrective Maintenance', 50000.00, 50000.00),
('Wiring', 'Wiring System Assembly and Repair', 75000.00, 75000.00),
('Tools & Equipment', 'Tools and Equipment Management', 30000.00, 30000.00),
('Quality Control', 'Quality Assurance and Testing', 40000.00, 40000.00),
('Electrical', 'Electrical Systems and Components', 60000.00, 60000.00);

-- ============================================
-- STEP 22: INSERT SUPPLIERS (From Real Data)
-- ============================================
INSERT INTO suppliers (name, contact_person, email, phone, city, country, payment_terms, is_active) VALUES
('ATF TECHNOLOGIE', '', '', '', '', 'France', 'Net 30', 1),
('HARTECH INTERNATIONAL', '', '', '', '', 'France', 'Net 30', 1),
('Komax Tunisia', '', '', '', 'Tunisia', 'Tunisia', 'Net 30', 1),
('Boudrant', '', '', '', '', 'France', 'Net 30', 1),
('MOHAMED MELKI TOURNAGE FRAISAGE', '', '', '', 'Tunisia', 'Tunisia', 'Net 30', 1),
('Mibostahl GmbH', '', '', '', '', 'Germany', 'Net 45', 1);

-- ============================================
-- STEP 23: INSERT SAMPLE ZONES
-- ============================================
INSERT INTO zones (name, description, created_by_id) VALUES
('Zone A', 'Main Production Area', 1),
('Zone B', 'Assembly Area', 1),
('Zone C', 'Testing Area', 1);

-- ============================================
-- STEP 24: INSERT SAMPLE MACHINES
-- ============================================
INSERT INTO machines (machine_code, name, description, location, department, model, manufacturer, purchase_date, installation_date, status) VALUES
('MACH001', 'Assembly Line 1', 'Main assembly line', 'Zone A', 'Wiring', 'AL-2000', 'Komax', '2022-01-15', '2022-02-01', 'operational'),
('MACH002', 'Testing Station', 'Quality testing equipment', 'Zone C', 'Quality Control', 'TS-500', 'Advantest', '2021-06-20', '2021-07-15', 'operational'),
('MACH003', 'Winding Machine', 'Wire winding machine', 'Zone B', 'Wiring', 'WM-300', 'Schleifring', '2023-03-10', '2023-04-01', 'operational');

-- ============================================
-- STEP 25: INSERT SAMPLE STOCK LOCATIONS
-- ============================================
INSERT INTO stock_locations (name, location_code, building, floor, warehouse_section, capacity) VALUES
('Main Warehouse', 'WH001', 'Building A', 1, 'Storage Room A', 5000),
('Secondary Storage', 'WH002', 'Building B', 0, 'Basement Level 1', 3000),
('Tech Lab Stock', 'WH003', 'Building A', 3, 'Lab Area - Secure Storage', 500);

-- ============================================
-- STEP 25.5: INSERT SAMPLE MAINTENANCE SCHEDULES
-- ============================================
INSERT INTO maintenance_schedules (machine_id, schedule_type, frequency_days, scheduled_date, description, estimated_duration_hours, assigned_supervisor_id, status, priority) VALUES
(1, 'Preventive', 30, '2026-03-10', 'Regular maintenance for Assembly Line 1', 4, 2, 'scheduled', 'high'),
(2, 'Preventive', 45, '2026-03-15', 'Testing station calibration and maintenance', 3, 2, 'scheduled', 'medium'),
(3, 'Corrective', NULL, '2026-02-28', 'Winding machine bearing replacement', 6, 2, 'scheduled', 'urgent');

-- ============================================
-- STEP 26: INSERT MATERIALS (From Real Inventory)
-- ============================================
INSERT INTO materials (code, name, description, category, unit, min_stock, max_stock, current_stock, supplier_id, unit_cost) VALUES
('293', 'Ruban Jaune 50mmx33m', 'Par rouleau (un carton de 24 piéce)', 'Adhésifs', 'Rouleau', 85, 128, 85, 1, 4.38),
('294', 'Ruban Rouge 50mmx33m', 'Par rouleau (un carton de 24 piéce)', 'Adhésifs', 'Rouleau', 6, 9, 6, 1, 4.33),
('295', 'Ruban Bleu 50mmx33m', 'Par rouleau (un carton de 24 piéce)', 'Adhésifs', 'Rouleau', 13, 20, 13, 1, 4.39),
('296', 'Ruban Vert 50mmx33m', 'Par rouleau (un carton de 24 piéce)', 'Adhésifs', 'Rouleau', 2, 3, 2, 2, 4.38),
('297', 'Ruban Rouge/Blanc 50mmx33m', 'Par rouleau (un carton de 24 piéce)', 'Adhésifs', 'Rouleau', 9, 14, 10, 2, 6.67),
('545', 'Fusible 5*20 10AT', 'Fusible standard', 'Électrique', 'Pièce', 1, 2, 1, 3, 2.14),
('551', 'Fusible 5*20 6,3AT', 'Fusible standard', 'Électrique', 'Pièce', 1, 2, 1, 3, 1.90),
('553', 'Fusible 5x20 1AT', 'Fusible standard', 'Électrique', 'Pièce', 1, 2, 1, 3, 1.96),
('1010', 'Roulement rainure a billes', 'Roulement standard', 'Roulements', 'Pièce', 1, 1, 1, 3, 2.92),
('1013', 'Roulement rainure a bille 608-2Z', 'Roulement rainuré', 'Roulements', 'Pièce', 3, 5, 3, 3, 2.95),
('1014', 'Roulement rainure a bille 6002-2Z', 'Roulement rainuré', 'Roulements', 'Pièce', 27, 41, 27, 3, 3.48),
('1061', 'Joint torique ORM 0280-20-28*2', 'Joint standard', 'Joints', 'Pièce', 1, 1, 1, 3, 1.99),
('1124', 'Joint double TS DUO 32,8', 'Joint double', 'Joints', 'Pièce', 1, 2, 1, 3, 6.23),
('1297', 'HUILE PNEUMATIQUE OFSW-32, 1LITRE', 'Huile pneumatique 1L', 'Fluides', 'Litre', 1, 2, 1, 3, 28.00),
('1512', 'Roue de mesure', 'Accessoire de mesure', 'Accessoires', 'Pièce', 3, 5, 3, 3, 105.85),
('1682', 'Roulement rainure a billes 626-2RS', 'Roulement à billes', 'Roulements', 'Pièce', 1, 1, 1, 3, 2.50),
('1742', 'Vis à tète cylindrique M3x6 inoxydable', 'Vis inoxydable', 'Quincaillerie', 'Pièce', 3, 5, 3, 3, 2.20),
('1744', 'Vis à tete cyl 6p ,cr,M5X20.8.8 vzb', 'Vis standard', 'Quincaillerie', 'Pièce', 6, 9, 6, 3, 2.22),
('1745', 'Vis tète cyl M6x16', 'Vis standard', 'Quincaillerie', 'Pièce', 4, 6, 4, 3, 1.99),
('1778', 'Circlips 26x1,2', 'Circlips de retenue', 'Quincaillerie', 'Pièce', 1, 1, 1, 3, 1.80),
('1786', 'Rondelle 5,3/10x1 VZB Gamma255', 'Rondelle plate', 'Quincaillerie', 'Pièce', 1, 1, 1, 3, 2.22),
('1789', 'Vis sans tete M4x5', 'Vis sans tête', 'Quincaillerie', 'Pièce', 2, 3, 2, 3, 2.22),
('1795', 'Vis à tète cylindrque M5*12 VZB', 'Vis standard', 'Quincaillerie', 'Pièce', 0, 1, 0, 3, 2.22),
('1800', 'Vis à téte Cyl 6p.cr M5X35 8.8vzb TC588', 'Vis standard', 'Quincaillerie', 'Pièce', 1, 2, 1, 3, 1.94),
('1803', 'Vis à téte fraisé', 'Vis fraisée', 'Quincaillerie', 'Pièce', 64, 96, 64, 3, 2.21),
('1804', 'Vis à téte Cyl 6p.cr M3x8 8.8vzb TC588', 'Vis standard', 'Quincaillerie', 'Pièce', 6, 9, 6, 3, 2.20),
('1805', 'Tige filetèè M5*6VZB', 'Tige filetée', 'Quincaillerie', 'Pièce', 1, 1, 1, 3, 1.07),
('1823', 'Vis tete cyl M4X12', 'Vis standard', 'Quincaillerie', 'Pièce', 6, 9, 6, 3, 2.23),
('1824', 'Vis à téte Cyl 6p.cr M4x8.8vzb TC588', 'Vis standard', 'Quincaillerie', 'Pièce', 7, 11, 7, 3, 2.15),
('1827', 'Vis à tête fraisée M4x12 VZB', 'Vis fraisée', 'Quincaillerie', 'Pièce', 1, 1, 1, 3, 1.94),
('1857', 'Vis à tète cylindrique  M4X10 VZB', 'Vis standard', 'Quincaillerie', 'Pièce', 4, 6, 4, 3, 2.22),
('1892', 'Vis sans tete M3x5 Alpha 488', 'Vis sans tête', 'Quincaillerie', 'Pièce', 0, 1, 0, 3, 2.24),
('1894', 'M5X30', 'Vis standard', 'Quincaillerie', 'Pièce', 3, 5, 3, 3, 1.96),
('1922', 'Vis à téte Cyl 6p.cr M4x20 8.8vzb TC588', 'Vis standard', 'Quincaillerie', 'Pièce', 1, 2, 1, 3, 1.94),
('1956', 'Vis à tète fraisée M3X8 VZB', 'Vis fraisée', 'Quincaillerie', 'Pièce', 3, 5, 3, 3, 2.23),
('1999', 'Vis a tète fraisée M5X12', 'Vis fraisée', 'Quincaillerie', 'Pièce', 4, 6, 4, 3, 2.22),
('2000', 'Vis a tète fraisée 6p.cr.M6X16', 'Vis fraisée', 'Quincaillerie', 'Pièce', 6, 9, 6, 3, 2.24),
('2198', 'Vis sans tete M4x4', 'Vis sans tête', 'Quincaillerie', 'Pièce', 1, 2, 1, 3, 1.94),
('2226', 'Barre de rondelle joint PR8', 'Accessoire', 'Accessoires', 'Pièce', 1, 1, 1, 3, 1.43),
('2228', 'Joint double', 'Joint double', 'Joints', 'Pièce', 3, 5, 3, 3, 4.42),
('2414', 'Vis à téte Cyl 6p.cr M4x25 8.8vzb TC 588', 'Vis standard', 'Quincaillerie', 'Pièce', 5, 8, 5, 3, 1.94),
('2416', 'Vis tète cyl .6p.cr.M6X12 8.8vzb TC588', 'Vis standard', 'Quincaillerie', 'Pièce', 7, 11, 7, 3, 2.24),
('2422', 'Vis à téte Cyl 6p.cr M8x40/28 8.8vzb TC588', 'Vis standard', 'Quincaillerie', 'Pièce', 5, 8, 5, 3, 1.94),
('2446', 'Circlop 52x2', 'Circlips de retenue', 'Quincaillerie', 'Pièce', 1, 1, 1, 3, 1.89),
('2493', 'Bride de serrage', 'Accessoire', 'Accessoires', 'Pièce', 1, 2, 1, 3, 6.11),
('2509', 'Vis à téte fraisée.6p.cr M6x35 010.9 vzb TC588', 'Vis fraisée', 'Quincaillerie', 'Pièce', 1, 1, 1, 3, 1.94),
('2547', 'Roulement rainure a bille 607-2ZIRV', 'Roulement à billes', 'Roulements', 'Pièce', 71, 107, 71, 3, 3.74),
('2551', 'Tige filetée M3x8 VZB', 'Tige filetée', 'Quincaillerie', 'Pièce', 1, 1, 1, 3, 2.26),
('2596', 'Ecrou M3B124', 'Écrou standard', 'Quincaillerie', 'Pièce', 1, 2, 1, 3, 1.99),
('2608', 'Rondelle 4.3/9x0,8 VZB', 'Rondelle plate', 'Quincaillerie', 'Pièce', 7, 11, 7, 3, 1.91),
('2797', 'Vis tète cyl .6p.cr.M6X25 8.8vzb TC588', 'Vis standard', 'Quincaillerie', 'Pièce', 2, 3, 2, 3, 2.21),
('2814', 'Vis à téte fraisée. 6p.cr M5x14 ZL 010.9 TC588', 'Vis fraisée', 'Quincaillerie', 'Pièce', 6, 9, 6, 3, 2.24),
('7633', 'Cable capteur', 'Câble de capteur', 'Câbles', 'Pièce', 2, 3, 2, 3, 15.99),
('7634', 'Cable de detecteur 180° 3x0,25  5m', 'Câble détecteur', 'Câbles', 'Pièce', 2, 3, 2, 3, 20.13),
('8014', 'Valve connector SMC 3P female 29x21mm', 'Connecteur SMC', 'Connecteurs', 'Pièce', 1, 1, 1, 3, 5.19),
('8097', 'STRIPPING PLIERS 0.2-6 MM2 , 200 MM', 'Pince à dénuder', 'Outils', 'Pièce', 4, 6, 4, 2, 59.57),
('8207', 'Fusible  2.0 AT', 'Fusible standard', 'Électrique', 'Pièce', 2, 3, 2, 3, 2.20),
('8357', 'Lampe a incandescence BA 9S 24 VDC', 'Ampoule incandescente', 'Électrique', 'Pièce', 1, 1, 1, 3, 2.08),
('10088', 'Proximity Surich', 'Capteur de proximité', 'Capteurs', 'Pièce', 1, 2, 1, 3, 53.01),
('10146', 'Naherungsschalter MK5100', 'Capteur de proximité', 'Capteurs', 'Pièce', 1, 2, 1, 3, 67.44),
('10167', 'Circlip 25x1,2', 'Circlips de retenue', 'Quincaillerie', 'Pièce', 1, 2, 1, 3, 1.96),
('10172', 'Quick -release mandrel 3', 'Mandrin à dégagement rapide', 'Accessoires', 'Pièce', 1, 1, 1, 3, 42.95),
('10173', 'Quick -release mandrel1,5', 'Mandrin à dégagement rapide', 'Accessoires', 'Pièce', 1, 1, 1, 3, 207.83),
('10175', 'Roulement 6205-2R', 'Roulement à billes', 'Roulements', 'Pièce', 12, 18, 12, 3, 4.99),
('10189', 'Naherungs schalter MK5140', 'Capteur de proximité', 'Capteurs', 'Pièce', 1, 1, 1, 3, 55.30),
('10290', 'Vis d épaulement de précision 6x12/M5', 'Vis d épaulement', 'Quincaillerie', 'Pièce', 1, 1, 1, 3, 1.97),
('10325', 'Amortisseur PRO 25 MF -3 Alpha 488', 'Amortisseur', 'Accessoires', 'Pièce', 1, 1, 1, 3, 130.49),
('10331', 'Vis d épaulement 8x12/M6', 'Vis d épaulement', 'Quincaillerie', 'Pièce', 3, 5, 3, 3, 2.22),
('10340', 'Joint piston', 'Joint de piston', 'Joints', 'Pièce', 1, 2, 1, 3, 3.03),
('10452', 'Potentiometer PMR411', 'Potentiomètre', 'Électrique', 'Pièce', 1, 1, 1, 3, 26.43),
('10561', 'Spring', 'Ressort', 'Accessoires', 'Pièce', 2, 3, 2, 3, 3.37),
('10567', 'Guiding carriage EGH 15 CA Z011', 'Chariot de guidage', 'Accessoires', 'Pièce', 1, 1, 1, 3, 69.70),
('10605', 'Module X20DO4322', 'Module électronique', 'Électrique', 'Pièce', 1, 1, 0, 3, 101.10),
('10608', 'Module for stepping motor X20SM1436', 'Module moteur', 'Électrique', 'Pièce', 1, 1, 1, 3, 494.73),
('10610', 'Stepping Motor 80MPD5,300S000-01', 'Moteur pas à pas', 'Moteurs', 'Pièce', 1, 2, 0, 3, 192.00),
('10620', 'Module X20DM9324', 'Module électronique', 'Électrique', 'Pièce', 1, 1, 1, 3, 200.76),
('10621', 'Module X20ZF0000', 'Module électronique', 'Électrique', 'Pièce', 1, 1, 1, 3, 18.88),
('10625', 'Power supply 24V', 'Alimentation 24V', 'Électrique', 'Pièce', 1, 1, 1, 3, 71.58),
('10673', 'X20BR9300 Automote kabatec', 'Contrôleur automote', 'Électrique', 'Pièce', 1, 1, 1, 3, 226.83),
('10674', 'X20BM01 Autonte kobatec', 'Module automote', 'Électrique', 'Pièce', 1, 1, 1, 3, 7.79),
('10675', 'Circlop with pin', 'Circlips avec goupille', 'Quincaillerie', 'Pièce', 1, 1, 1, 3, 15.25),
('10676', 'Joint de Tige', 'Joint de tige', 'Joints', 'Pièce', 2, 3, 2, 3, 3.60),
('10683', 'Cutting blade', 'Lame de coupe', 'Accessoires', 'Pièce', 2, 3, 2, 3, 3.24),
('10704', 'Clevis SG-M6', 'Patte de fixation', 'Accessoires', 'Pièce', 1, 2, 1, 3, 11.00),
('10730', 'Sensor diameter-detection', 'Capteur détection diamètre', 'Capteurs', 'Pièce', 1, 1, 1, 3, 311.54),
('10732', 'Top knife complete', 'Couteau supérieur complet', 'Accessoires', 'Pièce', 2, 3, 1, 3, 261.76),
('10734', 'Bearing ,left', 'Roulement gauche', 'Roulements', 'Pièce', 1, 1, 1, 3, 30.54),
('10735', 'Bearing ,right', 'Roulement droit', 'Roulements', 'Pièce', 1, 1, 1, 3, 32.06),
('10736', 'Felt strip for knife', 'Bande de feutre pour lame', 'Accessoires', 'Pièce', 1, 2, 1, 3, 7.91),
('10741', 'Toothed belt L1120 for winding head', 'Courroie dentée', 'Transmissions', 'Pièce', 1, 1, 1, 3, 63.20),
('10743', 'Cylinder ADVU-25-20-A-P-A', 'Cylindre pneumatique', 'Pneumatique', 'Pièce', 1, 1, 1, 3, 100.19),
('10760', 'Axle D=7', 'Axe d=7', 'Accessoires', 'Pièce', 2, 3, 2, 3, 11.30),
('10763', 'Roue denté Z18', 'Roue dentée Z18', 'Transmissions', 'Pièce', 6, 9, 6, 3, 17.00),
('10828', 'Joint torique', 'Joint torique standard', 'Joints', 'Pièce', 1, 2, 1, 3, 2.25),
('10882', 'Clavette à rainure 5x5x25', 'Clavette', 'Quincaillerie', 'Pièce', 1, 2, 1, 3, 2.24),
('10896', 'Division roll', 'Rouleau de division', 'Accessoires', 'Pièce', 1, 1, 1, 3, 13.00),
('10923', 'Fork light Barrier', 'Barrière photoélectrique fourchue', 'Capteurs', 'Pièce', 1, 2, 1, 3, 52.27),
('10933', 'Pendulum roll cpl', 'Rouleau pendulaire complet', 'Accessoires', 'Pièce', 1, 1, 1, 3, 38.79),
('10937', 'Circlip with pin,1,5', 'Circlips avec goupille 1,5', 'Quincaillerie', 'Pièce', 1, 1, 1, 3, 145.90),
('11011', 'Cylinder DSNU-12-50-P-A', 'Cylindre pneumatique', 'Pneumatique', 'Pièce', 1, 1, 1, 3, 30.38),
('11037', 'Toothed belt T5 10mm L460', 'Courroie dentée', 'Transmissions', 'Pièce', 1, 1, 1, 3, 17.03),
('11070', 'Panel KTP400', 'Panneau de contrôle', 'Électrique', 'Pièce', 1, 1, 1, 3, 745.16),
('11115', 'Coulisseau 8 St M6', 'Coulisseau', 'Accessoires', 'Pièce', 2, 3, 2, 3, 2.07),
('11135', 'Amortisseur', 'Amortisseur standard', 'Accessoires', 'Pièce', 1, 1, 1, 3, 97.08),
('11143', 'Spring for safety flup', 'Ressort de sécurité', 'Accessoires', 'Pièce', 1, 1, 1, 3, 4.13),
('11155', 'Magnet D=4 X5', 'Aimant', 'Électrique', 'Pièce', 1, 1, 1, 3, 2.92),
('11165', 'Micro Switch', 'Micro-switch', 'Électrique', 'Pièce', 1, 1, 1, 3, 12.30),
('11166', 'Felt strip for konife', 'Bande de feutre', 'Accessoires', 'Pièce', 1, 2, 1, 3, 9.65),
('11193', 'Distanzstange', 'Entretoise', 'Accessoires', 'Pièce', 1, 1, 1, 3, 63.55),
('11249', 'Emergency switch', 'Arrêt d urgence', 'Électrique', 'Pièce', 1, 2, 1, 3, 59.75),
('11250', 'Emergency stop label 16 mm hole', 'Étiquette arrêt d urgence', 'Accessoires', 'Pièce', 1, 1, 1, 3, 4.65),
('11306', 'Zahnriemenrad T5 _Z20_D8', 'Poulie dentée', 'Transmissions', 'Pièce', 1, 2, 1, 3, 35.13),
('11386', 'Side pane protctive hood-KTR', 'Capot de protection', 'Accessoires', 'Pièce', 1, 1, 1, 3, 59.60),
('11387', 'Radial window for cover KTR50+KTR500', 'Fenêtre radiale', 'Accessoires', 'Pièce', 1, 1, 0, 3, 0.30),
('11410', 'Cover ,internal for KTR10', 'Couvercle interne', 'Accessoires', 'Pièce', 1, 1, 1, 3, 201.76),
('11500', 'Cable Box M8', 'Boîte à câbles M8', 'Accessoires', 'Pièce', 1, 1, 1, 3, 18.90),
('11502', 'Cablebox with cable for sensor', 'Boîte à câbles avec câble', 'Accessoires', 'Pièce', 1, 1, 1, 3, 9.99),
('11546', 'Vis à téte fraisée.6p.cr .t.basse M5x16', 'Vis fraisée', 'Quincaillerie', 'Pièce', 3, 5, 3, 3, 1.94),
('11547', 'Diversion roll D15262', 'Rouleau de déviation', 'Accessoires', 'Pièce', 1, 1, 1, 3, 29.29),
('11553', 'GEAR HUB ,X-AXIS', 'Moyeu d engrenage', 'Transmissions', 'Pièce', 5, 8, 0, 3, 120.00),
('11571', 'Vis tete cylindrique M5*10', 'Vis standard', 'Quincaillerie', 'Pièce', 1, 2, 0, 3, 2.13),
('11609', 'Druckfeder d58L36', 'Ressort de compression', 'Accessoires', 'Pièce', 1, 1, 1, 3, 2.06),
('11731', 'Safety sensor bns 250', 'Capteur de sécurité', 'Capteurs', 'Pièce', 1, 1, 1, 3, 137.42),
('11746', 'Battery for Power panel PP45', 'Batterie', 'Électrique', 'Pièce', 1, 1, 1, 3, 99.71),
('11874', 'Vis à tète cylindrique M4x10', 'Vis standard', 'Quincaillerie', 'Pièce', 0, 1, 0, 3, 2.25),
('11914', 'Toothed belt', 'Courroie dentée', 'Transmissions', 'Pièce', 1, 1, 1, 3, 9.11),
('11916', 'Coulisseau 8 St M8 ITEM', 'Coulisseau', 'Accessoires', 'Pièce', 3, 5, 3, 3, 1.96),
('12068', 'Din 625 SKF-SKF608-2Z', 'Roulement SKF', 'Roulements', 'Pièce', 1, 1, 1, 3, 5.69),
('12083', 'Anneau torique 16*2', 'Anneau torique', 'Joints', 'Pièce', 1, 1, 1, 3, 1.07),
('12396', 'Disque de marquage', 'Disque de marquage', 'Accessoires', 'Pièce', 2, 3, 2, 3, 512.73),
('12447', 'Levier de serrage M5x25', 'Levier', 'Accessoires', 'Pièce', 1, 1, 1, 3, 7.42),
('12575', 'Bague de paumelle 16/22*2', 'Bague', 'Accessoires', 'Pièce', 1, 1, 1, 3, 2.23),
('12861', 'Rondelle conique M5 vzb', 'Rondelle conique', 'Quincaillerie', 'Pièce', 2, 3, 2, 3, 1.94),
('12873', 'Saferty Switch', 'Interrupteur de sécurité', 'Électrique', 'Pièce', 1, 2, 1, 3, 123.97),
('13038', 'Douille cylindrique', 'Douille', 'Accessoires', 'Pièce', 1, 2, 1, 3, 1.98),
('13070', 'Vis d épaulement 6/25-M5', 'Vis d épaulement', 'Quincaillerie', 'Pièce', 1, 1, 1, 3, 1.95),
('13081', 'Stepping motor,2-phases', 'Moteur pas à pas', 'Moteurs', 'Pièce', 1, 1, 1, 3, 360.96);

-- ============================================
-- STEP 27: VERIFY DATABASE CREATION
-- ============================================
SELECT '✓ DATABASE CREATION COMPLETE!' as message;
SELECT COUNT(*) as total_tables FROM information_schema.tables WHERE table_schema = 'maintenance_system_v2';
SELECT 'Users created:' as info, COUNT(*) as record_count FROM users;
SELECT 'Departments created:' as info, COUNT(*) as record_count FROM departments;
SELECT 'Suppliers created:' as info, COUNT(*) as record_count FROM suppliers;
SELECT 'Materials created:' as info, COUNT(*) as record_count FROM materials;
SELECT 'Zones created:' as info, COUNT(*) as record_count FROM zones;
SELECT 'Machines created:' as info, COUNT(*) as record_count FROM machines;
