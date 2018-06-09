Bitte hier die Kommunikation eintragen und committen:


1)
select c.companyname as [Customer], count(distinct o.orderid) as Orders, count(distinct od.productid) as Products from Sales.Customers c
join Sales.Orders o on o.custid = c.custid
join Sales.OrderDetails od on o.orderid = od.orderid
group by c.companyname
order by [Customer]
