IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetAllResourceOTSummeryReport')
DROP PROCEDURE GetAllResourceOTSummeryReport

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go





CREATE PROCEDURE [dbo].[GetAllResourceOTSummeryReport](
	@FromDate as Datetime2,
	@ToDate as Datetime2
	
)
AS
BEGIN
	
	  BEGIN TRY

	  	    Declare @Teams as varchar(8000)='DSG,Video Production,RBC,PSP,JBL,LOD,JOD-T,ABS-2,LIF,SOS,ATS,SIX,MLS,ABS-1,SOD,AMS,FOUR/KLM,ABS,JOD,MAC,GNR,GLS,NFC'
 

		SELECT *
			INTO #TEAMS
			FROM dbo.SplitString(@Teams, ',')
	    
		SELECT u.Id,u.UserName,u.FullName,u.TeamNames as Team,(DATEDIFF(SECOND, jc.InTime, jc.OutTime)) as WorkHour,
		(DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE,jc.OverTime) + 3600 * DATEPART(HOUR, jc.OverTime )) as OverTime,

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

		into #USER_WISE_TOTAL
		From JobCards jc
		Left join AspNetUsers u ON jc.UserId = u.Id
		Where 
		jc.SubmitDate>=@FromDate and jc.SubmitDate<=@ToDate Group by u.Id,u.UserName,u.FullName,u.TeamNames ,jc.OverTime,jc.SubmitDate,jc.InTime,
		jc.OutTime
	  

					

	    Select Id as Id,UserName ,FullName as Name,Team,SUM(RoundedOT)  as ROT,SUM(WorkHour) as WH ,SUM(OverTime) as OT,
		CAST(CAST(SUM(WorkHour)/3600 as bigint) as varchar(100))+':'+ 
		CASE 
		WHEN (SUM(WorkHour)/60-(CAST(SUM(WorkHour)/3600 as bigint))*60)<10
		THEN '0'+ CAST(CAST(SUM(WorkHour)/60-(CAST(SUM(WorkHour)/3600 as bigint))*60 as int) as varchar(2))
		ELSE CAST(CAST(SUM(WorkHour)/60-(CAST(SUM(WorkHour)/3600 as bigint))*60 as int) as varchar(2))
		END AS WorkHour,

		CAST(CAST(SUM(OverTime)/3600 as bigint) as varchar(100))+':'+ 
		CASE 
		WHEN (SUM(OverTime)/60-(CAST(SUM(OverTime)/3600 as bigint))*60)<10
		THEN '0'+ CAST(CAST(SUM(OverTime)/60-(CAST(SUM(OverTime)/3600 as bigint))*60 as int) as varchar(2))
		ELSE CAST(CAST(SUM(OverTime)/60-(CAST(SUM(OverTime)/3600 as bigint))*60 as int) as varchar(2))
		END AS OverTime,


		CAST(CAST(SUM(RoundedOT)/60 as bigint) as varchar(100))+':'+ 
		CASE 
		WHEN (SUM(RoundedOT)-(CAST(SUM(RoundedOT)/60 as bigint))*60)<10
		THEN '0'+ CAST(CAST(SUM(RoundedOT)-(CAST(SUM(RoundedOT)/60 as bigint))*60 as int) as varchar(2))
		ELSE CAST(CAST(SUM(RoundedOT)-(CAST(SUM(RoundedOT)/60 as bigint))*60 as int) as varchar(2))
		END AS RoundedOverTime

		INTO #USER_WISE_LIST
		FROM #USER_WISE_TOTAL  group by Id,UserName,FullName,Team order by Team,UserName
	
	

		 
		Declare @TotalRoundedOvertime  as varchar(200)
		Declare @TotalWorkHour as varchar(100)
		Declare @TotalOvertime as varchar(100)

		Declare @TotalRoundedHour as bigint 
		Declare @TotalRoundedMin as bigint
	   
		declare @TotalHour as bigint
		declare @TotalMin as bigint

		declare @TotalOvertimeHour as bigint
		declare @TotalOvertimeMin as bigint

		


		Set @TotalHour=(SELECT SUM(WH)/3600 FROM #USER_WISE_LIST)
		Set @TotalMin=(Select (SUM(WH)%3600)/60   From #USER_WISE_LIST)
		Set @TotalWorkHour = CAST(@TotalHour as varchar(100))+':'+
		                           CASE
									WHEN @TotalMin<10
									THEN 
									'0'+CAST(@TotalMin as varchar(100))
									ELSE
									CAST(@TotalMin as varchar(100))
									END 
		
		

		Set @TotalOvertimeMin=(Select SUM(OT)%3600/60   From #USER_WISE_LIST)
		Set @TotalOvertimeHour =(SELECT SUM(OT)/3600 FROM #USER_WISE_LIST)
		Set @TotalOvertime=CAST(@TotalOvertimeHour as varchar(100))+':'+ 
		                           CASE
									WHEN @TotalOvertimeMin<10
									THEN 
									'0'+CAST(@TotalOvertimeMin as varchar(100))
									ELSE
									CAST(@TotalOvertimeMin as varchar(100))
									END 

		SET @TotalRoundedHour=(SELECT SUM(ROT)/60 FROM #USER_WISE_LIST)
		SET @TotalRoundedMin = (SELECT SUM(ROT) FROM #USER_WISE_LIST)-@TotalRoundedHour*60
		SET @TotalRoundedOvertime = CAST(@TotalRoundedHour as varchar(200))+':'+
									CASE
									WHEN @TotalRoundedMin<10
									THEN 
									'0'+CAST(@TotalRoundedMin as varchar(200))
									ELSE
									CAST(@TotalRoundedMin as varchar(200))
									END
	
	    


		
        select CAST(null as varchar(8000)) AS ColumnName,CAST(null as varchar(8000)) AS ColumnValue into #FooterTempTable
        delete from #FooterTempTable
	
	    Insert Into #FooterTempTable(ColumnName,ColumnValue) Values('Total Work Hour',CAST(@TotalWorkHour as varchar(100))),
		('Total Overtime',CAST(@TotalOvertime as varchar(100))),('Total Rounded Overtime',CAST(@TotalRoundedOvertime  as varchar(100)))

		select CAST(null as varchar(8000)) AS ColumnName into #HeaderTempTable
        delete from #HeaderTempTable
	
	    Insert Into #HeaderTempTable(ColumnName) Values('Team Name'),
		('Work Hour'),('Overtime'),('Rounded Overtime')

		------------------------------polish start--------------------------

		SELECT Id,UserName,FullName,
		CASE 
			WHEN (Team IS NOT NULL AND Team <> '' )
					THEN  (
						SELECT TOP 1 * 
						FROM dbo.SplitString(Team, ',') 
						where Item <> ''
					)
			ELSE Team
		END AS Team,
		WorkHour,OverTime,RoundedOT 
		INTO #USER_WISE_TOTAL_FIRST_TEAM
		FROM #USER_WISE_TOTAL 


		--------------------------polish end-------------------------


		--------------------------------start-------------------------------------
		Select Team,CAST(CAST(SUM(WorkHour)/3600 as bigint) as varchar(100))+':'+ 
		CASE 
		WHEN (SUM(WorkHour)/60-(CAST(SUM(WorkHour)/3600 as bigint))*60)<10
		THEN '0'+ CAST(CAST(SUM(WorkHour)/60-(CAST(SUM(WorkHour)/3600 as bigint))*60 as int) as varchar(2))
		ELSE CAST(CAST(SUM(WorkHour)/60-(CAST(SUM(WorkHour)/3600 as bigint))*60 as int) as varchar(2))
		END AS WorkHour,

		CAST(CAST(SUM(OverTime)/3600 as bigint) as varchar(100))+':'+ 
		CASE 
		WHEN (SUM(OverTime)/60-(CAST(SUM(OverTime)/3600 as bigint))*60)<10
		THEN '0'+ CAST(CAST(SUM(OverTime)/60-(CAST(SUM(OverTime)/3600 as bigint))*60 as int) as varchar(2))
		ELSE CAST(CAST(SUM(OverTime)/60-(CAST(SUM(OverTime)/3600 as bigint))*60 as int) as varchar(2))
		END AS OverTime,


		CAST(CAST(SUM(RoundedOT)/60 as bigint) as varchar(100))+':'+ 
		CASE 
		WHEN (SUM(RoundedOT)-(CAST(SUM(RoundedOT)/60 as bigint))*60)<10
		THEN '0'+ CAST(CAST(SUM(RoundedOT)-(CAST(SUM(RoundedOT)/60 as bigint))*60 as int) as varchar(2))
		ELSE CAST(CAST(SUM(RoundedOT)-(CAST(SUM(RoundedOT)/60 as bigint))*60 as int) as varchar(2))
		END AS RoundedOverTime
		INTO #TableBody
		FROM #USER_WISE_TOTAL_FIRST_TEAM  group by Team having Team in(SELECT * FROM #TEAMS) OR Team =' ' order by Team
		-----------------------------end-----------------------------


		SELECT * From #HeaderTempTable
		SELECT * From #TableBody order by Team
        Select * From #FooterTempTable

    
		
		DROP Table #TEAMS
		DROP TABLE #FooterTempTable
		DROP TABLE #USER_WISE_TOTAL
		DROP TABLE #USER_WISE_LIST
		DROP Table #HeaderTempTable
		DROP Table #TableBody
		DROP Table #USER_WISE_TOTAL_FIRST_TEAM

	  END TRY
	  BEGIN CATCH


	  END CATCH
END
