IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetAllProjectCpi')
DROP PROCEDURE GetAllProjectCpi

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE GetAllProjectCpi(
	@FromDate as Datetime2,
	@ToDate as Datetime2,
	@Teams as nvarchar(MAX)
)
AS
BEGIN
	
	  BEGIN TRY
			SELECT *
			INTO #TEAMS
			FROM dbo.SplitString(@Teams, ',')

			

			SELECT Id, UserId, Convert(varchar, InTime, 1) as Date 
			into #TempJobCards
			FROM JobCards
			WHERE SubmitDate between @FromDate and @ToDate



			SELECT #TempJobCards.Id as JobCardId, #TempJobCards.Date as Date, #TempJobCards.UserId, ANU.UserName, JCT.NumberOfImages as Images, JCT.TaskType, JCT.TeamName, (ANU.Salary+ANU.OverheadCost)/30.0 as PerDaySalary
			INTO #TempJoinedJobCards
			FROM #TempJobCards
			INNER JOIN JobCardTasks as JCT ON #TempJobCards.Id = JCT.JobCardId
			INNER JOIN AspNetUsers as ANU on #TempJobCards.UserId = ANU.Id
			WHERE TeamName IN (SELECT * FROM #TEAMS)

			

			SELECT TeamName as Team, SUM(ISNULL(Images, 0)) as Images
			INTO #TeamWiseTotalImages
			FROM #TempJoinedJobCards
			WHERE TaskType = 'Quality Control'
			GROUP BY TeamName



			SELECT Date, UserId, MIN(ISNULL(PerDaySalary, 0)) as PerDaySalary, JobCardId
			INTO #ConvertingToSingleDay
			FROM #TempJoinedJobCards
			GROUP BY Date, UserId, PerDaySalary, JobCardId
			
			

			SELECT JCT.JobCardId, CS.Date, CS.UserId, CS.PerDaySalary, CAST(COUNT(DISTINCT JCT.TeamName) AS FLOAT) AS TeamContributionCount, CAST(0 AS FLOAT) as PerDayPerTeamSalary, JCT.TaskType, JCT.TeamName, JCT.NumberOfImages
			INTO #PRIMARY_RESULT
			FROM #ConvertingToSingleDay AS CS
			INNER JOIN JobCardTasks AS JCT
			ON CS.JobCardId = JCT.JobCardId
			WHERE TeamName IN (SELECT * FROM #TEAMS)
			GROUP BY JCT.JobCardId, CS.Date, CS.UserId, CS.PerDaySalary, JCT.TaskType, JCT.TeamName, JCT.NumberOfImages

			

			SELECT PR.JobCardId, PR.Date, PR.UserId, PR.PerDaySalary, PR.TeamContributionCount, PR.PerDayPerTeamSalary, PR.TeamName,
				CASE
					WHEN PR.TaskType = 'Quality Control' AND PR.TeamName IN (SELECT * FROM #TEAMS) THEN PR.NumberOfImages
					ELSE 0
				END AS NumberOfQC
			INTO #PRIMARY_RESULT_WITH_QC_COUNT
			FROM #PRIMARY_RESULT AS PR
			GROUP BY PR.JobCardId, PR.Date, PR.UserId, PR.PerDaySalary, PR.TeamContributionCount, PR.PerDayPerTeamSalary, PR.TaskType, PR.TeamName, PR.NumberOfImages

			

			SELECT PR.JobCardId, PR.Date, PR.UserId, PR.PerDaySalary, PR.TeamContributionCount, PR.PerDayPerTeamSalary, PR.TeamName, SUM(NumberOfQC) AS NumberOfQC
			INTO #RESULT_WITHOUT_TEAM_COUNT
			FROM #PRIMARY_RESULT_WITH_QC_COUNT AS PR
			GROUP BY PR.JobCardId, PR.Date, PR.UserId, PR.PerDaySalary, PR.TeamContributionCount, PR.PerDayPerTeamSalary, PR.TeamName



			SELECT RS.JobCardId, Rs.Date, RS.UserId, RS.PerDaySalary, COUNT(DISTINCT JCT.TeamName) AS TeamContributionCount, RS.PerDayPerTeamSalary, RS.TeamName, MAX(RS.NumberOfQC) AS NumberOfQC
			INTO #RESULT
			FROM #RESULT_WITHOUT_TEAM_COUNT AS RS
			INNER JOIN JobCardTasks AS JCT
			ON JCT.JobCardId = RS.JobCardId
			GROUP BY RS.JobCardId, Rs.Date, RS.UserId, RS.PerDaySalary, RS.TeamContributionCount, RS.PerDayPerTeamSalary, RS.TeamName
			ORDER BY RS.JobCardId


			UPDATE #RESULT
			SET PerDayPerTeamSalary = PerDaySalary/TeamContributionCount

			

			SELECT TeamName, CAST(SUM(PerDayPerTeamSalary) AS FLOAT) AS Cost, CAST(SUM(NumberOfQC) AS FLOAT) AS Images
			INTO #SUMMARY
			FROM #RESULT AS RS
			GROUP BY TeamName
			


			SELECT TeamName, Images, ROUND(Cost, 2) AS Cost, ROUND(CAST(ISNULL(Cost/Images, 0) AS FLOAT), 2) AS CPI
			INTO #RETURN_VALUE
			FROM #SUMMARY
			WHERE Images <> 0

			SELECT * FROM #RETURN_VALUE

			DROP TABLE #TEAMS
			DROP TABLE #TempJobCards
			DROP TABLE #TempJoinedJobCards
			DROP TABLE #ConvertingToSingleDay
			DROP TABLE #PRIMARY_RESULT
			DROP TABLE #PRIMARY_RESULT_WITH_QC_COUNT
			DROP TABLE #RESULT_WITHOUT_TEAM_COUNT
			DROP TABLE #RESULT
			DROP TABLE #SUMMARY
			DROP TABLE #RETURN_VALUE

	  END TRY
	  BEGIN CATCH


	  END CATCH
END


go

--EXEC GetAllProjectCpi '2021-04-01 00:00:00', '2021-04-30 23:59:00', 'NFC'

EXEC GetAllProjectCpi '2021-04-01 00:00:00', '2021-04-30 23:59:00', 'DSG,Video Production,RBC,PSP,JBL,LOD,JOD-T,ABS-2,LIF,SOS,ATS,SIX,MLS,ABS-1,SOD,AMS,FOUR/KLM,ABS,JOD,MAC,GNR,GLS,NFC'

--EXEC GetAllProjectCpi '2021-03-01 00:00:00', '2021-03-31 23:59:00', 'GNR,SIX,ABS,LIF'
--EXEC GetAllProjectCpi '2021-02-01 00:00:00', '2021-02-28 23:59:00', 'GNR,SIX,ABS,LIF'

--exec GetFirstSP '2021-01-01 00:00:00', '2021-04-30 23:59:00', 'GNR'


--select * FROM JobCardTasks WHERE JobCardId = '0762e0fa-8737-41e9-8988-54ba469e3b7b'

--select jc.InTime, jct.TaskType, jct.TeamName, jct.NumberOfImages
--from JobCardTasks as jct
--inner join JobCards as jc
--on jct.JobCardId = jc.Id
--where jct.TeamName = 'AMS'

