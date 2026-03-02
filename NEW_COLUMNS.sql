-- Additional columns for technician separation implementation
-- Run these queries to update your database

USE maintenance_system;

-- 1. Add machine_name to maintenance_reports (for cached machine name)
ALTER TABLE maintenance_reports ADD COLUMN machine_name VARCHAR(200) AFTER technician_id;

-- 2. Add approved_notes to material_returns (stock agent approval notes)
ALTER TABLE material_returns ADD COLUMN approved_notes TEXT AFTER notes;

-- 3. Add approved_date to material_returns (when stock agent approved)
ALTER TABLE material_returns ADD COLUMN approved_date TIMESTAMP AFTER processed_at;

-- Verify the changes
-- SELECT * FROM maintenance_reports LIMIT 1;
-- SELECT * FROM material_returns LIMIT 1;
