let
    // Direct OneDrive/SharePoint path - not a sharing link, and no "?web=1" at the end
    Source = Excel.Workbook(
        Web.Contents("https://<tenant>-my.sharepoint.com/personal/<user>/Documents/Power%20BI/Pricing%20Data/RESELLER%20LIST%20PRICE%20REPORT.xlsx"),
        null, true),
    Data = Source{[Item = "DATA", Kind = "Sheet"]}[Data],
    Headers = Table.PromoteHeaders(Data, [PromoteAllScalars = true]),

    // Cost and margin never reach Power BI
    NoCost = Table.RemoveColumns(Headers, {"Last Cost", "GP%", "Code"}),

    // 1 -> "001"
    AddWarehouse = Table.AddColumn(NoCost, "Warehouse",
        each Text.PadStart(Text.From([Whse]), 3, "0"), type text),
    NoWhse = Table.RemoveColumns(AddWarehouse, {"Whse"}),

    NoBlanks = Table.SelectRows(NoWhse,
        each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null}))),
    Renamed = Table.RenameColumns(NoBlanks, {{"Excl Price", "Reseller Price (ex GST)"}}),
    Typed = Table.TransformColumnTypes(Renamed, {{"Reseller Price (ex GST)", type number}})
in
    Typed
