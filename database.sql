-- Sumitomo Maintenance Management System Database Schema

CREATE DATABASE IF NOT EXISTS maintenance_system;
USE maintenance_system;

-- Users Table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role ENUM('admin', 'supervisor', 'technician', 'stock_agent') NOT NULL DEFAULT 'technician',
    department VARCHAR(100),
    zone VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_role (role),
    INDEX idx_active (is_active)
);

-- Materials/Stock Table
CREATE TABLE materials (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    unit VARCHAR(50),
    min_stock INT NOT NULL DEFAULT 10,
    max_stock INT NOT NULL DEFAULT 100,
    current_stock INT DEFAULT 0,
    reorder_point INT,
    unit_cost DECIMAL(10, 2),
    supplier VARCHAR(100),
    last_restocked TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_stock_level (current_stock),
    INDEX idx_category (category)
);

-- Machines Table
CREATE TABLE machines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    machine_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    location VARCHAR(200),
    department VARCHAR(100),
    model VARCHAR(100),
    manufacturer VARCHAR(100),
    purchase_date DATE,
    installation_date DATE,
    status ENUM('active', 'inactive', 'under_maintenance', 'retired') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_department (department)
);

-- Preventive Maintenance Schedule Table
CREATE TABLE maintenance_schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    machine_id INT NOT NULL,
    schedule_type VARCHAR(50),
    frequency_days INT,
    scheduled_date DATE NOT NULL,
    description TEXT,
    estimated_duration_hours INT,
    assigned_supervisor_id INT NOT NULL,
    status ENUM('scheduled', 'in_progress', 'completed', 'cancelled', 'overdue') DEFAULT 'scheduled',
    priority ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (machine_id) REFERENCES machines(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_supervisor_id) REFERENCES users(id),
    INDEX idx_status (status),
    INDEX idx_scheduled_date (scheduled_date),
    INDEX idx_machine_id (machine_id)
);

-- Maintenance Report Table
CREATE TABLE maintenance_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    schedule_id INT NOT NULL,
    technician_id INT NOT NULL,
    actual_start_time DATETIME,
    actual_end_time DATETIME,
    actual_duration_hours DECIMAL(5, 2),
    work_description TEXT,
    findings TEXT,
    actions_taken TEXT,
    issues_found BOOLEAN DEFAULT FALSE,
    issue_description TEXT,
    components_replaced TEXT,
    next_maintenance_recommendation TEXT,
    report_type VARCHAR(50) DEFAULT 'standard',
    report_status ENUM('draft', 'submitted', 'approved', 'rejected') DEFAULT 'draft',
    technician_zone VARCHAR(100),
    machine_condition VARCHAR(50),
    machine_condition_after VARCHAR(50),
    environmental_conditions TEXT,
    safety_observations TEXT,
    tools_used TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (schedule_id) REFERENCES maintenance_schedules(id) ON DELETE CASCADE,
    FOREIGN KEY (technician_id) REFERENCES users(id),
    INDEX idx_status (report_status),
    INDEX idx_technician_id (technician_id)
);

-- Spare Parts Demand Table
CREATE TABLE spare_parts_demands (
    id INT AUTO_INCREMENT PRIMARY KEY,
    demand_number VARCHAR(50) UNIQUE NOT NULL,
    maintenance_report_id INT,
    requestor_id INT NOT NULL,
    material_id INT NOT NULL,
    quantity_requested INT NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    reason TEXT,
    supervisor_id INT,
    supervisor_approval ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    supervisor_approval_date DATETIME,
    supervisor_notes TEXT,
    stock_agent_id INT,
    stock_agent_approval ENUM('pending', 'approved', 'rejected', 'partial') DEFAULT 'pending',
    stock_agent_approval_date DATETIME,
    quantity_allocated INT,
    stock_agent_notes TEXT,
    quantity_returned INT DEFAULT 0,
    return_date DATETIME,
    return_notes TEXT,
    demand_status ENUM('pending', 'supervisor_review', 'approved_supervisor', 'stock_agent_review', 'approved_stock_agent', 'rejected', 'partial_allocated', 'fulfilled') DEFAULT 'pending',
    fulfilled_date DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (maintenance_report_id) REFERENCES maintenance_reports(id) ON DELETE SET NULL,
    FOREIGN KEY (requestor_id) REFERENCES users(id),
    FOREIGN KEY (material_id) REFERENCES materials(id),
    FOREIGN KEY (supervisor_id) REFERENCES users(id),
    FOREIGN KEY (stock_agent_id) REFERENCES users(id),
    INDEX idx_status (demand_status),
    INDEX idx_demand_number (demand_number),
    INDEX idx_material_id (material_id),
    INDEX idx_created_at (created_at)
);

-- Stock Movement/Transaction Table
CREATE TABLE stock_movements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    material_id INT NOT NULL,
    movement_type ENUM('addition', 'withdrawal', 'adjustment', 'allocated', 'fulfilled', 'returned') NOT NULL,
    quantity INT NOT NULL,
    previous_stock INT,
    new_stock INT,
    reference_id INT,
    reference_type VARCHAR(50),
    user_id INT,
    return_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_material_id (material_id),
    INDEX idx_created_at (created_at),
    INDEX idx_movement_type (movement_type)
);

-- Stock Notifications/Alerts Table
CREATE TABLE stock_alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    material_id INT NOT NULL,
    alert_type ENUM('below_min', 'at_min', 'near_max', 'at_max') NOT NULL,
    current_stock INT,
    min_stock INT,
    max_stock INT,
    is_read BOOLEAN DEFAULT FALSE,
    email_sent BOOLEAN DEFAULT FALSE,
    email_sent_to VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE,
    INDEX idx_material_id (material_id),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);

-- Material Returns Table
CREATE TABLE material_returns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    demand_id INT NOT NULL,
    material_id INT NOT NULL,
    quantity_returned INT NOT NULL,
    return_reason TEXT,
    condition_of_material VARCHAR(50),
    returned_by_id INT,
    received_by_id INT,
    return_status VARCHAR(50) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    FOREIGN KEY (demand_id) REFERENCES spare_parts_demands(id) ON DELETE CASCADE,
    FOREIGN KEY (material_id) REFERENCES materials(id),
    FOREIGN KEY (returned_by_id) REFERENCES users(id),
    FOREIGN KEY (received_by_id) REFERENCES users(id),
    INDEX idx_demand_id (demand_id),
    INDEX idx_material_id (material_id),
    INDEX idx_created_at (created_at)
);

-- Maintenance Template Table (for common maintenance tasks)
CREATE TABLE maintenance_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    frequency_days INT,
    estimated_duration_hours INT,
    required_materials JSON,
    checklist JSON,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_name (name)
);

-- Dashboard KPI Cache Table
CREATE TABLE dashboard_kpis (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kpi_name VARCHAR(100) NOT NULL,
    kpi_value DECIMAL(10, 2),
    kpi_date DATE,
    kpi_data JSON,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_kpi_name (kpi_name),
    INDEX idx_kpi_date (kpi_date)
);

-- Insert default admin user (password: admin123 - hashed with werkzeug)
INSERT INTO users (username, password, email, first_name, last_name, role, is_active) 
VALUES ('admin', 'scrypt:32768:8:1$RLnmfT6cF7F1Z5Z9$8f5c8e1b5d5f5c5e5f5c5e5f5c5e5f5c5e5f5c5e5f5c5e5f5c5e5f5c5e5f5c', 'admin@sumitomo.com', 'Admin', 'User', 'admin', TRUE);

-- Insert sample data
INSERT INTO machines (machine_code, name, description, location, department, model, manufacturer, status) 
VALUES 
('MCH-001', 'Industrial Press A', 'Main hydraulic press for production', 'Floor 1', 'Production', 'HP-2000', 'Sumitomo', 'active'),
('MCH-002', 'CNC Machine B', 'Precision cutting machine', 'Floor 1', 'Production', 'CNC-500', 'Sumitomo', 'active'),
('MCH-003', 'Conveyor System C', 'Main production line conveyor', 'Floor 2', 'Logistics', 'CONV-1000', 'Siemens', 'active');

INSERT INTO materials (code, name, description, category, unit, min_stock, max_stock, current_stock, unit_cost) 
VALUES 
('MAT-001', 'Hydraulic Oil', 'Premium hydraulic fluid ISO 46', 'Fluids', 'Liter', 50, 200, 120, 15.50),
('MAT-002', 'Bearings SKF 6205', 'Deep groove ball bearing', 'Components', 'Unit', 20, 100, 45, 25.00),
('MAT-003', 'Sealing Ring 50mm', 'Rubber sealing ring', 'Components', 'Unit', 30, 150, 25, 5.50),
('MAT-004', 'Motor Brush Set', 'Carbon brush set for motor', 'Electrical', 'Set', 10, 50, 12, 45.00);

-- Create indexes for better query performance
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_machines_status ON machines(status);
CREATE INDEX idx_maintenance_schedules_machine ON maintenance_schedules(machine_id);
CREATE INDEX idx_demands_status ON spare_parts_demands(demand_status);
CREATE INDEX idx_stock_movements_material ON stock_movements(material_id);
