-----------------------------------
-- TECH-DA102-4 SQL for Data Analytics (202504)
-- Assessment 3: Unit Summary Project Presentations
-----------------------------------
-- (Team 6 : JoonHee, Lucca,  Yui)
-- This is for Powerpoint sql
-----------------------------------

-- Presentation

-- (a) Range of data
SELECT MIN(OrderDate) AS Startdate,
  MAX(OrderDate) AS Enddate
FROM Sales.SalesOrderHeader;


--What is the quantity of items purchased?
select ProductID, count(*) as 'Qty', Year(OrderDate) as [year] 
from Sales.SalesOrderDetail sod 
	join Sales.SalesOrderHeader soh
		on sod.SalesOrderID=soh.SalesOrderID
group by ProductID, year(OrderDate)
order by ProductID,[year];


--Total profits for B2C and B2B
with Profit_CTE as
(
select sum(sod.OrderQty) as 'NoOfQty',
sum(sod.LineTotal)-(sum(sod.OrderQty)*pp.StandardCost) 'total profits',
case 
when p.PersonType = 'IN' then 'B2C'
else 'B2B'
end as 'Status'
from Sales.SalesOrderHeader soh
	join Sales.SalesOrderDetail sod
		on soh.SalesOrderID=sod.SalesOrderID
    join Sales.Customer c
		on soh.CustomerID=c.CustomerID
	join Person.Person p
		on p.BusinessEntityID=c.PersonID
	join Production.Product pp
		on pp.ProductID=sod.ProductID
group by sod.ProductID,p.PersonType,pp.StandardCost
)

select format(sum([total profits]),'###,#') as 'total profits',Status
from Profit_CTE
group by Status
order by sum([total profits]) desc;


-- B2B/B2C TotalProfit LifeTime Per Month
SELECT  
    CASE  
        WHEN c.StoreID IS NOT NULL THEN 'Business (B2B)'  
        WHEN c.StoreID IS NULL THEN 'Consumer (B2C)'  
    END AS CustomerType,  
	year(h.OrderDate) as 'Year',
    format (SUM(d.LineTotal - (p.StandardCost * d.OrderQty)),'###,#') AS TotalProfit
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON h.SalesOrderID = d.SalesOrderID  
JOIN Sales.Customer c ON c.CustomerID = h.CustomerID  
JOIN Production.Product p ON p.ProductID = d.ProductID  
GROUP BY  
    CASE  
        WHEN c.StoreID IS NOT NULL THEN 'Business (B2B)'  
        WHEN c.StoreID IS NULL THEN 'Consumer (B2C)'  
    END,
    YEAR(h.OrderDate)
order by CustomerType, year(h.OrderDate), TotalProfit DESC;


--NoOfCustomer for each country
select distinct count(*) as NoOfCustomer, psp.CountryRegionCode,pcr.[Name]
from Sales.Customer c
	join Sales.SalesOrderHeader soh
		on c.CustomerID=soh.CustomerID
	join Person.person p
		on c.PersonID=p.BusinessEntityID
	join Person.Address pa
		on	pa.AddressID=soh.ShipToAddressID
	join Person.StateProvince psp
		on psp.StateProvinceID=pa.StateProvinceID
	join Person.CountryRegion pcr
		on psp.CountryRegionCode=pcr.CountryRegionCode
group by psp.CountryRegionCode,pcr.[Name]
order by NoOfCustomer desc;


--TotalProfits for each country
with ProfitsPerCoutry_CTE as (
select SUM(sod.LineTotal - (pp.StandardCost * sod.OrderQty)) AS TotalProfit,pcr.Name
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
		on	pa.AddressID=soh.ShipToAddressID
	join Person.StateProvince psp
		on psp.StateProvinceID=pa.StateProvinceID
	join Person.CountryRegion pcr
		on psp.CountryRegionCode=pcr.CountryRegionCode
group by pcr.Name,sod.ProductID
)

select Name,format (sum(TotalProfit),'###,#') as profits
from ProfitsPerCoutry_CTE
group by Name
order by sum(TotalProfit) desc;


--Total profits for B2B and B2c in each month
SELECT  
    CASE  
        WHEN c.StoreID IS NOT NULL THEN 'Business (B2B)'  
        WHEN c.StoreID IS NULL THEN 'Consumer (B2C)'  
    END AS CustomerType,
    CONCAT(YEAR(h.OrderDate), '-', RIGHT('00' + CAST(MONTH(h.OrderDate) AS VARCHAR(2)), 2)) AS Date,
    SUM(d.LineTotal - (p.StandardCost * d.OrderQty)) AS TotalProfit
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON h.SalesOrderID = d.SalesOrderID  
JOIN Sales.Customer c ON c.CustomerID = h.CustomerID  
JOIN Production.Product p ON p.ProductID = d.ProductID  
GROUP BY  
    CASE  
        WHEN c.StoreID IS NOT NULL THEN 'Business (B2B)'  
        WHEN c.StoreID IS NULL THEN 'Consumer (B2C)'  
    END,
    YEAR(h.OrderDate),
    MONTH(h.OrderDate)
ORDER BY CustomerType,Date, TotalProfit DESC;


--Revenue for B2B and B2c in each month
SELECT  
    CASE  
        WHEN c.StoreID IS NOT NULL THEN 'Business (B2B)'  
        WHEN c.StoreID IS NULL THEN 'Consumer (B2C)'  
    END AS CustomerType,
    CONCAT(YEAR(h.OrderDate), '-', RIGHT('00' + CAST(MONTH(h.OrderDate) AS VARCHAR(2)), 2)) AS Date,
    SUM(d.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON h.SalesOrderID = d.SalesOrderID  
JOIN Sales.Customer c ON c.CustomerID = h.CustomerID  
JOIN Production.Product p ON p.ProductID = d.ProductID  
GROUP BY  
    CASE  
        WHEN c.StoreID IS NOT NULL THEN 'Business (B2B)'  
        WHEN c.StoreID IS NULL THEN 'Consumer (B2C)'  
    END,
    YEAR(h.OrderDate),
    MONTH(h.OrderDate)
ORDER BY CustomerType, Date, TotalRevenue DESC;


--Checking NoOfQty per category for each month in only B2B
with Profit_CTE as
(
select sod.ProductID, FORMAT(OrderDate,'yyyy-MM') as 'Date',sum(sod.OrderQty) as 'NoOfQty',
pp.StandardCost,ppc.Name as 'Category',
case 
when p.PersonType = 'IN' then 'B2C'
else 'B2B'
end as 'Status'
from Sales.SalesOrderHeader soh
	join Sales.SalesOrderDetail sod
		on soh.SalesOrderID=sod.SalesOrderID
    join Sales.Customer c
		on soh.CustomerID=c.CustomerID
	join Person.Person p
		on p.BusinessEntityID=c.PersonID
	join Production.Product pp
		on pp.ProductID=sod.ProductID
	join Production.ProductSubcategory ppsc
		on ppsc.ProductSubcategoryID=pp.ProductSubcategoryID
	join Production.ProductCategory ppc
		on ppc.ProductCategoryID=ppsc.ProductCategoryID
group by sod.ProductID,p.PersonType,pp.StandardCost,FORMAT(OrderDate,'yyyy-MM'),ppc.Name
)

select Date, sum(NoOfQty) as 'NoOfQty',Category
from Profit_CTE
where Status='B2B'
group by Category,Date
order by Category, Date;


--Checking StandardCost per category for each month in only B2B
with Profit_CTE as
(
select sod.ProductID, FORMAT(OrderDate,'yyyy-MM') as 'Date',sum(sod.OrderQty) as 'NoOfQty',
pp.StandardCost,ppc.Name as 'Category',
case 
when p.PersonType = 'IN' then 'B2C'
else 'B2B'
end as 'Status'
from Sales.SalesOrderHeader soh
	join Sales.SalesOrderDetail sod
		on soh.SalesOrderID=sod.SalesOrderID
    join Sales.Customer c
		on soh.CustomerID=c.CustomerID
	join Person.Person p
		on p.BusinessEntityID=c.PersonID
	join Production.Product pp
		on pp.ProductID=sod.ProductID
	join Production.ProductSubcategory ppsc
		on ppsc.ProductSubcategoryID=pp.ProductSubcategoryID
	join Production.ProductCategory ppc
		on ppc.ProductCategoryID=ppsc.ProductCategoryID
group by sod.ProductID,p.PersonType,pp.StandardCost,FORMAT(OrderDate,'yyyy-MM'),ppc.Name
)

select Date, sum(NoOfQty)*sum(StandardCost) as 'TotalStandardCost',Category
from Profit_CTE
where Status='B2B'
group by Category,Date
order by Category, Date;


-- Total Profit Per Season and each country
SELECT 
    YEAR(H.OrderDate) AS Year,
	CASE  
        WHEN st.CountryRegionCode = 'AU' and MONTH(H.OrderDate) IN (3, 4, 5) THEN 'Fall'  
        WHEN st.CountryRegionCode = 'AU' and MONTH(H.OrderDate) IN (6, 7, 8) THEN 'Winter'  
        WHEN st.CountryRegionCode = 'AU' and MONTH(H.OrderDate) IN (9, 10, 11) THEN 'Spring'  
        when st.CountryRegionCode = 'AU' and MONTH(H.OrderDate) IN (12, 1, 2) then 'Summer'
		WHEN st.CountryRegionCode != 'AU' and MONTH(H.OrderDate) IN (3, 4, 5) THEN 'Spring'  
        WHEN st.CountryRegionCode != 'AU' and MONTH(H.OrderDate) IN (6, 7, 8) THEN 'Summer'  
        WHEN st.CountryRegionCode != 'AU' and MONTH(H.OrderDate) IN (9, 10, 11) THEN 'Fall'  
        when st.CountryRegionCode != 'AU' and MONTH(H.OrderDate) IN (12, 1, 2) then 'winter'  
    END AS Season,  
    SUM(D.LineTotal - (P.StandardCost * D.OrderQty)) AS Profit_$  
FROM Sales.SalesOrderHeader H  
JOIN Sales.SalesOrderDetail D ON D.SalesOrderID = H.SalesOrderID  
JOIN Production.Product P ON P.ProductID = D.ProductID 
join Sales.SalesTerritory st on st.TerritoryID=h.TerritoryID 
GROUP BY  
	YEAR(H.OrderDate),  
	CASE  
        WHEN st.CountryRegionCode = 'AU' and MONTH(H.OrderDate) IN (3, 4, 5) THEN 'Fall'  
        WHEN st.CountryRegionCode = 'AU' and MONTH(H.OrderDate) IN (6, 7, 8) THEN 'Winter'  
        WHEN st.CountryRegionCode = 'AU' and MONTH(H.OrderDate) IN (9, 10, 11) THEN 'Spring'  
        when st.CountryRegionCode = 'AU' and MONTH(H.OrderDate) IN (12, 1, 2) then 'Summer'
		WHEN st.CountryRegionCode != 'AU' and MONTH(H.OrderDate) IN (3, 4, 5) THEN 'Spring'  
        WHEN st.CountryRegionCode != 'AU' and MONTH(H.OrderDate) IN (6, 7, 8) THEN 'Summer'  
        WHEN st.CountryRegionCode != 'AU' and MONTH(H.OrderDate) IN (9, 10, 11) THEN 'Fall'  
        when st.CountryRegionCode != 'AU' and MONTH(H.OrderDate) IN (12, 1, 2) then 'winter'  
    END   
ORDER BY Season,Year;


--Profit per Country
 SELECT  
    sp.CountryRegionCode AS Country,
    YEAR(h.OrderDate) AS Date,
    FORMAT(SUM(d.LineTotal - (p.StandardCost * d.OrderQty)), '###,#') AS TotalProfit
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON h.SalesOrderID = d.SalesOrderID  
JOIN Sales.Customer c ON c.CustomerID = h.CustomerID  
JOIN Production.Product p ON p.ProductID = d.ProductID  
JOIN Person.Address a ON h.ShipToAddressID = a.AddressID  -- Join to get address  
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID  -- Join to get country  
GROUP BY  
    sp.CountryRegionCode,
    YEAR(h.OrderDate)
ORDER BY Country, Date, TotalProfit DESC;


--Revenue per Country
 SELECT  
    sp.CountryRegionCode AS Country,
    YEAR(h.OrderDate) AS Date,
    format(SUM(d.LineTotal),'###,#') AS TotalRevenue
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON h.SalesOrderID = d.SalesOrderID  
JOIN Sales.Customer c ON c.CustomerID = h.CustomerID  
JOIN Production.Product p ON p.ProductID = d.ProductID  
JOIN Person.Address a ON h.ShipToAddressID = a.AddressID  -- Join to get address  
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID  -- Join to get country  
GROUP BY  
    sp.CountryRegionCode,
    YEAR(h.OrderDate)
ORDER BY Country, Date, TotalRevenue DESC;


--Reason of Discount
select sod.ProductID,pp.[Name],soh.OrderDate,sod.UnitPrice,sod.UnitPriceDiscount,spo.Description,
case
when sc.StoreID is Null then 'B2C'
when sc.StoreID is not null and sc.PersonID is not null then 'B2B'
else 'Nothing'
end as 'Status'
from Sales.Customer sc
	join Sales.SalesOrderHeader soh on soh.CustomerID=sc.CustomerID
	join Sales.SalesOrderDetail sod on sod.SalesOrderID=soh.SalesOrderID
	join Production.Product pp on sod.ProductID=pp.ProductID
	join Sales.SpecialOffer spo on spo.SpecialOfferID = sod.SpecialOfferID 
where Description != 'No discount'
order by sod.ProductID;


--Finding Top 15 products that make big loss
select top 15
sod.ProductID,pp.[Name],soh.OrderDate,sod.UnitPrice,sod.UnitPriceDiscount,
sum(sod.UnitPrice*(1-sod.UnitPriceDiscount)-pp.StandardCost) as 'Profit per Product',
case
when sc.StoreID is Null then 'B2C'
when sc.StoreID is not null and sc.PersonID is not null then 'B2B'
else 'Nothing'
end as 'Status'
from Sales.Customer sc
	join Sales.SalesOrderHeader soh on soh.CustomerID=sc.CustomerID
	join Sales.SalesOrderDetail sod on sod.SalesOrderID=soh.SalesOrderID
	join Production.Product pp on sod.ProductID=pp.ProductID
	join Sales.SpecialOffer spo on spo.SpecialOfferID = sod.SpecialOfferID 
group by sod.ProductID,pp.[Name],soh.OrderDate,sod.UnitPriceDiscount,sod.UnitPrice,
case
when sc.StoreID is Null then 'B2C'
when sc.StoreID is not null and sc.PersonID is not null then 'B2B'
else 'Nothing'
end
order by [Profit per Product] asc;


--checking when newproduct launched
select p.[Name],soh.OrderDate
from Sales.SalesOrderDetail sod
	join Sales.SalesOrderHeader soh on sod.SalesOrderID=soh.SalesOrderID
	join Production.Product p on p.ProductID=sod.ProductID

-- NOTE: Forecasting, flagging of individual products, and time limits were performed by options within the BI tool (Exploratry).

