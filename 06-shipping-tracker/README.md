# 6. Shipping / ETA tracker

**Problem:** inbound shipments were tracked in a free-text spreadsheet. Dates were typed as "Mid Nov",
"3-4 Nov" or "Sep 14th", supplier names were spelled several ways, and one PO appeared twice - so nothing
could be sorted or flagged.

**Data clean-up (kept the team's original 8 columns):**

- Converted every ETD/ETA to a real date; vague dates became best guesses, highlighted for review.
- Found the cause of swapped dates: the ETA column was formatted `mm-dd-yy` on a `dd/mm/yyyy` system.
- Standardised supplier and shipment-type spellings; removed the duplicate PO.
- One simple rule for the team: type dates as dd/mm/yyyy; if it's an estimate, write "est." in Progress.

See [`sample_data/shipments_before.csv`](sample_data/shipments_before.csv) and
[`sample_data/shipments_after.csv`](sample_data/shipments_after.csv).

**Power BI:** a status board for the manager - table sorted by ETA with a colour-coded flag.

```
Flag =
VAR eta = Shipments[ETA to Port]
VAR p = LOWER ( Shipments[Progress] )
RETURN
SWITCH ( TRUE (),
    CONTAINSSTRING ( p, "delivered" ), "Delivered",
    ISBLANK ( eta ), "No ETA",
    eta < TODAY (), "Overdue",
    eta <= TODAY () + 7, "Due in 7 days",
    "On the way" )

Days to ETA =
IF ( ISBLANK ( Shipments[ETA to Port] ), BLANK (),
     DATEDIFF ( TODAY (), Shipments[ETA to Port], DAY ) )
```

Design choice: the first version added many columns and dropdowns; the team said it would be too much
work to maintain, so the final version keeps their familiar layout and lets Power BI do the logic.
