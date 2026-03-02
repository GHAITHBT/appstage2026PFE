-- ============================================
-- DATA MIGRATION & POPULATION SCRIPT
-- ============================================
-- Use this script to populate new columns with existing data

-- ============================================
-- STEP 1: POPULATE user_id FOR EXISTING USERS
-- ============================================
-- Generate user_id based on role and user ID if doesn't exist
UPDATE users 
SET user_id = CONCAT(
    UPPER(SUBSTRING(role, 1, 3)), 
    LPAD(id, 3, '0')
)
WHERE user_id IS NULL;

-- ============================================
-- STEP 2: ASSIGN DEFAULT DEPARTMENT TO ALL USERS
-- ============================================
-- If users don't have a department assigned, assign 'Unassigned'
UPDATE users 
SET department_id = (SELECT id FROM departments WHERE name = 'Unassigned')
WHERE department_id IS NULL OR department_id = 0;

-- ============================================
-- STEP 3: CREATE DEPARTMENT STRUCTURE (Optional - Customize based on your org)
-- ============================================
-- Add standard departments if they don't exist
INSERT INTO departments (name, description) VALUES 
('Maintenance', 'Maintenance Department') 
ON DUPLICATE KEY UPDATE name=name;

INSERT INTO departments (name, description) VALUES 
('Stock Management', 'Stock and Inventory Management') 
ON DUPLICATE KEY UPDATE name=name;

INSERT INTO departments (name, description) VALUES 
('Operations', 'Operations Department') 
ON DUPLICATE KEY UPDATE name=name;

INSERT INTO departments (name, description) VALUES 
('Safety & Training', 'Health, Safety, and Training') 
ON DUPLICATE KEY UPDATE name=name;

-- ============================================
-- STEP 4: REASSIGN USERS TO PROPER DEPARTMENTS
-- ============================================
-- Example: Assign supervisors to Maintenance department
-- UPDATE users SET department_id = (SELECT id FROM departments WHERE name = 'Maintenance')
-- WHERE role = 'supervisor';

-- Example: Assign stock roles to Stock Management
-- UPDATE users SET department_id = (SELECT id FROM departments WHERE name = 'Stock Management')
-- WHERE role IN ('stock_agent', 'stock_manager');

-- Example: Assign technicians to Maintenance
-- UPDATE users SET department_id = (SELECT id FROM departments WHERE name = 'Maintenance')
-- WHERE role = 'technician';

-- ============================================
-- STEP 5: ASSIGN SUPERVISORS TO TECHNICIANS
-- ============================================
-- This needs to be customized based on your organizational structure
-- Example (modify the IDs based on your actual users):
/*
-- Find supervisors
SELECT id, full_name, role FROM users WHERE role IN ('supervisor', 'admin');

-- Assign technicians to supervisor with ID 2
UPDATE users 
SET supervisor_id = 2 
WHERE role = 'technician' AND id IN (3, 4, 5, 6, 7);

-- Verify supervisor assignments
SELECT u1.full_name, u1.role, u2.full_name as supervisor_name, u2.role 
FROM users u1 
LEFT JOIN users u2 ON u1.supervisor_id = u2.id 
WHERE u1.role = 'technician';
*/

-- ============================================
-- STEP 6: POPULATE EXISTING DEMANDS WITH USER & DEPARTMENT INFO
-- ============================================
-- If your existing demands don't have requested_by_id, you may need to assign a default
-- This is a placeholder - you'll need to map based on your business logic

-- Example: If you have a creator_id column, map it
-- UPDATE spare_parts_demands 
-- SET requested_by_id = creator_id 
-- WHERE requested_by_id IS NULL AND creator_id IS NOT NULL;

-- Example: If no creator info exists, assign to first admin user
-- UPDATE spare_parts_demands 
-- SET requested_by_id = (SELECT id FROM users WHERE role = 'admin' LIMIT 1)
-- WHERE requested_by_id IS NULL;

-- Assign default department if NULL
-- UPDATE spare_parts_demands 
-- SET department_id = (SELECT id FROM departments WHERE name = 'Maintenance')
-- WHERE department_id IS NULL;

-- ============================================
-- STEP 7: CREATE DEFAULT STOCK LOCATIONS (if not exists)
-- ============================================
INSERT INTO stock_locations (location_code, location_name, warehouse_zone, capacity) VALUES 
('DEFAULT', 'Default Location', 'Zone A', 1000)
ON DUPLICATE KEY UPDATE location_code=location_code;

-- Populate inventory location_id if missing
/*
UPDATE inventory 
SET location_id = (SELECT id FROM stock_locations WHERE location_code = 'DEFAULT')
WHERE location_id IS NULL;
*/

-- ============================================
-- STEP 8: POPULATE EXISTING MATERIAL PRICING
-- ============================================
-- If materials don't have supplier_id or pricing, set defaults
UPDATE materials 
SET supplier_id = 1 
WHERE supplier_id IS NULL 
AND (SELECT COUNT(*) FROM suppliers) > 0;

-- ============================================
-- STEP 9: VERIFICATION QUERIES
-- ============================================

-- Verify users are properly assigned
SELECT 
    u.id,
    u.user_id,
    u.full_name,
    u.role,
    d.name as department,
    COALESCE(s.full_name, 'N/A') as supervisor_name
FROM users u
LEFT JOIN departments d ON u.department_id = d.id
LEFT JOIN users s ON u.supervisor_id = s.id
ORDER BY u.role, u.full_name;

-- Verify demands structure
SELECT 
    spd.demand_number,
    m.reference,
    m.designation,
    COALESCE(u.full_name, 'UNASSIGNED') as requested_by,
    COALESCE(d.name, 'UNASSIGNED') as department,
    spd.demand_status,
    spd.created_at
FROM spare_parts_demands spd
LEFT JOIN materials m ON spd.material_id = m.id
LEFT JOIN users u ON spd.requested_by_id = u.id
LEFT JOIN departments d ON spd.department_id = d.id
LIMIT 10;

-- Verify material data
SELECT 
    m.reference,
    m.designation,
    m.category,
    COALESCE(s.name, 'UNASSIGNED') as supplier,
    m.min_quantity,
    m.max_quantity,
    m.unit_price_eur
FROM materials m
LEFT JOIN suppliers s ON m.supplier_id = s.id
LIMIT 10;

-- ============================================
-- STEP 10: POST-MIGRATION CHECKLIST
-- ============================================
/*
After running this migration, verify:

□ All users have department_id assigned (not NULL)
□ All supervisors have NULL supervisor_id
□ All technicians have their supervisor_id assigned
□ Users have proper user_id codes (e.g., TECH001, SUP001)
□ Materials have supplier_id assigned
□ All existing demands have requested_by_id assigned
□ All existing demands have department_id assigned
□ Stock locations are set up
□ No orphaned foreign keys

Then run these checks:
SELECT * FROM users WHERE department_id IS NULL;
SELECT * FROM users WHERE role IN ('supervisor', 'admin') AND supervisor_id IS NOT NULL;
SELECT * FROM spare_parts_demands WHERE requested_by_id IS NULL;
SELECT * FROM materials WHERE supplier_id IS NULL;
*/

-- ============================================
-- MANUAL STEPS REQUIRED
-- ============================================
/*
1. REVIEW AND CUSTOMIZE:
   - The department assignments (STEP 4) need to match your org structure
   - The supervisor assignments (STEP 5) need to match your hierarchy
   - Update the example queries with your actual IDs

2. RUN ORGANIZATION SETUP:
   - Document your org structure
   - Run appropriate UPDATE statements to assign departments
   - Run UPDATE statements to assign supervisors

3. TEST:
   - Verify all user/department/supervisor relationships are correct
   - Check that no data was lost during migration
   - Test the approval workflow with new tables

4. UPDATE APPLICATION CODE:
   - Update Flask models to use new columns
   - Update routes to populate new columns
   - Update templates to show department/supervisor info

5. TRAIN USERS:
   - Explain new approval workflow
   - Show how to track demands
   - Demonstrate audit trail visibility
*/
