

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetAllResourceWiseDetailReport')
DROP PROCEDURE GetAllResourceWiseDetailReport

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go


CREATE PROCEDURE [dbo].[GetAllResourceWiseDetailReport](
	@FromDate as Datetime2,
	@ToDate as Datetime2,
	@ResourceId as nvarchar(MAX)
)
AS
BEGIN
	
	  BEGIN TRY

	    Declare @hour as decimal(18,2)
		Declare  @TeamName as varchar(100)

		Set  @TeamName =  (Select TeamNames From AspNetUsers where UserName=@ResourceId)

		SELECT Distinct CONVERT(varchar, jc.SubmitDate, 5) As Date,u.FullName AS Name,jt.NumberOfImages as TotalImages,CAST(DATEDIFF(SECOND, jc.InTime, jc.OutTime)/3600 as varchar(200))+':'+
		CASE
		   WHEN (DATEDIFF(SECOND, jc.InTime, jc.OutTime)%3600)/60<10
		   THEN '0'+CAST((DATEDIFF(SECOND, jc.InTime, jc.OutTime)%3600)/60 as varchar(2))
		   
		   ELSE CAST((DATEDIFF(SECOND, jc.InTime, jc.OutTime)%3600)/60 as varchar(2))
		   
	    END AS  WH,
		
		(DATEDIFF(SECOND, jc.InTime, jc.OutTime)) as WorkHour,(DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE,jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as OverTime,
		CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))/3600 as varchar(200))+':'+
		CASE
		   WHEN ((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))%3600)/60 <10
		   THEN '0'+CAST(((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))%3600)/60 as varchar(200))
		   ELSE CAST(((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))%3600)/60 as varchar(200))
		END AS  OT,

		et.Abbreviation as Abbreviation,jc.SubmitDate as SubDate,jc.InTime as InTime,jc.OutTime as OutTime,jc.Shift,u.TeamNames As TeamName,
		CASE 
		     

			 WHEN   CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))  = 0 THEN '00:00'

             WHEN  CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60 >= 0
			       and  
				    CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60<=24
				  
				  THEN  CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +0)/60 as varchar(200))+':'+ 
					   CASE 
					   WHEN (((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +0)
					   -((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +0)/60)*60<10
					   THEN 
					  '0'+ CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +0)
					   -((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +0)/60)*60 as varchar(200))
					   ELSE
						CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +0)
					   -((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +0)/60)*60 as varchar(200))
					   END
				 
		     WHEN   CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60 >= 25
			       and  
				   CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60<=54
				  
			    THEN  CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +30)/60 as varchar(200))+':'+ 
					   CASE 
					   WHEN (((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +30)
					   -((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +30)/60)*60<10
					   THEN 
					  '0'+ CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +30)
					   -((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +30)/60)*60 as varchar(200))
					   ELSE
						CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +30)
					   -((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +30)/60)*60 as varchar(200))
					   END

			 WHEN   CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60 >= 55
			       and  
				    CAST((CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as decimal(18,2))/CAST(60 as decimal(18,2))) as decimal(18,2))%60<=60
				  
				 THEN  CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +60)/60 as varchar(200))+':'+ 
					   CASE 
					   WHEN (((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +60)
					   -((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +60)/60)*60<10
					   THEN 
					  '0'+ CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +60)
					   -((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +60)/60)*60 as varchar(200))
					   ELSE
						CAST((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +60)
					   -((((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime ))/3600)*60 +60)/60)*60 as varchar(200))
					   END
			

             ELSE '00:00'
             END AS RoundedOverTime,

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
             END AS RoundedOT

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
		jc.OutTime,jc.Shift,u.TeamNames
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
	


		Select Date,SUM(TotalImages) as Images,t.WorkHour,CAST(CAST(WorkHour as decimal(18,2)) /( CASE WHEN SUM(TotalImages)=0 
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
		
		Select  distinct ta.Date,t.Name,ta.Images as Images, t.WH,t.WorkHour,FORMAT (t.InTime, 'MM-dd-yy hh:mm tt') AS InTime,FORMAT (t.OutTime, 'MM-dd-yy hh:mm tt') AS OutTime,t.OverTime,t.OT, ta.Task,ta.TPI,t.Shift,t.TeamName,t.Images as OtherTeams,t.RoundedOverTime ,t.RoundedOT
		INTO #RETURNVALUE From #TempOtherImages t INNER JOIN #TASK ta ON t.Date=ta.Date   order by ta.Date DESC

	
			
	   
		SELECT Distinct CONVERT(varchar, jc.SubmitDate, 5) As Date,u.FullName AS Name,jt.NumberOfImages as TotalImages,CAST(CAST(DATEDIFF(MINUTE, jc.InTime, jc.OutTime) as decimal(18,2))/CAST(60 as decimal(18,2)) as decimal(18,2) )  as WH,(DATEDIFF(MINUTE, jc.InTime, jc.OutTime)) as WorkHour,
		DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] )/3600 as OverTime,
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
		Declare @CPI as decimal(18,2)
		Declare @CPIWithoutQC as decimal(18,2)
		Declare @TimeRequiredPerImage as decimal(18,2)
		--SET @TimeRequiredPerImage =CAST(( @TotalWorkHour*60/CAST(@TotalImagesWithOT as decimal(18,2))) as decimal(18,2))
	    Declare @TotalTimeRequiredPerImage  as decimal(18,2)
		Declare @TotalRoundedOvertime  as varchar(200)
		Declare @TotalRoundedHour as bigint 
		Declare @TotalRoundedMin as bigint

		declare @TotalHour as bigint
		declare @TotalMin as bigint
		declare @TotalOvertimeHour as bigint
		declare @TotalOvertimeMin as bigint

		Declare @TotalHourPerImage as decimal(18,2)
		

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
		SET @OptimumCapacityPerHourWithoutQC =CAST(( @TotalImageWithoutQC/CAST(@TotalDayWithOT*8.0 as decimal(18,2))) as decimal(18,2) )

		
		SET @TotalOvertime = (SELECT SUM(OverTime) FROM #RETURNVALUE)

		SET @TotalHourPerImage = (Select CAST(SUM(WorkHour)/CAST(60 as decimal(18,2)) as decimal(18,2)) FROM #RETURNVALUE)
		SET @TimeRequiredPerImage =CAST(( @TotalHourPerImage/CAST(@TotalImagesWithOT as decimal(18,2))) as decimal(18,2))


		Set @TotalHour=(SELECT SUM(WorkHour)/3600 FROM #RETURNVALUE) 
		Set @TotalMin=(Select (SUM(WorkHour)%3600)/60   From #RETURNVALUE)
	
		Set @TotalWorkHour = CAST(@TotalHour as varchar(100))+':'+ CAST(@TotalMin as varchar(100))
		Set @TotalOvertimeMin=(Select SUM(OverTime)%3600/60   From #RETURNVALUE)
		Set @TotalOvertimeHour =(Select SUM(OverTime)/3600 From #RETURNVALUE)
		Set @TotalOvertime=CAST(@TotalOvertimeHour as varchar(100))+':'+ CAST(@TotalOvertimeMin as varchar(100))
		

		SET @TotalRoundedHour=(SELECT SUM(RoundedOT)/60 FROM #RETURNVALUE)
		SET @TotalRoundedMin = (SELECT SUM(RoundedOT) FROM #RETURNVALUE)-@TotalRoundedHour*60
		
		SET @TotalRoundedOvertime = CAST(@TotalRoundedHour as varchar(200))+':'+CAST(@TotalRoundedMin as varchar(200))
	    

		SET @CPI=  (Select CAST(CAST(SUM(p.TotalImages*p.CPIDaily) as decimal(16,2))/CAST(SUM(p.TotalImages) as decimal(16,2)) as decimal(16,2)) 
		From PerformanceEvaluations p 
		left join AspNetUsers u ON p.UserId = u.Id
		Where u.UserName =@ResourceId and
		Date>=@FromDate and Date<=@ToDate )


		SET @CPIWithoutQC =(Select CAST(CAST(SUM((p.TotalImages-p.QC)*p.CPIDaily) as decimal(16,2))/CAST(SUM(p.TotalImages) as decimal(16,2)) as decimal(16,2)) 
		From PerformanceEvaluations p 
		left join AspNetUsers u ON p.UserId = u.Id
		Where u.UserName =@ResourceId and
		Date>=@FromDate and Date<=@ToDate )




		SELECT CAST(null as varchar(8000)) AS ColumnName,CAST(null as varchar(8000)) AS ColumnValue into #RightTempTable
        delete from #RightTempTable
	
	    Insert Into #RightTempTable(ColumnName,ColumnValue) Values('Total Images',CAST(@TotalImagesWithOT as varchar(100))),('Minimum Images',CAST(@MinImageWithouOT as varchar(100))),
		('Maximum Images',CAST(@MaxImageWithouOT as varchar(100))),('OPTC Per day',CAST(@OptimumCapacityPerDay as varchar(100))),('OPTC Per hour',CAST(@OptimumCapacityPerHour as varchar(100))),('Cost Per Image',CAST(@CPI as varchar(100)))

		SELECT CAST(null as varchar(8000)) AS ColumnName,CAST(null as varchar(8000)) AS ColumnValue into #RightDownTempTable
        Delete from #RightDownTempTable
	
	    Insert Into #RightDownTempTable(ColumnName,ColumnValue) Values('Total Images (without QC)',CAST(@TotalImageWithoutQC as varchar(100))),('Minimum Images (without QC)',CAST(@MinImageWithoutQC as varchar(100))),
		('Maximum Images (without QC)',CAST(@MaxImageWithoutQC as varchar(100))),('OPTC Per day (without QC)',CAST(@OptimumCapacityPerDayWithoutQC as varchar(100))),('OPTC Per hour (without QC)',CAST(@OptimumCapacityPerHourWithoutQC as varchar(100))),
		('Cost Per Image (without QC)',CAST(@CPIWithoutQC as varchar(100)))
	          SELECT CAST(null as varchar(8000)) AS ColumnName,CAST(null as varchar(8000)) AS ColumnValue into #TableFooter
        Delete from #TableFooter
	
	    Insert Into #TableFooter(ColumnName,ColumnValue) Values('Total Number of images',CAST(@TotalImagesWithOT as varchar(200))),
		('Total Work Hour',@TotalWorkHour),('Time Required per Image',CAST(@TimeRequiredPerImage as varchar(200))),('Total Overtime',@TotalOvertime),('Total Rounded Overtime',@TotalRoundedOvertime)
		
		

			SELECT CAST(null as varchar(8000)) AS ColumnName into #TableHeader
			Delete from #TableHeader
	
			Insert Into #TableHeader(ColumnName)
			Values('Date'),('Name'),('Task'),('Images'),('W.H.'),('T.P.I.'),('O.T.'),('Rounded O.T'),('InTime'),('OutTime'),('Shift'),('Other Teams')

			SELECT * from  #RightTempTable
		    SELECT * From  #RightDownTempTable
			SELECT * FROM #TableHeader
			SELECT Date,Name,Task,Images,WH ,TPI,OT ,RoundedOverTime,InTime,OutTime,Shift,OtherTeams FROM #RETURNVALUE Order by Date DESC
		    SELECT * from  #TableFooter


		  DROP TABLE #ImageWithoutQC
		  DROP TABLE #RETURNVALUE
		  DROP Table #WithOutQC
		  DROP TABLE #TEMPROOTTABLE
		  DROP Table #TASK
		  DROP Table #OtherImages
		  DROP Table #TempOtherImages
		  DROP TABLE #RightTempTable
		  DROP Table #RightDownTempTable
		  DROP Table #TableFooter
		  DROP Table #TableHeader


	  END TRY
	  BEGIN CATCH


	  END CATCH
END

