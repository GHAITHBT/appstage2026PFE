# Feature Access Guide

## 📋 Manual Report Creation / Detailed Report

### Location 1: Maintenance Schedules List
**Path:** `/maintenance/` or click "Maintenance Schedules" from dashboard
- Look for the green **"Create Report"** button (📄 icon) next to each schedule in the table
- Only appears for schedules with status: Scheduled or In Progress
- Available to: Technician, Supervisor, Admin

### Process:
1. Click the **"Create Report"** button on any maintenance schedule
2. System redirects to report type selection page
3. Choose between:
   - **Standard Report** - Basic maintenance details
   - **Detailed Report** - Enhanced report with machine condition, environmental data, safety observations, tools used
4. Fill in the form with all required information
5. Click **"Submit Report"** to save to database

### What Gets Saved:
- Work description
- Findings and observations  
- Actions taken
- Issues found (if any)
- Components replaced
- Next maintenance recommendations
- **[Detailed Only]** Machine condition before/after
- **[Detailed Only]** Environmental conditions
- **[Detailed Only]** Safety observations
- **[Detailed Only]** Tools used
- Start/end times and actual duration
- Technician's zone assignment

---

## 🔄 Return Material to Stock

### Location 1: Stock Inventory Page
**Path:** `/stock/` or click "Stock Management" from dashboard
- Look for the yellow **"Return Material"** button (↩️ icon) at the top right
- Available to: Technician, Supervisor, Admin

### Location 2: Direct URL
- Go directly to: `/stock/return-material`

### Process:
1. Click **"Return Material"** button
2. Select the demand from the dropdown (only shows fulfilled demands with available quantities)
3. System displays:
   - Material name
   - Available quantity to return
4. Fill in:
   - **Quantity to Return** - How much to send back
   - **Condition** - New, Used, or Damaged
   - **Reason** - Why returning (e.g., "Ordered more than needed", "Job cancelled")
5. Click **"Submit Return Request"**
6. Request goes into pending status with stock agent

### What Happens Next:
- Stock agent receives notification in **"Pending Returns"**
- Stock agent reviews the condition
- Stock agent can:
  - **Accept** - Material added back to stock, stock level increases
  - **Reject** - Return is denied, material stays with user

---

## 📦 Pending Returns (Stock Agent Only)

### Location 1: Stock Inventory Page
**Path:** `/stock/` 
- Look for the blue **"Pending Returns"** button (📥 icon)
- Available to: Stock Agent, Admin

### Location 2: Direct URL
- Go directly to: `/stock/returns-pending`

### What You'll See:
- All pending return requests from technicians
- Information:
  - Who requested the return
  - Material details
  - Quantity being returned
  - Material condition (New/Used/Damaged)
  - Reason for return
  - Request timestamp

### Actions Available:
- **Accept Return** 
  - Click green "Accept" button
  - Confirm in modal
  - Material quantity added to stock
  - Stock movement recorded in history
  
- **Reject Return**
  - Click red "Reject" button  
  - Optionally add notes about rejection
  - Confirm in modal
  - Material stays with requestor

---

## 📊 Stock Movement History

### Location 1: Stock Inventory Page
**Path:** `/stock/`
- Look for the gray **"History"** button (⏰ icon) at the top right
- Available to: All users

### Location 2: Direct URL
- Go directly to: `/stock/movement-history`

### Features:
- View all stock transactions (additions, withdrawals, allocations, fulfillments, returns)
- Filter by:
  - **Material** - See transactions for specific material
  - **Movement Type** - Show only additions, returns, etc.
- See complete transaction history including:
  - Date/Time
  - Material changed
  - Type of movement
  - Quantity
  - Stock before/after
  - Who made the change
  - Reference (which demand/report)
  - Notes or return reason

---

## 🗂️ Summary of All New Buttons & Links

### Stock Management (`/stock`)
| Button | Icon | Color | Role | Action |
|--------|------|-------|------|--------|
| Add Material | ➕ | Primary | Admin, Stock Agent | Create new material |
| Pending Returns | 📥 | Info | Admin, Stock Agent | Review material returns |
| Return Material | ↩️ | Warning | All | Request material return |
| Alerts | 🔔 | Warning | All | View stock alerts |
| History | ⏰ | Secondary | All | View movement history |

### Maintenance (`/maintenance`)
| Button | Icon | Color | Role | Action |
|--------|------|-------|------|--------|
| Create Report | 📄 | Success | Tech, Supervisor, Admin | Create maintenance report |
| View | 👁️ | Primary | All | View schedule details |

---

## 🔐 Permission Levels

### Technician
✅ Create reports (standard & detailed)
✅ Request material returns
✅ View stock inventory & history
❌ Approve returns
❌ Add materials

### Stock Agent  
✅ Add materials
✅ Review pending returns
✅ Approve/Reject returns
✅ View stock inventory & history
❌ Create reports
❌ Request returns

### Supervisor
✅ Create reports (standard & detailed)
✅ Request material returns
✅ View stock inventory & history
✅ View all schedules
❌ Approve material returns
❌ Add materials

### Admin
✅ All features
✅ Full access to everything

---

## 💾 Database Tables Updated

Data is automatically saved to these tables:

- **maintenance_reports** - Report details including type, zone, conditions
- **material_returns** - Return requests with status and condition
- **stock_movements** - All stock transactions including returns
- **spare_parts_demands** - Updated with return tracking fields
- **users** - Technician zone assignments

---

## 🚀 Quick Start

### To Create a Manual Report:
1. Go to **Maintenance** → **Schedules**
2. Click the green **Create Report** button (📄)
3. Choose report type (Standard or Detailed)
4. Fill form and click **Submit Report**

### To Return Material:
1. Go to **Stock Management** → Click **Return Material** button (↩️)
2. Select demand and quantity
3. Add reason and material condition
4. Click **Submit Return Request**

### To Process Returns (Stock Agent):
1. Go to **Stock Management** → Click **Pending Returns** button (📥)
2. Review each return request
3. Click **Accept** or **Reject**
4. Confirm action

### To View Stock History:
1. Go to **Stock Management** → Click **History** button (⏰)
2. Filter by material or type if needed
3. View complete transaction history
