IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetRoleBasedAbsentForDifferentShift')
DROP PROCEDURE GetRoleBasedAbsentForDifferentShift

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go



CREATE PROCEDURE [dbo].[GetRoleBasedAbsentForDifferentShift](
	@FromDate as Datetime2,
	@ToDate as Datetime2,
    @Team as nvarchar(MAX),
	@Role as nvarchar(MAX),
	@Shift as nvarchar(MAX)
)
AS

BEGIN
	
	  BEGIN TRY
  

		Select UserName INTO #TeamUserName
		From 
		AspNetUsers 
		where (TeamNames LIKE  '%'+@team+',%'  OR TeamNames  LIKE '%'+@team)
		and Designation=@Role and (EmploymentStatus='Probation' OR EmploymentStatus='Permanent') and  WorkShift=@Shift



	    SELECT u.UserName,U.FullName INTO #Attendance
		From  EmployeeAttendances j
		Left Join AspNetUsers u
		ON j.UserId = u.Id
		where j.SubmitDate between @FromDate and @ToDate and (u.TeamNames  LIKE  '%'+@Team+',%'  OR u.TeamNames  LIKE '%'+@Team) and u.Designation=@Role
		and (EmploymentStatus='Probation' OR EmploymentStatus='Permanent') and  u.WorkShift=@Shift


		SELECT UserName Into #User From #Attendance
		Select UserName INTO #Absent from #TeamUserName t where t.UserName Not In (Select * From #User)

	    SELECT UserName,FullName FROM AspNetUsers where UserName IN (Select * From #Absent)




	  END TRY
	  BEGIN CATCH


	  END CATCH
END

