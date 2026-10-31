# Lessons learned

| Problem | Cause | Fix |
| --- | --- | --- |
| Totals row showed 0 for an order-quantity measure | The measure was evaluated once at total level, where the shortfall logic gives 0 | Wrap the logic in `SUMX ( VALUES ( item ), ... )` so the total is the sum of rows |
| A "period" card went blank when slicers were used | The slicers filtered out the rows holding the dates | Use `ALL ( table )` inside `CALCULATE` for the label |
| Prices for the same item added together | Price column was summarised | Set the column to *Don't summarize* |
| Refresh from OneDrive failed (`DataFormat.Error`) | URL ended in `?web=1`, or a sharing link (`:x:/g/...`) was used | Use *File > Info > Copy path* and stop the URL at `.xlsx` |
| Report published from a `C:\` file path | Local paths can only refresh through a gateway | Point the query at the OneDrive https path instead |
| Dates swapped day and month (8/10 became 10 August) | Column formatted `mm-dd-yy` on a dd/mm/yyyy system | Store real dates and format as `dd/mm/yyyy` |
| "Invalid column name" in SQL | Guessed ERP column names | Look them up in `INFORMATION_SCHEMA.COLUMNS` first |
| Query returned no rows | Inner JOIN dropped rows without a match | Use `LEFT JOIN` to see what is missing |
| Syntax error near `LineNo` | Reserved word in T-SQL | Rename the alias, e.g. `LineNumber` |
| A rep could see everyone's prices | Workspace roles (Admin/Member/Contributor) bypass RLS | Share reports with *Viewer* access only |
| Hiding cost columns for reps | RLS filters rows, not columns | Remove the columns in Power Query in the reps' version |
| Renaming a published report | Republishing under a new name creates a second report and loses settings | Rename the report and semantic model in the Service, then rename the file to match |
| Scheduled refresh paused | Repeated failures while the gateway PC was off | Schedule only during working hours, Mon-Fri |
