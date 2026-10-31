# 1. Customer price list with row-level security

**Problem:** special customer prices lived in one Excel file. Sending each sales rep their own list was manual,
and a rep must not see other reps' customers.

**Solution:** one Power BI report on top of the Excel file (stored in OneDrive). Row-level security gives each
rep a role that filters to their own customers. Managers get a "Master" role with no filter.

## RLS roles (Modeling > Manage roles)

| Role | Rule on table `Data` |
| --- | --- |
| Alex | `[Rep] = "Alex"` |
| Brooke | `[Rep] = "Brooke"` |
| Chris | `[Rep] = "Chris"` |
| Dana | `[Rep] = "Dana"` |
| Master | *(no rule - sees everything)* |

People are added to roles in the Power BI Service: semantic model > Security.

## Sharing rules that make RLS actually work

- Share the report with **Viewer** access only. Workspace Admin, Member and Contributor roles bypass RLS.
- Untick *Allow recipients to share*.
- Reps must not have access to the source Excel file, or they could read every price there.
- Test with *View as role* in Desktop and *Test as role* in the Service.

## Refresh

- Source: Excel in OneDrive via `Web.Contents` / Excel connector, OAuth2, privacy *Organizational*.
- No gateway needed. Scheduled refresh three times a day.
- Accounts updates prices by saving the new export over the old file with the same name.

## Validation

Row counts per role were checked against the source file, and the roles' totals added up to the full list.
Duplicate prices for the same customer and item were found and sent back to Accounts to fix.

Sample data: [`sample_data/customer_prices.csv`](sample_data/customer_prices.csv)
