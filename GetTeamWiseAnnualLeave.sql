IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetTeamWiseAnnualLeave')
DROP PROCEDURE GetTeamWiseAnnualLeave

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go


CREATE PROCEDURE [dbo].[GetTeamWiseAnnualLeave](
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
		where (TeamNames LIKE  '%'+@team+',%'  OR TeamNames  LIKE '%'+@team)  
		and Designation!='2' AND  Designation!='5' AND Designation!='6'  and (Status='Active' OR Status='EmailNotConfirmed')
		
		

	    SELECT u.UserName,U.FullName INTO #Attendance
		From  LeaveApplications la
		Left Join
		AspNetUsers u
		ON la.UserId = u.Id Where la.Status != 'Rejected' and la.Status != 'Pending' and la.Status != 'Cancelled' and @FromDate between la.StartDate And la.EndDate and 
		la.LeaveType='Annual Leave' 
		and (u.TeamNames LIKE  '%'+@team+',%'  OR u.TeamNames  LIKE '%'+@team)  
		and u.Designation!='2' AND  u.Designation!='5' AND u.Designation!='6'  and (u.Status='Active' OR u.Status='EmailNotConfirmed')

		SELECT UserName Into #User From #Attendance
		Select UserName INTO #Absent from #TeamUserName t where t.UserName  In (Select * From #User)

	    SELECT UserName,FullName FROM AspNetUsers where UserName IN (Select * From #Absent)




	  END TRY
	  BEGIN CATCH


	  END CATCH
END

