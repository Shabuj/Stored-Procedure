

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetJCInvestigationReport')
DROP PROCEDURE GetJCInvestigationReport

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go



CREATE PROCEDURE [dbo].[GetJCInvestigationReport](
	@FromDate as Datetime2,
	@ToDate as Datetime2,
	@TeamName as nvarchar(MAX)
)
AS
BEGIN
	
	  BEGIN TRY

	
		SELECT jc.Id,jc.SubmitDate as SubmitDate, CONVERT(varchar, jc.SubmitDate, 5) As Date, u.FullName AS Name,
		et.Abbreviation as Abbreviation,jt.NumberOfImages as Images,CAST((DATEDIFF(SECOND, jc.InTime, jc.OutTime))/3600 as varchar(100))+':'+ 
		CASE 
		WHEN ((DATEDIFF(SECOND, jc.InTime, jc.OutTime))%3600)/60<10
		  THEN '0'+CAST(((DATEDIFF(SECOND, jc.InTime, jc.OutTime))%3600)/60 as varchar(2))
	    ELSE CAST(((DATEDIFF(SECOND, jc.InTime, jc.OutTime))%3600)/60 as varchar(2))

		END AS WorkHour,
		CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))/3600 as varchar(200))+':'+
		CASE
		   WHEN ((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))%3600)/60 <10
		   THEN '0'+CAST(((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))%3600)/60 as varchar(200))
		   ELSE CAST(((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))%3600)/60 as varchar(200))
		END AS  OverTime,
	
		FORMAT (jc.InTime, 'MM-dd-yy hh:mm tt') AS InTime,FORMAT (jc.OutTime, 'MM-dd-yy hh:mm tt') AS OutTime,
		jc.Shift,jc.InvestigatorComment As InvestigatorComment
	    INTO #TempTable
		From JobCards jc
		Left join JobCardTasks jt ON  jc.Id = jt.JobCardId 
		Left Join
		(
		   Select * From EditingTasks 
		) 
		et ON et.Id =jt.EditingTaskId
	    Left join AspNetUsers u ON jc.UserId = u.Id
		Where 
		(u.TeamNames LIKE  '%'+@TeamName+'%' AND u.TeamNames NOT LIKE '%'+@TeamName+'-%')
		AND (jc.InvestigatorId != null OR jc.InvestigatorId != '')
		AND (jc.InvestigatorComment != null OR jc.InvestigatorComment != '')
		AND jc.SubmitDate >=@FromDate and jc.SubmitDate<=@ToDate 
		ORDER BY jc.SubmitDate Desc



		--------------new ----------

		SELECT  jt.JobCardId, jc.SubmitDate as SubmitDate,CONVERT(varchar, jc.SubmitDate, 5) As Date, u.FullName AS Name,
		SUM(jt.NumberOfImages) as Images,CAST((DATEDIFF(SECOND, jc.InTime, jc.OutTime))/3600 as varchar(100))+':'+ 
		CASE 
		WHEN ((DATEDIFF(SECOND, jc.InTime, jc.OutTime))%3600)/60<10
		  THEN '0'+CAST(((DATEDIFF(SECOND, jc.InTime, jc.OutTime))%3600)/60 as varchar(2))
	    ELSE CAST(((DATEDIFF(SECOND, jc.InTime, jc.OutTime))%3600)/60 as varchar(2))

		END AS WorkHour,
		CAST((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))/3600 as varchar(200))+':'+
		CASE
		   WHEN ((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))%3600)/60 <10
		   THEN '0'+CAST(((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))%3600)/60 as varchar(200))
		   ELSE CAST(((DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime] ))%3600)/60 as varchar(200))
		END AS  OverTime,
	
		FORMAT (jc.InTime, 'MM-dd-yy hh:mm tt') AS InTime,FORMAT (jc.OutTime, 'MM-dd-yy hh:mm tt') AS OutTime,
		jc.Shift,jc.InvestigatorComment As InvestigatorComment,
	     STUFF((
			SELECT ', ' + c.Abbreviation+ '(' + CAST(Images AS VARCHAR(MAX)) +')'
			FROM #TempTable c where Id= jt.JobCardId
			FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)') ,1,2,'') AS Task

		INTO #TASK
		From JobCards jc
		Left join JobCardTasks jt ON  jc.Id = jt.JobCardId 
		Left Join
		(
		   Select * From EditingTasks 
		) 
		et ON et.Id =jt.EditingTaskId
	    Left join AspNetUsers u ON jc.UserId = u.Id
		Where 
		(u.TeamNames LIKE  '%'+@TeamName+'%' AND u.TeamNames NOT LIKE '%'+@TeamName+'-%')
		AND (jc.InvestigatorId != null OR jc.InvestigatorId != '')
		AND (jc.InvestigatorComment != null OR jc.InvestigatorComment != '')
		AND jc.SubmitDate >=@FromDate and jc.SubmitDate<=@ToDate 
		group by  jt.JobCardId,jc.SubmitDate,u.FullName,jc.InTime, jc.OutTime,jc.OverTime,jc.Shift,jc.InvestigatorComment
		



		SELECT CAST(null as varchar(8000)) AS ColumnName into #TableHeader
		delete from #TableHeader
	
		Insert Into #TableHeader(ColumnName)
		Values('Date'),('Name'),('Task'),('Images'),('W.H.'),('O.T.'),('In Time'),('Out Time'),('Shift'),('Comment')

		
	    	
        SELECT * FROM  #TableHeader

	    SELECT Date, Name,Task, Images, WorkHour, OverTime, InTime, OutTime, Shift, InvestigatorComment 
		FROM  #TASK 
	    ORDER BY SubmitDate DESC
  

		DROP TABLE #TempTable
		DROP TABLE #TableHeader
		DROP TABLE #TASK

	  END TRY
	  BEGIN CATCH


	  END CATCH
END



