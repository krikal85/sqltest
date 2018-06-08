Drop View uvw_Top10Customers
Create View uvw_Top10Customers AS
select TOP 10 c.companyname, c.custid, COUNT(c.custid) as AmountOrdersFromCustomers, YEAR(o.orderdate) AS JAHR from [Sales].[Orders] as o
join Sales.Customers as c on c.custid = o.custid
group by c.custid, c.companyname, YEAR(o.orderdate)
order by AmountOrdersFromCustomers DESC