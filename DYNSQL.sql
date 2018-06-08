Declare @tabelle nvarchar(255);

--Set @tabelle='Sales.Orders';

SET @tabelle = 'Sales.Customers';
Declare @sql nvarchar(255);

SET @sql = 'Select * FROM '  + @tabelle + ';'

exec sp_executesql @sql;

-----------------------------------------------------

Declare @tabelle nvarchar(255);

--Set @tabelle='Sales.Orders';

SET @tabelle = 'Sales.Orders';
Declare @sql nvarchar(255);
Declare @column nvarchar(255);
SET @column = 'Sales.Orders.shipname'
SET @sql = 'Select ' + @column +  ' FROM '  + @tabelle + ';'

exec sp_executesql @SQL;