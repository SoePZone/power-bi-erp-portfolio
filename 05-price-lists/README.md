# 5. Price lists for the sales team

**Problem:** reseller and wholesale price lists were Excel files that included cost and gross-profit
columns, so they couldn't be sent to the sales team as they were.

**Solution:** two Power BI reports that read the same Excel files from OneDrive but **remove cost and GP%
in Power Query**, so those columns never reach Power BI at all. (Row-level security can hide rows, not
columns - removing the columns is the only safe option for a "no cost" version.)

## Power Query steps

See [`power_query/clean_price_list.m`](power_query/clean_price_list.m):

1. Load sheet `DATA` from the OneDrive file (direct https path ending in `.xlsx`).
2. Remove `Last Cost`, `GP%` and the duplicate warehouse column.
3. Add `Warehouse` as text with leading zeros (1 -> `001`).
4. Remove blank rows, rename the price column.

## Report

- Table: item code, description, warehouse, price, category, group - sorted by description.
- Dropdown slicers for description (with search), category, group and warehouse.
- Price set to *Don't summarize*.
- The wholesale report was made by copying the reseller report and changing only the source path.

Sample data: [`sample_data/reseller_prices.csv`](sample_data/reseller_prices.csv)
