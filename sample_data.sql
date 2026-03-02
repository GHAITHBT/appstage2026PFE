-- ============================================
-- SAMPLE INSERT DATA BASED ON PROVIDED EXAMPLE
-- ============================================

-- ============================================
-- 1. INSERT DEPARTMENTS
-- ============================================
INSERT INTO departments (name, description) VALUES
('PPE', 'Personal Protective Equipment'),
('PPR-MNT', 'Preventive Maintenance'),
('PHSE', 'Health & Safety'),
('Operations', 'Operations Department'),
('Maintenance', 'Maintenance Department'),
('Stock Management', 'Stock & Inventory Management');

-- ============================================
-- 2. INSERT SUPPLIERS
-- ============================================
INSERT INTO suppliers (name, code, contact_person, email, phone, city, country, status) VALUES
('ATF TECHNOLOGIE', '800163', 'Contact Person', 'info@atf-tech.com', '+33 1 2345 6789', 'Paris', 'France', 'active'),
('HARTECH INTERNATIONAL', '800471', 'Contact Person', 'info@hartech.com', '+1 234 567 8900', 'New York', 'USA', 'active'),
('Komax Tunisia', '800123', 'Contact Person', 'info@komax-tn.com', '+216 71 123 456', 'Tunis', 'Tunisia', 'active'),
('Boudrant', '800229', 'Contact Person', 'info@boudrant.fr', '+33 2 9876 5432', 'Lyon', 'France', 'active'),
('MOHAMED MELKI TOURNAGE FRAISAGE', '800019', 'Mohamed Melki', 'contact@melki-production.tn', '+216 74 234 567', 'Sfax', 'Tunisia', 'active'),
('Mibostahl GmbH', '72598', 'Contact Person', 'info@mibostahl.de', '+49 234 567 8900', 'Stuttgart', 'Germany', 'active');

-- ============================================
-- 3. INSERT USERS WITH DEPARTMENTS & SUPERVISORS
-- ============================================
-- Admin User
INSERT INTO users (user_id, full_name, email, password_hash, role, department_id, supervisor_id, status) VALUES
('ADMIN001', 'Admin User', 'admin@sumitomo.com', 'hashed_password_here', 'admin', 1, NULL, 'active');

-- Supervisors
INSERT INTO users (user_id, full_name, email, password_hash, role, department_id, supervisor_id, status) VALUES
('SUP001', 'Supervisor PPR-MNT', 'supervisor.ppr@sumitomo.com', 'hashed_password_here', 'supervisor', 2, NULL, 'active'),
('SUP002', 'Supervisor PPE', 'supervisor.ppe@sumitomo.com', 'hashed_password_here', 'supervisor', 1, NULL, 'active'),
('SUP003', 'Supervisor Ops', 'supervisor.ops@sumitomo.com', 'hashed_password_here', 'supervisor', 4, NULL, 'active');

-- Technicians & Operators (with supervisors assigned)
INSERT INTO users (user_id, full_name, email, password_hash, role, department_id, supervisor_id, status) VALUES
('TECH001', 'Jouini Abdelkader', 'jouini.abdelkader@sumitomo.com', 'hashed_password_here', 'technician', 2, 1, 'active'),
('TECH002', 'Oueslati Riadh', 'oueslati.riadh@sumitomo.com', 'hashed_password_here', 'technician', 2, 1, 'active'),
('TECH003', 'Fouzai Hassen', 'fouzai.hassen@sumitomo.com', 'hashed_password_here', 'technician', 2, 1, 'active'),
('TECH004', 'Souissi Bilel', 'souissi.bilel@sumitomo.com', 'hashed_password_here', 'technician', 2, 1, 'active'),
('TECH005', 'Soudani Aymen', 'soudani.aymen@sumitomo.com', 'hashed_password_here', 'technician', 2, 1, 'active'),
('TECH006', 'Khemiri Haythem', 'khemiri.haythem@sumitomo.com', 'hashed_password_here', 'technician', 2, 1, 'active'),
('TECH007', 'Bellali Adel', 'bellali.adel@sumitomo.com', 'hashed_password_here', 'technician', 2, 1, 'active'),
('OP001', 'Jamai Anis', 'jamai.anis@sumitomo.com', 'hashed_password_here', 'operator', 4, 3, 'active');

-- Stock Agent
INSERT INTO users (user_id, full_name, email, password_hash, role, department_id, supervisor_id, status) VALUES
('STOCK001', 'Stock Manager', 'stock.manager@sumitomo.com', 'hashed_password_here', 'stock_agent', 6, NULL, 'active');

-- ============================================
-- 4. INSERT STOCK LOCATIONS
-- ============================================
INSERT INTO stock_locations (location_code, location_name, warehouse_zone, capacity) VALUES
('A_37', 'Shelf A-37', 'Zone A', 500),
('A_39', 'Shelf A-39', 'Zone A', 500),
('A_40', 'Shelf A-40', 'Zone A', 500),
('A_41', 'Shelf A-41', 'Zone A', 500),
('A_42', 'Shelf A-42', 'Zone A', 500),
('A_54', 'Shelf A-54', 'Zone A', 300),
('W_60', 'Warehouse W-60', 'Zone W', 1000),
('W_64', 'Warehouse W-64', 'Zone W', 1000),
('W_17', 'Warehouse W-17', 'Zone W', 800),
('O_1', 'Office O-1', 'Zone O', 200);

-- ============================================
-- 5. INSERT MATERIALS (Sample from provided data)
-- ============================================
-- Tapes
INSERT INTO materials (reference, designation, code_frs, category, supplier_id, unit_of_measure, min_quantity, max_quantity, unit_price_eur, status) VALUES
('293', 'Ruban Jaune 50mmx33m', '800163', 'Tapes', 1, 'PCS', 85, 128, 4.38, 'active'),
('294', 'Ruban Rouge 50mmx33m', '800163', 'Tapes', 1, 'PCS', 6, 9, 4.33, 'active'),
('295', 'Ruban Bleu 50mmx33m', '800163', 'Tapes', 1, 'PCS', 13, 20, 4.39, 'active'),
('296', 'Ruban Vert 50mmx33m', '800471', 'Tapes', 2, 'PCS', 2, 3, 4.38, 'active'),
('297', 'Ruban Rouge/Blanc 50mmx33m', '800471', 'Tapes', 2, 'PCS', 9, 14, 6.67, 'active');

-- Fuses
INSERT INTO materials (reference, designation, code_frs, category, supplier_id, unit_of_measure, min_quantity, max_quantity, unit_price_eur, status) VALUES
('545', 'Fusible 5*20 10AT', '800123', 'Electrical', 3, 'PCS', 1, 2, 2.14, 'active'),
('551', 'Fusible 5*20 6,3AT', '800123', 'Electrical', 3, 'PCS', 1, 2, 1.90, 'active'),
('553', 'Fusible 5x20 1AT', '800123', 'Electrical', 3, 'PCS', 1, 2, 1.96, 'active');

-- Bearings & Mechanical Parts
INSERT INTO materials (reference, designation, code_frs, category, supplier_id, unit_of_measure, min_quantity, max_quantity, unit_price_eur, status) VALUES
('1010', 'Roulement rainure a billes', '800123', 'Bearings', 3, 'PCS', 1, 1, 2.92, 'active'),
('1013', 'Roulement rainure a bille 608-2Z', '800123', 'Bearings', 3, 'PCS', 3, 5, 2.95, 'active'),
('1014', 'Roulement rainure a bille 6002-2Z', '800123', 'Bearings', 3, 'PCS', 27, 41, 3.48, 'active'),
('1512', 'Roue de mesure', '800123', 'Mechanical', 3, 'PCS', 3, 5, 105.85, 'active');

-- Fasteners (Screws, Bolts, Nuts)
INSERT INTO materials (reference, designation, code_frs, category, supplier_id, unit_of_measure, min_quantity, max_quantity, unit_price_eur, status) VALUES
('1742', 'Vis à tète cylindrique M3x6 inoxydable', '800123', 'Fasteners', 3, 'BOX', 3, 5, 2.20, 'active'),
('1744', 'Vis à tete cyl 6p ,cr,M5X20.8.8 vzb', '800123', 'Fasteners', 3, 'BOX', 6, 9, 2.22, 'active'),
('1745', 'Vis tète cyl M6x16', '800123', 'Fasteners', 3, 'BOX', 4, 6, 1.99, 'active'),
('3776', 'Ecrou M4', '800123', 'Fasteners', 3, 'BOX', 17, 26, 1.59, 'active');

-- Tools & Equipment
INSERT INTO materials (reference, designation, code_frs, category, supplier_id, unit_of_measure, min_quantity, max_quantity, unit_price_eur, status) VALUES
('8097', 'STRIPPING PLIERS 0.2-6 MM2 , 200 MM', '800471', 'Tools', 2, 'PCS', 4, 6, 59.57, 'active');

-- Lubricants
INSERT INTO materials (reference, designation, code_frs, category, supplier_id, unit_of_measure, min_quantity, max_quantity, unit_price_eur, status) VALUES
('1297', 'HUILE PNEUMATIQUE OFSW-32, 1LITRE', '800123', 'Lubricants', 3, 'L', 1, 2, 28.00, 'active');

-- ============================================
-- 6. INSERT INVENTORY DATA
-- ============================================
-- Populate inventory with quantities from the example
INSERT INTO inventory (material_id, location_id, quantity_on_hand, quantity_reserved, status) VALUES
-- Ruban Jaune (293) - 0 on hand, 150 ordered
((SELECT id FROM materials WHERE reference = '293'), (SELECT id FROM stock_locations WHERE location_code = 'A_41'), 0, 0, 'good'),
-- Ruban Vert (296) - 84 on hand
((SELECT id FROM materials WHERE reference = '296'), (SELECT id FROM stock_locations WHERE location_code = 'A_37'), 84, 0, 'good'),
-- Fusible 5*20 10AT (545) - 13 on hand
((SELECT id FROM materials WHERE reference = '545'), (SELECT id FROM stock_locations WHERE location_code = 'W_60'), 13, 0, 'good'),
-- Roulement 6002-2Z (1014) - 42 on hand
((SELECT id FROM materials WHERE reference = '1014'), (SELECT id FROM stock_locations WHERE location_code = 'W_60'), 42, 0, 'good'),
-- Ecrou M4 (3776) - 34 on hand
((SELECT id FROM materials WHERE reference = '3776'), (SELECT id FROM stock_locations WHERE location_code = 'W_60'), 34, 0, 'good'),
-- Tools (8097) - 5 on hand
((SELECT id FROM materials WHERE reference = '8097'), (SELECT id FROM stock_locations WHERE location_code = 'A_54'), 5, 0, 'good');

-- ============================================
-- 7. INSERT SAMPLE PURCHASE ORDERS
-- ============================================
INSERT INTO purchase_orders (po_number, material_id, supplier_id, quantity_ordered, unit_price_eur, order_date, expected_delivery, status, created_by_id) VALUES
('PO-2025-001', (SELECT id FROM materials WHERE reference = '293'), 1, 150, 4.38, '2025-11-27', '2025-12-27', 'pending', (SELECT id FROM users WHERE user_id = 'ADMIN001')),
('PO-2025-002', (SELECT id FROM materials WHERE reference = '294'), 1, 10, 4.33, '2025-11-27', '2025-12-27', 'pending', (SELECT id FROM users WHERE user_id = 'ADMIN001')),
('PO-2025-003', (SELECT id FROM materials WHERE reference = '1014'), 3, 50, 3.48, '2025-12-11', '2026-01-11', 'confirmed', (SELECT id FROM users WHERE user_id = 'STOCK001')),
('PO-2025-004', (SELECT id FROM materials WHERE reference = '1512'), 3, 3, 105.85, '2025-12-11', '2026-01-11', 'shipped', (SELECT id FROM users WHERE user_id = 'STOCK001'));

-- ============================================
-- 8. INSERT SAMPLE SPARE PARTS DEMANDS
-- ============================================
INSERT INTO spare_parts_demands (demand_number, material_id, quantity_requested, priority, requested_by_id, department_id, request_date, required_by_date, demand_status, notes) VALUES
('DEM-2026-001', (SELECT id FROM materials WHERE reference = '1014'), 50, 'high', (SELECT id FROM users WHERE user_id = 'TECH001'), 2, NOW(), DATE_ADD(NOW(), INTERVAL 5 DAY), 'approved_stock_agent', 'Required for maintenance'),
('DEM-2026-002', (SELECT id FROM materials WHERE reference = '545'), 10, 'urgent', (SELECT id FROM users WHERE user_id = 'TECH002'), 2, NOW(), DATE_ADD(NOW(), INTERVAL 2 DAY), 'pending', 'Critical for production'),
('DEM-2026-003', (SELECT id FROM materials WHERE reference = '1512'), 3, 'medium', (SELECT id FROM users WHERE user_id = 'TECH003'), 2, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), 'fulfilled', 'Scheduled maintenance'),
('DEM-2026-004', (SELECT id FROM materials WHERE reference = '8097'), 2, 'low', (SELECT id FROM users WHERE user_id = 'TECH004'), 1, NOW(), DATE_ADD(NOW(), INTERVAL 10 DAY), 'supervisor_review', 'Tool replacement for team');

-- ============================================
-- 9. INSERT DEMAND APPROVALS HISTORY
-- ============================================
INSERT INTO demand_approvals (demand_id, approval_level, approved_by_id, approval_status, approval_date, notes) VALUES
((SELECT id FROM spare_parts_demands WHERE demand_number = 'DEM-2026-001'), 'supervisor', (SELECT id FROM users WHERE user_id = 'SUP001'), 'approved', NOW(), 'Approved by supervisor'),
((SELECT id FROM spare_parts_demands WHERE demand_number = 'DEM-2026-001'), 'stock_agent', (SELECT id FROM users WHERE user_id = 'STOCK001'), 'approved', DATE_ADD(NOW(), INTERVAL 1 DAY), 'Stock available, order fulfilled'),
((SELECT id FROM spare_parts_demands WHERE demand_number = 'DEM-2026-002'), 'supervisor', (SELECT id FROM users WHERE user_id = 'SUP001'), 'pending', NULL, 'Awaiting supervisor review'),
((SELECT id FROM spare_parts_demands WHERE demand_number = 'DEM-2026-003'), 'supervisor', (SELECT id FROM users WHERE user_id = 'SUP001'), 'approved', NOW(), 'Approved and fulfilled'),
((SELECT id FROM spare_parts_demands WHERE demand_number = 'DEM-2026-003'), 'stock_agent', (SELECT id FROM users WHERE user_id = 'STOCK001'), 'approved', DATE_ADD(NOW(), INTERVAL 1 DAY), 'Picked and delivered'),
((SELECT id FROM spare_parts_demands WHERE demand_number = 'DEM-2026-004'), 'supervisor', (SELECT id FROM users WHERE user_id = 'SUP002'), 'pending', NULL, 'Under review');

-- ============================================
-- 10. INSERT STOCK MOVEMENTS
-- ============================================
INSERT INTO stock_movements (material_id, location_id, movement_type, quantity_change, reference_number, reference_type, initiated_by_id, approved_by_id, notes, movement_date) VALUES
((SELECT id FROM materials WHERE reference = '1014'), (SELECT id FROM stock_locations WHERE location_code = 'W_60'), 'receipt', 50, 'PO-2025-003', 'purchase_order', (SELECT id FROM users WHERE user_id = 'STOCK001'), (SELECT id FROM users WHERE user_id = 'SUP001'), 'Received from supplier', DATE_SUB(NOW(), INTERVAL 5 DAY)),
((SELECT id FROM materials WHERE reference = '1014'), (SELECT id FROM stock_locations WHERE location_code = 'W_60'), 'issue', -50, 'DEM-2026-001', 'demand', (SELECT id FROM users WHERE user_id = 'STOCK001'), (SELECT id FROM users WHERE user_id = 'TECH001'), 'Issued to technician', DATE_SUB(NOW(), INTERVAL 2 DAY)),
((SELECT id FROM materials WHERE reference = '545'), (SELECT id FROM stock_locations WHERE location_code = 'W_60'), 'adjustment', 5, 'ADJ-2026-001', 'adjustment', (SELECT id FROM users WHERE user_id = 'STOCK001'), (SELECT id FROM users WHERE user_id = 'ADMIN001'), 'Inventory count adjustment', DATE_SUB(NOW(), INTERVAL 7 DAY)),
((SELECT id FROM materials WHERE reference = '296'), (SELECT id FROM stock_locations WHERE location_code = 'A_37'), 'receipt', 84, 'PO-2025-ALT', 'purchase_order', (SELECT id FROM users WHERE user_id = 'STOCK001'), NULL, 'Initial stock receipt', DATE_SUB(NOW(), INTERVAL 30 DAY));

-- ============================================
-- 11. INSERT STOCK ALERTS
-- ============================================
INSERT INTO stock_alerts (material_id, alert_type, alert_status, description) VALUES
((SELECT id FROM materials WHERE reference = '293'), 'low_stock', 'active', 'Stock below minimum quantity (0/85). PO-2025-001 pending'),
((SELECT id FROM materials WHERE reference = '294'), 'low_stock', 'active', 'Stock below minimum quantity (0/6). PO-2025-002 pending'),
((SELECT id FROM materials WHERE reference = '545'), 'low_stock', 'acknowledged', 'Stock at acceptable level (13/1)', (SELECT id FROM users WHERE user_id = 'SUP001'), NOW(), 'Monitored');

-- ============================================
-- VERIFY INSERTS (Optional - for checking)
-- ============================================
-- SELECT COUNT(*) FROM departments;
-- SELECT COUNT(*) FROM users;
-- SELECT COUNT(*) FROM suppliers;
-- SELECT COUNT(*) FROM materials;
-- SELECT COUNT(*) FROM stock_locations;
-- SELECT COUNT(*) FROM inventory;
-- SELECT COUNT(*) FROM purchase_orders;
-- SELECT COUNT(*) FROM spare_parts_demands;
-- SELECT COUNT(*) FROM demand_approvals;
-- SELECT COUNT(*) FROM stock_movements;
