-- Database Migration Queries
-- Run these queries to update your existing database with new columns and tables

USE maintenance_system;

-- 1. Add zone column to users table
ALTER TABLE users ADD COLUMN zone VARCHAR(100) AFTER department;

-- 2. Add new columns to maintenance_reports table
ALTER TABLE maintenance_reports ADD COLUMN machine_name VARCHAR(200) AFTER technician_id;
ALTER TABLE maintenance_reports ADD COLUMN report_type VARCHAR(50) DEFAULT 'standard' AFTER next_maintenance_recommendation;
ALTER TABLE maintenance_reports ADD COLUMN technician_zone VARCHAR(100) AFTER report_type;
ALTER TABLE maintenance_reports ADD COLUMN machine_condition VARCHAR(50) AFTER technician_zone;
ALTER TABLE maintenance_reports ADD COLUMN machine_condition_after VARCHAR(50) AFTER machine_condition;
ALTER TABLE maintenance_reports ADD COLUMN environmental_conditions TEXT AFTER machine_condition_after;
ALTER TABLE maintenance_reports ADD COLUMN safety_observations TEXT AFTER environmental_conditions;
ALTER TABLE maintenance_reports ADD COLUMN tools_used TEXT AFTER safety_observations;

-- 3. Add new columns to spare_parts_demands table
ALTER TABLE spare_parts_demands ADD COLUMN quantity_returned INT DEFAULT 0 AFTER stock_agent_notes;
ALTER TABLE spare_parts_demands ADD COLUMN return_date DATETIME AFTER quantity_returned;
ALTER TABLE spare_parts_demands ADD COLUMN return_notes TEXT AFTER return_date;

-- 4. Add new column to stock_movements table
ALTER TABLE stock_movements ADD COLUMN return_reason TEXT AFTER user_id;

-- 5. Update stock_movements movement_type enum to include 'returned'
ALTER TABLE stock_movements MODIFY COLUMN movement_type ENUM('addition', 'withdrawal', 'adjustment', 'allocated', 'fulfilled', 'returned') NOT NULL;

-- 6. Create material_returns table if it doesn't exist
CREATE TABLE IF NOT EXISTS material_returns (
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
    approved_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    approved_date TIMESTAMP,
    FOREIGN KEY (demand_id) REFERENCES spare_parts_demands(id) ON DELETE CASCADE,
    FOREIGN KEY (material_id) REFERENCES materials(id),
    FOREIGN KEY (returned_by_id) REFERENCES users(id),
    FOREIGN KEY (received_by_id) REFERENCES users(id),
    INDEX idx_demand_id (demand_id),
    INDEX idx_material_id (material_id),
    INDEX idx_created_at (created_at)
);

-- 7. Add missing columns to material_returns if they don't exist
-- These are added conditionally to avoid errors if the table already exists
ALTER TABLE material_returns ADD COLUMN approved_notes TEXT AFTER notes;
ALTER TABLE material_returns ADD COLUMN approved_date TIMESTAMP AFTER processed_at;
