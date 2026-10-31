# 2. Stock movement and reorder report

**Problem:** a stock report was built by exporting from the ERP to Excel every time. It was always out of date.

**Solution:** the same logic rewritten as one SQL query that Power BI runs on every refresh through an
on-premises data gateway. The sales window is always *exactly the last 6 months up to today*.

## What the query does

1. Stock per item per warehouse (on hand, on order, on sales order, reserved).
2. 6-month and 3-month sales quantities per item and warehouse.
3. Average monthly sales and supply coverage (months of stock).
4. Returns the period start/end so the report can show "Sales period: ...".

See [`sql/stock_movement.sql`](sql/stock_movement.sql) and [`dax/measures.dax`](dax/measures.dax).

## Validation

Before switching over, the SQL was compared with the existing Excel report for the same dates:
row count, total sales quantity, on-hand, on-order and average monthly sales all matched.

## Report features

- Target-months slicer (what-if): the user picks 3, 6, 9 or 12 months of cover and sees the order quantity needed.
- Card showing the sales period so readers know how fresh the numbers are.
