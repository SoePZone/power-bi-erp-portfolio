# 3. Live product costing

**Problem:** the ERP stores a product's cost only when someone runs a costing. Many products had not been
costed for years, so margins on price lists were based on stale numbers.

**Solution:** recalculate every manufactured product's cost from its recipe (bill of materials) using
**today's** average cost of each raw material, on every refresh.

```
Product cost = SUM over recipe lines of ( quantity per unit x current average cost of the component )
```

## How I found the logic (step by step in SSMS)

1. Listed every table/view with `BOM` in its name using `INFORMATION_SCHEMA.TABLES`.
2. Looked at sample rows of the BOM report view to understand quantity and cost columns.
3. Picked one product with a known cost on the ERP's own costing screen.
4. Compared each recipe line with the stored costs in the stock-cost table until every line matched.
5. Result: quantity x **average cost** in the line's default warehouse (warehouse 0 for non-stock cost
   items such as freight and labour) reproduces the ERP screen exactly (to the cent).

Discovery queries: [`sql/discovery.sql`](sql/discovery.sql) - final query: [`sql/bom_live_cost.sql`](sql/bom_live_cost.sql).

## Checks

- Row count with joins = row count of the BOM view (checked with the query in `discovery.sql`), so no line is double-counted.
- Products costed recently in the ERP match the live cost; products last costed years ago do not -
  which is exactly the gap the report is meant to show.

## Three costs, side by side

| Cost | Meaning | Up to date? |
| --- | --- | --- |
| Live cost | qty x today's average cost | Every refresh |
| Stored line cost | cost saved on each recipe line | Often old or zero |
| Last costing | cost from the last costing run, with its date | Only as of that date |

## Next step

Add list prices and a what-if GP% slider: `Suggested price = Live cost / (1 - target GP%)`.

Sample data: [`sample_data/bom_lines.csv`](sample_data/bom_lines.csv) - DAX: [`dax/measures.dax`](dax/measures.dax)
