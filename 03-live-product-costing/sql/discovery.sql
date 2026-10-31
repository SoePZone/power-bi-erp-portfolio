-- Discovery queries used to reverse-engineer the ERP's costing (read-only).

-- 1) Find BOM / manufacturing tables and views
SELECT t.TABLE_NAME, t.TABLE_TYPE,
       (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = t.TABLE_NAME) AS Columns
FROM INFORMATION_SCHEMA.TABLES t
WHERE t.TABLE_NAME LIKE '%BOM%' OR t.TABLE_NAME LIKE '%Manuf%'
ORDER BY t.TABLE_TYPE, t.TABLE_NAME;

-- 2) Find every table holding an average / latest cost column
SELECT C.TABLE_NAME, C.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS C
JOIN INFORMATION_SCHEMA.TABLES T ON T.TABLE_NAME = C.TABLE_NAME
WHERE (C.COLUMN_NAME LIKE '%AverageCost%' OR C.COLUMN_NAME LIKE '%LatestCost%')
  AND T.TABLE_TYPE = 'BASE TABLE';

-- 3) One test product: recipe lines next to the stored costs (LEFT JOIN shows gaps)
DECLARE @Product int = 1234;   -- internal ID of the test product
SELECT B.Code,
       B.UnitCost / NULLIF(B.ProductionQty, 0) AS BOM_CostPerUnit,
       C.*
FROM _smvrptGetBOMDetails B
LEFT JOIN _etblStockCosts C ON C.StockID = B.ComponentStockLink
WHERE B.BomStockLink = @Product
ORDER BY B.ComponentIndex;

-- 4) Safety check: joins must not duplicate lines (both numbers must be equal)
SELECT
    (SELECT COUNT(*) FROM _smvrptGetBOMDetails) AS Lines_InERP,
    (SELECT COUNT(*)
       FROM _smvrptGetBOMDetails B
       LEFT JOIN _etblStockCosts CW ON CW.StockID = B.ComponentStockLink AND CW.WhseID = B.DefaultWhseID
       LEFT JOIN _etblStockCosts C0 ON C0.StockID = B.ComponentStockLink AND C0.WhseID = 0) AS Lines_Live;
