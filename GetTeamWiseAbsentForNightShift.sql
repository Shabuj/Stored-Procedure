IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetTeamWiseAbsentForNightShift')
DROP PROCEDURE GetTeamWiseAbsentForNightShift

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE [dbo].[GetTeamWiseAbsentForNightShift](
	@FromDate as Datetime2,
	@ToDate as Datetime2,
    @Team as nvarchar(MAX)
)
AS

BEGIN
	
	  BEGIN TRY
  

		Select UserName INTO #TeamUserName
		From 
		AspNetUsers 
		where 
		WorkShift='Night'   and 
		(TeamNames LIKE  '%'+@team+',%'  OR TeamNames  LIKE '%'+@team)
		and Designation!='2' AND  Designation!='5' AND Designation!='6'  and (Status='Active' OR Status='EmailNotConfirmed')
		
		

	    SELECT u.UserName,U.FullName into  #Attendance
		From  EmployeeAttendances j
		Left Join AspNetUsers u
		ON j.UserId = u.Id
		where j.SubmitDate between @FromDate and @ToDate and (u.TeamNames  LIKE  '%'+@Team+',%'  OR u.TeamNames  LIKE '%'+@Team) and u.WorkShift='Night' 
		and u.Designation!='2' AND  u.Designation!='5' AND u.Designation!='6'  and (u.Status='Active' OR u.Status='EmailNotConfirmed')

		SELECT UserName Into #User From #Attendance
		Select UserName INTO #Absent from #TeamUserName t where t.UserName Not In (Select * From #User)

	    SELECT UserName,FullName FROM AspNetUsers where UserName IN (Select * From #Absent)




	  END TRY
	  BEGIN CATCH


	  END CATCH
END

