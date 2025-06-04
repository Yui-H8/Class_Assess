USE [AdventureWorks2016]
GO

---------------- (e)

-----------------------------------------------
WITH
    B2BB2C_CTE
    AS
    (
        SELECT
            CASE  
        WHEN c.StoreID IS NOT NULL THEN 'Business (B2B)'  
        WHEN c.StoreID IS NULL THEN 'Consumer (B2C)'  
    END AS CustomerType,
            YEAR(h.OrderDate) AS 'Year',
            SUM(d.LineTotal) AS TotalRevYear,
            SUM(d.LineTotal) - (p.StandardCost * sum(d.OrderQty)) AS TotalProfit
        FROM Sales.SalesOrderDetail d
            JOIN Sales.SalesOrderHeader h ON h.SalesOrderID = d.SalesOrderID
            JOIN Sales.Customer c ON c.CustomerID = h.CustomerID
            JOIN Production.Product p ON p.ProductID = d.ProductID
        GROUP BY  
    CASE  
        WHEN c.StoreID IS NOT NULL THEN 'Business (B2B)'  
        WHEN c.StoreID IS NULL THEN 'Consumer (B2C)'  
    END,
    YEAR(h.OrderDate), p.ProductID, p.StandardCost
    )

select CustomerType, [Year],
    SUM(TotalProfit) AS 'B2BperProfit'
from B2BB2C_CTE
GROUP BY CustomerType, [Year]
ORDER BY [Year], CustomerType DESC

