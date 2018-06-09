Bitte hier die Kommunikation eintragen und committen:


1)
select c.companyname as [Customer], count(distinct o.orderid) as Orders, count(distinct od.productid) as Products from Sales.Customers c
join Sales.Orders o on o.custid = c.custid
join Sales.OrderDetails od on o.orderid = od.orderid
group by c.companyname
order by [Customer]

2)
GO
create function Sales.udf_DistinctOrdersAndProductsCountPerCustomerFiltered(@MinOrders int, @MaxOrders int, @MinProducts int, @MaxProducts int)
returns table
as
return
(
	select c.companyname as [Customer], count(distinct o.orderid) as Orders, count(distinct od.productid) as Products from Sales.Customers c
	join Sales.Orders o on o.custid = c.custid
	join Sales.OrderDetails od on o.orderid = od.orderid
	group by c.companyname
	having count(distinct o.orderid) > @MinOrders AND count(distinct o.orderid) < @MaxOrders AND count(distinct od.productid) > @MinProducts AND count(distinct od.productid) < @MaxProducts
);

GO
select * from Sales.udf_DistinctOrdersAndProductsCountPerCustomerFiltered (1,10,1,30);
