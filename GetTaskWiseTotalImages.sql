IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetTaskWiseTotalImages')
DROP PROCEDURE GetTaskWiseTotalImages

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

SET NOCOUNT ON;

GO

CREATE PROCEDURE GetTaskWiseTotalImages(
	@FromDate AS DATETIME2,
	@ToDate AS DATETIME2,
	@Teams AS NVARCHAR(MAX)
)
AS
BEGIN
	
	BEGIN TRY
		
		SELECT * INTO #TEAMS FROM dbo.SplitString(@Teams, ',')

		SELECT JCT.TaskType, SUM(ISNULL(JCT.NumberOfImages, 0)) AS NumberOfImages
		FROM JobCards AS JC
		INNER JOIN JobCardTasks AS JCT
		ON JC.Id = JCT.JobCardId
		WHERE InTime BETWEEN @FromDate AND @ToDate AND JCT.TeamName IN (SELECT * FROM #TEAMS)
		GROUP BY JCT.TaskType
		ORDER BY NumberOfImages DESC

		DROP TABLE #TEAMS

	END TRY

	BEGIN CATCH
		
		

	END CATCH

END


GO

EXEC GetTaskWiseTotalImages '2021-04-01 00:00:00', '2021-04-30 23:59:59', 'FOUR/KLM,GLS'












