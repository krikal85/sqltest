-- Beispiel für die Nutzung von Indizes
-- Erstellen einer einfachen temporüren Tabelle mit 1M Zeilen

SET NOCOUNT ON
DROP TABLE IF EXISTS #temp;
CREATE TABLE #temp (id int, txt varchar(1))

DECLARE @i int = 1;
WHILE @i <= 1000000
BEGIN
	INSERT INTO #temp VALUES (@i,'A')
	SET @i +=1
END

-- 100 Zeilen updaten, um unterschiedliche Werte zu haben
UPDATE #temp
SET txt = 'B'
WHERE id/100 = 9

-- Den Code nach erstellen der Tabelle inzeln ausführen
-- Ctrl+M: akt. Ausführungsplan mit anzeigen

-- Variante 1: Kein Index, einfache Abfrage
-- Ausführungsplan: TableScan, alle Zeilen werden gelesen (Kosten 2.83365)
SELECT * FROM #temp WHERE txt = 'B'


-- Variante 2: Clustered Index auf die ID Spalte + Covering Non-Clustered Index
-- Ausführungsplan: nur Index Scan für ganze Abfrage, aber immernoch alle Zeilen, weil id indiziert (Kosten 2.66106)
CREATE CLUSTERED INDEX #idx_temp ON #temp(id)
CREATE NONCLUSTERED INDEX #idx_nc_temp ON #temp(id) INCLUDE (txt)

SELECT * FROM #temp WHERE txt = 'B'

DROP INDEX #idx_nc_temp ON #temp
DROP INDEX #idx_temp ON #temp


-- Variante 3: Mit Non-Clustered Index auf die txt-Spalte 
-- Ausführungsplan: Suche auf Basis des Index (100 Zeilen), dann nachschlagen der Werte im Heap (RID-Lookup) (Kosten: 0.322597)
CREATE NONCLUSTERED INDEX #idx_nc_temp ON #temp(txt)

SELECT * FROM #temp WHERE txt = 'B'

DROP INDEX #idx_nc_temp ON #temp


-- Variante 4: Mit Non-Clustered Index auf die txt-Spalte, diesmal mit B-Tree statt Heap (in diesem Fall die effektivste Lüsung, da txt=B der Sortierung entspricht)
-- Ausführungsplan: Suche nur auf Basis des Non-Clustered Index, da id sowieso enthalten (100 Zeilen) (Kosten: 0.003392)
CREATE CLUSTERED INDEX #idx_temp ON #temp(id)
CREATE NONCLUSTERED INDEX #idx_nc_temp ON #temp(txt)

SELECT * FROM #temp WHERE txt = 'B'

DROP INDEX #idx_nc_temp ON #temp
DROP INDEX #idx_temp ON #temp




-- Abfragen der Metadaten zu den Indizes einer Datenbank
-- hier bzgl. Fragmentation, fehlender und ungenutzter Indizes

-- Fragmentaition
SELECT 
	SCHEMA_NAME(so.schema_id) AS [SchemaName],
	OBJECT_NAME(idx.OBJECT_ID) AS [TableName],
	idx.name AS [IndexName],
	idxstats.index_type_desc AS [Index_Type_Desc],
	CAST(idxstats.avg_fragmentation_in_percent AS decimal(5,2)) AS [Frag_Pct],
	idxstats.fragment_count,
	idxstats.page_count,
	idx.fill_factor

FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, 'DETAILED') idxstats

INNER JOIN sys.indexes idx 
   ON idx.OBJECT_ID = idxstats.OBJECT_ID
  AND idx.index_id = idxstats.index_id

INNER JOIN sys.objects so
   ON so.object_id = idx.object_id

WHERE idxstats.avg_fragmentation_in_percent > 20

ORDER BY idxstats.avg_fragmentation_in_percent DESC



-- Missing Indizes
SELECT 
	 user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS [Index_Useful]
	,igs.last_user_seek
	,id.statement AS [Statement]
	,id.equality_columns
	,id.inequality_columns
	,id.included_columns
	,igs.unique_compiles
	,igs.user_seeks
	,igs.avg_total_user_cost
	,igs.avg_user_impact

FROM sys.dm_db_missing_index_group_stats AS igs

INNER JOIN sys.dm_db_missing_index_groups AS ig
   ON igs.group_handle = ig.index_group_handle

INNER JOIN sys.dm_db_missing_index_details AS id
   ON ig.index_handle = id.index_handle

ORDER BY [Index_Useful] DESC;



-- Index Review (unused)
SELECT
	OBJECT_SCHEMA_NAME(i.OBJECT_ID) AS [SchemaName],
	OBJECT_NAME(i.OBJECT_ID) AS [ObjectName],
	i.name AS [IndexName],
	i.type_desc AS [IndexType],
	ius.user_updates AS [UserUpdates],
	ius.last_user_update AS [LastUserUpdate]
FROM sys.indexes i

INNER JOIN sys.dm_db_index_usage_stats ius
   ON ius.OBJECT_ID = i.OBJECT_ID 
  AND ius.index_id = i.index_id

WHERE OBJECTPROPERTY(i.OBJECT_ID, 'IsUserTable') = 1 -- User Indexes
  AND NOT(user_seeks > 0 OR user_scans > 0 or user_lookups > 0) -- not used
  AND i.is_primary_key = 0
  AND i.is_unique = 0
  AND i.name IS NOT NULL

ORDER BY ius.user_updates DESC, SchemaName, ObjectName, IndexName

---------------------------------------------------------------------
-- Preparation Querying Full-Text Data
---------------------------------------------------------------------

USE TSQL2012;
GO
SET NOCOUNT ON;
GO

---------------------------------------------------------------------
-- Creating Full-Text Catalogs and Indexes
---------------------------------------------------------------------

-- Check whether Full-Text and Semantic search is installed
SELECT SERVERPROPERTY('IsFullTextInstalled');
GO

-- Check the filters with sys.sp_help_fulltext_system_components
EXEC sys.sp_help_fulltext_system_components 'filter'; 
GO

-- Check the filters through sys.fulltext_document_types
SELECT document_type, path
FROM sys.fulltext_document_types;
GO

-- Download and install Office 2010 filter pack
-- https://www.microsoft.com/en-us/download/confirmation.aspx?id=17062

-- Next, load them
EXEC sys.sp_fulltext_service 'load_os_resources', 1;
GO
-- Restart SQL Server
-- Check the filters again
EXEC sys.sp_help_fulltext_system_components 'filter'; 
GO
-- Office 2010 filters should be installed

-- Check the languages
SELECT lcid, name
FROM sys.fulltext_languages
ORDER BY name; 
GO

-- Check the stoplists/stopwords
SELECT stoplist_id, name
FROM sys.fulltext_stoplists;
SELECT stoplist_id, stopword, language
FROM sys.fulltext_stopwords;
GO

-- Loading a thesaurus file for US English
EXEC sys.sp_fulltext_load_thesaurus_file 1033; 
GO


---------------------------------------------------------------------
-- Creating Full-Text Catalogs and Indexes
---------------------------------------------------------------------

-- Creating a Table and Full-Text Components


-- Table for documents
CREATE TABLE dbo.Documents
(
  id INT IDENTITY(1,1) NOT NULL,
  title NVARCHAR(100) NOT NULL,
  doctype NCHAR(4) NOT NULL,
  docexcerpt NVARCHAR(1000) NOT NULL,
  doccontent VARBINARY(MAX) NOT NULL,
  CONSTRAINT PK_Documents 
   PRIMARY KEY CLUSTERED(id)
);
GO

-- Put files in folder C:\Temp
-- Insert data
INSERT INTO dbo.Documents
(title, doctype, docexcerpt, doccontent)
SELECT N'Columnstore Indices and Batch Processing', 
 N'docx',
 N'You should use a columnstore index on your fact tables,
   putting all columns of a fact table in a columnstore index. 
   In addition to fact tables, very large dimensions could benefit 
   from columnstore indices as well. 
   Do not use columnstore indices for small dimensions. ',
 bulkcolumn
FROM OPENROWSET(BULK 'C:\Temp\ColumnstoreIndicesAndBatchProcessing.docx', 
                SINGLE_BLOB) AS doc;
INSERT INTO dbo.Documents
(title, doctype, docexcerpt, doccontent)
SELECT N'Introduction to Data Mining', 
 N'docx',
 N'Using Data Mining is becoming more a necessity for every company 
   and not an advantage of some rare companies anymore. ',
 bulkcolumn
FROM OPENROWSET(BULK 'C:\Temp\IntroductionToDataMining.docx', 
                SINGLE_BLOB) AS doc;
INSERT INTO dbo.Documents
(title, doctype, docexcerpt, doccontent)
SELECT N'Why Is Bleeding Edge a Different Conference', 
 N'docx',
 N'During high level presentations attendees encounter many questions. 
   For the third year, we are continuing with the breakfast Q&A session. 
   It is very popular, and for two years now, 
   we could not accommodate enough time for all questions and discussions! ',
 bulkcolumn
FROM OPENROWSET(BULK 'C:\Temp\WhyIsBleedingEdgeADifferentConference.docx', 
                SINGLE_BLOB) AS doc;
INSERT INTO dbo.Documents
(title, doctype, docexcerpt, doccontent)
SELECT N'Additivity of Measures', 
 N'docx',
 N'Additivity of measures is not exactly a data warehouse design problem. 
   However, you have to realize which aggregate functions you will use 
   in reports for which measure, and which aggregate functions 
   you will use when aggregating over which dimension.',
 bulkcolumn
FROM OPENROWSET(BULK 'C:\Temp\AdditivityOfMeasures.docx', 
                SINGLE_BLOB) AS doc;
GO

/*
SELECT *
FROM dbo.Documents;
GO
*/

-- Create Search property list
CREATE SEARCH PROPERTY LIST WordSearchPropertyList;
GO
ALTER SEARCH PROPERTY LIST WordSearchPropertyList
 ADD 'Author' 
 WITH (PROPERTY_SET_GUID = 'F29F85E0-4FF9-1068-AB91-08002B27B3D9', 
       PROPERTY_INT_ID = 4, 
       PROPERTY_DESCRIPTION = 'System.Authors - authors of a given item.');
GO

-- Create Stopwords list
CREATE FULLTEXT STOPLIST SQLStopList;
GO
ALTER FULLTEXT STOPLIST SQLStopList
 ADD 'SQL' LANGUAGE 'English';
GO

-- Check the Stopwords list
SELECT w.stoplist_id,
 l.name,
 w.stopword,
 w.language
FROM sys.fulltext_stopwords AS w
 INNER JOIN sys.fulltext_stoplists AS l
  ON w.stoplist_id = l.stoplist_id;
GO

-- Test parsing
-- Check the correct stoplist id
SELECT * 
FROM sys.dm_fts_parser
(N'"Additivity of measures is not exactly a data warehouse design problem. 
   However, you have to realize which aggregate functions you will use 
   in reports for which measure, and which aggregate functions 
   you will use when aggregating over which dimension."', 1033, 5, 0);
SELECT * 
FROM sys.dm_fts_parser
('FORMSOF(INFLECTIONAL,'+ 'function' + ')', 1033, 5, 0);
GO


-- Installing a Semantic Database and Creating a Full-Text Index

-- Check whether Semantic Language Statistics Database is installed
SELECT * 
FROM sys.fulltext_semantic_language_statistics_database;
GO

-- Install Semantic Language Statistics Database
-- Run the SemanticLanguageDatabase.msi from D:\x64\Setup or download from https://www.microsoft.com/en-us/download/details.aspx?id=52681

-- Attach the database (in case of access denied error grant full permission on files to user)
CREATE DATABASE semanticsdb ON
 (FILENAME = 'C:\Program Files\Microsoft Semantic Language Database\semanticsdb.mdf'),
 (FILENAME = 'C:\Program Files\Microsoft Semantic Language Database\semanticsdb_log.ldf')
 FOR ATTACH;
GO


-- Register it
EXEC sp_fulltext_semantic_register_language_statistics_db
 @dbname = N'semanticsdb';
GO

-- Check whether Semantic Language Statistics Database is installed
/* Check again
SELECT * 
FROM sys.fulltext_semantic_language_statistics_database;
GO
*/

-- Full-text catalog
CREATE FULLTEXT CATALOG DocumentsFtCatalog;
GO

-- Full-text index
CREATE FULLTEXT INDEX ON dbo.Documents
( 
  docexcerpt Language 1033, 
  doccontent TYPE COLUMN doctype
  Language 1033
  STATISTICAL_SEMANTICS
)
KEY INDEX PK_Documents
ON DocumentsFtCatalog
WITH STOPLIST = SQLStopList, 
     SEARCH PROPERTY LIST = WordSearchPropertyList, 
	 CHANGE_TRACKING AUTO;
GO

---------------------------------------------------------------------
--  Using the CONTAINS and FREETEXT Predicates
---------------------------------------------------------------------


-- Simple query
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'data');

-- Logical operators - OR
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'data OR index');

-- Logical operators - AND NOT
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'data AND NOT mining');

-- Logical operators - parentheses
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'data OR (fact AND warehouse)');

-- Phrase
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'"data warehouse"');

-- Prefix
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'"add*"');

-- Simple proximity
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'NEAR(problem, data)');

-- Proximity with max distance
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'NEAR((problem, data),5)');
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'NEAR((problem, data),1)');

-- Proximity with max distance and order
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'NEAR((problem, data),5, TRUE)');

-- Inflectional forms
-- The next query does not return any rows
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'presentation');
-- The next query returns a row
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'FORMSOF(INFLECTIONAL, presentation)');
GO

-- Exercise 2 Use Synonyms

-- Thesaurus
-- 1. Edit the US English thesaurus file tsenu.xml to have the following content: 
--    Location: C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\FTData
/*
<XML ID="Microsoft Search Thesaurus">
    <thesaurus xmlns="x-schema:tsSchema.xml">
	<diacritics_sensitive>0</diacritics_sensitive>
        <expansion>
            <sub>Internet Explorer</sub>
            <sub>IE</sub>
            <sub>IE5</sub>
        </expansion>
        <replacement>
            <pat>NT5</pat>
            <pat>W2K</pat>
            <sub>Windows 2000</sub>
        </replacement>
        <expansion>
            <sub>run</sub>
            <sub>jog</sub>
        </expansion>
        <expansion>
            <sub>need</sub>
            <sub>necessity</sub>
        </expansion>
    </thesaurus>
</XML>
*/

-- Load the US English file
EXEC sys.sp_fulltext_load_thesaurus_file 1033;
GO

-- Synonyms
-- The next query does not return any rows
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'need');
-- The next query returns a row
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'FORMSOF(THESAURUS, need)');

-- Document properties
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(PROPERTY(doccontent,'Author'), 'Dejan');

-- 5. FREETEXT
SELECT id, title, doctype, docexcerpt
FROM dbo.Documents
WHERE FREETEXT(docexcerpt, N'data presentation need');
GO


---------------------------------------------------------------------
--  Using the Full-Text and Semantic Search Table-Valued Functions
---------------------------------------------------------------------

-- Rank with CONTAINSTABLE
SELECT D.id, D.title, CT.[RANK], D.docexcerpt
FROM CONTAINSTABLE(dbo.Documents, docexcerpt, 
      N'data OR level') AS CT
 INNER JOIN dbo.Documents AS D
  ON CT.[KEY] = D.id
ORDER BY CT.[RANK] DESC;

-- Rank with FREETEXTTABLE
SELECT D.id, D.title, FT.[RANK], D.docexcerpt
FROM FREETEXTTABLE (dbo.Documents, docexcerpt, 
      N'data level') AS FT
 INNER JOIN dbo.Documents AS D
  ON FT.[KEY] = D.id
ORDER BY FT.[RANK] DESC;

-- Weighted terms
SELECT D.id, D.title, CT.[RANK], D.docexcerpt
FROM CONTAINSTABLE
      (dbo.Documents, docexcerpt, 
       N'ISABOUT(data weight(0.8), level weight(0.2))') AS CT
 INNER JOIN dbo.Documents AS D
  ON CT.[KEY] = D.id
ORDER BY CT.[RANK] DESC;

-- Proximity term
SELECT D.id, D.title, CT.[RANK]
FROM CONTAINSTABLE (dbo.Documents, doccontent, 
      N'NEAR((data, row), 30)') AS CT
 INNER JOIN dbo.Documents AS D
  ON CT.[KEY] = D.id
ORDER BY CT.[RANK] DESC;


-- Top 20 semantic key phrases
SELECT TOP (20)
 D.id, D.title, SKT.keyphrase, SKT.score
FROM SEMANTICKEYPHRASETABLE
      (dbo.Documents, doccontent) AS SKT
 INNER JOIN dbo.Documents AS D
  ON SKT.document_key = D.id
ORDER BY SKT.score DESC;

-- Documents that are similar to document 1
SELECT SST.matched_document_key, 
 D.title, SST.score
FROM SEMANTICSIMILARITYTABLE
     (dbo.Documents, doccontent, 1) AS SST
 INNER JOIN dbo.Documents AS D
  ON SST.matched_document_key = D.id
ORDER BY SST.score DESC;

-- Semantic search key phrases that are common to two documents
SELECT SSDT.keyphrase, SSDT.score
FROM SEMANTICSIMILARITYDETAILSTABLE
      (dbo.Documents, doccontent, 1,
       doccontent, 4) AS SSDT
ORDER BY SSDT.score DESC;
GO

-- In case of no results: check index population
-- SELECT * FROM sys.dm_fts_index_population WHERE table_id = OBJECT_ID('Documents')  
-- SELECT * FROM sys.dm_fts_semantic_similarity_population WHERE table_id = OBJECT_ID('Documents') 


-- Clean up
DROP TABLE dbo.Documents;
DROP FULLTEXT CATALOG DocumentsFtCatalog;
DROP SEARCH PROPERTY LIST WordSearchPropertyList;
DROP FULLTEXT STOPLIST SQLStopList;
GO

-- Liste der Tabellen samt Schema, geordnet nach Schema und Tabellenname

SELECT
	 s.name AS SchemaName
	,t.name AS TableName
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY SchemaName, TableName


-- Erweiterung um Indexnamen, IndexTypen und Index-Unique-Eigenschaft

SELECT
	 s.name AS SchemaName
	,t.name AS TableName
	,i.name AS IndexName
	,i.type_desc AS IndexType
	,i.is_unique AS IsUnique
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.indexes i ON t.object_id = i.object_id
ORDER BY SchemaName, TableName, IndexName


-- Liste der Tabellen und Datentypen sowie der Lünge und der maximalen Lünge

SELECT
	 s.name AS SchemaName
	,t.name AS TableName
	,c.name AS ColumnName	
	,ty.name AS ColumnType
	,c.max_length AS ColumnLength
	,ty.max_length AS ColumnMaxLength
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.system_type_id = ty.system_type_id
ORDER BY SchemaName, TableName

-- Wer ist aktuell mit dem SQL-Server verbunden
SELECT 
	 c.connect_time
	,c.auth_scheme
	,s.login_time
	,s.login_name
	,s.host_name
	,s.program_name
	
FROM sys.dm_exec_connections c
JOIN sys.dm_exec_sessions s ON c.session_id = s.session_id


-- Erweiterung um Transaktionsinformation

SELECT 
	 c.session_id
	,c.auth_scheme
	,c.node_affinity
	,s.login_name
	,DB_NAME(s.database_id) AS database_name
	,CASE s.transaction_isolation_level
		 WHEN 0 THEN 'Unspecified'
		 WHEN 1 THEN 'Read Uncomitted'
		 WHEN 2 THEN 'Read Committed'
		 WHEN 3 THEN 'Repeatable'
		 WHEN 4 THEN 'Serializable'
		 WHEN 5 THEN 'Snapshot'
	 END AS transaction_isolation_level
	,s.status
	,c.most_recent_sql_handle
 FROM sys.dm_exec_connections c
 JOIN sys.dm_exec_sessions s ON c.session_id = s.session_id


 -- Erweiterung um das Statement
 SELECT 
	 c.session_id
	,c.auth_scheme
	,c.node_affinity
	,s.login_name
	,db_name(s.database_id) AS database_name
	,CASE s.transaction_isolation_level
		WHEN 0 THEN 'Unspecified'
		WHEN 1 THEN 'Read Uncomitted'
		WHEN 2 THEN 'Read Committed'
		WHEN 3 THEN 'Repeatable'
		WHEN 4 THEN 'Serializable'
		WHEN 5 THEN 'Snapshot'
	 END AS transaction_isolation_level
	,s.status AS SessionStatus
	,r.status AS RequestStatus
	,r.cpu_time
	,r.reads
	,r.writes
	,r.logical_reads
	,r.total_elapsed_time
	,t.text
FROM sys.dm_exec_connections c
JOIN sys.dm_exec_sessions s ON c.session_id = s.session_id
LEFT JOIN sys.dm_exec_requests r ON c.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t


SELECT TOP 10 WITH TIES
       c.companyname AS Name
      ,YEAR(o.[orderdate]) AS Jahr
      ,COUNT(o.orderid) AS Anzahl

FROM [Sales].[Orders] o
JOIN [Sales].[Customers] c ON o.custid = c.custid

GROUP BY c.companyname, YEAR(o.[orderdate])
ORDER BY Anzahl DESC


-- übung 2
---- Chars Tabelle
DROP TABLE IF EXISTS dbo.Chars;
GO

CREATE TABLE dbo.Chars (Char char(1) UNIQUE)

------ add letters A-Z  (aka ASCII 65-90) 	
DECLARE @asciiCode INT= 65 
WHILE @asciiCode <= 90 
BEGIN
	INSERT dbo.Chars (Char) SELECT CHAR(@asciiCode)
	SELECT  @asciiCode = @asciiCode + 1
END

SELECT * FROM dbo.Chars
GO

---- View erstellen
CREATE VIEW dbo.IDs (ID,Char,Val)
AS
SELECT CONCAT(Char,Val) AS ID, Char, Val
FROM dbo.Chars
CROSS JOIN (
SELECT Val FROM (VALUES (1),(2),(3),(4),(5)) tbl(Val)
) val
GO

SELECT * FROM dbo.IDs
GO

-- übung 3
---- Tabelle lüschen
DROP TABLE dbo.Chars
GO

---- View aufrufen führt zu Fehler
SELECT * FROM dbo.IDs
GO

DROP VIEW dbo.IDs
GO

---- Tabelle neu anlegen
CREATE TABLE dbo.Chars (Char char(1) UNIQUE)
DECLARE @asciiCode INT= 65 
WHILE @asciiCode <= 90 
BEGIN
	INSERT dbo.Chars (Char) SELECT CHAR(@asciiCode)
	SELECT  @asciiCode = @asciiCode + 1
END
GO

---- View neu anlegen
CREATE VIEW dbo.IDs (ID,Char,Val)
WITH SCHEMABINDING
AS
SELECT CONCAT(Char,Val) AS ID, Char, Val
FROM dbo.Chars
CROSS JOIN (
SELECT Val FROM (VALUES (1),(2),(3),(4),(5)) tbl(Val)
) val
GO

---- Tabelle lüschen
DROP TABLE dbo.Chars -- Fehlermeldung weil es noch eine View auf die Tabelle gibt
GO

---- übung 4
---- View ündern
ALTER VIEW dbo.IDs (ID,Char,Val)
WITH SCHEMABINDING
AS
SELECT CONCAT(Char,Val) AS ID, Char, Val
FROM dbo.Chars
CROSS JOIN (
SELECT Val FROM (VALUES (1),(2),(3),(4),(5)) tbl(Val)
) val
WHERE Char = 'A'
GO

SELECT * FROM dbo.IDs -- 5 Zeilen

-- Update von A auf ü
UPDATE dbo.IDs
SET Char = 'ü'
WHERE Char = 'A'

SELECT * FROM [dbo].[IDs] -- keine Zeilen mehr


-- das Ganze nochmal, aber mit Check-Option
---- View + Tabelle lüschen
DROP VIEW dbo.IDs
GO
DROP TABLE dbo.Chars
GO

---- Tabelle neu anlegen
CREATE TABLE dbo.Chars (Char char(1) UNIQUE)
DECLARE @asciiCode INT= 65 
WHILE @asciiCode <= 90 
BEGIN
	INSERT dbo.Chars (Char) SELECT CHAR(@asciiCode)
	SELECT  @asciiCode = @asciiCode + 1
END
GO

---- View neu anlegen
CREATE VIEW dbo.IDs (ID,Char,Val)
WITH SCHEMABINDING
AS

SELECT CONCAT(Char,Val) AS ID, Char, Val
FROM dbo.Chars
CROSS JOIN (
SELECT Val FROM (VALUES (1),(2),(3),(4),(5)) tbl(Val)
) val
WHERE Char = 'A'
WITH CHECK OPTION
GO

SELECT * FROM dbo.IDs -- 5 Zeilen

-- Update von A auf ü nun nicht mehr müglich
UPDATE dbo.IDs
SET Char = 'ü'
WHERE Char = 'A'






*/



-- View als Ausgangspunkt für Abfragen:
USE TSQL2012;

-- Lüschen falls bereits vorhanden
IF OBJECT_ID (N'Sales.OrderTotalsByYear') IS NOT NULL
DROP VIEW Sales.OrderTotalsByYear;
GO

CREATE VIEW Sales.OrderTotalsByYear
WITH SCHEMABINDING
AS
SELECT
	YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty) AS qty
FROM Sales.Orders AS O
JOIN Sales.OrderDetails AS OD ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate)
GO

-- Gleiche View als Function

-- Lüschen falls bereits vorhanden
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear') IS NOT NULL
DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO

-- Erstellen der Funktion
CREATE FUNCTION Sales.fn_OrderTotalsByYear () -- leere Klammer = kein Parameter
RETURNS TABLE
AS
RETURN
(
	SELECT
		YEAR(O.orderdate) AS orderyear,
		SUM(OD.qty) AS qty
	FROM Sales.Orders AS O
	JOIN Sales.OrderDetails AS OD ON OD.orderid = O.orderid
	GROUP BY YEAR(orderdate)
);

-- Nutzung der View stattdessen
USE TSQL2012;
GO
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear') IS NOT NULL
DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO

CREATE FUNCTION Sales.fn_OrderTotalsByYear ()
RETURNS TABLE
AS
RETURN
(
SELECT orderyear, qty FROM Sales.OrderTotalsByYear
);
GO

-- Select von View mit WHERE Clause
SELECT orderyear, qty
FROM Sales.OrderTotalsByYear
WHERE orderyear = 2007;

-- Select von View mit parametrisierter WHERE-Clause
DECLARE @orderyear int = 2007; -- Variable definieren
SELECT orderyear, qty
FROM Sales.OrderTotalsByYear
WHERE orderyear = @orderyear; -- Variable benutzen

-- Parametrisierte Funktion
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear') IS NOT NULL
DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO

CREATE FUNCTION Sales.fn_OrderTotalsByYear (@orderyear int) -- Parameter übergeben
RETURNS TABLE
AS
RETURN
(
SELECT orderyear, qty FROM Sales.OrderTotalsByYear
WHERE orderyear = @orderyear -- Parameter verwenden
);
GO

-- Abfrage der Funktion
SELECT orderyear, qty FROM Sales.fn_OrderTotalsByYear(2007);

USE TSQL2012;

-- Wenn Funktion schon vorhanden, dann lüschen
IF OBJECT_ID('Sales.udf_turnover') IS NOT NULL
DROP FUNCTION Sales.udf_turnover
GO

-- Funktion erstellen, übergabeparameter UnitPrice und Quantity, deren Multiplikation als Rückgabewert
CREATE FUNCTION Sales.udf_turnover
(
	@unitprice AS MONEY,
	@qty AS INT
)
RETURNS MONEY
AS
BEGIN
	RETURN @unitprice * @qty
END;
GO

-- Funktion in Spaltenliste
SELECT Orderid, unitprice, qty, Sales.udf_turnover(unitprice, qty) AS turnover
FROM Sales.OrderDetails;

-- Funktion in Spaltenliste und WHERE-Bedingung
SELECT Orderid, unitprice, qty, Sales.udf_turnover(unitprice, qty) AS turnover
FROM Sales.OrderDetails
WHERE Sales.udf_turnover(unitprice, qty) > 1000;

USE TSQL2012;

-- Funktion lüschen falls bereits vorhanden
IF OBJECT_ID('Sales.udf_QuantityFilter1') IS NOT NULL
DROP FUNCTION Sales.udf_QuantityFilter1;
GO

-- Erstellen der Inline Table-valued Function
CREATE FUNCTION Sales.udf_QuantityFilter1
(
	@lowqty AS SMALLINT,
	@highqty AS SMALLINT
)
RETURNS TABLE AS 
RETURN -- Tabelle als Rückgabewert, nur ein SELECT zur Definition
(
	SELECT orderid, unitprice, qty
	FROM Sales.OrderDetails
	WHERE qty BETWEEN @lowqty AND @highqty
);
GO


-- Funktion lüschen falls bereits vorhanden
IF OBJECT_ID('Sales.udf_QuantityFilter2') IS NOT NULL
DROP FUNCTION Sales.udf_QuantityFilter2;
GO

-- Erstellen einer Multi-Statement Table-valued Function
CREATE FUNCTION Sales.udf_QuantityFilter2
(
	@lowqty AS SMALLINT,
	@highqty AS SMALLINT
)
RETURNS @returntable TABLE -- der Rückgabewert ist hier eine Tabellenvariable mit definierten Spalten
(
	orderid INT,
	unitprice MONEY,
	qty SMALLINT
)
AS
BEGIN -- Die Tabellen-Variable kann mehrfach modifiziert werden.
	INSERT INTO @returntable (orderid, unitprice, qty)
	SELECT orderid, unitprice, qty
	FROM Sales.OrderDetails
	WHERE qty BETWEEN @lowqty AND @highqty
	RETURN -- beendet die Funktion
END;
GO

-- Der Aufruf ist in beiden Füllen gleich und in diesem Fall ebenso das Ergebnis
SELECT * FROM Sales.udf_QuantityFilter1 (10,20)

SELECT * FROM Sales.udf_QuantityFilter2 (10,20)

Gollners Best

--View scalar Function
Create FUNCTION dbo.Multiply (@A INT, @B INT)
RETURNS INT
AS
BEGIN
Return @A * @B
END
CREATE VIEW test AS
Select dbo.Multiply((Select Top 1 Menge FROM baseTable),2) AS Multiplikation

--View table Function
Create FUNCTION dbo.MultiplyTable (@KundenID int)
RETURNS TABLE
AS
Return select SUM(Menge) AS Kundensumme
FROM dbo.baseTable
where KundenID = @KundenID
CREATE VIEW testTablefunction AS
Select * From dbo.MultiplyTable(1)

-- Everybody love Views
Create View uvw_Top10Customers AS
select TOP 10 c.companyname, c.custid, COUNT(c.custid) as AmountOrdersFromCustomers, YEAR(o.orderdate) AS JAHR from [Sales].[Orders] as o
join Sales.Customers as c on c.custid = o.custid
group by c.custid, c.companyname, YEAR(o.orderdate)
order by AmountOrdersFromCustomers DESC

CREATE TABLE dbo.Chars (Char char(1) UNIQUE)
------ add letters A-Z  (aka ASCII 65-90)  
DECLARE @asciiCode INT= 65
WHILE @asciiCode <= 90
BEGIN
 INSERT dbo.Chars (Char) SELECT CHAR(@asciiCode)
 SELECT  @asciiCode = @asciiCode + 1
END
Select * FROM Chars
DROP Table dbo.Chars
CREATE VIEW VWCHAR AS
Select CONCAT(char,val) AS ID, char, val
From Chars
Cross JOIN (Select val ) val
Select char From Chars
Union ALL
Select val  FROM (VALUES ('1'),('2')) tbl(val)
Create View AE AS
SELECT REPLACE(CONCAT(char, val),'A','Ä') AS ID, char, val
FROM   Chars
CROSS JOIN  (SELECT val  FROM	(VALUES (1), (2), (3), (4), (5)) tbl(val)) val




