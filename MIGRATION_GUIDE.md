# Database Migration Guide

## Overview
This guide helps you migrate your existing maintenance system database to the new enhanced schema with department tracking, supervisor assignment, and complete audit trails.

---

## Pre-Migration Checklist

- [ ] **BACKUP DATABASE** - This is CRITICAL!
  ```bash
  mysqldump -u root -p maintenance_system > backup_$(date +%Y%m%d_%H%M%S).sql
  ```

- [ ] Review current database structure
- [ ] Document your organizational hierarchy
- [ ] Identify supervisor relationships
- [ ] List all departments/teams

---

## Migration Steps

### Step 1: Backup Your Database
```bash
# Full backup
mysqldump -u root -p maintenance_system > maintenance_system_backup.sql

# Verify backup was created
ls -lh maintenance_system_backup.sql
```

### Step 2: Run Migration Script
```bash
# Connect to MySQL
mysql -u root -p

# Select database
USE maintenance_system;

# Run migration script
SOURCE migration_existing_db.sql;

# Check for errors and verify
SHOW TABLES;
```

### Step 3: Verify Migration Worked
```sql
-- Check new columns exist
DESCRIBE users;
DESCRIBE materials;
DESCRIBE spare_parts_demands;

-- Check new tables created
SHOW TABLES LIKE '%approval%';
SHOW TABLES LIKE '%movement%';
SHOW TABLES LIKE '%alert%';

-- Count records
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_materials FROM materials;
SELECT COUNT(*) as total_departments FROM departments;
```

### Step 4: Run Data Population Script
```bash
# Connect to MySQL
mysql -u root -p maintenance_system < migration_populate_data.sql
```

### Step 5: Customize Your Organization

**IMPORTANT**: You need to customize the organization structure for YOUR company.

#### 5a. Set Up Departments
```sql
-- View current departments
SELECT * FROM departments;

-- Add your departments (customize these)
INSERT INTO departments (name, description) VALUES
('Maintenance Team 1', 'First maintenance shift'),
('Maintenance Team 2', 'Second maintenance shift'),
('Quality Control', 'Quality and testing'),
('Stock Management', 'Inventory and stock');
```

#### 5b. Assign Users to Departments
```sql
-- View current users and their departments
SELECT id, full_name, role, department_id FROM users;

-- Assign users to departments (replace IDs with yours)
UPDATE users 
SET department_id = (SELECT id FROM departments WHERE name = 'Maintenance Team 1')
WHERE id IN (3, 4, 5, 6);  -- Replace with your actual user IDs

UPDATE users 
SET department_id = (SELECT id FROM departments WHERE name = 'Stock Management')
WHERE role = 'stock_agent';
```

#### 5c. Assign Supervisors
```sql
-- View current supervisors
SELECT id, full_name, role, department_id FROM users 
WHERE role IN ('supervisor', 'admin');

-- Assign supervisors to technicians (replace IDs with yours)
UPDATE users 
SET supervisor_id = 2  -- Replace 2 with your supervisor's ID
WHERE id IN (3, 4, 5);  -- Replace with technician IDs

-- Verify assignments
SELECT 
    u1.id, 
    u1.full_name, 
    u1.role, 
    (SELECT full_name FROM users WHERE id = u1.supervisor_id) as supervisor
FROM users u1 
WHERE u1.supervisor_id IS NOT NULL;
```

#### 5d. Assign Existing Demands to Users/Departments
```sql
-- If your existing demands don't have requested_by_id, assign them
-- Find demands without creator info
SELECT COUNT(*) FROM spare_parts_demands WHERE requested_by_id IS NULL;

-- Assign to a default user (usually admin or stock manager)
UPDATE spare_parts_demands 
SET requested_by_id = 1,  -- Replace 1 with your admin/stock user ID
    department_id = (SELECT id FROM departments WHERE name = 'Stock Management' LIMIT 1)
WHERE requested_by_id IS NULL;

-- Verify
SELECT COUNT(*) FROM spare_parts_demands WHERE requested_by_id IS NULL;
```

### Step 6: Verify Data Integrity
```sql
-- Run verification queries
SELECT 
    u.id,
    u.user_id,
    u.full_name,
    u.role,
    d.name as department,
    COALESCE(s.full_name, '-') as supervisor_name
FROM users u
LEFT JOIN departments d ON u.department_id = d.id
LEFT JOIN users s ON u.supervisor_id = s.id
ORDER BY u.role, u.full_name;

-- Check for unassigned records
SELECT COUNT(*) as users_without_dept FROM users WHERE department_id IS NULL;
SELECT COUNT(*) as demands_without_requester FROM spare_parts_demands WHERE requested_by_id IS NULL;
SELECT COUNT(*) as materials_without_supplier FROM materials WHERE supplier_id IS NULL;
```

### Step 7: Update Flask Models
Replace your old models with the new ones from `updated_models.py`

```bash
# Backup old models
cp app/models/__init__.py app/models/__init__.py.bak

# Copy new models
cp updated_models.py app/models/__init__.py
```

### Step 8: Update Flask Routes
Update your routes to use new columns:

```python
# Example: When creating a demand
demand = SparePartsDemand(
    demand_number="DEM-2026-001",
    material_id=1,
    quantity_requested=50,
    priority="high",
    requested_by_id=current_user.id,  # NEW
    department_id=current_user.department_id,  # NEW
    required_by_date=datetime.now() + timedelta(days=5)  # NEW
)
db.session.add(demand)
db.session.commit()
```

### Step 9: Test System
- [ ] Log in with different user roles
- [ ] Create a new demand and verify it captures user_id and department_id
- [ ] Test approval workflow
- [ ] Verify supervisor can see subordinate demands
- [ ] Check stock movement logging works
- [ ] Verify audit trail is populated

### Step 10: Deploy to Production
Once tested locally:
1. Run migration script on production database
2. Deploy updated code
3. Verify all functionality works
4. Monitor logs for errors

---

## Troubleshooting

### Issue: Foreign key constraint error
```
Error 1452: Cannot add or update a child row

Solution:
- Ensure parent records exist before inserting child records
- Check that referenced IDs actually exist in parent table
```

### Issue: Column already exists error
```
Error 1060: Duplicate column name

Solution:
- The migration script uses "ADD COLUMN IF NOT EXISTS"
- This is normal and means the column was already there
- Check if migration partially completed and restart
```

### Issue: Can't assign supervisor
```
Solution:
- Ensure supervisor_id references a valid user ID
- Verify that user has role 'supervisor' or 'admin'
- Check: SELECT * FROM users WHERE id = <supervisor_id>;
```

### Issue: Demands missing requester info
```sql
-- Find problematic demands
SELECT * FROM spare_parts_demands WHERE requested_by_id IS NULL;

-- Manually assign them
UPDATE spare_parts_demands 
SET requested_by_id = 1 
WHERE id = <demand_id>;
```

---

## Useful Queries After Migration

### Get Supervisor's Pending Approvals
```sql
SELECT 
    spd.demand_number,
    u.full_name as requester,
    m.reference,
    m.designation,
    spd.quantity_requested,
    spd.priority,
    spd.created_at
FROM spare_parts_demands spd
JOIN materials m ON spd.material_id = m.id
JOIN users u ON spd.requested_by_id = u.id
WHERE spd.demand_status = 'pending'
    AND u.supervisor_id = (SELECT id FROM users WHERE user_id = 'SUP001')
ORDER BY spd.priority DESC;
```

### Get All Demands by Department
```sql
SELECT 
    d.name as department,
    COUNT(*) as total_demands,
    SUM(CASE WHEN demand_status = 'pending' THEN 1 ELSE 0 END) as pending,
    SUM(CASE WHEN demand_status = 'fulfilled' THEN 1 ELSE 0 END) as fulfilled
FROM spare_parts_demands spd
JOIN departments d ON spd.department_id = d.id
GROUP BY d.id, d.name;
```

### Get Stock Movement Audit Trail
```sql
SELECT 
    sm.movement_date,
    sm.movement_type,
    m.reference,
    m.designation,
    sm.quantity_change,
    u1.full_name as initiated_by,
    COALESCE(u2.full_name, '-') as approved_by,
    sm.notes
FROM stock_movements sm
JOIN materials m ON sm.material_id = m.id
JOIN users u1 ON sm.initiated_by_id = u1.id
LEFT JOIN users u2 ON sm.approved_by_id = u2.id
WHERE m.reference = '1014'
ORDER BY sm.movement_date DESC;
```

---

## Post-Migration Checklist

- [ ] All users have department_id assigned
- [ ] All supervisors have NULL supervisor_id (except admin)
- [ ] All technicians have supervisor_id assigned
- [ ] All materials have supplier_id assigned
- [ ] Existing demands have requested_by_id and department_id
- [ ] New tables created: demand_approvals, stock_movements, stock_alerts
- [ ] Flask models updated
- [ ] Routes updated to use new columns
- [ ] Approval workflow tested
- [ ] Stock tracking tested
- [ ] Audit trail verified
- [ ] Users trained on new process

---

## Rollback Plan (If Needed)

If something goes wrong and you need to rollback:

```bash
# Restore from backup
mysql -u root -p maintenance_system < maintenance_system_backup.sql

# Or manually restore
mysql -u root -p < backup_20260227_120000.sql
```

---

## Support Contacts

For questions or issues:
1. Check the `DATABASE_REDESIGN.md` file
2. Review sample queries in this guide
3. Check database logs for errors

---

## Timeline

- **Phase 1**: Backup & Migration (30 minutes)
- **Phase 2**: Organization Setup (1-2 hours)
- **Phase 3**: Testing (2-4 hours)
- **Phase 4**: Deployment (1 hour)
- **Phase 5**: Training & Documentation (2-4 hours)

**Total estimated time**: 6-12 hours (depending on complexity)
