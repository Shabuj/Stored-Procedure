IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetAllResourceWiseSummaryReport')
DROP PROCEDURE GetAllResourceWiseSummaryReport

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go


CREATE PROCEDURE [dbo].[GetAllResourceWiseSummaryReport](
	@FromDate as Datetime2,
	@ToDate as Datetime2,
	@ResourceId as nvarchar(MAX)
)
AS
BEGIN
	
	  BEGIN TRY


		Declare  @TeamName as varchar(100)

		Set  @TeamName =  (Select TeamNames From AspNetUsers where UserName=@ResourceId)

		SELECT Distinct CONVERT(varchar, jc.SubmitDate, 5) As Date,u.FullName AS Name,jt.NumberOfImages as TotalImages,CAST(CAST(DATEDIFF(MINUTE, jc.InTime, jc.OutTime) as decimal(18,2))/CAST(60 as decimal(18,2)) as decimal(18,2) )  as WH,(DATEDIFF(SECOND, jc.InTime, jc.OutTime)) as WorkHour,(DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE,jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as OverTime,
		et.Abbreviation as Abbreviation,jc.SubmitDate as SubDate,jc.InTime as InTime,jc.OutTime as OutTime,jc.Shift,u.TeamNames As TeamName,jc.InvestigatorComment as InvestigatorComment,
		 CASE 
		     

			 WHEN   CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))  = 0 THEN 0

             WHEN  CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60 >= 0
			       and  
				    CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60<=24
				  
				   THEN  CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +0) as decimal(18,2))
			
		     WHEN   CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60 >= 25
			       and  
				   CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60<=54
				  
				   THEN  CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +30) as decimal(18,2))
					   

			 WHEN   CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60 >= 55
			       and  
				    CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60<=60
				  
				   THEN CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +60) as decimal(18,2))
			
			

             ELSE 0
			 END AS RoundedOverTime

		INTO #TEMPROOTTABLE
		From JobCards jc
		Left join AspNetUsers u ON jc.UserId = u.Id
		Left join JobCardTasks jt ON jt.JobCardId  = jc.Id
		Left Join
		(
		   Select * From EditingTasks 
		) 
		et ON et.Id =jt.EditingTaskId
		Where 
		u.UserName =@ResourceId and
		jc.SubmitDate>=@FromDate and jc.SubmitDate<=@ToDate Group by CONVERT(varchar, jc.SubmitDate, 5),u.FullName,jt.NumberOfImages,jc.OverTime,et.Abbreviation,jc.SubmitDate,jc.InTime,
		jc.OutTime,jc.Shift,u.TeamNames,jc.InvestigatorComment
		order by jc.SubmitDate DESC


		SELECT  CONVERT(varchar, jc.SubmitDate, 5) as  Date ,ISNULL(Sum(jt.NumberOfImages),0 ) as Images
		INTO #OtherImages
		From JobCardTasks jt
		left outer join JobCards jc ON jt.JobCardId  = jc.Id
		left outer join AspNetUsers u ON jc.UserId = u.Id
		Where 
		u.UserName =@ResourceId and
		jc.SubmitDate>=@FromDate and jc.SubmitDate<=@ToDate and jt.TeamName !=@TeamName  Group by jc.SubmitDate
		order by jc.SubmitDate DESC

		Select t.*,Isnull(o.Images,0) as Images INTO #TempOtherImages FROM #TEMPROOTTABLE t Left Join #OtherImages o ON t.Date=o.Date
	
	    

		Select Date,SUM(TotalImages) as Images,SUM(WH) as WorkHour,CAST(CAST(WorkHour as decimal(18,2)) /( CASE WHEN SUM(TotalImages)=0 
		THEN 1
		ELSE
		Cast(SUM(TotalImages) as decimal(18,2))
		END )
		
	    as decimal(18,2))as TPI,
		STUFF((
			SELECT ', ' + Abbreviation+ '(' + CAST(TotalImages AS VARCHAR(MAX)) +')'
			FROM #TEMPROOTTABLE c where Date= t.Date
			FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)') ,1,2,'') AS Task
	    INTO #TASK From #TEMPROOTTABLE t Group by t.Date,t.WorkHour ORDER BY Date DESC
	
		Select  distinct ta.Date,t.Name,ta.Images as Images, t.WH,t.WorkHour,t.InTime,t.OutTime,t.OverTime, ta.Task,ta.TPI,t.Shift,t.TeamName,t.Images as OtherTeams,t.RoundedOverTime,t.InvestigatorComment 
		INTO #RETURNVALUE From #TempOtherImages t INNER JOIN #TASK ta ON t.Date=ta.Date   order by ta.Date DESC

	
			
	   

		SELECT Distinct CONVERT(varchar, jc.SubmitDate, 5) As Date,u.FullName AS Name,jt.NumberOfImages as TotalImages,CAST(CAST(DATEDIFF(MINUTE, jc.InTime, jc.OutTime) as decimal(18,2))/CAST(60 as decimal(18,2)) as decimal(18,2) )  as WH,(DATEDIFF(MINUTE, jc.InTime, jc.OutTime)) as WorkHour,
		CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))/CAST(3600 as decimal(18,2))as decimal(18,2)) as OverTime,
		et.Abbreviation as Abbreviation,jc.SubmitDate as SubDate,jc.InTime as InTime,jc.OutTime as OutTime,jc.Shift,u.TeamNames As TeamName
		INTO #WithOutQC
		From JobCards jc
		Left join AspNetUsers u ON jc.UserId = u.Id
		Left join JobCardTasks jt ON jt.JobCardId  = jc.Id
		Left Join
		(
		   Select * From EditingTasks 
		) 
		et ON et.Id =jt.EditingTaskId
		Where 
		u.UserName =@ResourceId and
		jc.SubmitDate>=@FromDate and jc.SubmitDate<=@ToDate and jt.TaskType <> 'Quality Control' Group by CONVERT(varchar, jc.SubmitDate, 5),u.FullName,jt.NumberOfImages,jc.OverTime,et.Abbreviation,jc.SubmitDate,jc.InTime,
		jc.OutTime,jc.Shift,u.TeamNames
		order by jc.SubmitDate DESC


		Select Date,SUM(TotalImages) as Images
	    INTO #ImageWithoutQC From #WithOutQC t Group by t.Date ORDER BY Date DESC
	
		


		Declare @MinImageWithouOT as bigint
		Declare @MinImageWithoutQC as bigint
		Declare @MaxImageWithouOT as bigint
		Declare @MaxImageWithoutQC as bigint
		Declare @TotalImageWithoutQC as bigint
		Declare @TotalImagesWithOT as bigint
		Declare @TotalDayWithOT as bigint
		Declare @OptimumCapacityPerDay as decimal(18,2)
		Declare @OptimumCapacityPerDayWithoutQC as decimal(18,2)
		Declare @OptimumCapacityPerHour as decimal(18,2)
		Declare @OptimumCapacityPerHourWithoutQC as decimal(18,2)
		
		Declare @TotalWorkHour as varchar(100)
		Declare @TotalOvertime as varchar(100)
		Declare @TimeRequiredPerImage as decimal(18,2)
		Declare @TotalInvestigatedJobCard as bigint
		Declare @CPI  as decimal(18,2)
		Declare @TotalTimeRequiredPerImage  as decimal(18,2)
		Declare @TotalRoundedOvertime  as decimal(18,2)
		declare @TotalHour as bigint
		declare @TotalMin as bigint
		declare @TotalOvertimeHour as bigint
		declare @TotalOvertimeMin as bigint
		Declare @TotalTime  as decimal(18,2)
	


		SET @MinImageWithouOT = (SELECT MIN(Images) FROM #TASK)
		SET @MaxImageWithouOT = (SELECT MAX(Images) FROM #TASK)
		SET @MinImageWithoutQC = (SELECT MIN(Images) FROM #ImageWithoutQC)
		SET @MaxImageWithoutQC = (SELECT MAX(Images) FROM #ImageWithoutQC)
		SET @TotalImageWithoutQC = (SELECT SUM(Images) FROM #ImageWithoutQC)
		SET @TotalImagesWithOT = (SELECT SUM(Images) FROM #TASK)
		SET @TotalDayWithOT = (SELECT COUNT(*) as TotalDay FROM #TASK)
		SET @OptimumCapacityPerDay=CAST(( @TotalImagesWithOT/CAST(@TotalDayWithOT as decimal(18,2))) as decimal(18,2) )
		SET @OptimumCapacityPerDayWithoutQC =CAST(( @TotalImageWithoutQC/CAST(@TotalDayWithOT as decimal(18,2))) as decimal(18,2) )
		SET @OptimumCapacityPerHour =CAST(( @TotalImagesWithOT/CAST(@TotalDayWithOT*8.0 as decimal(18,2))) as decimal(18,2) )
		SET @OptimumCapacityPerHourWithoutQC =CAST(( @TotalImageWithoutQC/CAST(@TotalDayWithOT*8.0 as decimal(18,2))) as decimal(18,2))
	    SET @TotalTime = (SELECT SUM(WH) FROM #RETURNVALUE)
		SET @TimeRequiredPerImage =CAST(( @TotalTime*60/CAST(@TotalImagesWithOT as decimal(18,2))) as decimal(18,2))
		--SET @TotalTimeRequiredPerImage = (SELECT SUM(RoundedOverTime) FROM #RETURNVALUE)
		--SET @TotalRoundedOvertime = (SELECT SUM(TPI) FROM #RETURNVALUE)


		Set @TotalHour=(SELECT SUM(WH) FROM #RETURNVALUE)
		Set @TotalMin=(Select (SUM(WorkHour)%3600)/60   From #RETURNVALUE)
	
		Set @TotalWorkHour = CAST(@TotalHour as varchar(100))+':'+ CAST(@TotalMin as varchar(100))
		Set @TotalOvertimeMin=(Select SUM(OverTime)%3600/60   From #RETURNVALUE)
		Set @TotalOvertimeHour =(Select SUM(OverTime)/3600 From #RETURNVALUE)
		Set @TotalOvertime=CAST(@TotalOvertimeHour as varchar(100))+':'+ CAST(@TotalOvertimeMin as varchar(100))
		

		SET @TotalInvestigatedJobCard =(SELECT Count(*) t FROM #RETURNVALUE where (InvestigatorComment != null OR InvestigatorComment != '') )

	    SET @CPI=  (Select CAST(CAST(SUM(p.TotalImages*p.CPIDaily) as decimal(16,2))/CAST(SUM(p.TotalImages) as decimal(16,2)) as decimal(16,2)) 
		From PerformanceEvaluations p 
		left join AspNetUsers u ON p.UserId = u.Id
		Where u.UserName =@ResourceId and
		Date>=@FromDate and Date<=@ToDate )
		


		Select jc.*, jt.NumberOfImages,jt.EditingTaskId
		INTO #JobCardsTasks 
		FROM JobCardTasks jt 
		Left Join JobCards jc ON jt.JobCardId =jc.Id 
		Left Join 
		(
		Select * From AspNetUsers 
		) as U ON jc.UserId = U.Id 
		Left Join Teams t ON 
		jt.TeamId = t.Id
		where
		u.UserName =@ResourceId and jc.SubmitDate between @FromDate and  @ToDate


		SELECT e.Name As ServiceName,Isnull(Sum(t.NumberOfImages),0) as ServiceBasedProduction
		INTO #ServiceBasedProduction 
		FROM EditingTasks e  left outer join #JobCardsTasks t ON t.EditingTaskId=e.Id Group by e.Name


		
	
		
	    select CAST(null as varchar(8000)) AS ColumnName,CAST(null as varchar(8000)) AS ColumnValue into #RightTempTable
        delete from #RightTempTable
	
	    Insert Into #RightTempTable(ColumnName,ColumnValue) Values('Minimum Images',CAST(@MinImageWithouOT  as varchar(100))),
		('Maximum Images',CAST(@MaxImageWithouOT  as varchar(100))),('Optimum Capacity Per day',CAST(@OptimumCapacityPerDay  as varchar(100))),('Optimum Capacity Per hour',CAST(@OptimumCapacityPerHour  as varchar(100))),('Cost Per Image',CAST(@CPI  as varchar(100)))

		select CAST(null as varchar(8000)) AS ColumnName,CAST(null as varchar(8000)) AS ColumnValue into #LeftDownTempTable
        delete from #LeftDownTempTable
	
	    Insert Into #LeftDownTempTable(ColumnName,ColumnValue) Values('Total Number of images',CAST(@TotalImagesWithOT as varchar(100))),
		('Total Work Hour',CAST(@TotalWorkHour as varchar(100))),('Total Overtime',CAST(@TotalOvertime as varchar(100))),('Time Required per Image',CAST(@TimeRequiredPerImage as varchar(100))),('Total Investigated Job Cards',CAST(@TotalInvestigatedJobCard as varchar(100)))	
		
		
		 Select * from  #RightTempTable
		 Select * From #LeftDownTempTable
	     Select ServiceName,ServiceBasedProduction from #ServiceBasedProduction
		 


		  DROP TABLE #ImageWithoutQC
		  DROP TABLE #RETURNVALUE
		  DROP TABLE #TEMPROOTTABLE
		  DROP Table #TASK
		  DROP Table #OtherImages
		  DROP Table #TempOtherImages
		  DROP TABLE #ServiceBasedProduction
		  DROP TABLE #JobCardsTasks
		  DROP TABLE #RightTempTable
		  DROP Table #LeftDownTempTable
		  


	  END TRY
	  BEGIN CATCH


	  END CATCH
END


