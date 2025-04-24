 -- (d)
-- Page 5 , 01 About Company 
-- Added total and % , 
-- Each year

with
  ProfitsPerCoutry_CTE
as
(
    select pcr.Name,
    YEAR(soh.Orderdate) AS 'Year',
    SUM(sod.LineTotal) - (pp.StandardCost * sum(sod.OrderQty)) AS TotalProfit,
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
group by YEAR(soh.Orderdate),sod.ProductID,pp.StandardCost,pcr.Name
  )


select [Year], sum(TotalProfit) as profits,
    [Name],
    SUM(TotalSales) AS AmountSales,
    SUM(SUM(TotalSales)) OVER (PARTITION BY [Year]) AS AllofSales,
    SUM(sum(TotalProfit)) OVER (PARTITION BY [Year]) AS AllofProfits

INTO SalesTableYear

from ProfitsPerCoutry_CTE
group by [Year], Name
ORDER BY [Year],[Name],AmountSales DESC
;

-------

SELECT [Name], [YEAR], profits,
    ( profits / AllofProfits ) * 100 AS PercentageofProfits,
    AmountSales,
    AllofSales,
    ( AmountSales / AllofSales ) * 100 AS PercentageofSales
FROM SalesTableYear

ORDER BY [YEAR],[Name]
