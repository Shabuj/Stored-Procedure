IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetAllBelowThresholdUsers')
DROP PROCEDURE GetAllBelowThresholdUsers

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE GetAllBelowThresholdUsers(
	@FromDate as Date,
	@ToDate as Date,
	@Teams as nvarchar(MAX)
)

AS

BEGIN
	
	BEGIN TRY
		
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



		SELECT ANU.UserName AS Id, ANU.Name, FT.TeamNames AS Team, CONVERT(varchar, FT.Date, 7) AS Date, FT.TotalImages AS Images, CEILING(FT.Threshold) AS Threshold
		INTO #JOINED_RESULT
		FROM #FILTERED_BY_TEAM AS FT
		INNER JOIN AspNetUsers AS ANU
		ON FT.UserId = ANU.Id



		SELECT *
		FROM #JOINED_RESULT AS JR
		WHERE JR.Images < JR.Threshold



		DROP TABLE #FILTERED_BY_TEAM
		DROP TABLE #JOINED_RESULT
		DROP TABLE #TEAMS

	END TRY

	BEGIN CATCH
		


	END CATCH

END

GO

--EXEC GetAllBelowThresholdUsers '2021-01-01', '2021-04-30', 'DSG,Video Production,RBC,PSP,JBL,LOD,JOD-T,ABS-2,LIF,SOS,ATS,SIX,MLS,ABS-1,SOD,AMS,FOUR/KLM,ABS,JOD,MAC,GNR,GLS,NFC'





