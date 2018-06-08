
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
CROSS JOIN  (SELECT val  FROM    (VALUES (1), (2), (3), (4), (5)) tbl(val)) val














