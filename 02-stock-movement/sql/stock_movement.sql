-- Stock levels + rolling 3/6-month consumption, straight from the ERP.
-- Table/view names are the ERP's standard reporting views; server, database and company details removed.
-- Rolling window: exactly 6 months back from today (e.g. 28 Apr .. 27 Oct).

SELECT
    W.Code,
    W.Description_1,
    W.ItemCategoryName,
    W.ItemGroupDescription,
    W.WhseCode,
    W.QtyInStock,
    W.QtyOnHand,
    W.QtyOnPO,
    W.QtyOnSO,
    W.ReservedQty,
    W.QtyOnHand - W.ReservedQty                    AS QtyAvailableAfterReserved,
    W.QtyOnHand - W.ReservedQty + W.QtyOnPO        AS QtyAfterReservedPOQty,
    S.Qty6 / 6                                     AS [Avg Monthly Sales],
    CASE WHEN ISNULL(S.Qty6, 0) > 0
         THEN (W.QtyOnHand - W.ReservedQty + W.QtyOnPO) / (S.Qty6 / 6)
         ELSE 0 END                                AS SupplyCoverage,
    ISNULL(S.Qty3, 0)                              AS [3 Month Consumption],
    ISNULL(S.Qty6, 0)                              AS [6 Month Consumption],
    CASE WHEN UPPER(W.ItemGroupDescription) LIKE '%SUPPLIER A%' THEN 'Supplier A'
         WHEN UPPER(W.ItemGroupDescription) LIKE '%SUPPLIER B%' THEN 'Supplier B'
         ELSE 'Other' END                          AS Supplier,
    D.DateStart6                                   AS PeriodStart,
    D.DateEnd                                      AS PeriodEnd
FROM _bvStockAndWhseItemsExPL AS W               -- stock per item per warehouse
CROSS JOIN (
    SELECT DateStart6 = DATEADD(DAY, 1, DATEADD(MONTH, -6, CAST(GETDATE() AS date))),
           DateEnd    = CAST(GETDATE() AS date)
) AS D
LEFT JOIN (
    SELECT T.Code, T.WhseCode,
           SUM(T.ActualQuantity) AS Qty6,
           SUM(CASE WHEN T.TxDate >= DATEADD(DAY, 1, DATEADD(MONTH, -3, CAST(GETDATE() AS date)))
                    THEN T.ActualQuantity ELSE 0 END) AS Qty3
    FROM SalesTransactions AS T                    -- sales lines (custom view in the original system)
    WHERE T.TxDate >= DATEADD(DAY, 1, DATEADD(MONTH, -6, CAST(GETDATE() AS date)))
      AND T.TxDate <= CAST(GETDATE() AS date)
    GROUP BY T.Code, T.WhseCode
) AS S
    ON S.Code = W.Code
   AND S.WhseCode = W.WhseCode;
