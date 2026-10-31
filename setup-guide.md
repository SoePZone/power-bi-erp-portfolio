# Power BI Supply Chain Reporting — Architecture & Setup Guide

A practical guide to connecting Power BI to a live ERP (SQL Server) database for automated supply chain reporting. Built for a manufacturing business with inventory across multiple warehouse locations.

---

## Architecture Overview

**7 reports, 2 data paths:**

- **SQL-connected reports** (require gateway PC to be on): Stock Movement, Product Costing, Sales Dashboard
- **Excel/OneDrive reports** (refresh even when gateway is off): Pricing (with RLS), Reseller Price List, Wholesale Price List, Shipping Tracker

---

## SQL Connection Setup

### Read-only login for Power BI

Power BI reads from the ERP database through a dedicated read-only SQL login. This means Power BI cannot change or delete anything in the ERP.

Run once in SSMS as `sa`:

```sql
USE [master];
CREATE LOGIN [powerbi_read] WITH PASSWORD = N'<your_password>', DEFAULT_DATABASE = [YourDatabase], CHECK_POLICY = ON;
GO
USE [YourDatabase];
CREATE USER [powerbi_read] FOR LOGIN [powerbi_read];
ALTER ROLE [db_datareader] ADD MEMBER [powerbi_read];
GO
```

**Security notes:**
- Store the password in a password manager, not in emails or chat
- Use `sa` only for admin jobs — never put `sa` credentials into Power BI
- Power BI queries are SELECT-only and run in Import mode (reads only a few times per day)

### Connecting from Power BI Desktop

Get data → SQL Server → enter server name → database name → Import → Advanced options → paste your SQL query.

When asked for credentials: choose **Database** and enter the `powerbi_read` login.

You must be on the work network (or VPN) for this to work.

---

## Extracting SQL from ERP (Sage Evolution)

Every Sage Intelligence Excel report runs a hidden SQL query called a **container**. Exporting the report gives you that SQL, so Power BI can run the same query and get the same numbers.

1. Open Sage Evolution → Sage Intelligence → Report Manager
2. Select the report → Tools → Export Report (saves a `.al_` file)
3. The `.al_` file is compressed XML containing the container SQL
4. Replace report prompts (`@DateStart@`, `@DateEnd@`) with fixed dates or rolling date expressions
5. Run the SQL in SSMS and compare totals with the Excel version before using in Power BI

---

## Stock Movement Report (SQL version)

Replaces a manual Excel export. Calculates the last 6 months of sales from the ERP on every refresh — no manual work required.

### What the SQL does

- Reads stock levels from the ERP stock view: on hand, on PO, on SO, reserved, IBT
- Adds 6-month and 3-month sales quantities by item code and warehouse
- Calculates: QtyOnHandOnPO, QtyAvailableAfterReserved, AvgMonthlySales, SupplyCoverage
- Sets supplier from item group
- Returns PeriodStart and PeriodEnd so the report shows the sales period

**6-month rolling rule:** period runs exactly 6 months back from today, starting the day after. The 3-month column uses the same logic.

### DAX Measures

**Stock Coverage (Months):**
```dax
Stock Coverage (Months) =
DIVIDE(
    SUM('Stock'[QtyAfterReservedPOQty]),
    DIVIDE(SUM('Stock'[6 Month Consumption]), 6)
)
```

**Order Quantity (based on selected target months of cover):**
```dax
Order Qty (Selected Target) =
SUMX(
    VALUES('Stock'[ItemCode]),
    VAR SelectedTarget = SELECTEDVALUE('Target Months Selector'[Target Months], 6)
    VAR Cover = [Stock Coverage (Months)]
    VAR Shortfall = SelectedTarget - Cover
    RETURN IF(
        ISBLANK(Cover) || Shortfall <= 0, 0,
        Shortfall * CALCULATE(SUM('Stock'[Avg Monthly Sales]))
    )
)
```

*Note: Uses SUMX per item so the table total is the sum of the rows (without it the total showed 0).*

**Period Label (for display card):**
```dax
Period Label =
VAR StartDate = CALCULATE(MIN('Stock'[PeriodStart]), ALL('Stock'))
VAR EndDate   = CALCULATE(MAX('Stock'[PeriodEnd]),   ALL('Stock'))
RETURN "Sales period: " & FORMAT(StartDate, "d mmm yyyy") & " – " & FORMAT(EndDate, "d mmm yyyy")
```

*Note: Uses ALL() so the card never goes blank when slicers are applied.*

---

## Pricing Report with Row-Level Security (RLS)

Shows each sales rep only their own customer prices. A Master role shows everything.

### Setting up roles in Power BI Desktop

Modeling → Manage roles → create one role per rep with a filter on the Rep column:

```
[Rep] = "Rep Name Here"
```

Create a `Master` role with no filter (sees everything).

### Adding people to roles (Power BI Service)

Workspace → semantic model → ⋯ → Security → add each person's email under their role.

**Important sharing rules:**
- Share the report with reps as **Viewers** only (untick "Allow recipients to share")
- Never give reps a workspace role — Admin, Member and Contributor all bypass RLS
- Reps must not have access to the source Excel file, or they can read all prices there

### Testing RLS

- Desktop: Modeling → View as → pick a role
- Service: Security → ⋯ → Test as role

---

## Product Costing (Live BOM Cost)

Calculates product cost as: **sum of (recipe quantity × current average cost per component)**

This matches the ERP's Bill of Material Requirements Plan calculation.

**Component cost rule:** use AverageCost from the component's default warehouse; if none, fall back to warehouse 0.

Full write-up, SQL and DAX: [Live product costing](../03-live-product-costing).

---

## Sales Query

Joins multiple transaction types with UNION ALL: AR transactions, stock transactions, GL lines, job card stock, job card GL.

**Key modifications from the standard ERP report:**
- Set start date to beginning of required financial year
- Replace end date with `EOMONTH(GETDATE())` so it rolls forward automatically
- Replace division by sales amount with `NULLIF(Sales, 0)` to avoid divide-by-zero errors on zero-sales lines
- Remove final `ORDER BY` (Power BI doesn't need it)

**Validation:** always compare SQL totals against the ERP Excel report before publishing.

---

## Refresh Schedule

- SQL-connected reports: require the gateway PC to be running
- OneDrive/Excel reports: refresh independently, no gateway needed
- Scheduled refreshes: set in Power BI Service → semantic model → Settings → Scheduled refresh (use local timezone)

---

## Tips

- Use `Don't summarize` on price columns so two prices for one item show as two rows, not a sum
- Use a search slicer on account/customer name for quick filtering
- Always validate SQL output against the ERP before publishing a new report
- Keep the gateway PC on during business hours for SQL reports to refresh on schedule
