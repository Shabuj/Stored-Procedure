
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetTeamWiseAttendanceForMorningShift')
DROP PROCEDURE GetTeamWiseAttendanceForMorningShift

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE [dbo].[GetTeamWiseAttendanceForMorningShift](
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
    
       	SELECT TeamName,
		  ((select COUNT(*) from dbo.SplitString(TeamMembers, ',') where item <> '')+ 
		  (select COUNT(*) from dbo.SplitString(TeamLeadIds, ',') where item <> '')) as TotalTeamMember 
		INTO #TEAMCOUNT
		FROM Teams WHERE TeamName In (SELECT * FROM #TEAMS)

	   

	    select CAST(null as varchar(8000)) AS TeamName, CAST(null as bigint) AS TeamMember,CAST(null as int) AS Present,CAST(null as int) AS [Absent],
		CAST(null as decimal) AS PresentPercentage,CAST(null as decimal) AS AbsentPercentage into #tmpTeamname
        delete from #tmpTeamname




	    Declare @team as varchar(800) 
		Declare @TotalTeamMembers as bigint
		



		-----------------------------MorningShift Member---

		select CAST(null as varchar(8000)) AS TeamName,CAST(null as int) AS MorningShiftMember
	    into #MorningTable
        delete from #MorningTable


		DECLARE curBindData  cursor for 
	    SELECT TeamName FROM #TEAMCOUNT 
		OPEN curBindData FETCH NEXT FROM curBindData INTO @team
		WHILE @@FETCH_STATUS =0
		BEGIN

		Insert Into #MorningTable(TeamName,MorningShiftMember)
		Select @team,Count(*)
		From 
		AspNetUsers 
		where 
		WorkShift='Morning'   and 
		(TeamNames LIKE  '%'+@team+',%'  OR TeamNames  LIKE '%'+@team)  
		and Designation!='2' AND  Designation!='5' AND Designation!='6'  and (Status='Active' OR Status='EmailNotConfirmed')
		
		FETCH NEXT FROM curBindData INTO @team
		END
		CLOSE curBindData
		DEALLOCATE curBindData

	    DECLARE curBindData  cursor for 
	    SELECT TeamName,MorningShiftMember FROM #MorningTable 
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

		From  EmployeeAttendances j
		Left Join AspNetUsers u
		ON j.UserId = u.Id
		where j.SubmitDate between @FromDate and @ToDate and (u.TeamNames LIKE  '%'+@team+',%'  OR u.TeamNames  LIKE '%'+@team) and u.WorkShift='Morning' 
		and u.Designation!='2' AND  u.Designation!='5' AND u.Designation!='6'  and (u.Status='Active' OR u.Status='EmailNotConfirmed')
		
		FETCH NEXT FROM curBindData INTO @team,@TotalTeamMembers
		END
		CLOSE curBindData
		DEALLOCATE curBindData

		


		SELECT t.TeamName as TeamName,t.TeamMember as TeamMember, t.Present as Present, t.Absent as Absent,t.PresentPercentage as PresentPercentage
		FROM #tmpTeamname t  order by t.TeamName
		
		 
		
		DROP TABLE #TEAMCOUNT
		Drop Table #tmpTeamname
		DROP Table #TEAMS
	
		

	  END TRY
	  BEGIN CATCH


	  END CATCH
END

