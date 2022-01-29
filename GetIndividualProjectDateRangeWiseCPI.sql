IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetIndividualProjectDateRangeWiseCPI')
DROP PROCEDURE GetIndividualProjectDateRangeWiseCPI

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE GetIndividualProjectDateRangeWiseCPI(
	@FromDate as Datetime2,
	@ToDate as Datetime2,
	@Teams as nvarchar(MAX)
)
AS
BEGIN
	
	  BEGIN TRY
			
			SELECT Id, UserId, Convert(varchar, InTime, 1) as Date 
			into #TempJobCards
			FROM JobCards
			WHERE SubmitDate between @FromDate and @ToDate



			SELECT #TempJobCards.Id as JobCardId, #TempJobCards.Date as Date, #TempJobCards.UserId, ANU.UserName, JCT.NumberOfImages as Images, JCT.TaskType, JCT.TeamName, (ANU.Salary+ANU.OverheadCost)/30.0 as PerDaySalary
			INTO #TempJoinedJobCards
			FROM #TempJobCards
			INNER JOIN JobCardTasks as JCT ON #TempJobCards.Id = JCT.JobCardId
			INNER JOIN AspNetUsers as ANU on #TempJobCards.UserId = ANU.Id
			WHERE TeamName = @Teams



			SELECT TeamName as Team, SUM(ISNULL(Images, 0)) as Images
			INTO #TeamWiseTotalImages
			FROM #TempJoinedJobCards
			WHERE TaskType = 'Quality Control'
			GROUP BY TeamName



			SELECT Date, UserId, MIN(ISNULL(PerDaySalary, 0)) as PerDaySalary, JobCardId
			INTO #ConvertingToSingleDay
			FROM #TempJoinedJobCards
			GROUP BY Date, UserId, PerDaySalary, JobCardId
			


			SELECT JCT.JobCardId, CS.Date, CS.UserId, CS.PerDaySalary, CAST(ISNULL(COUNT(DISTINCT JCT.TeamName), 0) AS FLOAT) AS TeamContributionCount, CAST(0 AS FLOAT) as PerDayPerTeamSalary, JCT.TaskType, JCT.TeamName, JCT.NumberOfImages
			INTO #PRIMARY_RESULT
			FROM #ConvertingToSingleDay AS CS
			INNER JOIN JobCardTasks AS JCT
			ON CS.JobCardId = JCT.JobCardId
			GROUP BY JCT.JobCardId, CS.Date, CS.UserId, CS.PerDaySalary, JCT.TaskType, JCT.TeamName, JCT.NumberOfImages

			

			SELECT PR.JobCardId, PR.Date, PR.UserId, PR.PerDaySalary, PR.TeamContributionCount, PR.PerDayPerTeamSalary, PR.TeamName,
				CASE
					WHEN PR.TaskType = 'Quality Control' AND PR.TeamName = @Teams THEN PR.NumberOfImages
					ELSE 0
				END AS NumberOfQC
			INTO #PRIMARY_RESULT_WITH_QC_COUNT
			FROM #PRIMARY_RESULT AS PR
			GROUP BY PR.JobCardId, PR.Date, PR.UserId, PR.PerDaySalary, PR.TeamContributionCount, PR.PerDayPerTeamSalary, PR.TaskType, PR.TeamName, PR.NumberOfImages

			

			SELECT PR.JobCardId, PR.Date, PR.UserId, PR.PerDaySalary, PR.TeamContributionCount, PR.PerDayPerTeamSalary, SUM(ISNULL(NumberOfQC, 0)) AS NumberOfQC
			INTO #RESULT_WITHOUT_TEAM_COUNT
			FROM #PRIMARY_RESULT_WITH_QC_COUNT AS PR
			GROUP BY PR.JobCardId, PR.Date, PR.UserId, PR.PerDaySalary, PR.TeamContributionCount, PR.PerDayPerTeamSalary, NumberOfQC



			SELECT RS.JobCardId, Rs.Date, RS.UserId, RS.PerDaySalary, ISNULL(COUNT(DISTINCT JCT.TeamName), 0) AS TeamContributionCount, RS.PerDayPerTeamSalary, MAX(ISNULL(RS.NumberOfQC, 0)) AS NumberOfQC
			INTO #RESULT
			FROM #RESULT_WITHOUT_TEAM_COUNT AS RS
			INNER JOIN JobCardTasks AS JCT
			ON JCT.JobCardId = RS.JobCardId
			GROUP BY RS.JobCardId, Rs.Date, RS.UserId, RS.PerDaySalary, RS.TeamContributionCount, RS.PerDayPerTeamSalary



			UPDATE #RESULT
			SET PerDayPerTeamSalary = PerDaySalary/TeamContributionCount



			SELECT Date, CAST(SUM(ISNULL(PerDayPerTeamSalary, 0)) AS FLOAT) AS Cost, CAST(SUM(ISNULL(NumberOfQC, 0)) AS FLOAT) AS Images
			INTO #SUMMARY
			FROM #RESULT AS RS
			GROUP BY Date
			


			SELECT CAST(Date AS DATE) AS Date, Images, Cost,  
				CASE
					WHEN Images = 0 THEN 0
					ELSE (COST/Images)
				END AS CPI 
			INTO #CHANGED_SUMMARY
			FROM #SUMMARY;
			


			WITH ListDates(AllDates) AS
			(    
				SELECT @FromDate AS DATE
				UNION ALL
				SELECT DATEADD(DAY,1,AllDates)
				FROM ListDates 
				WHERE AllDates < @ToDate
			)



			SELECT AllDates AS Date, CAST(ISNULL(Images, 0) AS INT) AS Images, 
					ROUND(CAST(ISNULL(Cost, 0.0) AS FLOAT), 2) AS Cost, ROUND(CAST(ISNULL(CPI, 0.0) AS FLOAT), 2) AS CPI
			--INTO #RETURN_VALUE
			FROM ListDates AS LD
			LEFT JOIN #CHANGED_SUMMARY AS CS
			ON LD.AllDates = CS.Date;
			
			

			--SELECT *
			--FROM #RETURN_VALUE



			DROP TABLE #TempJobCards
			DROP TABLE #TempJoinedJobCards
			DROP TABLE #ConvertingToSingleDay
			DROP TABLE #PRIMARY_RESULT
			DROP TABLE #PRIMARY_RESULT_WITH_QC_COUNT
			DROP TABLE #RESULT_WITHOUT_TEAM_COUNT
			DROP TABLE #RESULT
			DROP TABLE #SUMMARY
			DROP TABLE #CHANGED_SUMMARY
			--DROP TABLE #RETURN_VALUE

	  END TRY
	  BEGIN CATCH


	  END CATCH
END


go

--EXEC GetFirstSP '2021-01-01 00:00:00', '2021-04-30 23:59:00', 'FOUR/KLM'


--exec GetFirstSP '2021-01-01 00:00:00', '2021-04-30 23:59:00', 'GNR'


--select * FROM JobCardTasks WHERE JobCardId = '1e7bcc16-ee4a-452f-aa1b-42ab860f878d'

