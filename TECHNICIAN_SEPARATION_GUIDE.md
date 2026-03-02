# Technician Separation & Role-Based View Implementation Guide

## Overview
This document outlines the implementation of complete role separation between technicians and stock agents, with dedicated interfaces for each role.

---

## 1. Architecture Changes

### New Routes Module
- **File**: `app/routes/technician.py` (NEW)
- **Blueprint**: `technician_bp` with URL prefix `/technician`
- **Purpose**: All technician-specific operations isolated from other user roles

### Updated Components
- **File**: `app/__init__.py` - Registered new `technician_bp` blueprint
- **File**: `app/templates/base.html` - Added technician navigation link
- **File**: `app/models/__init__.py` - Enhanced models with new fields
- **File**: `app/routes/maintenance.py` - Updated to capture machine_name in reports

---

## 2. Technician Routes & Features

### Dashboard
- **Route**: `/technician/` or `/technician/dashboard`
- **Access**: Technicians only
- **Shows**:
  - Your zone/assignment
  - Count of available materials
  - Count of pending returns awaiting approval
  - Recent maintenance reports
  - Quick action buttons

### Available Stock View
- **Route**: `/technician/available-stock`
- **Access**: Technicians only
- **Features**:
  - Shows only materials with `current_stock > 0`
  - Search by name or code
  - Filter by category
  - Pagination (20 items per page)
  - Read-only view (technicians can view but not edit)

### Material Return Request Form
- **Route**: `/technician/material-return` (GET/POST)
- **Access**: Technicians only
- **Form Fields**:
  - Material to Return (dropdown of fulfilled demands)
  - Quantity to Return (number)
  - Reason for Return (dropdown with 6 predefined options)
  - Condition of Material (5 condition types)
  - Additional Notes (optional)
- **Workflow**:
  1. Technician submits return request
  2. Status becomes "Pending Approval"
  3. Stock agent reviews and accepts/rejects
  4. Upon acceptance, material returns to stock

### Return Status Tracking
- **Route**: `/technician/return-status`
- **Access**: Technicians only
- **Shows**:
  - Count of pending, approved, and rejected returns
  - List of all technician's return requests
  - Filter by status (Pending, Approved, Rejected)
  - Detail modal for each return with full information
  - Includes approval date and stock agent notes

### Maintenance History
- **Route**: `/technician/maintenance-history`
- **Access**: Technicians only
- **Shows**:
  - All maintenance reports created by technician
  - Filter by machine name
  - Filter by report type (Standard/Detailed)
  - Display both standard and detailed report information
  - Detail modal with complete report data

---

## 3. Maintenance Report Forms

### Standard Report
- Basic information (start time, end time)
- Work description
- Findings and actions taken
- Issues found (checkbox + description if checked)
- Components replaced
- Next maintenance recommendation

### Detailed Report
**All Standard fields PLUS:**
- Machine condition before maintenance
- Machine condition after maintenance
- Environmental conditions (temperature, humidity, lighting, etc.)
- Safety observations and concerns
- Tools used during maintenance

### Creating Reports
1. **Access**: `/maintenance/choose-report-type`
2. **Select**: Standard or Detailed
3. **Fill Form**: Appropriate fields for selected type
4. **Breakdown Time**: Calculated from start/end times
5. **Auto-Captured**: 
   - Technician zone (from user profile)
   - Machine name (from schedule)
   - Creation timestamp

---

## 4. Database Schema Updates

### New Columns

#### `users` table
- `zone VARCHAR(100)` - Work area/zone for technicians

#### `maintenance_reports` table
- `machine_name VARCHAR(200)` - Cached machine name
- `report_type VARCHAR(50)` - 'standard' or 'detailed'
- `technician_zone VARCHAR(100)` - Zone where work was done
- `machine_condition VARCHAR(50)` - Before condition
- `machine_condition_after VARCHAR(50)` - After condition
- `environmental_conditions TEXT` - Environmental notes
- `safety_observations TEXT` - Safety observations
- `tools_used TEXT` - Tools used

#### `spare_parts_demands` table
- `quantity_returned INT` - Tracks quantity returned
- `return_date DATETIME` - When returned
- `return_notes TEXT` - Return details

#### `stock_movements` table
- `return_reason TEXT` - Reason for return movement

#### `material_returns` table (NEW)
- `id INT PRIMARY KEY`
- `demand_id INT FK` - Links to original demand
- `material_id INT FK` - Links to material
- `quantity_returned INT` - Amount being returned
- `return_reason TEXT` - Why returning (excess, defective, etc.)
- `condition_of_material VARCHAR(50)` - Condition when returned
- `returned_by_id INT FK` - Technician who returned it
- `received_by_id INT FK` - Stock agent who processed it
- `return_status VARCHAR(50)` - pending/accepted/rejected
- `notes TEXT` - Technician notes
- `approved_notes TEXT` - Stock agent approval notes
- `created_at TIMESTAMP` - Submission date
- `approved_date TIMESTAMP` - Approval date
- `processed_at TIMESTAMP` - Processing date

---

## 5. Templates Created

### Technician Interface
All templates located in `app/templates/technician/`:

1. **dashboard.html**
   - Zone display
   - Stock availability counter
   - Pending returns counter
   - Recent maintenance log
   - Quick action buttons

2. **available_stock.html**
   - Material list table
   - Search and filter options
   - Pagination controls
   - Stock quantity badges

3. **material_return.html**
   - Return request form with 5 sections
   - Dropdown for fulfilled demands
   - Return reason and condition selectors
   - Process explanation sidebar

4. **return_status.html**
   - Status summary cards (pending, approved, rejected, total)
   - Return requests table with filtering
   - Detail modals for each request
   - Approval information and notes

5. **maintenance_history.html**
   - Report list with machine/type filters
   - Detailed and standard report display
   - Condition before/after cards (for detailed reports)
   - Full detail modals with all fields

### Updated Templates
- **base.html** - Added technician dashboard nav link
- **maintenance/create_report.html** - Already supports standard/detailed types

---

## 6. Stock Agent Approval Process

### Stock Agent Routes (Existing)
- **Route**: `/stock/returns-pending`
- **Route**: `/stock/return/<id>/accept`
- **Route**: `/stock/return/<id>/reject`

### Workflow
1. Technician submits material return
2. Stock agent views pending returns at `/stock/returns-pending`
3. Stock agent accepts/rejects each return
4. Upon acceptance:
   - Material stock quantity increases
   - Stock movement record created with type='returned'
   - Technician receives notification via status view
   - Status changes to 'accepted' with approval date

---

## 7. Migration Instructions

### Database Update
Execute the migration.sql file to update your existing database:

```bash
mysql -u your_user -p your_database < migration.sql
```

**Or run queries individually:**
```sql
-- Add zone to technicians
ALTER TABLE users ADD COLUMN zone VARCHAR(100) AFTER department;

-- Update maintenance_reports with new columns
ALTER TABLE maintenance_reports ADD COLUMN machine_name VARCHAR(200) AFTER technician_id;
ALTER TABLE maintenance_reports ADD COLUMN report_type VARCHAR(50) DEFAULT 'standard' AFTER next_maintenance_recommendation;
-- ... (see migration.sql for all queries)

-- Create material_returns table
CREATE TABLE material_returns (
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
    approved_date TIMESTAMP,
    processed_at TIMESTAMP,
    FOREIGN KEY (demand_id) REFERENCES spare_parts_demands(id) ON DELETE CASCADE,
    FOREIGN KEY (material_id) REFERENCES materials(id),
    FOREIGN KEY (returned_by_id) REFERENCES users(id),
    FOREIGN KEY (received_by_id) REFERENCES users(id),
    INDEX idx_demand_id (demand_id),
    INDEX idx_material_id (material_id),
    INDEX idx_created_at (created_at)
);
```

---

## 8. User Flow by Role

### Technician Flow
1. Login → Dashboard
2. View available materials → Check stock
3. Create maintenance report (standard or detailed)
4. Request material return → Fill form → Submit
5. Track return status → See approval/rejection
6. View maintenance history → Filter by machine/type

### Stock Agent Flow
1. Login → Stock Management
2. View inventory and stock movements
3. View pending material returns
4. Accept/reject returns with notes
5. Material automatically restored to stock upon acceptance

### Admin/Supervisor Flow
1. Access all views
2. Manage zones for technicians
3. View all reports and returns
4. Override decisions if needed

---

## 9. Key Features

✅ **Complete Role Separation**
- Technician sees only available stock (not full inventory)
- Technician can only return materials from fulfilled demands
- Stock agents have approval authority

✅ **Detailed Tracking**
- All return reasons and conditions captured
- Approval notes from stock agents
- Complete audit trail with timestamps
- Movement history updated automatically

✅ **Enhanced Maintenance Reporting**
- Standard vs. Detailed report types
- Machine condition tracking (before/after)
- Safety and environmental observations
- Tool usage documentation
- Breakdown time calculated from timestamps

✅ **Dashboard Navigation**
- Separate technician hub accessible from dashboard
- Quick access buttons for common tasks
- Status cards with counts
- Recent activity log

---

## 10. File Structure Summary

```
app/
├── routes/
│   ├── technician.py (NEW) - 273 lines
│   ├── maintenance.py (UPDATED) - machine_name added
│   └── main.py (EXISTING) - stock agent approval
├── models/
│   └── __init__.py (UPDATED) - New fields & MaterialReturn model
├── templates/
│   ├── technician/ (NEW)
│   │   ├── dashboard.html
│   │   ├── available_stock.html
│   │   ├── material_return.html
│   │   ├── return_status.html
│   │   └── maintenance_history.html
│   └── base.html (UPDATED) - Tech nav link
├── __init__.py (UPDATED) - Registered technician_bp
└── static/
    └── css/style.css (EXISTING)

migration.sql - Updated with all ALTER TABLE commands
```

---

## 11. Testing Checklist

- [ ] Run migration.sql against your database
- [ ] Login as technician
- [ ] Verify Technician Hub appears in navigation
- [ ] View dashboard - all sections should load
- [ ] Check available stock - only items with stock > 0 show
- [ ] Create a maintenance report (both standard and detailed)
- [ ] Submit a material return request
- [ ] Check return status - should show 'Pending Approval'
- [ ] Login as stock agent
- [ ] View pending returns
- [ ] Accept a return - quantity should update in inventory
- [ ] Verify technician can see 'Approved' status
- [ ] Check stock movement history - return movement visible

---

## 12. Notes

- Machine names are cached in reports for faster access and historical accuracy
- All timestamps use UTC
- Breakdown time is automatically calculated from start/end times
- Material returns link back to original demand for history
- Stock movements now track return reasons
- All queries include proper indexing for performance
- Role-based access control enforced on all routes

---

## Next Steps

1. Execute migration.sql
2. Restart the Flask application
3. Test all features with different user roles
4. Monitor for any database constraint issues
5. Provide technician training on new interface

