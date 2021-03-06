
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetProjectWiseDetailsReport')
DROP PROCEDURE GetProjectWiseDetailsReport

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go




CREATE PROCEDURE [dbo].[GetProjectWiseDetailsReport](
	@FromDate as Datetime2,
	@ToDate as Datetime2,
	@TeamName as nvarchar(MAX)
)
AS
BEGIN
	
	  BEGIN TRY

		Select Id,FullName as [Name] , Designation as Designation,
		CASE WHEN Designation = 1 THEN 'SuperAdmin'
             WHEN Designation = 2 THEN 'Admin'
			 WHEN Designation = 3 THEN 'ClientAdmin'
			 WHEN Designation = 4 THEN 'ClientUser'
			 WHEN Designation = 5 THEN 'KeyPerson'
			 WHEN Designation = 6 THEN 'QC'
			 WHEN Designation = 7 THEN 'User'
			 WHEN Designation = 8 THEN 'HR'
			 WHEN Designation = 9 THEN 'Shop'
			
             ELSE ''
             END AS UserDesignation,
		     WorkShift into #TempAspNetUsers  From AspNetUsers 

	   
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

	
		
	    SELECT jc.UserId As UserId,CAST(SUM(DATEDIFF(MINUTE, jc.InTime, jc.OutTime))/60 as varchar(20))+':'+
		CASE 
		 WHEN (SUM(DATEDIFF(SECOND, jc.InTime, jc.OutTime))%3600)/60<10
		   THEN 
		   '0'+CAST((SUM(DATEDIFF(SECOND, jc.InTime, jc.OutTime))%3600)/60 as varchar(20))
		   ELSE
		   CAST((SUM(DATEDIFF(SECOND, jc.InTime, jc.OutTime))%3600)/60 as varchar(20))
		   END AS WorkHour,
		CAST(SUM(DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime]))/3600 as varchar(200))+':'+
		CASE 
		 WHEN (SUM(DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime]))%3600)/60<10
		   THEN 
		   '0'+CAST((SUM(DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime]))%3600)/60 as varchar(200))
		   ELSE
		   CAST((SUM(DATEPART(SECOND, jc.OverTime) + 60 * DATEPART(MINUTE, [OverTime]) + 3600 * DATEPART(HOUR, [OverTime]))%3600)/60 as varchar(200))
		 END AS OverTime,

		SUM(ActiveHour) as ActiveHour ,SUM(ActualActiveHour) as ActualActiveHour
		INTO #TEMP_HOUR_CALC
		From JobCards jc
		Left join AspNetUsers u ON jc.UserId = u.Id
		Where 
		(u.UserName IN (SELECT * FROM #TEAMMEMBER) OR u.UserName IN (SELECT * FROM #TEAMLEAD)) and
		jc.SubmitDate>=@FromDate and jc.SubmitDate<=@ToDate 
		group by jc.UserId




        SELECT jc.UserId As UserId,SUM(jt.NumberOfImages) as TotalImages
		INTO #OWN_TOTAL_IMAGES
		From JobCards jc
		Left join AspNetUsers u ON jc.UserId = u.Id
		Left join JobCardTasks jt ON jt.JobCardId  = jc.Id
		Where 
		(u.UserName IN (SELECT * FROM #TEAMMEMBER) OR u.UserName IN (SELECT * FROM #TEAMLEAD)) and
		jc.SubmitDate>=@FromDate and jc.SubmitDate<=@ToDate 
		group by jc.UserId


		SELECT u.*,o.TotalImages INTO #TEMP_OWN_TOTAL_IMAGES FROM #OWN_TOTAL_IMAGES o Left join #TempAspNetUsers u on o.UserId=u.Id


		SELECT u.*,o.* INTO #TEMPROOTTABLE FROM #TEMP_HOUR_CALC o Left join #TEMP_OWN_TOTAL_IMAGES u on o.UserId=u.Id




		SELECT jc.UserId As UserId,SUM(jt.NumberOfImages) OtherTeamImages
		INTO #OtherTeamImage
		From JobCards jc
		Left join AspNetUsers u ON jc.UserId = u.Id
		Left join JobCardTasks jt ON jt.JobCardId  = jc.Id
		Where 
		(u.UserName IN (SELECT * FROM #TEAMMEMBER) OR u.UserName IN (SELECT * FROM #TEAMLEAD)) and
		jc.SubmitDate>=@FromDate and jc.SubmitDate<=@ToDate and jt.TeamName!=@TeamName
		group by jc.UserId



        
		SELECT u.*,c.OtherTeamImages INTO #TEMP_OTHER_IMAGES FROM #OtherTeamImage c Left join #TempAspNetUsers u on c.UserId=u.Id

		
		
		Select  p.UserId,CAST(CAST(SUM(p.TotalImages*p.CPIDaily) as decimal(16,2))/CAST(SUM(p.TotalImages) as decimal(16,2)) as decimal(16,2)) as CPI
		INTO #TEMPCPI
		From PerformanceEvaluations p 
		left join AspNetUsers u ON p.UserId = u.Id
		Where (u.UserName IN (SELECT * FROM #TEAMMEMBER) OR u.UserName IN (SELECT * FROM #TEAMLEAD)) and
		Date>=@FromDate and Date<=@ToDate 
		group by p.UserId order by CPI asc


		SELECT u.*,c.CPI INTO #TEMPUSERCPI FROM #TEMPCPI c Left join #TempAspNetUsers u on c.UserId=u.Id


	
	
		SELECT  u.Id,u.Name as [Name],u.UserDesignation as Designation,t.TotalImages as Images, t.WorkHour,t.OverTime,u.WorkShift,u.CPI as CPI,t.ActiveHour,t.ActualActiveHour 
		INTO #TEAM_CPI FROM #TEMPROOTTABLE t INNER JOIN #TEMPUSERCPI  u ON t.UserId=u.Id order by t.TotalImages DESC

		SELECT  r.Id,r.Name as [Name],r.Designation as Designation,r.Images as Images, r.WorkHour,r.OverTime,r.WorkShift,r.CPI as CPI,r.ActiveHour,r.ActualActiveHour,t.OtherTeamImages
		INTO #RETURNVALUE FROM #TEAM_CPI r INNER JOIN #TEMP_OTHER_IMAGES t ON r.Id=t.Id

	   
		SELECT CAST(null as varchar(8000)) AS ColumnName into #TableHeader
        delete from #TableHeader
	
	    Insert Into #TableHeader(ColumnName)
		Values('Name'),('Designation'),('Images'),('Other Teams'),('Work Hour'),('Overtime'),('Work Shift'),('CPI'),('Active Hour'),('Actual Active Hour')

		SELECT * FROM #TableHeader
		SELECT Name, Designation,Images,OtherTeamImages,WorkHour,OverTime,WorkShift,CPI, ActiveHour,ActualActiveHour  FROM #RETURNVALUE  order by Images desc



		DROP TABLE #TempAspNetUsers
		DROP TABLE #RETURNVALUE
		DROP Table #TEAMMEMBER
		DROP Table #TEAMLEAD
		DROP TABLE #TEMPROOTTABLE
		DROP Table #TableHeader
		DROP Table #TEMPCPI
		DROP Table #TEMPUSERCPI
		DROP TABLE #TEMP_HOUR_CALC
		DROP TABLE #OWN_TOTAL_IMAGES

	  END TRY
	  BEGIN CATCH


	  END CATCH
END

