--Creamos la base de datos.
CREATE DATABASE AdventureWorks_Limpieza;

/* Se puede hacer de dos formas, solo escribimos las consultas para ver si funcionan
   y guardarlas en la query para luego copiarlas y pegarlas en las opciones avanzadas de power bi
   para que power bi las ejecute directo sobre la base de datos o, como voy a hacer aca, crear
   una base de datos con solo las tablas que voy a necesitar para el analisis y poder hacer la limpieza 
   o modificar la base de datos directamente aca, asi se pasa todo limpio a power bi (o su gran mayoria) */ 

USE AdventureWorks_Limpieza;

-- Una vez dentro de la base de datos creada por nosotros exportamos datos.
-- En este caso vamos a usar adventure works 2022

--SELECT @@SERVERNAME AS NombreServidor;

/* Principalmente seleccione las que podrian servir en principio para diferentes analisis, como de ventas,
   clientes, financiero, etc */

--Vistazo rapido de las tablas
SELECT * FROM Production.Product;                     --check
SELECT * FROM Production.ProductCategory;             --check
SELECT * FROM Production.ProductSubcategory;          --check
SELECT * FROM sales.SalesOrderDetail;		          --check
SELECT * FROM sales.SalesOrderHeader;                 --check
SELECT * FROM sales.SalesTerritory;                   --check
SELECT * FROM sales.SalesPerson;			          --check
SELECT * FROM Production.ProductListPriceHistory;     --check



--vemos tipos de datos
SELECT * FROM Production.Product;

SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Production.product');

-- Limpieza de production.product 

SELECT
    SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS Nulos_ProductID,
    SUM(CASE WHEN Name IS NULL THEN 1 ELSE 0 END) AS Nulos_Name,
	SUM(CASE WHEN ProductNumber IS NULL THEN 1 ELSE 0 END) AS Nulos_ProductNumber,
	SUM(CASE WHEN MakeFlag IS NULL THEN 1 ELSE 0 END) AS Nulos_MakeFlag,
	SUM(CASE WHEN FinishedGoodsFlag IS NULL THEN 1 ELSE 0 END) AS Nulos_FinishedGoodsFlag,
	SUM(CASE WHEN Color IS NULL THEN 1 ELSE 0 END) AS Nulos_color,
	SUM(CASE WHEN SafetyStockLevel IS NULL THEN 1 ELSE 0 END) AS Nulos_SafetyStockLevel,
	SUM(CASE WHEN ReorderPoint IS NULL THEN 1 ELSE 0 END) AS Nulos_ReorderPoint,
	SUM(CASE WHEN StandardCost IS NULL THEN 1 ELSE 0 END) AS Nulos_StandardCost,
	SUM(CASE WHEN ListPrice IS NULL THEN 1 ELSE 0 END) AS Nulos_ListPrice,
	SUM(CASE WHEN Size IS NULL THEN 1 ELSE 0 END) AS Nulos_Size,
	SUM(CASE WHEN SizeUnitMeasureCode IS NULL THEN 1 ELSE 0 END) AS Nulos_SizeUnitMeasureCode,
	SUM(CASE WHEN WeightUnitMeasureCode IS NULL THEN 1 ELSE 0 END) AS Nulos_WeightUnitMeasureCode,
	SUM(CASE WHEN Weight IS NULL THEN 1 ELSE 0 END) AS Nulos_Weight,
	SUM(CASE WHEN DaysToManufacture IS NULL THEN 1 ELSE 0 END) AS Nulos_DaysToManufacture,
    SUM(CASE WHEN ProductLine IS NULL THEN 1 ELSE 0 END) AS Nulos_ProductLine,
    SUM(CASE WHEN Class IS NULL THEN 1 ELSE 0 END) AS Nulos_Class,
    SUM(CASE WHEN Style IS NULL THEN 1 ELSE 0 END) AS Nulos_Style,
	SUM(CASE WHEN ProductSubcategoryID IS NULL THEN 1 ELSE 0 END) AS Nulos_ProductSubcategoryID,
	SUM(CASE WHEN ProductModelID IS NULL THEN 1 ELSE 0 END) AS Nulos_ProductModelID,
	SUM(CASE WHEN SellStartDate IS NULL THEN 1 ELSE 0 END) AS Nulos_SellStartDate,
	SUM(CASE WHEN SellEndDate IS NULL THEN 1 ELSE 0 END) AS Nulos_SellEndDate,
	SUM(CASE WHEN DiscontinuedDate IS NULL THEN 1 ELSE 0 END) AS Nulos_DiscontinuedDate,
	SUM(CASE WHEN ModifiedDate IS NULL THEN 1 ELSE 0 END) AS Nulos_ModifiedDate
FROM Production.Product;

--DUPLICADOS

SELECT *
FROM Production.Product
EXCEPT
SELECT DISTINCT *
FROM Production.Product;

ALTER TABLE production.product
DROP COLUMN rowguid;

UPDATE Production.Product
SET Color = 'None',
	SizeUnitMeasureCode = 'CM',
	WeightUnitMeasureCode = 'LB'
WHERE Color IS NULL
OR SizeUnitMeasureCode IS NULL 
OR WeightUnitMeasureCode IS NULL;

-- Iba a tomar una sola forma de tamaño de la columna size, como numero o letra pero no tendria sentido porque
-- es parte de identificacion del producto por ende solo se trataran los nulos como N/A pero tambien hay nombres
-- que terminan con numeros pero siguen nulos asique se tomara en cuenta esos numeros para rellenar los nulos

SELECT 
    ProductID,
    Name,
    Size,
    REVERSE(SUBSTRING(REVERSE(Name), 1, PATINDEX('%[^0-9]%', REVERSE(Name) + 'X') - 1)) AS ExtractedSizeNumber
FROM Production.Product
WHERE Size IS NULL
  AND Name LIKE '%[0-9]';

UPDATE Production.Product
SET Size = REVERSE(SUBSTRING(REVERSE(Name), 1, PATINDEX('%[^0-9]%', REVERSE(Name) + 'X') - 1))
WHERE Size IS NULL
  AND Name LIKE '%[0-9]';

UPDATE Production.Product
SET size = 'N/A'
WHERE size IS NULL;


SELECT Weight
FROM Production.Product
WHERE TRY_CAST(Weight AS FLOAT) IS NULL
  AND Weight IS NOT NULL;

ALTER TABLE Production.Product
ALTER COLUMN Weight FLOAT NULL;

--comprobar
SELECT 
    CASE 
        WHEN Weight IS NULL THEN NULL
        WHEN Weight = FLOOR(Weight) THEN
            CASE 
                WHEN Weight >= 100 THEN Weight / 100.0   -- 218 → 2.18
                WHEN Weight >= 10 THEN Weight / 10.0     -- 75 → 7.5
                ELSE Weight * 1.0                        -- 1, 2, 9 → se mantienen
            END
        ELSE Weight  -- ya tiene decimales, se mantiene
    END AS WeightNormalizado
FROM Production.Product;

UPDATE Production.Product
SET Weight = 
    CASE 
        WHEN Weight IS NULL THEN NULL
        WHEN Weight = FLOOR(Weight) THEN
            CASE 
                WHEN Weight >= 100 THEN Weight / 100.0
                WHEN Weight >= 10 THEN Weight / 10.0
                ELSE Weight * 1.0
            END
        ELSE Weight
    END
WHERE Weight IS NOT NULL;

UPDATE Production.Product
SET Weight = (SELECT ROUND(AVG(Weight), 2) FROM Production.Product WHERE Weight IS NOT NULL)
WHERE Weight IS NULL;


-- al quedar varios valores de un mismo valor que antes eran nulos esto puede sesgar el analisis por ende 
-- se añadira ruido 
SELECT weight
from Production.Product 


UPDATE Production.Product
SET Weight = Weight / 4
WHERE Weight = 11.73;

--Para chequear si se rellenan bien los nulos
SELECT name, ProductLine = CASE 
	WHEN name LIKE '%Road%' THEN 'R'
	WHEN name LIKE '%Mountain%' THEN 'M'
	WHEN name LIKE '%Touring%' THEN 'T'
	ELSE 'S'
END
FROM Production.Product

--rellenamos nulos.

UPDATE Production.Product
SET ProductLine = CASE 
	WHEN name LIKE '%Road%' THEN 'R'
	WHEN name LIKE '%Mountain%' THEN 'M'
	WHEN name LIKE '%Touring%' THEN 'T'
	ELSE 'S'
END
WHERE ProductLine IS NULL;

SELECT ProductID, class, name
FROM Production.Product

SELECT Name,
       Class = CASE 
           WHEN RIGHT(CAST(ProductID AS VARCHAR), 1) IN ('1','2','3') THEN 'L'
           WHEN RIGHT(CAST(ProductID AS VARCHAR), 1) IN ('4','5','6') THEN 'M'
           WHEN RIGHT(CAST(ProductID AS VARCHAR), 1) IN ('7','8','9') THEN 'H'
           ELSE 'L'
       END
FROM Production.Product;

UPDATE Production.Product
SET  Class = CASE 
           WHEN RIGHT(CAST(ProductID AS VARCHAR), 1) IN ('1','2','3') THEN 'L'
           WHEN RIGHT(CAST(ProductID AS VARCHAR), 1) IN ('4','5','6') THEN 'M'
           WHEN RIGHT(CAST(ProductID AS VARCHAR), 1) IN ('7','8','9') THEN 'H'
           ELSE 'L'
       END
WHERE class IS NULL;

SELECT Name,
       Class = CASE 
           WHEN RIGHT(CAST(ProductID AS VARCHAR), 1) IN ('1','2','3') THEN 'L'
           WHEN RIGHT(CAST(ProductID AS VARCHAR), 1) IN ('4','5','6') THEN 'M'
           WHEN RIGHT(CAST(ProductID AS VARCHAR), 1) IN ('7','8','9') THEN 'H'
           ELSE 'L'
       END
FROM Production.Product;


--buscamos si hay algun patron o ayuda para poder diferencia si es de mujer hombre o unisex
SELECT name, Style
FROM Production.Product

SELECT name, style
FROM Production.Product
WHERE name LIKE '%women%' or Name LIKE '%-w%' OR style = 'W';

SELECT name, style
FROM Production.Product
WHERE name like 'Men%' or style = 'M';  -- no me deja men's

SELECT name, style
FROM Production.Product
WHERE style = 'U';


SELECT name, 
       style = CASE 
	           WHEN name LIKE 'Men%' THEN 'M'
	           WHEN name LIKE '%Women%' or Name LIKE '%-W%' THEN 'W'
			   ELSE 'U'
			   END
FROM Production.Product

UPDATE Production.Product
SET style = CASE 
	           WHEN name LIKE 'Men%' THEN 'M'
	           WHEN name LIKE '%Women%' or Name LIKE '%-W%' THEN 'W'
			   ELSE 'U'
			   END
WHERE style IS NULL

DELETE FROM Production.Product
WHERE ListPrice IS NULL OR ListPrice = 0;

---------------------------------------------------------------------------------------------------------------------

SELECT * FROM Production.ProductCategory;

SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('production.productCategory');

--NULOS

SELECT
    SUM(CASE WHEN ProductCategoryID IS NULL THEN 1 ELSE 0 END) AS Nulos_ProductCategoryID,
    SUM(CASE WHEN Name IS NULL THEN 1 ELSE 0 END) AS Nulos_Name,
--	SUM(CASE WHEN rowguid IS NULL THEN 1 ELSE 0 END) AS Nulos_rowguid,
	SUM(CASE WHEN ModifiedDate IS NULL THEN 1 ELSE 0 END) AS Nulos_ModifiedDate
FROM Production.ProductCategory;

--DUPLICADOS

SELECT *
FROM Production.ProductCategory
EXCEPT
SELECT DISTINCT *
FROM Production.ProductCategory;

ALTER TABLE production.productCategory
DROP COLUMN rowguid;

---------------------------------------------------------------------------------------------------------------------

SELECT * FROM Production.ProductSubcategory;

SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Production.ProductSubcategory');

--NULOS
SELECT
    SUM(CASE WHEN ProductSubcategoryID IS NULL THEN 1 ELSE 0 END) AS Nulos_ProductSubcategoryID,
	SUM(CASE WHEN ProductCategoryID IS NULL THEN 1 ELSE 0 END) AS Nulos_ProductCategoryID,
    SUM(CASE WHEN Name IS NULL THEN 1 ELSE 0 END) AS Nulos_Name,
--	SUM(CASE WHEN rowguid IS NULL THEN 1 ELSE 0 END) AS Nulos_rowguid,
	SUM(CASE WHEN ModifiedDate IS NULL THEN 1 ELSE 0 END) AS Nulos_ModifiedDate
FROM Production.ProductSubcategory;

--DUPLICADOS
SELECT *
FROM Production.ProductCategory
EXCEPT
SELECT DISTINCT *
FROM Production.ProductCategory;

ALTER TABLE production.productSubCategory
DROP COLUMN rowguid;

---------------------------------------------------------------------------------------------------------------------

SELECT * FROM sales.SalesOrderDetail;

SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('sales.SalesOrderDetail');

ALTER TABLE sales.salesOrderDetail
DROP COLUMN rowguid;

-- nulos

SELECT
    SUM(CASE WHEN SalesOrderID IS NULL THEN 1 ELSE 0 END) AS Nulos_SalesOrderID,
    SUM(CASE WHEN SalesOrderDetailID IS NULL THEN 1 ELSE 0 END) AS Nulos_SalesOrderDetailID,
	SUM(CASE WHEN CarrierTrackingNumber IS NULL THEN 1 ELSE 0 END) AS Nulos_CarrierTrackingNumber,
    SUM(CASE WHEN OrderQty IS NULL THEN 1 ELSE 0 END) AS Nulos_OrderQty,
	SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS Nulos_ProductID,
    SUM(CASE WHEN SpecialOfferID IS NULL THEN 1 ELSE 0 END) AS Nulos_SpecialOfferID,
	SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS Nulos_UnitPrice,
	SUM(CASE WHEN UnitPriceDiscount IS NULL THEN 1 ELSE 0 END) AS Nulos_UnitPriceDiscount,
    SUM(CASE WHEN LineTotal IS NULL THEN 1 ELSE 0 END) AS Nulos_LineTotal,
    SUM(CASE WHEN ModifiedDate IS NULL THEN 1 ELSE 0 END) AS Nulos_ModifiedDate
FROM sales.SalesOrderDetail;

--DUPLICADOS
SELECT *
FROM sales.salesOrderDetail
EXCEPT
SELECT DISTINCT *
FROM sales.salesOrderDetail;

--------------------------------------------------------------------------------------------------------------------

SELECT * FROM sales.SalesOrderHeader;

--NULOS
SELECT
    SUM(CASE WHEN SalesOrderID IS NULL THEN 1 ELSE 0 END) AS Nulos_SalesOrderID,
    SUM(CASE WHEN RevisionNumber IS NULL THEN 1 ELSE 0 END) AS Nulos_RevisionNumber,
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS Nulos_OrderDate,
    SUM(CASE WHEN DueDate IS NULL THEN 1 ELSE 0 END) AS Nulos_DueDate,
    SUM(CASE WHEN ShipDate IS NULL THEN 1 ELSE 0 END) AS Nulos_ShipDate,
    SUM(CASE WHEN Status IS NULL THEN 1 ELSE 0 END) AS Nulos_Status,
    SUM(CASE WHEN OnlineOrderFlag IS NULL THEN 1 ELSE 0 END) AS Nulos_OnlineOrderFlag,
    SUM(CASE WHEN SalesOrderNumber IS NULL THEN 1 ELSE 0 END) AS Nulos_SalesOrderNumber,
    SUM(CASE WHEN PurchaseOrderNumber IS NULL THEN 1 ELSE 0 END) AS Nulos_PurchaseOrderNumber,
    SUM(CASE WHEN AccountNumber IS NULL THEN 1 ELSE 0 END) AS Nulos_AccountNumber,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Nulos_CustomerID,
    SUM(CASE WHEN SalesPersonID IS NULL THEN 1 ELSE 0 END) AS Nulos_SalesPersonID,
    SUM(CASE WHEN TerritoryID IS NULL THEN 1 ELSE 0 END) AS Nulos_TerritoryID,
    SUM(CASE WHEN BillToAddressID IS NULL THEN 1 ELSE 0 END) AS Nulos_BillToAddressID,
    SUM(CASE WHEN ShipToAddressID IS NULL THEN 1 ELSE 0 END) AS Nulos_ShipToAddressID,
    SUM(CASE WHEN ShipMethodID IS NULL THEN 1 ELSE 0 END) AS Nulos_ShipMethodID,
    SUM(CASE WHEN CreditCardID IS NULL THEN 1 ELSE 0 END) AS Nulos_CreditCardID,
    SUM(CASE WHEN CreditCardApprovalCode IS NULL THEN 1 ELSE 0 END) AS Nulos_CreditCardApprovalCode,
    SUM(CASE WHEN CurrencyRateID IS NULL THEN 1 ELSE 0 END) AS Nulos_CurrencyRateID,
    SUM(CASE WHEN SubTotal IS NULL THEN 1 ELSE 0 END) AS Nulos_SubTotal,
    SUM(CASE WHEN TaxAmt IS NULL THEN 1 ELSE 0 END) AS Nulos_TaxAmt,
    SUM(CASE WHEN Freight IS NULL THEN 1 ELSE 0 END) AS Nulos_Freight,
    SUM(CASE WHEN TotalDue IS NULL THEN 1 ELSE 0 END) AS Nulos_TotalDue,
    SUM(CASE WHEN Comment IS NULL THEN 1 ELSE 0 END) AS Nulos_Comment,
    SUM(CASE WHEN rowguid IS NULL THEN 1 ELSE 0 END) AS Nulos_rowguid,
    SUM(CASE WHEN ModifiedDate IS NULL THEN 1 ELSE 0 END) AS Nulos_ModifiedDate
FROM Sales.SalesOrderHeader;

--DUPLICADOS
SELECT *
FROM Sales.SalesOrderHeader
EXCEPT
SELECT DISTINCT *
FROM Sales.SalesOrderHeader;

ALTER TABLE sales.salesOrderHeader
DROP COLUMN comment, rowguid;

--info de la tabla
SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Sales.SalesOrderHeader');

------------------------------------------------------------------------------------------
SELECT * FROM sales.SalesTerritory;


--nulos

SELECT
    SUM(CASE WHEN TerritoryID IS NULL THEN 1 ELSE 0 END) AS Nulos_TerritoryID,
    SUM(CASE WHEN Name IS NULL THEN 1 ELSE 0 END) AS Nulos_Name,
    SUM(CASE WHEN CountryRegionCode IS NULL THEN 1 ELSE 0 END) AS Nulos_CountryRegionCode,
    SUM(CASE WHEN [Group] IS NULL THEN 1 ELSE 0 END) AS Nulos_Group,
    SUM(CASE WHEN SalesYTD IS NULL THEN 1 ELSE 0 END) AS Nulos_SalesYTD,
    SUM(CASE WHEN SalesLastYear IS NULL THEN 1 ELSE 0 END) AS Nulos_SalesLastYear,
    SUM(CASE WHEN CostYTD IS NULL THEN 1 ELSE 0 END) AS Nulos_CostYTD,
    SUM(CASE WHEN CostLastYear IS NULL THEN 1 ELSE 0 END) AS Nulos_CostLastYear,
    SUM(CASE WHEN rowguid IS NULL THEN 1 ELSE 0 END) AS Nulos_rowguid,
    SUM(CASE WHEN ModifiedDate IS NULL THEN 1 ELSE 0 END) AS Nulos_ModifiedDate
FROM Sales.SalesTerritory;

--DUPLICADOS
SELECT *
FROM Sales.SalesTerritory
EXCEPT
SELECT DISTINCT *
FROM Sales.SalesTerritory;

--info de la tabla
SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Sales.SalesTerritory');

ALTER TABLE Sales.SalesTerritory
DROP COLUMN rowguid;

------------------------------------------------------------------------------------------
SELECT * FROM sales.SalesPerson;


--nulos
SELECT
    SUM(CASE WHEN BusinessEntityID IS NULL THEN 1 ELSE 0 END) AS Nulos_BusinessEntityID,
    SUM(CASE WHEN TerritoryID IS NULL THEN 1 ELSE 0 END) AS Nulos_TerritoryID,
    SUM(CASE WHEN SalesQuota IS NULL THEN 1 ELSE 0 END) AS Nulos_SalesQuota,
    SUM(CASE WHEN Bonus IS NULL THEN 1 ELSE 0 END) AS Nulos_Bonus,
    SUM(CASE WHEN CommissionPct IS NULL THEN 1 ELSE 0 END) AS Nulos_CommissionPct,
    SUM(CASE WHEN SalesYTD IS NULL THEN 1 ELSE 0 END) AS Nulos_SalesYTD,
    SUM(CASE WHEN SalesLastYear IS NULL THEN 1 ELSE 0 END) AS Nulos_SalesLastYear,
    SUM(CASE WHEN rowguid IS NULL THEN 1 ELSE 0 END) AS Nulos_rowguid,
    SUM(CASE WHEN ModifiedDate IS NULL THEN 1 ELSE 0 END) AS Nulos_ModifiedDate
FROM Sales.SalesPerson;

--rellenamos nulos de salesquota
UPDATE sales.SalesPerson
SET SalesQuota = 250000
WHERE SalesQuota IS NULL;

--DUPLICADOS
SELECT *
FROM Sales.SalesPerson
EXCEPT
SELECT DISTINCT *
FROM Sales.SalesPerson;

SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Sales.SalesPerson');

ALTER TABLE sales.salesperson
DROP COLUMN rowguid;

-----------------------------------------------------------------------------------------

SELECT * FROM Production.ProductListPriceHistory;  


--nulos
SELECT
    SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS Nulos_ProductID,
    SUM(CASE WHEN StartDate IS NULL THEN 1 ELSE 0 END) AS Nulos_StartDate,
    SUM(CASE WHEN EndDate IS NULL THEN 1 ELSE 0 END) AS Nulos_EndDate,
    SUM(CASE WHEN ListPrice IS NULL THEN 1 ELSE 0 END) AS Nulos_ListPrice,
    SUM(CASE WHEN ModifiedDate IS NULL THEN 1 ELSE 0 END) AS Nulos_ModifiedDate
FROM Production.ProductListPriceHistory;


--duplicados

--DUPLICADOS
SELECT *
FROM Production.ProductListPriceHistory
EXCEPT
SELECT DISTINCT *
FROM Production.ProductListPriceHistory;

--tipos de datos
SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Production.ProductListPriceHistory');
-----------------------------------

--python me lee el none de color como Nan asique se modificara eso

UPDATE Production.Product
SET Color = 'Not Have'
WHERE Color = 'None';