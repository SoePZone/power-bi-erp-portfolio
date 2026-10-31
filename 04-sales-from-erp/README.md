# 4. Sales reporting from the ERP

**Problem:** monthly sales came from an Excel add-in report that had to be run and exported by hand.

**Approach**

1. Exported the existing report definition from the reporting add-in. The export is a compressed file
   that contains the report's SQL ("container") in XML.
2. Extracted the SQL. It combines five sources with `UNION ALL`: customer invoices, stock transactions,
   general-ledger lines, and two job-costing sources.
3. Replaced the report's date prompts with rolling rules so it updates itself:
   - start: first day of the financial year range needed (e.g. `'2021-07-01'`)
   - end: `EOMONTH(GETDATE())` - the end of the current month
4. Guarded the profit % against divide-by-zero with `NULLIF(sales, 0)`.
5. Loaded it into Power BI through the gateway.

## Reconciliation

Totals by financial year from SQL were compared with the Excel report:

| Financial year | Matches Excel |
| --- | --- |
| FY2022 | Yes |
| FY2023 | Yes |
| FY2024 | Yes |
| FY2025 | Yes |
| FY2026 | Yes |

(Line counts and sales values withheld.)

## Simplified structure

```sql
SELECT ... FROM CustomerInvoiceLines   -- part 1
UNION ALL
SELECT ... FROM StockTransactions      -- part 2
UNION ALL
SELECT ... FROM LedgerLines            -- part 3
UNION ALL
SELECT ... FROM JobCardStockLines      -- part 4
UNION ALL
SELECT ... FROM JobCardLedgerLines     -- part 5
WHERE TxDate BETWEEN '2021-07-01' AND EOMONTH(GETDATE());
```

The full query is not published because it was written by the add-in vendor and contains company-specific logic.

**Next:** sales dashboard pages and row-level security by sales rep (same pattern as project 1).
