# Quick Migration Reference

## Files Created for Database Migration

### 1. **migration_existing_db.sql**
- Transforms existing database schema
- Adds new columns to existing tables
- Creates new required tables
- Sets up foreign key relationships
- **Status**: Safe to run multiple times (uses IF NOT EXISTS)

### 2. **migration_populate_data.sql**
- Populates new columns with data
- Creates department structure
- Assigns users to departments
- Establishes supervisor relationships
- **Status**: Requires customization for your organization

### 3. **updated_models.py**
- New Flask SQLAlchemy models
- Includes Department, User updates
- New approval/movement tracking models
- **Status**: Replace your existing models

### 4. **MIGRATION_GUIDE.md**
- Complete step-by-step guide
- Troubleshooting tips
- Useful queries
- Rollback procedures

---

## Quick Start (5 Steps)

### Step 1: Backup Database
```bash
mysqldump -u root -p maintenance_system > backup_$(date +%Y%m%d).sql
```

### Step 2: Run Migration
```bash
mysql -u root -p maintenance_system < migration_existing_db.sql
```

### Step 3: Populate Data
```bash
mysql -u root -p maintenance_system < migration_populate_data.sql
```

### Step 4: Customize Organization
Edit `migration_populate_data.sql` and update these sections with YOUR data:
- Department list
- User-to-department assignments
- Supervisor-technician relationships

### Step 5: Update Application
Replace Flask models and update routes to use new columns

---

## What Gets Added/Changed

### Existing Tables - NEW COLUMNS

**users table:**
- `user_id` - Unique identifier (TECH001, SUP001, etc.)
- `department_id` - FK to departments
- `supervisor_id` - Self-referential FK
- `status` - active/inactive/suspended

**materials table:**
- `code_frs` - French reference code
- `category` - Material category
- `supplier_id` - FK to suppliers
- `min_quantity` - Minimum stock level
- `max_quantity` - Maximum stock level
- `reorder_quantity` - Reorder point
- `unit_price_eur` - Unit price
- `status` - active/discontinued/obsolete

**spare_parts_demands table:**
- `requested_by_id` - FK to users (who requested)
- `department_id` - FK to departments
- `required_by_date` - When needed
- `notes` - Additional notes

**inventory table:**
- `location_id` - FK to stock_locations
- `quantity_reserved` - Reserved stock
- `status` - good/damaged/expired/quarantine
- `last_count_date` - Last physical count

---

### NEW TABLES Created

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| departments | Organize users | name, description |
| suppliers | Supplier info | name, code, contact, terms |
| stock_locations | Warehouse locations | location_code, capacity |
| purchase_orders | PO tracking | po_number, qty, status |
| demand_approvals | Approval history | demand_id, approved_by_id, status |
| stock_movements | Audit trail | movement_type, qty_change, initiated_by |
| stock_alerts | Stock alerts | alert_type, material_id, status |

---

## Organization Structure Template

### Your Department List
```
1. Maintenance (ID: 2)
   - Supervisor: Supervisor PPR-MNT (ID: 1)
   - Technicians: Jouini, Oueslati, Fouzai, etc.

2. PPE Team (ID: 1)
   - Supervisor: Supervisor PPE (ID: 2)
   - Team members: ...

3. Operations (ID: 4)
   - Supervisor: Supervisor Ops (ID: 3)
   - Operators: ...

4. Stock Management (ID: 6)
   - Manager: Stock Manager (ID: 5)
   - Assistants: ...
```

### Your Supervisor Assignments
```
Jouini Abdelkader (ID: 3) → Supervisor: Supervisor PPR-MNT (ID: 1)
Oueslati Riadh (ID: 4) → Supervisor: Supervisor PPR-MNT (ID: 1)
Fouzai Hassen (ID: 5) → Supervisor: Supervisor PPR-MNT (ID: 1)
...
```

---

## Database Size Impact

| Item | Approximate Size |
|------|------------------|
| New columns added | ~50-100 KB |
| New tables created | ~100-200 KB |
| Indexes added | ~50-100 KB |
| **Total growth** | **~250 KB** |

---

## Performance Impact

- ✅ New indexes improve query speed
- ✅ Denormalized fields reduce joins
- ✅ Minimal impact on existing queries
- ✅ Slight overhead for audit logging

---

## Testing Before Production

### Test Cases to Run

1. **User Management**
   - [ ] Can create new user with department
   - [ ] Can assign supervisor to technician
   - [ ] Can change user department

2. **Demand Workflow**
   - [ ] Technician can create demand
   - [ ] Supervisor sees pending demands
   - [ ] Approval creates history record
   - [ ] Rejection reason is saved

3. **Stock Tracking**
   - [ ] Stock movement logged
   - [ ] Audit trail shows who/when/why
   - [ ] Alerts triggered when stock low
   - [ ] Movement visible in reports

4. **Reporting**
   - [ ] Department reports work
   - [ ] Supervisor can see team demands
   - [ ] Audit trail queries return data
   - [ ] Stock movement history complete

---

## Rollback Procedure

If migration fails:

```bash
# Restore from backup
mysql -u root -p maintenance_system < backup_YYYYMMDD.sql

# Verify restore
mysql -u root -p maintenance_system -e "SELECT COUNT(*) FROM users;"
```

**Time needed**: 5-30 minutes (depending on database size)

---

## After Migration Checklist

- [ ] Run verification queries
- [ ] Check for NULL values in critical columns
- [ ] Verify foreign key constraints
- [ ] Test approval workflow
- [ ] Test stock tracking
- [ ] Run report queries
- [ ] Monitor application logs
- [ ] Train users on new features

---

## Command Reference

### View Migration Status
```bash
# Check table structure
mysql -u root -p maintenance_system -e "
  SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_NAME = 'users';"
```

### Count Records
```bash
mysql -u root -p maintenance_system -e "
  SELECT 
    (SELECT COUNT(*) FROM users) as users,
    (SELECT COUNT(*) FROM materials) as materials,
    (SELECT COUNT(*) FROM departments) as departments,
    (SELECT COUNT(*) FROM spare_parts_demands) as demands;"
```

### Verify Relationships
```bash
mysql -u root -p maintenance_system -e "
  SELECT u.full_name, d.name as department, s.full_name as supervisor
  FROM users u
  LEFT JOIN departments d ON u.department_id = d.id
  LEFT JOIN users s ON u.supervisor_id = s.id;"
```

---

## Next Steps After Migration

1. **Update Models**: Replace `app/models/__init__.py` with `updated_models.py`
2. **Update Routes**: Modify routes to use new columns
3. **Update Templates**: Show department/supervisor info
4. **Test Thoroughly**: Run through all workflows
5. **Deploy**: Move to production
6. **Train Users**: Show new features and workflows
7. **Monitor**: Watch for any issues in production

---

## Support Resources

- **MIGRATION_GUIDE.md** - Detailed step-by-step guide
- **DATABASE_REDESIGN.md** - Schema documentation & sample queries
- **new_schema.sql** - Complete fresh schema (reference only)
- **sample_data.sql** - Example data for testing

---

## Estimated Timeline

| Phase | Time | Notes |
|-------|------|-------|
| Pre-migration planning | 30 min | Review org structure |
| Database backup | 10 min | Always backup first |
| Run migration script | 5 min | Alter existing tables |
| Populate data | 10 min | Assign departments/supervisors |
| Test & verify | 1-2 hrs | Run test cases |
| Update code | 1-2 hrs | Update models and routes |
| Production deployment | 30 min | Deploy with backup ready |
| **Total** | **3-5 hours** | Depends on complexity |

---

## Emergency Contact Points

If issues arise:
1. Check MIGRATION_GUIDE.md troubleshooting section
2. Review sample queries for data validation
3. Restore from backup if needed
4. Contact database administrator

---

**Version**: 1.0
**Last Updated**: February 27, 2026
**Status**: Ready for production
