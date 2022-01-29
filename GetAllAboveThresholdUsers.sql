IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetAllAboveThresholdUsers')
DROP PROCEDURE GetAllAboveThresholdUsers

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE GetAllAboveThresholdUsers(
	@FromDate as Date,
	@ToDate as Date,
	@Teams as nvarchar(MAX)
)

AS

BEGIN
	
	BEGIN TRY
		--select * from dbo.SplitString(@Teams, ',')

		select * INTO #TEAMS from dbo.SplitString(@Teams, ',')

		SELECT *
		INTO #FILTERED_BY_DATE
		FROM PerformanceEvaluations AS PE
		WHERE CAST(Date AS date) BETWEEN @FromDate AND @ToDate 
		--AND (SELECT * FROM #TEAMS INTERSECT select * from dbo.SplitString(PE.TeamNames, ',')) IS NOT NULL
		--AND (SELECT COUNT(*) FROM (SELECT * FROM #TEAMS INTERSECT select * from dbo.SplitString(PE.TeamNames, ',')) AS TEMP) <> 0



		SELECT *
		INTO #FILTERED_BY_TEAM
		FROM #FILTERED_BY_DATE AS PE
		WHERE ( SELECT COUNT(*) FROM #TEAMS WHERE Item IN (SELECT * FROM dbo.SplitString(PE.TeamNames, ',') ) ) <> 0
		


		SELECT ANU.UserName AS Id, ANU.Name, FT.TeamNames AS Team, CONVERT(varchar, FT.Date, 7) AS Date, FT.TotalImages AS Images, CEILING(ISNULL(FT.Threshold, 0)) AS Threshold
		INTO #JOINED_RESULT
		FROM #FILTERED_BY_TEAM AS FT
		INNER JOIN AspNetUsers AS ANU
		ON FT.UserId = ANU.Id



		SELECT *
		FROM #JOINED_RESULT AS JR
		WHERE JR.Images >= JR.Threshold
		ORDER BY Date DESC



		DROP TABLE #FILTERED_BY_TEAM
		DROP TABLE #JOINED_RESULT
		DROP TABLE #TEAMS

	END TRY

	BEGIN CATCH
		


	END CATCH

END

GO


--EXEC GetAllAboveThresholdUsers '2021-04-01', '2021-04-30', 'SIX'

--EXEC GetAllAboveThresholdUsers '2021-04-01', '2021-04-30', 'MLS'

--EXEC GetAllAboveThresholdUsers '2021-04-01', '2021-04-30', 'DSG'

--EXEC GetAllAboveThresholdUsers '2021-04-01', '2021-04-30', 'SIX,DSG'

--EXEC GetAllAboveThresholdUsers '2021-04-01', '2021-04-30', 'SIX,MLS'

--EXEC GetAllAboveThresholdUsers '2021-04-01', '2021-04-30', 'MLS,DSG'

--EXEC GetAllAboveThresholdUsers '2021-04-01', '2021-04-30', 'SIX,MLS,DSG'


--select *
--FROM AspNetUsers
--where (
--	select * from dbo.SplitString('SIX,MLS,SIX', ',')
--		INTERSECT
--	select * from dbo.SplitString('SIX,MLS,SIX', ',')
--) is not null


--select COUNT(*)
--from (
--	select * from dbo.SplitString('SIX,SIX', ',')
--		INTERSECT
--	select * from dbo.SplitString('SIX,MLS,SIX', ',')
--) as a



--select * from AspNetUsers where id = 'd2c4ff7a-ae64-4004-bbb8-e021bdb8cad9'

