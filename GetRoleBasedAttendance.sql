IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetRoleBasedAttendance')
DROP PROCEDURE GetRoleBasedAttendance

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go



CREATE PROCEDURE [dbo].[GetRoleBasedAttendance](
	@FromDate as Datetime2,
	@ToDate as Datetime2,
    @Teams as nvarchar(MAX),
	@Role as nvarchar(MAX)
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

		
		
	    select CAST(null as varchar(8000)) AS UserName, CAST(null as varchar(8000)) AS Name,CAST(null as varchar(8000)) AS Status,CAST(null as varchar(8000)) AS TeamName
		into #Present
        delete from #Present


		select CAST(null as varchar(8000)) AS UserName, CAST(null as varchar(8000)) AS Name,CAST(null as varchar(8000)) AS Status,CAST(null as varchar(8000)) AS TeamName
		into #Absent
        delete from #Absent

	    Declare @team as varchar(800) 
		


	    DECLARE curBindData  cursor for 
	    SELECT TeamName FROM #TEAMCOUNT 
		OPEN curBindData FETCH NEXT FROM curBindData INTO @team
		WHILE @@FETCH_STATUS =0
		BEGIN

		Insert Into #Present(UserName,Name,Status,TeamName)
		Select u.UserName,u.FullName , 'Present' as Present , u.TeamNames
	    From  EmployeeAttendances j
		Left Join AspNetUsers u
		ON j.UserId = u.Id
		where j.SubmitDate between @FromDate and @ToDate  and  u.Designation=@Role and (u.TeamNames LIKE  '%'+@team+',%'  OR u.TeamNames  LIKE '%'+@team) 
		and (u.Status='Active' OR u.Status='EmailNotConfirmed')
		
		FETCH NEXT FROM curBindData INTO @team
		END
		CLOSE curBindData
		DEALLOCATE curBindData



		DECLARE curBindData  cursor for 
	    SELECT TeamName FROM #TEAMCOUNT 
		OPEN curBindData FETCH NEXT FROM curBindData INTO @team
		WHILE @@FETCH_STATUS =0
		BEGIN

		Insert Into #Absent(UserName,Name,Status,TeamName)
		
		Select u.UserName,u.FullName ,'Absent' as Absent ,u.TeamNames
	    From   AspNetUsers u
		where   u.Designation=@Role and (u.TeamNames LIKE  '%'+@team+',%'  OR u.TeamNames  LIKE '%'+@team) 
		and (u.Status='Active' OR u.Status='EmailNotConfirmed') and u.UserName Not In (Select UserName From #Present)
		
		FETCH NEXT FROM curBindData INTO @team
		END
		CLOSE curBindData
		DEALLOCATE curBindData


		
		(Select * from #Present ) UNION (Select * from #Absent )
		
		DROP TABLE #Present
		Drop Table #Absent
		DROP Table #TEAMS
	
		

	  END TRY
	  BEGIN CATCH


	  END CATCH
END

