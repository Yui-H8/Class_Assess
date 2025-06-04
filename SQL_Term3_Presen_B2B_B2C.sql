USE [AdventureWorks2016]
GO

-----------------------------------
-- This is for Powerpoint sql
-----------------------------------

--- PAGE 3 / Summary ---

-- (a) Range of data

SELECT MIN(OrderDate) AS Startdate,
  MAX(OrderDate) AS Enddate
FROM Sales.SalesOrderHeader;

-- (b) The type of sales is half B-to-B and half B-to-C.
-- >>> FROM 4/9 9:47 in teams chat

with
  Profit_CTE
  as
  (
    select

      sod.ProductID,
      SUM(soh.SubTotal) AS 'Totalsales', -- Yui added

      sum(sod.OrderQty) as 'NoOfQty',
      sum(sod.LineTotal)-(sum(sod.OrderQty)*pp.StandardCost) 'total profits',
      case 
when c.StoreID is null then 'B2C'
when c.StoreID is not null then 'B2B'
end as 'Status'
    from Sales.SalesOrderHeader soh
      join Sales.SalesOrderDetail sod
      on soh.SalesOrderID=sod.SalesOrderDetailID
      join Sales.Customer c
      on soh.CustomerID=c.CustomerID
      join Person.Person p
      on p.BusinessEntityID=c.PersonID
      join Production.Product pp
      on pp.ProductID=sod.ProductID
    group by sod.ProductID,(case 
when c.StoreID is null then 'B2C'
when c.StoreID is not null then 'B2B'
end)
,pp.StandardCost
  )

select
  [Status],
  sum([total profits]) as 'total profits',

  SUM(Totalsales) AS TotalSales, -- Yui added
  (sum([total profits]) / SUM(Totalsales) * 100) AS Percentage_profit

from Profit_CTE
group by Status
order by [total profits] desc
