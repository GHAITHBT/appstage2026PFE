# 📊 Maintenance & Stock Management — Power BI Dashboard

> A complete step-by-step guide to build a Power BI analytics dashboard from scratch, covering **Maintenance KPIs** and **Stock Management KPIs** from a live database.  
> Designed for **Admin**, **Supervisor**, and **Stock Agent** roles.

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

This dashboard has two report pages:

| Page | Who Can See It | What It Shows |
|---|---|---|
| **Maintenance Analytics** | Admin, Supervisor | Total Events, Downtime, MTTR, MTBF, Availability Rate, Failure Rate, Top Users |
| **Stock Management** | Admin, Supervisor, Stock Agent | Stock Value, Low/Critical Stock, Stock In/Out, Alerts, Category Breakdown |

> ⚠️ **Technicians have no access to either page.**

---

## Prerequisites

| Tool | Notes | Link |
|---|---|---|
| Power BI Desktop | Free to download | [powerbi.microsoft.com/desktop](https://powerbi.microsoft.com/desktop) |
| Microsoft Account | Free to create, needed to sign in | [account.microsoft.com](https://account.microsoft.com) |
| Database credentials | Server address, DB name, username, password | From your sysadmin |
| Windows 10 or later | Power BI Desktop is Windows only | — |

---

## Project Structure

```
powerbi-dashboard/
│
├── README.md                  ← This file
├── dashboard.pbix             ← Power BI report file (created after you build it)
├── theme.json                 ← Custom dark theme (optional, import into Power BI)
└── screenshots/
    ├── maintenance_page.png
    └── stock_page.png
```

---

## Step 1 — Install Power BI Desktop

1. Go to [https://powerbi.microsoft.com/desktop](https://powerbi.microsoft.com/desktop)
2. Click **"Download free"**
3. Run the installer and open the app
4. Sign in with your Microsoft account when prompted

---

## Step 2 — Connect to the Database

1. Open **Power BI Desktop**
2. Click **"Get Data"** in the top ribbon
3. Search for your database type and select it:
   - `PostgreSQL` if you use PostgreSQL
   - `MySQL` if you use MySQL
   - `SQL Server` if you use SQL Server
4. Fill in your connection details:

```
Server:    your-server-address   (e.g. localhost  or  192.168.1.10)
Database:  your_database_name
Port:      5432 (PostgreSQL) / 3306 (MySQL) / 1433 (SQL Server)
Username:  your_username
Password:  your_password
```

5. Click **Connect**

> 💡 **Firewall error?** Make sure your database port is open and your IP address is whitelisted on the server.

---

## Step 3 — Load the Tables

After connecting, a **Navigator** window appears listing all your tables.

Check the box next to each of these 5 tables:

- [x] `maintenance_reports`
- [x] `materials`
- [x] `stock_movements`
- [x] `stock_alerts`
- [x] `users`

Then click **"Load"** at the bottom right.

> ⚠️ **Important — Table Names with Spaces:**  
> Power BI loads your tables with their full database prefix, for example:  
> `maintenance_system_v2 maintenance_reports`  
> This is completely normal. When writing DAX, **always use autocomplete** — start typing the table name in the formula bar and press `Tab` to let Power BI insert the correct name with quotes automatically. Never type the full name by hand.

---

## Step 4 — Set Up Relationships

1. Click the **Model view** icon on the left sidebar (three boxes connected by lines)
2. You will see your 5 tables displayed as boxes on screen
3. Verify these connecting lines exist:

| From (Many side ∗) | To (One side 1) |
|---|---|
| `maintenance_reports[technician_id]` | `users[id]` |
| `stock_movements[material_id]` | `materials[id]` |
| `stock_alerts[material_id]` | `materials[id]` |

4. **If a line is missing:** click and drag from one field to the matching field in the other table
5. Double-click any relationship line → confirm it is **Many to One (∗:1)** and Cross filter direction is **Single**

---

## Step 5 — Create DAX Measures

**How to create a measure:**
1. In the **Fields panel** on the right, click the table you want to store the measure in
2. In the top ribbon click **Home → New Measure**
3. The formula bar appears — delete the placeholder text, paste your formula, and press **Enter**

> 💡 **Replace the table name prefix** in all formulas below with your actual prefix.  
> Example: if your table is named `maintenance_system_v2 maintenance_reports`, replace accordingly.  
> Use **autocomplete** (type + press `Tab`) to avoid typos.

---

### 🔧 Maintenance Measures

> Select the `maintenance_reports` table in the Fields panel before creating each of these.

---

**Total Events** — counts all maintenance reports
```dax
Total Events =
COUNTROWS('maintenance_system_v2 maintenance_reports')
```

---

**Total Downtime Hours** — sum of all repair durations
```dax
Total Downtime Hours =
SUM('maintenance_system_v2 maintenance_reports'[actual_duration_hours])
```

---

**Canceled Events** — reports with status = rejected
```dax
Canceled Events =
CALCULATE(
    COUNTROWS('maintenance_system_v2 maintenance_reports'),
    'maintenance_system_v2 maintenance_reports'[report_status] = "rejected"
)
```

---

**Avg Downtime Seconds** — average repair time converted to seconds
```dax
Avg Downtime Seconds =
VAR total = [Total Events]
RETURN
    IF(
        total > 0,
        DIVIDE([Total Downtime Hours], total) * 3600,
        0
    )
```

---

**Availability Rate %** — percentage of time equipment was operational

> ⚠️ `CLAMP` does **not exist** in DAX — use `MIN(MAX(...))` as shown below instead.

```dax
Availability Rate % =
VAR downtime = [Total Downtime Hours]
VAR totalHours =
    DATEDIFF(
        MIN('maintenance_system_v2 maintenance_reports'[created_at]),
        MAX('maintenance_system_v2 maintenance_reports'[created_at]),
        HOUR
    )
VAR rate = (1 - DIVIDE(downtime, totalHours)) * 100
RETURN
    IF(
        downtime > 0 && totalHours > 0,
        MIN(MAX(rate, 0), 100),
        0
    )
```

---

**Failure Rate** — failures per hour of operation
```dax
Failure Rate =
DIVIDE(
    [Canceled Events],
    IF([Total Downtime Hours] > 0, [Total Downtime Hours], 1)
)
```

---

**MTTR Seconds** — Mean Time To Repair (lower = faster repairs)
```dax
MTTR Seconds =
CALCULATE(
    AVERAGE('maintenance_system_v2 maintenance_reports'[actual_duration_hours]),
    NOT(ISBLANK('maintenance_system_v2 maintenance_reports'[actual_duration_hours]))
) * 3600
```

---

**MTBF Hours** — Mean Time Between Failures (higher = more reliable)
```dax
MTBF Hours =
VAR canceled = [Canceled Events]
VAR days =
    DATEDIFF(
        MIN('maintenance_system_v2 maintenance_reports'[created_at]),
        MAX('maintenance_system_v2 maintenance_reports'[created_at]),
        DAY
    )
RETURN
    IF(canceled > 0, DIVIDE(days * 24, canceled), 0)
```

---

### 📦 Stock Measures

> Select the `materials` table in the Fields panel before creating these.

---

**Total Spare Parts** — count of all unique materials
```dax
Total Spare Parts =
COUNTROWS('maintenance_system_v2 materials')
```

---

**Total Stock Value** — total monetary value of current inventory
```dax
Total Stock Value =
SUMX(
    'maintenance_system_v2 materials',
    'maintenance_system_v2 materials'[current_stock]
        * 'maintenance_system_v2 materials'[unit_cost]
)
```

---

**Low Stock Items** — materials at or below minimum threshold
```dax
Low Stock Items =
CALCULATE(
    COUNTROWS('maintenance_system_v2 materials'),
    'maintenance_system_v2 materials'[current_stock]
        <= 'maintenance_system_v2 materials'[min_stock]
)
```

---

**Overstock Items** — materials at or above maximum capacity
```dax
Overstock Items =
CALCULATE(
    COUNTROWS('maintenance_system_v2 materials'),
    'maintenance_system_v2 materials'[current_stock]
        >= 'maintenance_system_v2 materials'[max_stock]
)
```

---

**Critical Stock Items** — zero stock or at reorder point
```dax
Critical Stock Items =
CALCULATE(
    COUNTROWS('maintenance_system_v2 materials'),
    'maintenance_system_v2 materials'[current_stock] = 0
        || 'maintenance_system_v2 materials'[current_stock]
            <= 'maintenance_system_v2 materials'[reorder_point]
)
```

---

**Avg Stock Level** — average quantity across all materials
```dax
Avg Stock Level =
AVERAGE('maintenance_system_v2 materials'[current_stock])
```

---

> Select the `stock_movements` table before creating these.

**Stock In** — total units received into inventory
```dax
Stock In =
CALCULATE(
    SUM('maintenance_system_v2 stock_movements'[quantity]),
    'maintenance_system_v2 stock_movements'[movement_type] IN { "in", "receipt" }
)
```

---

**Stock Out** — total units issued or removed
```dax
Stock Out =
CALCULATE(
    SUM('maintenance_system_v2 stock_movements'[quantity]),
    'maintenance_system_v2 stock_movements'[movement_type] IN { "out", "issue", "allocated" }
)
```

---

> Select the `stock_alerts` table before creating this.

**Active Alerts** — unread stock alerts
```dax
Active Alerts =
CALCULATE(
    COUNTROWS('maintenance_system_v2 stock_alerts'),
    'maintenance_system_v2 stock_alerts'[is_read] = FALSE
)
```

---

## Step 6 — Build the Report Pages

Click the **Report view** icon at the top of the left sidebar.

---

### Page 1 — Maintenance Analytics

Right-click the page tab at the bottom → **Rename** → type `Maintenance`

---

#### 🟦 KPI Cards

For each card below:
1. Click the **Card** visual in the Visualizations panel
2. Drag the measure into the **Fields** box
3. Resize and arrange them in a row across the top of the page

| Card Label | Measure |
|---|---|
| Total Events | `Total Events` |
| Total Downtime | `Total Downtime Hours` |
| Canceled Events | `Canceled Events` |
| Avg Downtime | `Avg Downtime Seconds` |
| Availability Rate | `Availability Rate %` |
| Failure Rate | `Failure Rate` |
| MTTR | `MTTR Seconds` |
| MTBF | `MTBF Hours` |

---

#### 📊 Chart 1 — Events per Machine (Clustered Bar Chart)

1. Click **Clustered Bar Chart** in the Visualizations panel
2. **Y-axis** → drag `machine_name` from `maintenance_reports`
3. **X-axis** → drag `Total Events` measure
4. In the **Filters** pane → find `machine_name` → change type to **Top N** → Top **10** by `Total Events`

---

#### 🍩 Chart 2 — Events by Status (Donut Chart)

1. Click **Donut Chart** visual
2. **Legend** → drag `report_status` from `maintenance_reports`
3. **Values** → drag `Total Events` measure

---

#### 📈 Chart 3 — Monthly Event Trend (Line Chart)

1. Click **Line Chart** visual
2. **X-axis** → drag `created_at` from `maintenance_reports` → select **Month** from the date hierarchy
3. **Y-axis** → drag `Total Events`
4. **Secondary Y-axis** → drag `Canceled Events`

---

#### 📋 Table — Top Technicians

1. Click **Table** visual
2. Drag in: `users[first_name]`, `users[last_name]`, `Total Events`, `Canceled Events`
3. Click the `Total Events` column header to sort descending

---

### Page 2 — Stock Management

Right-click the page tab → **Rename** → type `Stock Management`

---

#### 🟦 KPI Cards

| Card Label | Measure |
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

---

#### 📊 Chart 1 — Materials by Category (Horizontal Bar Chart)

1. Click **Clustered Bar Chart**
2. **Y-axis** → drag `category` from `materials`
3. **X-axis** → drag `Total Spare Parts` measure

---

#### 📊 Chart 2 — Stock Movement Summary (Stacked Column Chart)

1. Click **Stacked Column Chart**
2. **X-axis** → drag `created_at` from `stock_movements` → set to **Month**
3. **Y-axis** → drag `quantity` from `stock_movements` (set to Sum)
4. **Legend** → drag `movement_type` from `stock_movements`

---

#### 📋 Table — Critical Stock Items

1. Click **Table** visual
2. Add columns: `materials[name]`, `materials[current_stock]`, `materials[min_stock]`, `materials[reorder_point]`, `materials[unit_cost]`
3. Add **Conditional Formatting** on `current_stock`:
   - Select the table → Format visual → Cell elements → Background color → enable it
   - Rule 1: If value **equals 0** → background color **Red**
   - Rule 2: If value **is less than or equal to** `min_stock` value → background color **Orange**

---

## Step 7 — Add Date Slicer

Do this on **both pages**:

1. Click the **Slicer** visual in the Visualizations panel
2. **Maintenance page** → drag `maintenance_reports[created_at]` into the slicer
3. **Stock page** → drag `stock_movements[created_at]` into the slicer
4. Click the slicer → click the small dropdown arrow in its top-left corner → select **"Between"**
5. You now have a From / To date picker that filters all visuals on the page

> 💡 To sync the date slicer across both pages: go to **View → Sync Slicers**, select the slicer, and enable it for both pages.

---

## Step 8 — Apply Styling & Theme

### Import the Dark Theme

1. Go to **View → Themes → Browse for themes**
2. Save the JSON below as `theme.json`, then import it from that menu

```json
{
  "name": "Dark Dashboard",
  "dataColors": [
    "#4F8EF7",
    "#38D9A9",
    "#F7764F",
    "#F7C94F",
    "#F25C5C",
    "#A782F7"
  ],
  "background": "#0D0F14",
  "foreground": "#E8EAF0",
  "tableAccent": "#4F8EF7"
}
```

### Color Coding Guide

| Color | Hex | Use For |
|---|---|---|
| 🔴 Red | `#F25C5C` | Critical stock, Canceled/Rejected events |
| 🟡 Yellow | `#F7C94F` | Low stock warnings |
| 🟢 Green | `#38D9A9` | Good availability, Approved events |
| 🔵 Blue | `#4F8EF7` | Neutral info, Total counts |
| 🟠 Orange | `#F7764F` | Overstock, secondary warnings |

### Card Formatting Tips

- Select a card → **Format visual** → turn off **"Category label"** for a cleaner look
- Set value font size to **28–32pt**
- Enable **Border** and set the top border to the matching status color

---

## Step 9 — Row-Level Security

Controls which roles can see which data after publishing.

1. Go to **Modeling → Manage Roles** in the top ribbon
2. Click **"New Role"** → name it `Stock Agent`
3. Select the `maintenance_reports` table → enter this filter to hide it completely:

```dax
FALSE()
```

4. Create another role named `Technician`
5. Apply `FALSE()` on both `maintenance_reports` and `materials` tables for this role
6. Click **Save**
7. After publishing → go to [app.powerbi.com](https://app.powerbi.com) → your Dataset → **Security** → assign each user to their role

---

## Step 10 — Publish to Power BI Service

1. Click **Home → Publish** in the top ribbon
2. Sign in to your Microsoft account if prompted
3. Select a **Workspace** (use "My Workspace" for personal use)
4. Once published, go to [app.powerbi.com](https://app.powerbi.com)
5. Open your report → click **Share** to give access to teammates
6. Set up **Scheduled Refresh** to keep data current:
   - Dataset → **Settings** → **Scheduled Refresh** → enable and set a time (e.g. daily at 7:00 AM)
   - If your database is on a private/local network, install a **Power BI On-premises Gateway** on the server machine first

---

## KPI Reference

### Maintenance KPIs

| KPI | What It Measures | Target |
|---|---|---|
| Total Events | Count of all maintenance reports | — |
| Total Downtime Hours | Sum of all repair durations | Lower is better |
| Canceled Events | Reports with status = rejected | Lower is better |
| Avg Downtime Seconds | Average repair time in seconds | Lower is better |
| Availability Rate % | % of time equipment was operational | **> 95%** |
| Failure Rate | Failures per hour of operation | Lower is better |
| MTTR Seconds | Average time to complete a repair | Lower is better |
| MTBF Hours | Average time between failures | Higher is better |

### Stock KPIs

| KPI | What It Measures | Alert Level |
|---|---|---|
| Total Spare Parts | Count of unique materials | — |
| Total Stock Value | Sum of (stock × unit cost) | — |
| Low Stock Items | Items at or below min stock | ⚠️ Warning |
| Overstock Items | Items at or above max stock | ⚠️ Warning |
| Critical Stock Items | Items at zero or at reorder point | 🔴 Urgent |
| Avg Stock Level | Average quantity per material | — |
| Stock In | Units received in date range | — |
| Stock Out | Units issued/used in date range | — |
| Active Alerts | Unread alerts in stock_alerts table | 🔴 Needs action |

---

## Database Schema

```
maintenance_reports
├── id                    PK
├── technician_id         FK → users.id
├── actual_duration_hours
├── report_status         draft | submitted | approved | rejected
├── report_type           standard | detailed
├── machine_condition
├── machine_name
├── created_at
└── updated_at

materials
├── id                    PK
├── name
├── current_stock
├── min_stock
├── max_stock
├── reorder_point
├── unit_cost
└── category

stock_movements
├── id                    PK
├── material_id           FK → materials.id
├── movement_type         in | out | allocated | returned | adjusted
├── quantity
└── created_at

stock_alerts
├── id                    PK
├── material_id           FK → materials.id
├── alert_type            low_stock | overstock | critical
├── is_read               true | false
└── created_at

users
├── id                    PK
├── first_name
└── last_name
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `CLAMP is not a function` | CLAMP does not exist in DAX | Use `MIN(MAX(value, 0), 100)` instead |
| Table name not found in formula | Table has a database prefix with spaces | Use Power BI autocomplete — type table name and press `Tab` |
| Can't connect to database | Wrong credentials or port blocked | Double-check server, port, and IP whitelist |
| Relationships not auto-detected | Power BI couldn't match column names | Go to Model view and drag fields manually |
| Date slicer not filtering a visual | Visual uses a different date column | Make sure all visuals on the page use the same date field |
| Card shows BLANK instead of 0 | Measure returns blank when no rows | Wrap with: `IF(ISBLANK([Measure]), 0, [Measure])` |
| Report not refreshing after publish | No gateway for on-premise database | Install Power BI On-premises Gateway on your DB server |
| Row-level security not working | Users not assigned to roles | Go to Dataset → Security on app.powerbi.com and assign roles |

---

## Access Control Summary

| Role | Maintenance Page | Stock Page |
|---|---|---|
| Admin | ✅ Full access | ✅ Full access |
| Supervisor | ✅ Full access | ✅ Full access |
| Stock Agent | ❌ No access | ✅ Full access |
| Technician | ❌ No access | ❌ No access |

---

> **Last updated:** March 2026  
> Built with Power BI Desktop — connected to live application database  
> For issues, open a GitHub issue or contact your system administrator
