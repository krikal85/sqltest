--BSP 1

SELECT * FROM dbo.titles

SELECT * FROM rel_title_author

SELECT * FROM dbo.authors

SELECT * FROM dbo.languages

CREATE VIEW dbo.Titel_Autoren_Jahr_jeSprache
AS
SELECT title, year, langName, authName 
FROM dbo.titles base
JOIN dbo.languages sprachen ON base.langID = sprachen.langID
JOIN dbo.rel_title_author autID ON base.titleID = autID.authID
JOIN dbo.authors authoren ON autID.authID = authoren.authID

CREATE FUNCTION dbo.udf_Titel_Autoren_Jahre_jeSprache (@sprache nvarchar(50))
RETURNS TABLE
AS
RETURN
(SELECT * 
FROM dbo.Titel_Autoren_Jahr_jeSprache 
WHERE langName = @sprache)

CREATE PROCEDURE dbo.usp_Titel_Autoren_jahr_JeSprache 
	@sprache nvarchar(50),
	@count int = null output

AS
SELECT *
FROM dbo.udf_Titel_Autoren_Jahre_jeSprache(@sprache)

SELECT @count = @@ROWCOUNT
GO

DECLARE @count int
EXEC dbo.usp_Titel_Autoren_jahr_JeSprache 'Schwedisch', @count output
SELECT @count
GO
	
DECLARE @count int
EXEC dbo.usp_Titel_Autoren_jahr_JeSprache 'svensk', @count output
SELECT @count
GO


--- BSP 2

DROP TABLE IF EXISTS #baseTable;

SELECT * 
INTO #baseTable
FROM (VALUES 
	(1,1,100),
	(1,2,200),
	(1,4,400),
	(2,2,200),
	(2,5,-200),
	(2,6,300),
	(2,6,100),
	(3,7,300),
	(3,8,300),
	(3,12,400)
) tbl(KundenID,Monat,Menge)

SELECT *,
	SUM(Menge) OVER (PARTITION BY KundenID ORDER BY KundenID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as Menge_kumuliert,
	SUM(Menge) OVER (PARTITION BY KundenID) / COUNT(KundenID) OVER (PARTITION BY KundenID ORDER BY KundenID) as menge_Durchschnitt
FROM #baseTable

-- BSP 3

DROP PROCEDURE IF EXISTS _tsql_insert;

CREATE PROCEDURE _tsql_insert
	@new_value  int
AS
DECLARE @sqlString AS NVARCHAR(400);

SET @sqlString = 'INSERT INTO #baseTable
(KundenID, Monat, Menge)
VALUES (3, 10, 500, @new_value)';

SET NOCOUNT ON;
DECLARE @error_message AS NVARCHAR(100), @error_number as int, @error_severity as int

BEGIN TRY
	EXEC sp_executesql
		@statement = @sqlString,
		@params = N'@new_value int',
		@new_value = @new_value
END TRY
BEGIN CATCH
	SELECT
	@error_number = ERROR_NUMBER(),
	@error_message = ERROR_MESSAGE(),
	@error_severity = ERROR_SEVERITY()

	RAISERROR ('zu viele Spalten im Insert', @error_number, @error_severity)

	IF @@TRANCOUNT >0 ROLLBACK TRANSACTION
	
END CATCH
RETURN
GO

EXEC _tsql_insert 50