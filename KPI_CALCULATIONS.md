# KPI Calculations Documentation

## Overview
This document explains how each Key Performance Indicator (KPI) is calculated from the database for both Maintenance and Stock Management analytics dashboards.

---

## MAINTENANCE KPIs (Admin & Supervisor)

### 1. **Total Events**
- **Definition**: Total number of maintenance reports created within the selected date range
- **Database Calculation**:
  ```sql
  SELECT COUNT(*) FROM maintenance_reports
  WHERE created_at BETWEEN start_date AND end_date
  ```
- **Location**: `app/routes/main.py` - Line ~170
- **Filter**: Date range (default: last 30 days)

### 2. **Total Downtime (hours)**
- **Definition**: Sum of all actual maintenance duration hours in the date range
- **Database Calculation**:
  ```sql
  SELECT SUM(actual_duration_hours) FROM maintenance_reports
  WHERE created_at BETWEEN start_date AND end_date
  ```
- **Location**: `app/routes/main.py` - Line ~180
- **Used For**: Calculating availability rate and MTTR

### 3. **Canceled Events**
- **Definition**: Number of maintenance reports with status 'rejected' in the date range
- **Database Calculation**:
  ```sql
  SELECT COUNT(*) FROM maintenance_reports
  WHERE report_status = 'rejected'
  AND created_at BETWEEN start_date AND end_date
  ```
- **Location**: `app/routes/main.py` - Line ~190
- **Used For**: Calculating failure rate and MTBF

### 4. **Avg Downtime (seconds)**
- **Definition**: Average duration per maintenance event converted to seconds
- **Calculation Formula**:
  ```
  IF total_events > 0:
    avg_hours = SUM(actual_duration_hours) / COUNT(*)
    avg_downtime_seconds = avg_hours * 3600
  ELSE:
    avg_downtime_seconds = 0
  ```
- **Location**: `app/routes/main.py` - Line ~200

### 5. **Availability Rate (%)**
- **Definition**: Percentage of time equipment was operational (not under maintenance)
- **Calculation Formula**:
  ```
  IF total_downtime_hours > 0 AND total_events > 0:
    operational_hours = (end_date - start_date).total_seconds() / 3600
    availability_rate = (1 - (total_downtime_hours / operational_hours)) * 100
    CLAMP(availability_rate, 0, 100)
  ELSE:
    availability_rate = 0
  ```
- **Location**: `app/routes/main.py` - Line ~210
- **Note**: Assumes 24-hour operation per day

### 6. **Failure Rate (per hour)**
- **Definition**: Number of failures per hour of operation
- **Calculation Formula**:
  ```
  failure_rate = canceled_events / total_downtime_hours (if > 0 else 1)
  ```
- **Database**: Aggregates from maintenance_reports
- **Location**: `app/routes/main.py` - Line ~220

### 7. **MTTR - Mean Time To Repair (seconds)**
- **Definition**: Average time it takes to complete a maintenance task
- **Database Calculation**:
  ```sql
  SELECT AVG(actual_duration_hours) FROM maintenance_reports
  WHERE created_at BETWEEN start_date AND end_date
  AND actual_duration_hours IS NOT NULL
  ```
- **Conversion**: `avg_hours * 3600 = seconds`
- **Location**: `app/routes/main.py` - Line ~230
- **Lower is Better**: Indicates faster repairs

### 8. **MTBF - Mean Time Between Failures (hours)**
- **Definition**: Average time between equipment failures (higher is better)
- **Calculation Formula**:
  ```
  IF canceled_events > 0:
    operational_days = (end_date - start_date).days
    mtbf_hours = (operational_days * 24) / canceled_events
  ELSE:
    mtbf_hours = 0
  ```
- **Location**: `app/routes/main.py` - Line ~240

### 9. **Most Common Event Type**
- **Definition**: The most frequently occurring maintenance report type (standard/detailed)
- **Database Calculation**:
  ```sql
  SELECT report_type, COUNT(*) as count
  FROM maintenance_reports
  WHERE created_at BETWEEN start_date AND end_date
  GROUP BY report_type
  ORDER BY count DESC
  LIMIT 1
  ```
- **Location**: `app/routes/main.py` - Line ~250

### 10. **Most Active User**
- **Definition**: Technician with the most maintenance reports completed
- **Database Calculation**:
  ```sql
  SELECT users.first_name, users.last_name, COUNT(*)
  FROM maintenance_reports
  JOIN users ON users.id = maintenance_reports.technician_id
  WHERE maintenance_reports.created_at BETWEEN start_date AND end_date
  GROUP BY maintenance_reports.technician_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
  ```
- **Location**: `app/routes/main.py` - Line ~260

### 11. **Top Resolver**
- **Definition**: User with highest approval rate in completed maintenance
- **Database Calculation**:
  ```sql
  SELECT users.first_name, users.last_name, COUNT(*) as total,
         SUM(CASE WHEN report_status = 'approved' THEN 1 ELSE 0 END) as approved
  FROM maintenance_reports
  JOIN users ON users.id = maintenance_reports.technician_id
  WHERE maintenance_reports.created_at BETWEEN start_date AND end_date
  GROUP BY users.id
  ORDER BY approved DESC
  LIMIT 1
  ```
- **Location**: `app/routes/main.py` - Line ~270

### 12. **Most Common Maintenance Type**
- **Definition**: Most frequently found machine condition before maintenance
- **Database Calculation**:
  ```sql
  SELECT machine_condition, COUNT(*) as count
  FROM maintenance_reports
  WHERE created_at BETWEEN start_date AND end_date
  AND machine_condition IS NOT NULL
  GROUP BY machine_condition
  ORDER BY count DESC
  LIMIT 1
  ```
- **Location**: `app/routes/main.py` - Line ~280

### 13. **Events per Machine** (Chart)
- **Definition**: Count of maintenance events per machine (top 10)
- **Database Calculation**:
  ```sql
  SELECT machine_name, COUNT(*) as count, SUM(actual_duration_hours) as total_hours
  FROM maintenance_reports
  WHERE created_at BETWEEN start_date AND end_date
  GROUP BY machine_name
  ORDER BY count DESC
  LIMIT 10
  ```
- **Location**: `app/routes/main.py` - Line ~290

### 14. **Events by Type** (Chart)
- **Definition**: Distribution of maintenance events by report status
- **Database Calculation**:
  ```sql
  SELECT report_status, COUNT(*) as count
  FROM maintenance_reports
  WHERE created_at BETWEEN start_date AND end_date
  GROUP BY report_status
  ```
- **Location**: `app/routes/main.py` - Line ~305

---

## STOCK MANAGEMENT KPIs (Admin, Supervisor, & Stock Agent)

### 1. **Total Spare Parts**
- **Definition**: Total count of unique materials/spare parts in the system
- **Database Calculation**:
  ```sql
  SELECT COUNT(*) FROM materials
  ```
- **Location**: `app/routes/main.py` - Line ~320
- **Note**: Not filtered by date (system total)

### 2. **Total Stock Value**
- **Definition**: Total monetary value of all current inventory
- **Calculation Formula**:
  ```
  total_value = SUM(material.current_stock * material.unit_cost)
  ```
- **Database Calculation**:
  ```sql
  SELECT SUM(current_stock * unit_cost) FROM materials
  ```
- **Location**: `app/routes/main.py` - Line ~325
- **Currency**: System currency (default USD)

### 3. **Low Stock Items**
- **Definition**: Number of materials with stock at or below minimum threshold
- **Database Calculation**:
  ```sql
  SELECT COUNT(*) FROM materials
  WHERE current_stock <= min_stock
  ```
- **Location**: `app/routes/main.py` - Line ~330
- **Alert Level**: Requires attention but not critical

### 4. **Overstock Items**
- **Definition**: Number of materials with stock at or above maximum capacity
- **Database Calculation**:
  ```sql
  SELECT COUNT(*) FROM materials
  WHERE current_stock >= max_stock
  ```
- **Location**: `app/routes/main.py` - Line ~335
- **Issue**: Excessive inventory ties up capital

### 5. **Critical Stock Items**
- **Definition**: Materials with zero stock or at reorder point
- **Database Calculation**:
  ```sql
  SELECT COUNT(*) FROM materials
  WHERE current_stock = 0
  OR current_stock <= reorder_point
  ```
- **Location**: `app/routes/main.py` - Line ~340
- **Alert Level**: URGENT - Needs immediate restocking

### 6. **Average Stock Level**
- **Definition**: Average quantity of stock across all materials
- **Calculation Formula**:
  ```
  avg_stock = SUM(current_stock) / COUNT(materials)
  ```
- **Location**: `app/routes/main.py` - Line ~345
- **Use Case**: Determines overall inventory health

### 7. **Stock In (Units)**
- **Definition**: Total units received/added to inventory in date range
- **Database Calculation**:
  ```sql
  SELECT SUM(quantity) FROM stock_movements
  WHERE movement_type IN ('in', 'receipt')
  AND created_at BETWEEN start_date AND end_date
  ```
- **Location**: `app/routes/main.py` - Line ~355

### 8. **Stock Out (Units)**
- **Definition**: Total units issued/allocated/removed in date range
- **Database Calculation**:
  ```sql
  SELECT SUM(quantity) FROM stock_movements
  WHERE movement_type IN ('out', 'issue', 'allocated')
  AND created_at BETWEEN start_date AND end_date
  ```
- **Location**: `app/routes/main.py` - Line ~365
- **Net Flow**: Stock Out - Stock In = Net Change

### 9. **Most Used Material**
- **Definition**: Material with highest movement quantity in date range
- **Database Calculation**:
  ```sql
  SELECT m.name, SUM(sm.quantity) as total_moved
  FROM stock_movements sm
  JOIN materials m ON m.id = sm.material_id
  WHERE sm.created_at BETWEEN start_date AND end_date
  GROUP BY m.id
  ORDER BY total_moved DESC
  LIMIT 1
  ```
- **Location**: `app/routes/main.py` - Line ~375
- **Use Case**: Identify which parts are in highest demand

### 10. **Top Value Material**
- **Definition**: Material with the highest current inventory value
- **Calculation Formula**:
  ```
  material_value = current_stock * unit_cost
  TOP = MAX(material_value)
  ```
- **Database Calculation**:
  ```sql
  SELECT name, (current_stock * unit_cost) as total_value
  FROM materials
  WHERE unit_cost IS NOT NULL
  ORDER BY total_value DESC
  LIMIT 1
  ```
- **Location**: `app/routes/main.py` - Line ~390
- **Use Case**: Identifies expensive materials to optimize

### 11. **Active Alerts**
- **Definition**: Number of unread stock alerts in the system
- **Database Calculation**:
  ```sql
  SELECT COUNT(*) FROM stock_alerts
  WHERE is_read = FALSE
  ```
- **Location**: `app/routes/main.py` - Line ~400
- **Alert Types**: low_stock, overstock, critical, expired

### 12. **Materials by Category** (Chart)
- **Definition**: Count of materials and total stock per category
- **Database Calculation**:
  ```sql
  SELECT category, COUNT(*) as count, SUM(current_stock) as total_stock
  FROM materials
  WHERE category IS NOT NULL
  GROUP BY category
  ORDER BY count DESC
  ```
- **Location**: `app/routes/main.py` - Line ~405
- **Use Case**: Inventory distribution analysis

### 13. **Stock Movement Summary** (Chart)
- **Definition**: Summary of all movement types in date range
- **Database Calculation**:
  ```sql
  SELECT movement_type, COUNT(*) as count, SUM(quantity) as total_quantity
  FROM stock_movements
  WHERE created_at BETWEEN start_date AND end_date
  GROUP BY movement_type
  ```
- **Location**: `app/routes/main.py` - Line ~420
- **Types**: in, out, allocated, returned, adjusted, etc.

---

## Database Schema References

### MaintenanceReport Fields
- `id` - Primary key
- `technician_id` - Who performed the maintenance
- `actual_duration_hours` - Time spent
- `report_status` - draft, submitted, approved, rejected
- `report_type` - standard, detailed
- `machine_condition` - Working condition assessment
- `machine_name` - Equipment name
- `created_at` - Report creation timestamp
- `updated_at` - Last update timestamp

### Material Fields
- `id` - Primary key
- `name` - Material/part name
- `current_stock` - Current quantity in inventory
- `min_stock` - Minimum acceptable level
- `max_stock` - Maximum storage capacity
- `reorder_point` - Level at which to reorder
- `unit_cost` - Cost per unit
- `category` - Material classification

### StockMovement Fields
- `id` - Primary key
- `material_id` - Which material
- `movement_type` - in, out, allocated, returned, etc.
- `quantity` - Units moved
- `created_at` - When movement occurred

### StockAlert Fields
- `id` - Primary key
- `material_id` - Which material triggered alert
- `alert_type` - low_stock, overstock, critical
- `is_read` - Alert acknowledgment status
- `created_at` - Alert creation time

---

## Dashboard Access Control

### Admin
- ✅ All Maintenance KPIs
- ✅ All Stock KPIs
- ✅ All Charts

### Supervisor
- ✅ All Maintenance KPIs
- ✅ All Stock KPIs
- ✅ All Charts

### Stock Agent
- ❌ Maintenance KPIs
- ✅ All Stock KPIs
- ✅ Stock Charts

### Technician
- ❌ Analytics Dashboard Access

---

## Date Range Filter

All KPIs support dynamic date filtering:
- **Default**: Last 30 days
- **Custom**: User can select custom date range
- **Format**: MM/DD/YYYY
- **Applied To**: All time-dependent calculations

---

## Performance Notes

- All calculations use database aggregation (SUM, COUNT, AVG) for efficient processing
- Date range filters reduce query result sets significantly
- Timestamp indexes on `created_at` improve query performance
- Foreign key relationships ensure data integrity across calculations

---

## Updated: March 3, 2026
