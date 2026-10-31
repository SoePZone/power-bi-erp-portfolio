-- One row per recipe line, for every active product with a bill of materials.
-- Component cost = average cost in the line's default warehouse, else warehouse 0 (non-stock cost items).

SELECT
    P.Code                    AS ProductCode,
    P.Description_1           AS ProductDescription,
    G.ItemGroup,
    G.ItemCategory,
    B.ComponentIndex          AS LineNumber,          -- 'LineNo' is a reserved word in T-SQL
    B.Code                    AS ComponentCode,
    C.Description_1           AS ComponentDescription,
    B.ProductionQty           AS QtyPerUnit,
    ISNULL(COALESCE(CW.AverageCost, C0.AverageCost), 0)                   AS ComponentUnitCost,
    B.ProductionQty * ISNULL(COALESCE(CW.AverageCost, C0.AverageCost), 0) AS LineCost,
    B.UnitCost                AS SavedLineCost,
    CASE WHEN M.BomStockLink IS NOT NULL THEN 'Made' ELSE 'Bought / cost item' END AS ComponentType
FROM _smvrptGetBOMDetails B                          -- recipe lines
JOIN StkItem P            ON P.StockLink = B.BomStockLink
LEFT JOIN StkItem C       ON C.StockLink = B.ComponentStockLink
LEFT JOIN (SELECT Code,
                  MAX(ItemGroupDescription) AS ItemGroup,
                  MAX(ItemCategoryName)     AS ItemCategory
           FROM _bvStockAndWhseItemsExPL
           GROUP BY Code) G                         -- one row per item, so no duplicates
                          ON G.Code = P.Code
LEFT JOIN _etblStockCosts CW ON CW.StockID = B.ComponentStockLink
                            AND CW.WhseID  = B.DefaultWhseID
LEFT JOIN _etblStockCosts C0 ON C0.StockID = B.ComponentStockLink
                            AND C0.WhseID  = 0
LEFT JOIN (SELECT DISTINCT BomStockLink FROM _smvrptGetBOMDetails) M
                          ON M.BomStockLink = B.ComponentStockLink
WHERE P.Code NOT LIKE 'ZZZ%'                         -- inactive products
  AND ISNULL(G.ItemCategory, '') <> 'Blocked';
