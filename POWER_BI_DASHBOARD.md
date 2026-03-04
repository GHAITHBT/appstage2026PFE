# 📊 Maintenance & Stock Management — Power BI Dashboard

> A complete analytics dashboard built on Power BI Desktop, covering **Maintenance KPIs** and **Stock Management KPIs** from a live database. Designed for Admin, Supervisor, and Stock Agent roles.

---

## 📁 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Step 1 — Install Power BI Desktop](#step-1--install-power-bi-desktop)
- [Step 2 — Connect to the Database](#step-2--connect-to-the-database)
- [Step 3 — Load the Tables](#step-3--load-the-tables)
- [Step 4 — Set Up Relationships](#step-4--set-up-relationships)
- [Step 5 — Create DAX Measures](#step-5--create-dax-measures)
  - [Maintenance Measures](#-maintenance-measures)
  - [Stock Measures](#-stock-measures)
- [Step 6 — Build the Report Pages](#step-6--build-the-report-pages)
  - [Page 1 — Maintenance Analytics](#page-1--maintenance-analytics)
  - [Page 2 — Stock Management](#page-2--stock-management)
- [Step 7 — Add Date Slicer](#step-7--add-date-slicer)
- [Step 8 — Apply Styling & Theme](#step-8--apply-styling--theme)
- [Step 9 — Row-Level Security](#step-9--row-level-security)
- [Step 10 — Publish to Power BI Service](#step-10--publish-to-power-bi-service)
- [KPI Reference](#kpi-reference)
- [Database Schema](#database-schema)
- [Troubleshooting](#troubleshooting)

---

## Overview

This dashboard provides two analytics pages:

| Page | Audience | KPIs |
|---|---|---|
| **Maintenance Analytics** | Admin, Supervisor | Total Events, Downtime, MTTR, MTBF, Availability Rate, Failure Rate, Top Users |
| **Stock Management** | Admin, Supervisor, Stock Agent | Stock Value, Low/Critical Stock, Stock In/Out, Alerts, Category Breakdown |

> ⚠️ Technicians have **no access** to this dashboard.

---

## Prerequisites

| Tool | Version | Link |
|---|---|---|
| Power BI Desktop | Latest (free) | [Download](https://powerbi.microsoft.com/desktop) |
| Database access | PostgreSQL / MySQL / SQL Server | Your DB credentials |
| Windows OS | Windows 10 or later | Required for Power BI Desktop |

---

## Project Structure

```
powerbi-dashboard/
│
├── POWER_BI_DASHBOARD.md      ← This file
├── dashboard.pbix             ← Power BI file (after you build it)
├── theme.json                 ← Custom dark theme (optional)
└── screenshots/
    ├── maintenance_page.png
    └── stock_page.png
```

---

## Step 1 — Install Power BI Desktop

1. Go to [https://powerbi.microsoft.com/desktop](https://powerbi.microsoft.com/desktop)
2. Click **"Download free"**
3. Install and open the application
4. Sign in with a Microsoft account (free to create)

---

## Step 2 — Connect to the Database

1. Open **Power BI Desktop**
2. Click **"Get Data"** in the top ribbon (or Home → Get Data)
3. Search for your database type:
   - **PostgreSQL** → select PostgreSQL
   - **MySQL** → select MySQL
   - **SQL Server** → select SQL Server
4. Enter your connection details:

```
Server:   your-server-address (e.g. localhost or 192.168.1.10)
Database: your_database_name
Username: your_username
Password: your_password
```

5. Click **Connect**

> 💡 If you see a firewall error, make sure your database port is open (5432 for PostgreSQL, 3306 for MySQL, 1433 for SQL Server).

---

## Step 3 — Load the Tables

After connecting, a **Navigator** window will appear showing all your tables.

Check the box next to each of these tables:

- [x] `maintenance_reports`
- [x] `materials`
- [x] `stock_movements`
- [x] `stock_alerts`
- [x] `users`

Click **"Load"** (not Transform — unless you need to clean data first).

---

## Step 4 — Set Up Relationships

1. Click the **Model view** icon on the left sidebar (looks like 3 connected boxes)
2. You should see your 5 tables as boxes on screen
3. Check that these relationships exist (shown as connecting lines):

| From | To |
|---|---|
| `maintenance_reports.technician_id` | `users.id` |
| `stock_movements.material_id` | `materials.id` |
| `stock_alerts.material_id` | `materials.id` |

4. If a line is **missing**, drag from one field to the other to create it manually
5. Double-click any line to confirm it is set to **Many-to-One** (∗ → 1)

---

## Step 5 — Create DAX Measures

For each measure below:
1. Click the target table in the **Fields panel** (right side)
2. Go to **Home → New Measure** in the top ribbon
3. Paste the formula and press **Enter**

---

### 🔧 Maintenance Measures

> Click the `maintenance_reports` table before creating these.

```dax
Total Events =
COUNTROWS(maintenance_reports)
```

```dax
Total Downtime Hours =
SUM(maintenance_reports[actual_duration_hours])
```

```dax
Canceled Events =
CALCULATE(
    COUNTROWS(maintenance_reports),
    maintenance_reports[report_status] = "rejected"
)
```

```dax
Avg Downtime Seconds =
VAR total = [Total Events]
RETURN
    IF(total > 0, DIVIDE([Total Downtime Hours], total) * 3600, 0)
```

```dax
Availability Rate % =
VAR downtime = [Total Downtime Hours]
VAR totalHours =
    DATEDIFF(
        MIN(maintenance_reports[created_at]),
        MAX(maintenance_reports[created_at]),
        HOUR
    )
RETURN
    IF(
        downtime > 0 && totalHours > 0,
        CLAMP((1 - DIVIDE(downtime, totalHours)) * 100, 0, 100),
        0
    )
```

```dax
Failure Rate =
DIVIDE(
    [Canceled Events],
    IF([Total Downtime Hours] > 0, [Total Downtime Hours], 1)
)
```

```dax
MTTR Seconds =
CALCULATE(
    AVERAGE(maintenance_reports[actual_duration_hours]),
    NOT(ISBLANK(maintenance_reports[actual_duration_hours]))
) * 3600
```

```dax
MTBF Hours =
VAR canceled = [Canceled Events]
VAR days =
    DATEDIFF(
        MIN(maintenance_reports[created_at]),
        MAX(maintenance_reports[created_at]),
        DAY
    )
RETURN
    IF(canceled > 0, DIVIDE(days * 24, canceled), 0)
```

---

### 📦 Stock Measures

> Click the `materials` table before creating these.

```dax
Total Spare Parts =
COUNTROWS(materials)
```

```dax
Total Stock Value =
SUMX(materials, materials[current_stock] * materials[unit_cost])
```

```dax
Low Stock Items =
CALCULATE(
    COUNTROWS(materials),
    materials[current_stock] <= materials[min_stock]
)
```

```dax
Overstock Items =
CALCULATE(
    COUNTROWS(materials),
    materials[current_stock] >= materials[max_stock]
)
```

```dax
Critical Stock Items =
CALCULATE(
    COUNTROWS(materials),
    materials[current_stock] = 0
        || materials[current_stock] <= materials[reorder_point]
)
```

```dax
Avg Stock Level =
AVERAGE(materials[current_stock])
```

```dax
Total Stock Value =
SUMX(materials, materials[current_stock] * materials[unit_cost])
```

> Click the `stock_movements` table before creating these.

```dax
Stock In =
CALCULATE(
    SUM(stock_movements[quantity]),
    stock_movements[movement_type] IN { "in", "receipt" }
)
```

```dax
Stock Out =
CALCULATE(
    SUM(stock_movements[quantity]),
    stock_movements[movement_type] IN { "out", "issue", "allocated" }
)
```

> Click the `stock_alerts` table before creating these.

```dax
Active Alerts =
CALCULATE(
    COUNTROWS(stock_alerts),
    stock_alerts[is_read] = FALSE
)
```

---

## Step 6 — Build the Report Pages

Go to **Report view** (top icon on the left sidebar).

### Page 1 — Maintenance Analytics

Right-click the page tab at the bottom → **Rename** → type `Maintenance`

#### KPI Cards (repeat for each)
1. Click the **Card** visual in the Visualizations panel
2. Drag the measure into the **Fields** box

| Card Label | Measure to use |
|---|---|
| Total Events | `Total Events` |
| Total Downtime | `Total Downtime Hours` |
| Canceled Events | `Canceled Events` |
| Avg Downtime | `Avg Downtime Seconds` |
| Availability Rate | `Availability Rate %` |
| Failure Rate | `Failure Rate` |
| MTTR | `MTTR Seconds` |
| MTBF | `MTBF Hours` |

#### Chart 1 — Events per Machine (Bar Chart)
1. Click **Clustered Bar Chart** visual
2. **Y-axis** → drag `machine_name`
3. **X-axis** → drag `Total Events` measure
4. In the **Filters** pane → add `machine_name` → set filter type to **Top N** → Top **10** by `Total Events`

#### Chart 2 — Events by Status (Donut Chart)
1. Click **Donut Chart** visual
2. **Legend** → drag `report_status`
3. **Values** → drag `Total Events`

#### Chart 3 — Monthly Trend (Line Chart)
1. Click **Line Chart** visual
2. **X-axis** → drag `created_at` from `maintenance_reports` → set to **Month**
3. **Y-axis** → drag `Total Events`
4. **Secondary Y-axis** → drag `Canceled Events`

#### Table — Top Technicians
1. Click **Table** visual
2. Drag these columns: `users[first_name]`, `users[last_name]`, `Total Events`, `Canceled Events`
3. Sort by `Total Events` descending

---

### Page 2 — Stock Management

Right-click the page tab → **Rename** → type `Stock Management`

#### KPI Cards

| Card Label | Measure to use |
|---|---|
| Total Spare Parts | `Total Spare Parts` |
| Total Stock Value | `Total Stock Value` |
| Low Stock Items | `Low Stock Items` |
| Overstock Items | `Overstock Items` |
| Critical Stock | `Critical Stock Items` |
| Avg Stock Level | `Avg Stock Level` |
| Stock In | `Stock In` |
| Stock Out | `Stock Out` |
| Active Alerts | `Active Alerts` |

#### Chart 1 — Materials by Category (Horizontal Bar)
1. Click **Clustered Bar Chart**
2. **Y-axis** → `materials[category]`
3. **X-axis** → `Total Spare Parts` (or drag `materials[id]` and set to Count)

#### Chart 2 — Stock Movement Summary (Stacked Column)
1. Click **Stacked Column Chart**
2. **X-axis** → `stock_movements[created_at]` → set to **Month**
3. **Y-axis** → `stock_movements[quantity]`
4. **Legend** → `stock_movements[movement_type]`

#### Table — Critical Stock Items
1. Click **Table** visual
2. Columns: `materials[name]`, `materials[current_stock]`, `materials[min_stock]`, `materials[reorder_point]`, `materials[unit_cost]`
3. Apply **Conditional Formatting** on `current_stock`:
   - Go to Format → Conditional formatting → Background color
   - Rule: if value = 0 → Red, if value <= min_stock → Orange

---

## Step 7 — Add Date Slicer

Do this on **both pages**:

1. Click the **Slicer** visual
2. Drag `maintenance_reports[created_at]` into the field box (for Maintenance page)
3. Drag `stock_movements[created_at]` (for Stock page)
4. Click the slicer → top-left dropdown → change to **"Between"**
5. This gives you a From / To date picker that filters all visuals on the page

> 💡 To sync the slicer across pages: go to **View → Sync Slicers** and enable sync.

---

## Step 8 — Apply Styling & Theme

### Quick Dark Theme
1. Go to **View → Themes → Browse for themes**
2. Or paste this minimal dark theme JSON into a file called `theme.json` and import it:

```json
{
  "name": "Dark Dashboard",
  "dataColors": ["#4F8EF7", "#38D9A9", "#F7764F", "#F7C94F", "#F25C5C", "#A782F7"],
  "background": "#0D0F14",
  "foreground": "#E8EAF0",
  "tableAccent": "#4F8EF7"
}
```

### Color Coding Tips
- 🔴 **Red** → Critical / Canceled / Rejected (`#F25C5C`)
- 🟡 **Yellow** → Warning / Low Stock (`#F7C94F`)
- 🟢 **Green** → Good / Approved / Available (`#38D9A9`)
- 🔵 **Blue** → Neutral info (`#4F8EF7`)

### Card Formatting
- Select a card → **Format visual** → turn off "Category label" if you want cleaner look
- Increase font size to **28–32pt** for the value
- Add a **colored top border** using the "Border" option per card

---

## Step 9 — Row-Level Security

This controls who sees what after publishing.

1. Go to **Modeling → Manage Roles**
2. Create these roles:

**Role: Stock Agent**
```dax
-- On maintenance_reports table:
FALSE()
```
> This hides the entire maintenance table from Stock Agents.

**Role: Technician**
```dax
-- On both maintenance_reports and materials tables:
FALSE()
```

3. Click **Save**
4. After publishing, go to Power BI Service → dataset → **Security** → assign users to roles

---

## Step 10 — Publish to Power BI Service

1. Click **Home → Publish**
2. Sign in to your Microsoft/Power BI account
3. Choose a **Workspace** to publish to
4. Once published, go to [app.powerbi.com](https://app.powerbi.com)
5. Find your report → click **Share** to send to teammates
6. Set up **Scheduled Refresh** so data updates automatically:
   - Dataset → Settings → Scheduled Refresh → set frequency (e.g. every day at 8am)

---

## KPI Reference

### Maintenance KPIs

| KPI | Formula | Good Value |
|---|---|---|
| Total Events | `COUNT(id)` | — |
| Total Downtime | `SUM(actual_duration_hours)` | Lower is better |
| Canceled Events | `COUNT WHERE status = 'rejected'` | Lower is better |
| Availability Rate | `(1 - downtime/total_hours) * 100` | > 95% |
| Failure Rate | `canceled / downtime_hours` | Lower is better |
| MTTR | `AVG(duration) * 3600` | Lower is better |
| MTBF | `(days * 24) / canceled` | Higher is better |

### Stock KPIs

| KPI | Formula | Alert Level |
|---|---|---|
| Total Stock Value | `SUM(current_stock * unit_cost)` | — |
| Low Stock Items | `COUNT WHERE stock <= min_stock` | ⚠️ Warning |
| Critical Stock | `COUNT WHERE stock = 0 OR stock <= reorder_point` | 🔴 Urgent |
| Overstock Items | `COUNT WHERE stock >= max_stock` | ⚠️ Warning |
| Stock In | `SUM(quantity) WHERE type IN ('in','receipt')` | — |
| Stock Out | `SUM(quantity) WHERE type IN ('out','issue','allocated')` | — |

---

## Database Schema

```
maintenance_reports
├── id (PK)
├── technician_id (FK → users.id)
├── actual_duration_hours
├── report_status       [draft, submitted, approved, rejected]
├── report_type         [standard, detailed]
├── machine_condition
├── machine_name
├── created_at
└── updated_at

materials
├── id (PK)
├── name
├── current_stock
├── min_stock
├── max_stock
├── reorder_point
├── unit_cost
└── category

stock_movements
├── id (PK)
├── material_id (FK → materials.id)
├── movement_type       [in, out, allocated, returned, adjusted]
├── quantity
└── created_at

stock_alerts
├── id (PK)
├── material_id (FK → materials.id)
├── alert_type          [low_stock, overstock, critical]
├── is_read
└── created_at

users
├── id (PK)
├── first_name
├── last_name
└── ...
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| Can't connect to database | Check server address, port, and that your IP is whitelisted |
| DAX formula error on `CLAMP` | Replace with `MIN(MAX(value, 0), 100)` |
| Relationships not auto-detected | Go to Model view and drag fields manually to connect tables |
| Date slicer not filtering charts | Check all visuals use the same table's date field |
| Blank values in cards | Add `IF(ISBLANK(...), 0, ...)` wrapper to your measure |
| Published report not refreshing | Set up gateway if DB is on-premise: Service → Manage Gateways |

---

## Access Control Summary

| Role | Maintenance Page | Stock Page |
|---|---|---|
| Admin | ✅ Full access | ✅ Full access |
| Supervisor | ✅ Full access | ✅ Full access |
| Stock Agent | ❌ Hidden | ✅ Full access |
| Technician | ❌ Hidden | ❌ Hidden |

---

> **Last updated:** March 2026  
> Built with Power BI Desktop · Data source: Application DB
