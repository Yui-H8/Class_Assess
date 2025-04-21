-----------------------------------
-- This is for Powerpoint sql
-----------------------------------
USE [AdventureWorks2016]
GO

-- (d)
-- Page 5 , 01 About Company
-- Added total and %
-- Create table / Code include 'DROP'

with
  ProfitsPerCoutry_CTE
  as
  (
    select SUM(sod.LineTotal) - (pp.StandardCost * sum(sod.OrderQty)) AS TotalProfit, pcr.Name,

      SUM(SubTotal) AS TotalSales

    from Sales.SalesOrderDetail sod
      join Production.Product pp
      on pp.ProductID=sod.ProductID
      join Sales.SalesOrderHeader soh
      on soh.SalesOrderID=sod.SalesOrderID
      join Sales.Customer c
      on c.CustomerID=soh.CustomerID
      join Person.person p
      on c.PersonID=p.BusinessEntityID
      join Person.Address pa
      on pa.AddressID=soh.ShipToAddressID
      join Person.StateProvince psp
      on psp.StateProvinceID=pa.StateProvinceID
      join Person.CountryRegion pcr
      on psp.CountryRegionCode=pcr.CountryRegionCode
    group by sod.ProductID,pp.StandardCost,pcr.Name
  )


select Name, sum(TotalProfit) as profits,

  SUM(TotalSales) AS AmountSales,
  SUM(SUM(TotalSales)) OVER () AS AllofSales,
  SUM(sum(TotalProfit)) OVER () AS AllofProfits

INTO SalesTable0413

from ProfitsPerCoutry_CTE
group by Name
ORDER BY AmountSales DESC

-------
DROP TABLE SalesTable0413;
-------

SELECT Name, profits,
  ( profits / AllofProfits ) * 100 AS PercentageofProfits,
  AmountSales,
  AllofSales,
  ( AmountSales / AllofSales ) * 100 AS PercentageofSales
FROM SalesTable0413


-----------------
