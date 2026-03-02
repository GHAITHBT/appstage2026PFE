# Stock Management System - Database Redesign Documentation

## Overview
This document outlines the comprehensive database redesign for the maintenance and stock management system, including proper tracking of user departments, supervisors, approval workflows, and complete audit trails.

---

## Key Changes & Improvements

### 1. **Department Management**
- New `departments` table to organize users by department
- Each user is assigned to a department (PPE, Maintenance, Operations, Stock, etc.)
- Enables better role-based access control and reporting

### 2. **User & Supervisor Tracking**
- `user_id`: Unique identifier for each user (e.g., TECH001, SUP001)
- `department_id`: Foreign key linking users to departments
- `supervisor_id`: Self-referential foreign key for supervisor assignment
- Enables hierarchical tracking of who reports to whom

### 3. **Complete Audit Trail**
All demand and approval actions now track:
- **WHO**: User ID and full name of person performing action
- **WHAT**: Type of action (approval, rejection, fulfillment)
- **WHEN**: Timestamp of action
- **WHERE**: Department and location
- **WHY**: Reasons and notes for decisions

### 4. **Enhanced Stock Management**
- Comprehensive inventory tracking with multiple locations
- Purchase order management with supplier tracking
- Stock movement history with full audit trail
- Automated stock alerts for low/overstock conditions

---

## Database Schema Details

### Tables Overview

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| `departments` | Organize users by department | name, description |
| `users` | User accounts with role/dept/supervisor | user_id, role, department_id, supervisor_id |
| `suppliers` | Supplier master data | name, code, contact info, payment terms |
| `materials` | Product/material master data | reference, designation, supplier_id, pricing |
| `stock_locations` | Physical warehouse locations | location_code, zone, capacity |
| `inventory` | Stock quantities by material/location | quantity_on_hand, quantity_reserved |
| `purchase_orders` | PO tracking with creator/status | po_number, material_id, order_date, status |
| `spare_parts_demands` | Material requests with full workflow | demand_number, requested_by_id, status |
| `demand_approvals` | Approval history for demands | approval_level, approved_by_id, status |
| `stock_movements` | Complete stock transaction history | movement_type, initiated_by_id, quantity_change |
| `stock_alerts` | System alerts for stock issues | alert_type, alert_status |

---

## User Role Hierarchy

```
ADMIN (System Administrator)
├── Full access to all features
├── Can manage users and departments
└── Can approve/reject any demand

SUPERVISOR (Department Supervisor)
├── Manages own department
├── Approves demands from subordinates
└── Cannot override other approvals

TECHNICIAN (Field Technician)
├── Can request spare parts
├── Cannot approve demands
└── Assigned to a supervisor

STOCK_AGENT (Stock Manager)
├── Manages inventory
├── Fulfills approved demands
└── Can check stock levels

OPERATOR (General Staff)
└── Basic system access for their role
```

---

## Supervisor Assignment Rules

1. **Technicians** are assigned to their department supervisor
2. **Supervisors** do NOT have a supervisor assigned (NULL in supervisor_id)
3. **Admins** are independent (NULL supervisor_id)
4. **Stock agents** report to Stock department manager

### Example Hierarchy:
```
Admin User (ADMIN)
├── Supervisor PPR-MNT (SUPERVISOR, dept: Maintenance)
│   ├── Jouini Abdelkader (TECHNICIAN)
│   ├── Oueslati Riadh (TECHNICIAN)
│   └── Fouzai Hassen (TECHNICIAN)
├── Supervisor PPE (SUPERVISOR, dept: PPE)
│   └── Team members...
└── Stock Manager (STOCK_AGENT, dept: Stock)
    └── Stock coordinators...
```

---

## Approval Workflow

### For Spare Parts Demands:

```
1. TECHNICIAN creates demand (status: pending)
   └─ Created by: Jouini Abdelkader
   └─ Department: Maintenance
   └─ Material: Roulement 6002-2Z
   └─ Quantity: 50

2. SUPERVISOR reviews (approval_level: supervisor)
   └─ Approved by: Supervisor PPR-MNT
   └─ Status changes to: approved_supervisor
   └─ Recorded in demand_approvals table

3. STOCK_AGENT reviews availability (approval_level: stock_agent)
   └─ Approved by: Stock Manager
   └─ Status changes to: approved_stock_agent
   └─ If available: Stock movement created (issue)
   └─ Status changes to: fulfilled

4. COMPLETE - Full audit trail maintained
```

---

## Stock Movement Tracking

### Movement Types:
- **receipt**: Stock received from purchase order
- **issue**: Stock issued for demand fulfillment
- **adjustment**: Inventory adjustment/count correction
- **return**: Material returned to stock
- **transfer**: Material moved between locations
- **damage**: Material marked as damaged
- **expired**: Material marked as expired

### Each Movement Records:
- Material and location
- Quantity changed
- Reference (PO number, demand number, etc.)
- Initiated by (who made the movement)
- Approved by (who authorized it)
- Timestamp
- Notes

---

## Data Migration Path

If migrating from existing system:

1. **Backup existing database**
   ```sql
   mysqldump -u root -p maintenance_system > backup_$(date +%Y%m%d).sql
   ```

2. **Create new tables** (run new_schema.sql)
   ```sql
   SOURCE new_schema.sql;
   ```

3. **Migrate existing data** (review migration queries needed)
   - Map old users to new user structure
   - Assign departments to users
   - Assign supervisors based on org structure
   - Migrate materials and suppliers
   - Migrate inventory quantities

4. **Test thoroughly** before going to production
   - Verify all relationships
   - Check data integrity
   - Test approval workflows

---

## Sample Query Examples

### Get all demands for a specific technician with full approval history:
```sql
SELECT 
    spd.demand_number,
    m.reference,
    m.designation,
    spd.quantity_requested,
    spd.demand_status,
    u.full_name as requested_by,
    d.name as department,
    da.approval_level,
    u2.full_name as approved_by,
    da.approval_status,
    da.approval_date
FROM spare_parts_demands spd
JOIN materials m ON spd.material_id = m.id
JOIN users u ON spd.requested_by_id = u.id
JOIN departments d ON spd.department_id = d.id
LEFT JOIN demand_approvals da ON spd.id = da.demand_id
WHERE u.user_id = 'TECH001'
ORDER BY spd.created_at DESC;
```

### Get complete stock movement history for audit:
```sql
SELECT 
    sm.id,
    m.reference,
    m.designation,
    sm.movement_type,
    sm.quantity_change,
    sl.location_code,
    u1.full_name as initiated_by,
    u2.full_name as approved_by,
    sm.reference_number,
    sm.movement_date,
    sm.notes
FROM stock_movements sm
JOIN materials m ON sm.material_id = m.id
JOIN stock_locations sl ON sm.location_id = sl.id
JOIN users u1 ON sm.initiated_by_id = u1.id
LEFT JOIN users u2 ON sm.approved_by_id = u2.id
WHERE m.reference = '1014'
ORDER BY sm.movement_date DESC;
```

### Get current stock status with demand forecast:
```sql
SELECT 
    m.reference,
    m.designation,
    m.min_quantity,
    m.max_quantity,
    COALESCE(SUM(i.quantity_on_hand), 0) as current_stock,
    COALESCE(SUM(i.quantity_reserved), 0) as reserved,
    COALESCE(SUM(i.quantity_on_hand), 0) - COALESCE(SUM(i.quantity_reserved), 0) as available,
    s.name as supplier,
    m.unit_price_eur,
    COUNT(DISTINCT spd.id) as pending_demands
FROM materials m
LEFT JOIN inventory i ON m.id = i.material_id
LEFT JOIN suppliers s ON m.supplier_id = s.id
LEFT JOIN spare_parts_demands spd ON m.id = spd.material_id AND spd.demand_status NOT IN ('fulfilled', 'cancelled')
GROUP BY m.id
HAVING current_stock < m.min_quantity
ORDER BY available ASC;
```

### Get supervisor's pending approvals:
```sql
SELECT 
    spd.demand_number,
    u.full_name as requester,
    m.reference,
    m.designation,
    spd.quantity_requested,
    spd.priority,
    d.name as department,
    spd.created_at
FROM spare_parts_demands spd
JOIN materials m ON spd.material_id = m.id
JOIN users u ON spd.requested_by_id = u.id
JOIN departments d ON spd.department_id = d.id
WHERE spd.demand_status = 'pending'
    AND u.supervisor_id = (SELECT id FROM users WHERE user_id = 'SUP001')
ORDER BY spd.priority DESC, spd.created_at ASC;
```

---

## Implementation Checklist

- [ ] Backup current database
- [ ] Review new schema and required changes
- [ ] Run new_schema.sql to create tables
- [ ] Run sample_data.sql for test data
- [ ] Update Python models (updated_models.py)
- [ ] Update Flask routes to use new models
- [ ] Create/update department setup in UI
- [ ] Test user creation with department assignment
- [ ] Test approval workflows
- [ ] Verify audit trail logging
- [ ] Update reports to show new tracking data
- [ ] Performance testing with production-like data
- [ ] User training on new workflow
- [ ] Deploy to production

---

## Support

For questions or issues with the new schema:
1. Review the comments in new_schema.sql
2. Check the sample queries for reference
3. Verify foreign key relationships
4. Enable query logging to debug issues
