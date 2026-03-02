# How to Inspect Database Structure in MySQL Workbench

## Step-by-Step Guide

### Step 1: Open MySQL Workbench
1. Launch MySQL Workbench
2. Connect to your database server
3. Click on your `maintenance_system` database in the navigator

### Step 2: Open SQL Editor
- Go to **File → New Query Tab** or press `Ctrl+T`
- Copy and paste queries from `INSPECT_DATABASE_STRUCTURE.sql`
- Run each query section by section

### Step 3: Run Inspection Queries in Order

#### Query 1: List All Tables
```sql
SELECT TABLE_NAME, TABLE_TYPE, ENGINE, TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system'
ORDER BY TABLE_NAME;
```
**What to look for:**
- ✓ Do you see: users, materials, spare_parts_demands, inventory?
- ✓ Do you see: stock_alerts, stock_locations, suppliers, departments?
- ✓ Check TABLE_ROWS to see how much data in each table

#### Query 2: Check Users Table Structure
```sql
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'users'
ORDER BY ORDINAL_POSITION;
```
**What to look for:**
- ✓ Does it have: user_id, department_id, supervisor_id, status?
- ✗ Missing columns = we need to add them

#### Query 3: Check Materials Table Structure
```sql
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'materials'
ORDER BY ORDINAL_POSITION;
```
**What to look for:**
- ✓ Does it have: supplier_id, min_quantity, max_quantity, unit_price_eur?
- ✗ Missing columns = we need to add them

#### Query 4: Check Spare Parts Demands Structure
```sql
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'spare_parts_demands'
ORDER BY ORDINAL_POSITION;
```
**What to look for:**
- ✓ Does it have: requested_by_id, department_id, required_by_date, notes?
- ✗ Missing columns = we need to add them

#### Query 5: Check What New Tables Exist
```sql
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'maintenance_system'
AND TABLE_NAME IN ('departments', 'suppliers', 'stock_locations', 
                   'purchase_orders', 'demand_approvals', 'stock_movements');
```
**What to look for:**
- ✓ Which tables already exist
- ✗ Which tables are missing and need to be created

#### Query 6: Check Data Records
```sql
SELECT 
    'users' as table_name, COUNT(*) as record_count FROM users
UNION ALL
SELECT 'materials', COUNT(*) FROM materials
UNION ALL
SELECT 'spare_parts_demands', COUNT(*) FROM spare_parts_demands
UNION ALL
SELECT 'inventory', COUNT(*) FROM inventory;
```
**What to look for:**
- How many records in each table
- This helps plan backup size and migration time

---

## MySQL Workbench Tips

### Running Multiple Queries
1. **Select all text**: `Ctrl+A`
2. **Execute**: `Ctrl+Enter` or click ⚡ button
3. **Results**: Show in tabs below editor

### Using the Results
- **Copy all**: Right-click → Export Result Set
- **Save as**: Can save results to CSV
- **Filter results**: Type in search box at top of results

### Table Inspector
Alternative: Use **MySQL Workbench Navigator**
1. Right-click table name
2. Select **Inspect Table**
3. Scroll through columns, indexes, triggers, etc.

---

## What to Do After Inspection

Based on what you find, send me the results of these queries:

### Report What You Find:

**1. From "List All Tables" query:**
```
Copy & paste the TABLE_NAME column showing:
- Which tables exist
- How many rows in each
```

**2. From "Check Users Table" query:**
```
Copy & paste all COLUMN_NAME values to show:
- What columns currently exist
```

**3. From "Check Materials Table" query:**
```
Copy & paste all COLUMN_NAME values
```

**4. From "Check Demands Table" query:**
```
Copy & paste all COLUMN_NAME values
```

**5. From "Check New Tables Exist" query:**
```
Copy & paste which tables exist/missing
```

---

## Example Output Format

**What MySQL Workbench will show:**

```
users table columns:
- id (INT)
- full_name (VARCHAR)
- email (VARCHAR)
- password_hash (VARCHAR)
- role (VARCHAR)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

```
New tables status:
- departments: MISSING (need to create)
- suppliers: MISSING (need to create)
- stock_locations: EXISTS
- purchase_orders: MISSING (need to create)
- demand_approvals: MISSING (need to create)
- stock_movements: MISSING (need to create)
```

---

## After You Run the Queries

1. **Copy the results**
2. **Send them to me**
3. **I'll create targeted migration script** that:
   - Only adds missing columns
   - Only creates missing tables
   - Doesn't touch existing data
   - Is customized for your actual database

---

## Backup Before Making Changes

```sql
-- Before running migration, backup your database
-- In MySQL Workbench terminal:
mysqldump -u root -p maintenance_system > backup_before_migration.sql
```

---

## Next Steps

1. ✅ Open MySQL Workbench
2. ✅ Run the inspection queries from `INSPECT_DATABASE_STRUCTURE.sql`
3. ✅ Copy the results
4. ✅ Share results with me
5. ✅ I'll provide customized migration script
6. ✅ Run migration with backup ready
7. ✅ Test everything

---

## Quick Copy-Paste Queries

Copy each section below and paste into MySQL Workbench:

### Quick Check - All Tables
```sql
SELECT TABLE_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'maintenance_system';
```

### Quick Check - Users Columns
```sql
SELECT COLUMN_NAME, COLUMN_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'users';
```

### Quick Check - Materials Columns
```sql
SELECT COLUMN_NAME, COLUMN_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'materials';
```

### Quick Check - Demands Columns
```sql
SELECT COLUMN_NAME, COLUMN_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'maintenance_system' AND TABLE_NAME = 'spare_parts_demands';
```

### Quick Check - Missing Tables
```sql
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'maintenance_system'
AND TABLE_NAME IN ('departments', 'suppliers', 'stock_locations', 
                   'purchase_orders', 'demand_approvals', 'stock_movements');
```

---

## Expected Output Examples

If your database is NEW:
- ✓ departments: MISSING
- ✓ suppliers: MISSING
- ✓ All new columns: MISSING
- **Action**: Run full migration script

If your database is PARTIALLY MIGRATED:
- ✓ users table: has some new columns
- ✓ departments table: EXISTS
- ✗ demand_approvals: MISSING
- **Action**: Run partial migration script

If your database is FULLY MIGRATED:
- ✓ All tables: EXIST
- ✓ All columns: EXIST
- **Action**: Just run data population script

---

## Support

If you have questions while running queries:
1. Check the comments in each query (what to look for)
2. Look at the expected output examples
3. Message with your actual results
4. I'll give you exact commands to run next
