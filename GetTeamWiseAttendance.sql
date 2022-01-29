

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetTeamWiseAttendance')
DROP PROCEDURE GetTeamWiseAttendance

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE [dbo].[GetTeamWiseAttendance](
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


				-----------------------------Team Members---

		select CAST(null as varchar(8000)) AS TeamName,CAST(null as int) AS TeamMemberCount
	    into #TeamMemberCountTable
        delete from #TeamMemberCountTable


		DECLARE curBindData  cursor for 
	    SELECT TeamName FROM #TEAMCOUNT 
		OPEN curBindData FETCH NEXT FROM curBindData INTO @team
		WHILE @@FETCH_STATUS =0
		BEGIN

		Insert Into #TeamMemberCountTable(TeamName,TeamMemberCount)
		Select @team,Count(*)
		From 
		AspNetUsers 
		where 
		
		(TeamNames LIKE  '%'+@team+',%'  OR TeamNames  LIKE '%'+@team) 
		and Designation!='2' And Designation!='5'  And Designation!='6' and (Status='Active' OR Status='EmailNotConfirmed')
		
		FETCH NEXT FROM curBindData INTO @team
		END
		CLOSE curBindData
		DEALLOCATE curBindData



		
	    DECLARE curBindData  cursor for 
	    SELECT TeamName,TeamMemberCount FROM #TeamMemberCountTable 
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
		where j.SubmitDate between @FromDate and @ToDate and (u.TeamNames LIKE  '%'+@team+',%'  OR u.TeamNames  LIKE '%'+@team) 
		and u.Designation!='2' AND  u.Designation!='5' AND u.Designation!='6'  and (u.Status='Active' OR u.Status='EmailNotConfirmed')
		
		FETCH NEXT FROM curBindData INTO @team,@TotalTeamMembers
		END
		CLOSE curBindData
		DEALLOCATE curBindData


		select CAST(null as varchar(8000)) AS TeamName,CAST(null as int) AS SickLeave
	    into #SickLeaveTable
        delete from #SickLeaveTable

		select CAST(null as varchar(8000)) AS TeamName,CAST(null as int) AS AnnualLeave
	    into #AnnualLeaveTable
        delete from #AnnualLeaveTable


		
		
	    DECLARE curBindData  cursor for 
	    SELECT TeamName FROM #TEAMCOUNT 
		OPEN curBindData FETCH NEXT FROM curBindData INTO @team
		WHILE @@FETCH_STATUS =0
		BEGIN

		Insert Into #SickLeaveTable(TeamName,SickLeave)
		Select @team,Count(*)

		From  LeaveApplications la
		Left Join
		AspNetUsers u
		ON la.UserId = u.Id Where la.Status != 'Rejected'and la.Status != 'Pending' and la.Status != 'Cancelled'
		and @FromDate between la.StartDate And la.EndDate and la.LeaveType='Sick Leave' 
		and (u.TeamNames LIKE  '%'+@team+',%'  OR u.TeamNames  LIKE '%'+@team)
		and u.Designation!='2' AND  u.Designation!='5' AND u.Designation!='6'  and (u.Status='Active' OR u.Status='EmailNotConfirmed')
		
		FETCH NEXT FROM curBindData INTO @team
		END
		CLOSE curBindData
		DEALLOCATE curBindData


		-----------------------------Annual---
		DECLARE curBindData  cursor for 
	    SELECT TeamName FROM #TEAMCOUNT 
		OPEN curBindData FETCH NEXT FROM curBindData INTO @team
		WHILE @@FETCH_STATUS =0
		BEGIN

		Insert Into #AnnualLeaveTable(TeamName,AnnualLeave)
		Select @team,Count(*)

		From  LeaveApplications la
		Left Join
		AspNetUsers u
		ON la.UserId = u.Id Where la.Status != 'Rejected' and la.Status != 'Pending' and la.Status != 'Cancelled'
		and @FromDate between la.StartDate And la.EndDate and la.LeaveType='Annual Leave'
		and (u.TeamNames LIKE  '%'+@team+',%'  OR u.TeamNames  LIKE '%'+@team) 
		and u.Designation!='2' AND  u.Designation!='5' AND u.Designation!='6'  and (u.Status='Active' OR u.Status='EmailNotConfirmed')
		
		FETCH NEXT FROM curBindData INTO @team
		END
		CLOSE curBindData
		DEALLOCATE curBindData
		---------------------------
		

	

	

		SELECT s.*, a.AnnualLeave INTO #PRELEAVE FROM #SickLeaveTable s inner join #AnnualLeaveTable a ON s.TeamName=a.TeamName


		

		SELECT t.TeamName as TeamName,t.TeamMember as TeamMember, t.Present as Present, t.Absent as Absent,p.SickLeave as SickLeave,p.AnnualLeave as AnnualLeave,
		t.PresentPercentage as PresentPercentage
		FROM #tmpTeamname t inner join #PRELEAVE p ON t.TeamName=p.TeamName order by t.TeamName
		
		 
		
		DROP TABLE #TEAMCOUNT
		Drop Table #tmpTeamname
		DROP Table #TEAMS
		DROP TABLE #PRELEAVE

	  END TRY
	  BEGIN CATCH


	  END CATCH
END

