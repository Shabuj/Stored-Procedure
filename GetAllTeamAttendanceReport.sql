
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetAllTeamAttendanceReport')
DROP PROCEDURE GetAllTeamAttendanceReport

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go



CREATE PROCEDURE [dbo].[GetAllTeamAttendanceReport](
	@FromDate as Datetime2,
	@ToDate as Datetime2
	
)
AS

BEGIN
	
	  BEGIN TRY
  
       	SELECT TeamName,
		  ((select COUNT(*) from dbo.SplitString(TeamMembers, ',') where item <> '')+ 
		  (select COUNT(*) from dbo.SplitString(TeamLeadIds, ',') where item <> '')) as TotalTeamMember 
		INTO #TEAMCOUNT
		FROM Teams

		
		
	    select CAST(null as varchar(8000)) AS TeamName, CAST(null as varchar(8000)) AS TeamMember,CAST(null as int) AS Present,CAST(null as int) AS [Absent],
		CAST(null as decimal) AS PresentPercentage,CAST(null as decimal) AS AbsentPercentage into #tmpTeamname
        delete from #tmpTeamname


	    Declare @team as varchar(800) 
		Declare @TotalTeamMembers as bigint
		
	    DECLARE curBindData  cursor for 
	    SELECT TeamName,TotalTeamMember FROM #TEAMCOUNT 
		OPEN curBindData FETCH NEXT FROM curBindData INTO @team,@TotalTeamMembers
		WHILE @@FETCH_STATUS =0
		BEGIN

		Insert Into #tmpTeamname(TeamName,TeamMember,Present,Absent,PresentPercentage,AbsentPercentage)
		Select @team,@TotalTeamMembers,Count(*),(@TotalTeamMembers-Count(*)),
		CASE
			WHEN @TotalTeamMembers<=0 THEN CEILING((CAST(Count(*) as decimal)/1)*100)
			ELSE ((CAST(Count(*) as decimal)/@TotalTeamMembers)*100)
		END,
		CASE 
			WHEN @TotalTeamMembers<=0 THEN FLOOR((100-((CAST(Count(*) as decimal)/1)*100)))
			ELSE ((100-((CAST(Count(*) as decimal)/@TotalTeamMembers)*100)))
		END

		From  JobCards j
		Left Join AspNetUsers u
		ON j.UserId = u.Id
		where j.SubmitDate between @FromDate and @ToDate and (u.TeamNames LIKE  '%'+@team+',%'  OR u.TeamNames  LIKE '%'+@team)
		
		FETCH NEXT FROM curBindData INTO @team,@TotalTeamMembers
		END
		CLOSE curBindData
		DEALLOCATE curBindData


		SELECT CAST(null as varchar(8000)) AS ColumnName into #TableHeader
        delete from #TableHeader
	
	    Insert Into #TableHeader(ColumnName)
		Values('Team Name'),('Present'),('Absent'),('Present Percentage'),('Absent Percentage')


		SELECT TeamName,CAST(Present as varchar) as Present,CAST(Absent AS varchar) as Absent,
		    CAST(PresentPercentage as varchar)+'%' as [Present Percentage],
			CAST(AbsentPercentage AS varchar)+'%' as [Absent Percentage] INTO #TABLEBODY  FROM #tmpTeamname 

		
		SELECT * FROM #TableHeader
		SELECT * FROM #TABLEBODY
		Select TeamName,Present,Absent,PresentPercentage,AbsentPercentage FROM #tmpTeamname
		 
		
		DROP TABLE #TEAMCOUNT
		Drop Table #tmpTeamname
		DROP TABLE #TableHeader
		DROP TABLE  #TABLEBODY
		

	  END TRY
	  BEGIN CATCH


	  END CATCH
END

