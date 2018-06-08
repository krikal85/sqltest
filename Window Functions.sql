 Select *
into #baseTable
From (Values
	(1,100),
	(1,200),
	(2,200),
	(2,300),
	(3,300),
	(3,400)
	) tbl(KundenID,Menge)
	
	--Summenspalten
	/*
	Select KundenID, SUM(Menge) AS Gesamtmenge
	From #baseTable b
	Group BY KundenID
	*/
	/*Windows Funktion
	Select *
	,SUM(Menge) OVER (PARTITION BY KundenID) AS KundenGesamtMenge
	,SUM(Menge) OVER () AS Gesamtmenge
	,Menge * 100.0 / SUM(Menge) OVER () AS AnteilAnGesamtMenge
	From #baseTable b
	*/

	--Kummulieren
	Select *
	,SUM(Menge) OVER (order by KundenID ROWS between UNBOUNDED PRECEDING AND CURRENT ROW) AS KundenGesamtMenge
	,AVG(Menge) OVER (order by KundenID ROWS between 1 Preceding AND Current Row) AS GleitenderDurchschnitt
	,SUM(Menge) OVER (order by KundenID ROWS between 1 PRECEDING AND CURRENT ROW)/2 AS Eigenversuch
	FROM #baseTable


	Select *,
	LAG(Menge) Over (Partition by KundenID Order by KundenID) AS VorherigerWert,
	LEAD(Menge) Over (Partition by KundenID Order by KundenID) AS NächsterWert,
	FROM #baseTable

CREATE TABLE dbo.Sales
(
 Sales_Id INT NOT NULL IDENTITY(1, 1)
  CONSTRAINT PK_Sales_Sales_Id PRIMARY KEY
 , Sales_Customer_Id INT NOT NULL
 , Sales_Date DATETIME2 NOT NULL
 , Sales_Amount DECIMAL (16, 2) NOT NULL
)

INSERT INTO dbo.Sales (Sales_Customer_Id, Sales_Date, Sales_Amount)
VALUES
 (1, '20180102', 54.99)
 , (1, '20180103', 72.99)
 , (1, '20180104', 34.99)
 , (1, '20180115', 29.99)
 , (1, '20180121', 67.00)

 SELECT 
 Sales_Customer_Id
 , Sales_Date
 , LAG(Sales_Amount, 2) OVER(PARTITION BY Sales_Customer_Id ORDER BY Sales_Date) AS PrevValue
 , Sales_Amount
 , LEAD(Sales_Amount, 2) OVER(PARTITION BY Sales_Customer_Id ORDER BY Sales_Date) AS NextValue
 , LAG(Sales_Amount, 2,0) OVER(PARTITION BY Sales_Customer_Id ORDER BY Sales_Date) AS PrevValueW0
 , Sales_Amount
 , LEAD(Sales_Amount, 2,0) OVER(PARTITION BY Sales_Customer_Id ORDER BY Sales_Date) AS NextValueW0
FROM dbo.Sales

 --ROW_Number um Fortlaufende Nummer zu generieren
 Select ROW_NUMBER() over (Order by custid) as Ordernumbergenerated, *
 From Sales.Orders

 --ROW_Number kombination mit Partition um Nummer pro Customer zu generieren
 Select ROW_NUMBER() over (Partition by custid order by custid) as OrdernumberbyCustomer, *
 FROM Sales.Orders

 --Rank generieren von einer Nummer für einen bestimten Namen zum Beispiel Kundennummer in diesem Fall bezug auf Shipname lässt aber nummern aus wie die 2 hier
  Select RANK() over (Order by shipname) as ShipnumberGenerated, *
  FROM Sales.Orders

--Gleich wie Rank aber ohne Nummern auslassen
  Select Dense_RANK() over (Order by shipname) as ShipnumberGenerated, *
  FROM Sales.Orders

    --First Value ich verstehs aber nicht ganz
  Select FIRST_VALUE(freight) Over (Partition by custid Order by custid) AS FirstValue,
  custid, orderid, shipperid, shipname, freight
  From Sales.Orders
  --Last Value ich verstehs aber nicht ganz
  Select LAST_VALUE(freight) Over (Partition by custid Order by custid) AS LastValue,
  custid, orderid, shipperid, shipname, freight
  From Sales.Orders