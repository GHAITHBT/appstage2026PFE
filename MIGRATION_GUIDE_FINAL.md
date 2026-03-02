# Database Migration Guide - Final

## Executive Summary

Your database **already has excellent structure!** The good news:
- ✅ Approval workflow columns exist in spare_parts_demands
- ✅ Supervisor hierarchy logic exists
- ✅ Stock movements tracking exists
- ✅ Material returns are tracked

**What this migration adds:**
1. Formal `user_id` column (TECH001, SUP001, etc.)
2. Supervisor hierarchy (`supervisor_id` foreign key)
3. Department tracking (`department_id` in demands)
4. New reference tables: departments, suppliers, stock_locations, purchase_orders
5. Audit trail table: demand_approvals

---

## Pre-Migration Checklist

- [ ] Close all Flask applications
- [ ] Backup database (CRITICAL - see Step 1)
- [ ] Review current user list
- [ ] Plan your department structure
- [ ] Identify supervisors for each user

---

## Step-by-Step Migration

### **STEP 1: CREATE DATABASE BACKUP** (MOST IMPORTANT)

**Option A: Via MySQL Workbench (Recommended)**
1. Right-click on **maintenance_system** database
2. Select **Data Export**
3. Check "Export to Self-Contained File"
4. Click **Start Export**
5. Save file to safe location with name like: `backup_maintenance_system_20260227.sql`
6. **Wait for completion** before proceeding

**Option B: Via Command Line** (If available)
```bash
mysqldump -u root -p maintenance_system > backup_20260227.sql
```

**VERIFY**: Backup file size should be > 100KB

---

### **STEP 2: RUN MIGRATION SCRIPT**

1. Open **MIGRATION_FINAL.sql** in MySQL Workbench
2. **DO NOT** click "Execute All"
3. Instead, **run in sections**:
   - STEP 2: Add users columns (user_id, supervisor_id, status)
   - STEP 3: Add demands columns (department_id)
   - STEP 4-9: Create new tables
   - STEP 10: Generate user_id codes
   - STEP 11-13: Create sample data
   - STEP 14: Verify everything works

4. After each section, check results before moving next

**If error occurs:**
- Note the error message
- STOP - do not continue
- Restore from backup (see Rollback section)

---

### **STEP 3: VERIFY MIGRATION SUCCESS**

Run the verification queries from STEP 14 of MIGRATION_FINAL.sql:

**Expected Results:**
- Users table has columns: id, user_id, supervisor_id, status, ...
- All users have user_id like: TECH001, SUP001, etc.
- 4 departments created: Maintenance, Wiring, Tools & Equipment, Quality Control
- 3 suppliers created
- 3 stock_locations created
- No errors in any queries

---

### **STEP 4: UPDATE FLASK APPLICATION MODELS**

1. Backup current `app/models/__init__.py`
   ```bash
   copy app\models\__init__.py app\models\__init__.py.backup
   ```

2. Copy new models from `UPDATED_MODELS.py` into `app/models/__init__.py`

3. Restart Flask application:
   ```bash
   python main.py
   ```

4. Test that application still runs without errors

---

### **STEP 5: CUSTOMIZE ORGANIZATION STRUCTURE**

Edit your actual department managers, supervisor assignments, and user information.

**Via SQL (Advanced):**
```sql
-- Assign supervisor to technician
UPDATE users 
SET supervisor_id = (SELECT id FROM users WHERE username = 'supervisor_user')
WHERE username = 'technician_user';

-- Assign department manager
UPDATE departments 
SET manager_id = (SELECT id FROM users WHERE username = 'supervisor_user')
WHERE name = 'Maintenance';

-- Assign supplier to materials
UPDATE materials 
SET supplier_id = (SELECT id FROM suppliers WHERE name = 'Local Supplier A')
WHERE category = 'Wiring Components';
```

---

### **STEP 6: TEST COMPLETE WORKFLOW**

On Flask application:

1. ✅ **Admin Login** - Verify dashboard works
2. ✅ **Create New User** - Verify user_id auto-generated
3. ✅ **Create Spare Parts Demand** - Verify department tracked
4. ✅ **Supervisor Approval** - Verify approval workflow
5. ✅ **Stock Agent Approval** - Verify stock allocation
6. ✅ **Material Return** - Verify return tracking
7. ✅ **View Reports** - Verify audit trail visible

---

## Rollback Instructions

**If migration failed or you need to restore:**

### Option A: Restore via MySQL Workbench

1. Right-click on **maintenance_system** database
2. Select **Data Import/Restore**
3. Choose your backup file (e.g., backup_20260227.sql)
4. Click **Start Import**
5. Wait for completion
6. Verify data is restored

### Option B: Restore via Command Line

```bash
mysql -u root -p maintenance_system < backup_20260227.sql
```

### After Restore
- Verify old data is intact
- Check record counts match before migration
- Restart Flask application

---

## Database Schema Changes Summary

### **Users Table (MODIFIED)**
```
Added:
- user_id (VARCHAR 50) - Format: TECH001, SUP001, ADM001, STOCK001
- supervisor_id (INT FK) - Self-referential for hierarchy
- status (VARCHAR 50) - active/inactive/on_leave
```

### **Spare_Parts_Demands Table (MODIFIED)**
```
Added:
- department_id (INT FK) - Links to departments table
```

### **New Tables Created**
- **departments** - Company departments with manager and budget
- **suppliers** - Supplier information and contacts
- **stock_locations** - Warehouse locations and storage areas
- **purchase_orders** - PO tracking from suppliers
- **demand_approvals** - Audit trail for all approvals
- *(stock_movements)* - Already existed, no changes needed

---

## Common Issues & Solutions

### **Issue: Foreign Key Constraint Error**
```
Error: Cannot add foreign key constraint
```
**Solution:**
- Check that referenced table exists
- Verify data types match (both INT)
- Ensure no orphaned records

### **Issue: Duplicate Entry Error**
```
Error: Duplicate entry for UNIQUE constraint
```
**Solution:**
- user_id might exist if script ran twice
- Delete duplicate: `DELETE FROM users WHERE user_id IS NULL;`
- Re-run Step 10 of migration

### **Issue: Backup File Not Found**
**Solution:**
- Verify file path in Data Import dialog
- Ensure backup file was actually created
- Check file size > 100KB

---

## Post-Migration Validation Queries

Run these to ensure data integrity:

```sql
-- Check 1: All users have user_id
SELECT COUNT(*) FROM users WHERE user_id IS NULL;
-- Should return: 0

-- Check 2: Supervisors are valid
SELECT COUNT(*) FROM users WHERE supervisor_id IS NOT NULL 
AND supervisor_id NOT IN (SELECT id FROM users);
-- Should return: 0 (no orphaned supervisors)

-- Check 3: All demands have timestamps
SELECT COUNT(*) FROM spare_parts_demands WHERE created_at IS NULL;
-- Should return: 0

-- Check 4: Sample approval audit trail
SELECT 
    d.demand_number,
    u.user_id as requester,
    d.supervisor_id,
    d.supervisor_approval,
    d.stock_agent_approval
FROM spare_parts_demands d
JOIN users u ON d.requestor_id = u.id
LIMIT 5;
```

---

## Key Points to Remember

1. **User ID Format:**
   - TECH### = Technician
   - SUP###   = Supervisor
   - ADM###   = Admin
   - STOCK### = Stock Agent
   - ### = Padded ID (001, 002, etc.)

2. **Supervisor Hierarchy:**
   - Each user can have ONE supervisor
   - Supervisors are also users (recursive relationship)
   - Admins typically have no supervisor

3. **Department Tracking:**
   - Each demand now tracks which department requested it
   - Helps with budget allocation and department reports
   - Departments can have a manager assigned

4. **Approval Audit Trail:**
   - New `demand_approvals` table logs every approval action
   - Includes timestamp, approver, approval level, notes
   - Provides complete compliance trail

---

## Next: Update Flask Application

After successful migration, update your Flask routes to use new columns:

### Example: Create User with User ID
```python
@app.route('/admin/create-user', methods=['POST'])
def create_user():
    # user_id auto-generated by migration script
    # supervisor_id links to another user
    # department_id links to departments table
    
    new_user = User(
        username=request.form['username'],
        email=request.form['email'],
        role=request.form['role'],
        supervisor_id=request.form.get('supervisor_id'),  # New
        # user_id auto-generated
        # status auto-set to 'active'
    )
    db.session.add(new_user)
    db.session.commit()
```

### Example: Create Demand with Department
```python
@app.route('/demands/create', methods=['POST'])
def create_demand():
    demand = SparePartsDemand(
        demand_number=generate_demand_number(),
        requestor_id=current_user.id,
        material_id=request.form['material_id'],
        quantity_requested=request.form['quantity'],
        department_id=current_user.department_id,  # New
        priority=request.form.get('priority', 'medium'),
        status='pending'
    )
    db.session.add(demand)
    db.session.commit()
```

---

## Files Generated for This Migration

1. **MIGRATION_FINAL.sql** - Complete migration script (use this!)
2. **UPDATED_MODELS.py** - New Flask models with all relationships
3. **DATABASE_STRUCTURE_ALL_IN_ONE.sql** - Inspection script used for analysis
4. **This guide** - Step-by-step instructions

---

## Support Notes

- Migration is **idempotent** - can be run multiple times safely
- **No data loss** - all existing data preserved
- **Backwards compatible** - old columns kept for transition period
- **Read-only** first run - verify before committing to production

---

**Migration Ready!** 🚀

When ready, start with STEP 1 (backup) and proceed sequentially.
Good luck! 

*Questions? Review the "Common Issues" section above.*
