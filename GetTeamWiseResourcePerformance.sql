IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetTeamWiseResourcePerformance')
DROP PROCEDURE GetTeamWiseResourcePerformance

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

SET NOCOUNT ON;

GO

CREATE PROCEDURE GetTeamWiseResourcePerformance(
	@FromDate AS Date,
	@ToDate AS Date,
	@Teams AS nvarchar(MAX)
)
AS 
BEGIN
	BEGIN TRY
		
		SELECT * 
		INTO #FILTERED_BY_TEAM
		FROM PerformanceEvaluations AS PE
		WHERE CAST(Date AS date) BETWEEN @FromDate AND @ToDate 
		AND @Teams IN (select * from dbo.SplitString(PE.TeamNames, ','))


		SELECT ANU.Id, ANU.Name, FT.TeamNames AS Team, CONVERT(varchar, FT.Date, 7) AS Date, FT.TotalImages, FT.QC, CEILING(FT.Threshold) AS Threshold
		INTO #JOINED_RESULT
		FROM #FILTERED_BY_TEAM AS FT
		INNER JOIN AspNetUsers AS ANU
		ON FT.UserId = ANU.Id


		SELECT JR.Name, JR.TotalImages, JR.QC, (JR.TotalImages - JR.QC) AS TotalImagesWithOutQc, JR.Threshold AS ThresholdWithQc
		INTO #SUMMARY
		FROM #JOINED_RESULT AS JR

		SELECT SM.Name, SUM(ISNULL(SM.TotalImages, 0)) AS TotalImages, SUM(ISNULL(SM.QC, 0)) AS TotalQc, SUM(ISNULL(SM.TotalImagesWithOutQc, 0)) AS TotalImagesWithOutQc, SUM(ISNULL(SM.ThresholdWithQc, 0)) AS ThresholdWithQc
		FROM #SUMMARY AS SM
		GROUP BY SM.Name
		ORDER BY TotalImages DESC

		DROP TABLE #FILTERED_BY_TEAM
		DROP TABLE #JOINED_RESULT
		DROP TABLE #SUMMARY

	END TRY

	BEGIN CATCH

	END CATCH
END

GO

EXEC GetTeamWiseResourcePerformance '2021-04-30', '2021-04-30', 'GNR'


