-- ============================================
-- DATA POPULATION & CUSTOMIZATION SCRIPT
-- Insert your organization structure here
-- ============================================
-- Run this AFTER running MIGRATION_FINAL.sql
-- Customize the values to match your organization

-- ============================================
-- SECTION 1: POPULATE DEPARTMENTS (CUSTOMIZE THIS!)
-- ============================================

DELETE FROM departments;

INSERT INTO departments (name, description, budget_allocated, budget_remaining, manager_id) VALUES
('Maintenance', 'Preventive and Corrective Maintenance Department', 50000.00, 50000.00, NULL),
('Wiring', 'Wiring System Assembly and Repair', 75000.00, 75000.00, NULL),
('Tools & Equipment', 'Tools and Equipment Management', 30000.00, 30000.00, NULL),
('Quality Control', 'Quality Assurance and Testing', 40000.00, 40000.00, NULL),
('Electrical', 'Electrical Systems and Components', 60000.00, 60000.00, NULL);

-- After adding managers to users table, update department managers:
-- UPDATE departments SET manager_id = (SELECT id FROM users WHERE username = 'supervisor_name') WHERE name = 'Department Name';

-- ============================================
-- SECTION 2: POPULATE SUPPLIERS (CUSTOMIZE THIS!)
-- ============================================

DELETE FROM suppliers;

INSERT INTO suppliers (name, contact_person, email, phone, address, city, country, payment_terms, is_active) VALUES
('Local Industrial Supply', 'Jean Pierre', 'jp@localindustrial.fr', '+33-1-2345-6789', '123 Industrial Road', 'Paris', 'France', 'Net 30', 1),
('European Components GmbH', 'Klaus Mueller', 'sales@eucomponents.de', '+49-89-2345-6789', 'Industriestrasse 45', 'Munich', 'Germany', 'Net 45', 1),
('Global Tech Solutions', 'Tech Support', 'support@globaltechs.com', '+1-800-TECH-123', '999 Tech Boulevard', 'Silicon Valley', 'USA', 'Net 60', 1),
('Nordic Wiring Systems', 'Anders Johnson', 'info@nordic-wiring.se', '+46-8-9876-5432', 'Cables Way 10', 'Stockholm', 'Sweden', 'Net 30', 1),
('Asian Electronics Corp', 'Wei Chen', 'procurement@asianelec.cn', '+86-10-5555-1234', 'Tech Park Building 5', 'Beijing', 'China', 'Net 45', 1);

-- ============================================
-- SECTION 3: POPULATE STOCK LOCATIONS (CUSTOMIZE THIS!)
-- ============================================

DELETE FROM stock_locations;

INSERT INTO stock_locations (name, location_code, building, floor, warehouse_section, capacity, is_active) VALUES
('Main Warehouse', 'WH001', 'Building A', 1, 'Storage Room A', 5000, 1),
('Secondary Storage', 'WH002', 'Building B', 0, 'Basement Level 1', 3000, 1),
('Tech Lab Stock', 'WH003', 'Building A', 3, 'Lab Area - Secure Storage', 500, 1),
('Office Supply Closet', 'OFC001', 'Building A', 2, 'Floor 2 East Wing', 200, 1),
('Emergency Stock Reserve', 'RSV001', 'Building C', 1, 'Restricted Access', 1000, 1);

-- ============================================
-- SECTION 4: ASSIGN SUPERVISORS TO TECHNICIANS
-- ============================================

-- Example: Assign supervisor to technician
-- UPDATE users 
-- SET supervisor_id = (SELECT id FROM users WHERE username = 'supervisor_username')
-- WHERE username = 'technician_username';

-- View current supervisors/staff:
SELECT 
    u.id,
    u.user_id,
    u.username,
    u.role,
    COALESCE(s.user_id, 'No Supervisor') as supervisor_user_id,
    COALESCE(s.username, '-') as supervisor_name
FROM users u
LEFT JOIN users s ON u.supervisor_id = s.id
ORDER BY u.role, u.username;

-- ============================================
-- SECTION 5: ASSIGN DEPARTMENTS TO USERS
-- ============================================

-- Assign technicians to departments:
-- UPDATE users SET department = 'Maintenance' WHERE username = 'tech_user_1';
-- UPDATE users SET department = 'Wiring' WHERE username = 'tech_user_2';

-- View current users and their departments:
SELECT 
    u.id,
    u.user_id,
    u.username,
    u.role,
    u.department,
    u.is_active,
    u.status
FROM users u
ORDER BY u.role, u.username;

-- ============================================
-- SECTION 6: LINK MATERIALS TO SUPPLIERS
-- ============================================

-- Update existing materials to link to suppliers by code/name match
-- Example 1: By exact name match
UPDATE materials m
SET supplier_id = (SELECT id FROM suppliers WHERE name = 'Local Industrial Supply')
WHERE supplier = 'Local Industrial Supply' AND supplier_id IS NULL;

-- Example 2: By supplier name containing text
UPDATE materials m
SET supplier_id = (SELECT id FROM suppliers WHERE name LIKE CONCAT('%', m.supplier, '%') LIMIT 1)
WHERE supplier IS NOT NULL AND supplier_id IS NULL;

-- Example 3: Manual individual updates
-- UPDATE materials SET supplier_id = (SELECT id FROM suppliers WHERE name = 'Local Industrial Supply') WHERE code = 'WIRE001';
-- UPDATE materials SET supplier_id = (SELECT id FROM suppliers WHERE name = 'European Components GmbH') WHERE code = 'CONN002';

-- View materials and their suppliers:
SELECT 
    m.id,
    m.code,
    m.name,
    m.supplier as supplier_name,
    COALESCE(s.name, 'NOT LINKED') as supplier_linked,
    m.current_stock,
    m.min_stock,
    m.reorder_point
FROM materials m
LEFT JOIN suppliers s ON m.supplier_id = s.id
ORDER BY m.code;

-- ============================================
-- SECTION 7: ASSIGN DEPARTMENT MANAGERS
-- ============================================

-- Assign supervisors as department managers
-- Example:
-- UPDATE departments SET manager_id = (SELECT id FROM users WHERE username = 'supervisor_1') WHERE name = 'Maintenance';
-- UPDATE departments SET manager_id = (SELECT id FROM users WHERE username = 'supervisor_2') WHERE name = 'Wiring';

-- View current department managers:
SELECT 
    d.id,
    d.name,
    d.description,
    COALESCE(u.user_id, 'No Manager') as manager_user_id,
    COALESCE(u.username, '-') as manager_name,
    d.budget_allocated,
    d.budget_remaining
FROM departments d
LEFT JOIN users u ON d.manager_id = u.id
ORDER BY d.name;

-- ============================================
-- SECTION 8: CREATE SAMPLE PURCHASE ORDERS
-- ============================================

-- Example 1: Create a PO for new stock
-- INSERT INTO purchase_orders 
-- (po_number, supplier_id, material_id, quantity_ordered, unit_price, total_cost, expected_delivery_date, status, created_by_id)
-- VALUES 
-- ('PO-2026-001', 1, 1, 100, 25.50, 2550.00, '2026-03-05', 'ordered', 1);

-- Example 2: Bulk insert sample POs (uncomment to use)
-- INSERT INTO purchase_orders 
-- (po_number, supplier_id, material_id, quantity_ordered, unit_price, total_cost, expected_delivery_date, status, notes, created_by_id)
-- SELECT 
--     CONCAT('PO-', DATE_FORMAT(NOW(), '%Y'), '-', LPAD(ROW_NUMBER() OVER (ORDER BY m.id), 3, '0')) as po_number,
--     COALESCE(m.supplier_id, 1) as supplier_id,
--     m.id as material_id,
--     m.max_stock - m.current_stock as quantity_ordered,
--     m.unit_cost as unit_price,
--     (m.max_stock - m.current_stock) * m.unit_cost as total_cost,
--     DATE_ADD(NOW(), INTERVAL 7 DAY) as expected_delivery_date,
--     'draft' as status,
--     'Auto-generated restock order' as notes,
--     1 as created_by_id
-- FROM materials m
-- WHERE m.current_stock < m.reorder_point
-- LIMIT 5;

-- View purchase orders:
SELECT 
    po.id,
    po.po_number,
    s.name as supplier,
    m.code as material_code,
    m.name as material_name,
    po.quantity_ordered,
    po.unit_price,
    po.total_cost,
    po.expected_delivery_date,
    po.status,
    u.user_id as created_by
FROM purchase_orders po
JOIN suppliers s ON po.supplier_id = s.id
JOIN materials m ON po.material_id = m.id
LEFT JOIN users u ON po.created_by_id = u.id
ORDER BY po.po_number DESC;

-- ============================================
-- SECTION 9: CREATE SAMPLE DEMAND APPROVALS
-- ============================================

-- This creates audit trail entries for existing demands
-- Example: Log existing approvals
-- INSERT INTO demand_approvals (demand_id, approval_level, approver_id, approval_status, approval_date, notes)
-- SELECT 
--     d.id,
--     'supervisor' as approval_level,
--     d.supervisor_id as approver_id,
--     d.supervisor_approval as approval_status,
--     d.supervisor_approval_date as approval_date,
--     d.supervisor_notes as notes
-- FROM spare_parts_demands d
-- WHERE d.supervisor_id IS NOT NULL 
-- AND d.supervisor_approval_date IS NOT NULL
-- AND NOT EXISTS (SELECT 1 FROM demand_approvals da WHERE da.demand_id = d.id AND da.approval_level = 'supervisor');

-- View audit trail:
SELECT 
    da.id,
    d.demand_number,
    u.user_id as requester,
    da.approval_level,
    appr.user_id as approver,
    da.approval_status,
    da.approval_date,
    da.notes
FROM demand_approvals da
JOIN spare_parts_demands d ON da.demand_id = d.id
JOIN users u ON d.requestor_id = u.id
LEFT JOIN users appr ON da.approver_id = appr.id
ORDER BY da.created_at DESC;

-- ============================================
-- SECTION 10: DATA VALIDATION QUERIES
-- ============================================

-- Check 1: Verify all users have user_id
SELECT 'CHECK: Users with user_id' as validation;
SELECT COUNT(*) as total_users, 
       SUM(CASE WHEN user_id IS NOT NULL THEN 1 ELSE 0 END) as users_with_id,
       SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) as users_without_id
FROM users;

-- Check 2: Verify supervision hierarchy
SELECT 'CHECK: Supervision Hierarchy' as validation;
SELECT 
    COUNT(*) as total_users,
    SUM(CASE WHEN supervisor_id IS NOT NULL THEN 1 ELSE 0 END) as users_with_supervisor,
    SUM(CASE WHEN supervisor_id IS NULL THEN 1 ELSE 0 END) as users_without_supervisor,
    COUNT(DISTINCT supervisor_id) as total_supervisors
FROM users;

-- Check 3: Verify department assignments
SELECT 'CHECK: Department Assignments' as validation;
SELECT 
    COUNT(*) as total_users,
    SUM(CASE WHEN department IS NOT NULL THEN 1 ELSE 0 END) as users_with_department,
    SUM(CASE WHEN department IS NULL THEN 1 ELSE 0 END) as users_without_department
FROM users;

-- Check 4: Verify material-supplier links
SELECT 'CHECK: Material-Supplier Links' as validation;
SELECT 
    COUNT(*) as total_materials,
    SUM(CASE WHEN supplier_id IS NOT NULL THEN 1 ELSE 0 END) as materials_linked,
    SUM(CASE WHEN supplier_id IS NULL THEN 1 ELSE 0 END) as materials_not_linked
FROM materials;

-- Check 5: Stock locations availability
SELECT 'CHECK: Stock Locations' as validation;
SELECT 
    COUNT(*) as total_locations,
    SUM(is_active) as active_locations,
    SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) as inactive_locations,
    SUM(capacity) as total_capacity
FROM stock_locations;

-- Check 6: Suppliers status
SELECT 'CHECK: Suppliers' as validation;
SELECT 
    COUNT(*) as total_suppliers,
    SUM(is_active) as active,
    SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) as inactive
FROM suppliers;

-- ============================================
-- SECTION 11: QUICK REFERENCE VIEWS
-- ============================================

-- View 1: Organization Full Structure
SELECT 'ORG_STRUCTURE' as section;
SELECT 
    u.user_id,
    u.username,
    u.role,
    u.status,
    u.department,
    COALESCE(s.user_id, '-') as supervisor_id,
    COALESCE(s.username, '-') as supervisor_name
FROM users u
LEFT JOIN users s ON u.supervisor_id = s.id
ORDER BY u.role, u.department, u.username;

-- View 2: Department Staff
SELECT 'DEPARTMENT_STAFF' as section;
SELECT 
    d.name as department,
    d.manager_id,
    COUNT(u.id) as staff_count,
    GROUP_CONCAT(DISTINCT u.role SEPARATOR ', ') as roles,
    d.budget_allocated,
    d.budget_remaining
FROM departments d
LEFT JOIN users u ON u.department = d.name
GROUP BY d.id, d.name
ORDER BY staff_count DESC;

-- View 3: Inventory Status
SELECT 'INVENTORY_STATUS' as section;
SELECT 
    m.code,
    m.name,
    m.current_stock,
    m.min_stock,
    m.max_stock,
    CASE 
        WHEN m.current_stock < m.min_stock THEN 'CRITICAL - ORDER NOW'
        WHEN m.current_stock < m.reorder_point THEN 'LOW - REORDER SOON'
        WHEN m.current_stock > m.max_stock THEN 'OVERSTOCK'
        ELSE 'OK'
    END as stock_status,
    COALESCE(s.name, 'NO SUPPLIER') as supplier
FROM materials m
LEFT JOIN suppliers s ON m.supplier_id = s.id
ORDER BY stock_status DESC, m.current_stock;

-- ============================================
-- CUSTOMIZATION INSTRUCTIONS
-- ============================================

/*
TO CUSTOMIZE THIS SCRIPT:

1. DEPARTMENTS:
   - Edit SECTION 1 with your actual departments
   - Update manager_id after you assign supervisors

2. SUPPLIERS:
   - Edit SECTION 2 with your real suppliers
   - Update contact information
   - Mark inactive suppliers as is_active = 0

3. STOCK LOCATIONS:
   - Edit SECTION 3 with your warehouse locations
   - Update building, floor, warehouse_section
   - Adjust capacity for each location

4. SUPERVISORS:
   - Run query in SECTION 4 to see users
   - Uncomment UPDATE statements for each technician
   - Execute one by one

5. DEPARTMENTS (Users):
   - View current assignments in SECTION 5
   - Update department field based on your org
   - Can use UPDATE with WHERE clause

6. SUPPLIERS (Materials):
   - Run query in SECTION 6 to see unlinked materials
   - Update material-supplier relationships
   - Uncomment and modify examples

7. PURCHASE ORDERS:
   - Uncomment SECTION 8 examples
   - Modify values for your suppliers and materials
   - Create orders in draft status for review

8. RUN VALIDATIONS:
   - After all customizations, run SECTION 10
   - Check all validation queries pass
   - Verify no NULL values where not allowed

9. GENERATE VIEWS:
   - Run SECTION 11 to see complete structure
   - Export results for reporting
   - Share org chart with team

IMPORTANT:
- Make a backup before running any UPDATE statements
- Test with SELECT before UPDATE
- Run validations after each major change
- Keep this file for future reference
*/
