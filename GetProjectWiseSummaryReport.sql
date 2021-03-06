

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetProjectWiseSummaryReport')
DROP PROCEDURE GetProjectWiseSummaryReport

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go



CREATE PROCEDURE [dbo].[GetProjectWiseSummaryReport](
	@FromDate as Datetime2,
	@ToDate as Datetime2,
	@TeamName as nvarchar(MAX)
)
AS

BEGIN
	
	  BEGIN TRY
  
        
                
	    SELECT 
		  ((select COUNT(*) from dbo.SplitString(TeamMembers, ',') where item <> '')+ 
		  (select COUNT(*) from dbo.SplitString(TeamLeadIds, ',') where item <> '')) as TotalTeamMember 
		INTO #TotalMemberTeam
		FROM Teams where TeamName = @TeamName


		Select SUM(jt.NumberOfImages) as TotalTeamImages 
		INTO #TotalTeamImages
		From JobCardTasks jt Left Join JobCards jc ON jt.JobCardId =jc.Id 
		Left Join 
		(
		Select * From AspNetUsers 
		) as U ON jc.UserId = U.Id 
		Left Join 
		Teams t ON jt.TeamId = t.Id 
		where jt.TaskType <> 'Quality Control' and jt.TeamName=@TeamName and jc.SubmitDate between @FromDate and @ToDate


		Select jc.*, jt.NumberOfImages,jt.EditingTaskId
		INTO #teamJobCardsTasks 
		FROM JobCardTasks jt 
		Left Join JobCards jc ON jt.JobCardId =jc.Id 
		Left Join 
		(
		Select * From AspNetUsers 
		) as U ON jc.UserId = U.Id 
		Left Join Teams t ON 
		jt.TeamId = t.Id
		where
		jt.TeamName=@TeamName and jc.SubmitDate between @FromDate and  @ToDate


	    Select jc.*, jt.NumberOfImages,jt.EditingTaskId,jt.TaskType,t.TeamName as Team
		INTO #OtherTeamJobCardsTasks
		FROM JobCardTasks jt
		Left Join JobCards jc ON jt.JobCardId =jc.Id
		Left Join 
		(
		Select * From AspNetUsers 
		) as U ON jc.UserId = U.Id 
		
		Left Join 
		Teams t ON 
		jt.TeamId = t.Id where (U.TeamNames NOT LIKE '%'+@TeamName+'%' OR U.TeamNames LIKE '%'+@TeamName+'-%') and  
		jt.TeamName=@TeamName and jc.SubmitDate between @FromDate and @ToDate

		----------------------other
		Select SUM(NumberOfImages) as OtherTotalImages 
		INTO #OtherTeamTotalImages
		FROM #OtherTeamJobCardsTasks where TaskType<> 'Quality Control'
		
		-----Service Based 
		SELECT e.Name As ServiceName,Sum(t.NumberOfImages) as ServiceBasedProduction
		INTO #ServiceBasedProduction 
		FROM #teamJobCardsTasks t inner join EditingTasks e ON t.EditingTaskId=e.Id Group by e.Name

		---- Team Based 
		SELECT 
		CASE
			WHEN (e.TeamNames <> '' and e.TeamNames is not NULL) THEN 
				(
					SELECT TOP 1 *
					FROM dbo.SplitString(e.TeamNames, ',')
					WHERE item <> ''
				)
			ELSE e.TeamNames
		END as TeamNames 
		
		,t.NumberOfImages as NumberOfImage
		INTO #teamBasedPro
		FROM #OtherTeamJobCardsTasks t 
		inner join
		AspNetUsers e ON t.UserId=e.Id
		Where t.TaskType<> 'Quality Control' 


		SELECT TeamNames,SUM(NumberOfImage) as NumberOfImage  INTO #teamBasedProduction FROM #teamBasedPro Group by TeamNames
		 

		Declare @EmployeeIds as Varchar(800)=''
		Declare @TeamLeadIds as Varchar(800)=''

		SET  @EmployeeIds= (SELECT  TeamMembers as TeamMembers FROM Teams where TeamName= @TeamName)
		SET  @TeamLeadIds= (SELECT  TeamLeadIds as TeamLeadIds FROM Teams where TeamName= @TeamName)
		
		SELECT *
			INTO #TEAMMEMBER
			FROM dbo.SplitString(@EmployeeIds, ',') 
			
        SELECT *
		INTO #TEAMLEAD
		FROM dbo.SplitString(@TeamLeadIds, ',')


		SELECT jc.UserId As UserId,SUM(DATEDIFF(MINUTE, jc.InTime, jc.OutTime))/CAST(60 as decimal(18,2)) as WorkHour,SUM(DATEDIFF(SECOND, jc.InTime, jc.OutTime))  as WorkSecond,
		SUM(CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))/CAST(3600 as decimal(18,2))as decimal(18,2))) as OverTime,
		SUM(DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] )) as OverTimeSecond
		INTO #TimeInterval
		From JobCards jc
		Left join AspNetUsers u ON jc.UserId = u.Id
		Where 
		(u.UserName IN (SELECT * FROM #TEAMMEMBER) OR u.UserName IN (SELECT * FROM #TEAMLEAD)) and
		jc.SubmitDate>=@FromDate and jc.SubmitDate<=@ToDate 
		group by jc.UserId

	

		declare @TotalImage as bigint
		declare @TotalTime as bigint
		declare @TimePerImage as varchar(200)
		declare @TotalTeamMembers as bigint
		declare @OtherTotalImages as bigint
		declare @TeamTotalImages as bigint
		declare @TotalHour as bigint
		declare @TotalOverTime as varchar(200)
		declare @TotalMin as bigint
		declare @TotalOvertimeHour as bigint
		declare @TotalOvertimeMin as bigint
		declare @TotalWorkHour as varchar(200)
		declare @TotalMinuteTimePerImage as bigint
		declare @TotalHourPerImage as bigint
		declare @TotalMinutePerImage as bigint


		Set @TotalTeamMembers = (Select TotalTeamMember FROM #TotalMemberTeam)
		Set @TotalImage = (Select TotalTeamImages from #TotalTeamImages)
		Set @OtherTotalImages = (Select OtherTotalImages From #OtherTeamTotalImages)
		Set @TeamTotalImages = (@TotalImage-@OtherTotalImages)
		Set @TotalTime = (Select CAST(SUM(WorkSecond)/60 as decimal(18,2))  from #TimeInterval)
		
		Set @TotalHour=(Select SUM(WorkHour)   From #TimeInterval)
		Set @TotalMin=(Select (SUM(WorkSecond)%3600)/60   From #TimeInterval)
		Set @TotalOvertimeMin=(Select (SUM(OverTimeSecond)%3600)/60   From #TimeInterval)
		Set @TotalWorkHour = CAST(@TotalHour as varchar(100))+':'+ CAST(@TotalMin as varchar(100))
		Set @TotalOvertimeMin=(Select SUM(OverTimeSecond)%3600/60   From #TimeInterval)
		Set @TotalOvertimeHour =(Select SUM(OverTime) From #TimeInterval)
		Set @TotalOverTime=CAST(@TotalOvertimeHour as varchar(100))+':'+ CAST(@TotalOvertimeMin as varchar(100))
		Set @TotalMinuteTimePerImage=CAST((@TotalTime/ CAST(@TotalImage as decimal(18,2))) as decimal(18,2))
		Set @TotalHourPerImage = @TotalMinuteTimePerImage/60
		SET @TotalMinutePerImage = @TotalMinuteTimePerImage-(@TotalHourPerImage*60)
		Set @TimePerImage = CAST(@TotalHourPerImage as varchar(200))+':'+ CASE WHEN @TotalMinutePerImage<10
									THEN 
		                            '0'+CAST(@TotalMinutePerImage as varchar(200))
	                                ELSE 
									CAST(@TotalMinutePerImage as varchar(200))
									END
	   

	   

	    select CAST(null as varchar(8000)) AS ColumnName,CAST(null as varchar(8000)) AS ColumnValue into #FirstTempTable
        delete from #FirstTempTable
	
	    Insert Into #FirstTempTable(ColumnName,ColumnValue) Values('Total '+@TeamName+' Team Members',@TotalTeamMembers),
		('Total Number of images',isnull(@TotalImage,0)),(@TeamName+' Team Contribution',isnull(@TeamTotalImages,0)),('Other Team Contribution',isnull(@OtherTotalImages,0))


		INSERT INTO #FirstTempTable(ColumnName,ColumnValue) Select TeamNames,NumberOfImage From #teamBasedProduction 
		Insert Into #FirstTempTable(ColumnName,ColumnValue) Values('Total Work Hour',isnull(@TotalWorkHour,0)),
		('Total Overtime',isnull(@TotalOverTime,0)),('Time Required per Image',isnull(@TimePerImage,0))
		 
		

		Select * FROM #FirstTempTable
	    Select ServiceName, ServiceBasedProduction from #ServiceBasedProduction 



		DROP TABLE #TotalMemberTeam
		DROP Table #teamJobCardsTasks 
		DROP Table #OtherTeamJobCardsTasks
		DROP Table #teamBasedProduction 
		DROP Table #TotalTeamImages
		DROP Table #OtherTeamTotalImages
		DROP Table #ServiceBasedProduction 
		DROP Table #FirstTempTable
		DROP Table #teamBasedPro

	  END TRY
	  BEGIN CATCH


	  END CATCH
END


