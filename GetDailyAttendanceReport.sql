

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetDailyAttendanceReport')
DROP PROCEDURE GetDailyAttendanceReport

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go



CREATE PROCEDURE [dbo].[GetDailyAttendanceReport](
	@FromDate as Datetime2,
	@ToDate as Datetime2
	
)
AS

BEGIN
	
	  BEGIN TRY
  
    
	    Declare @totalEmployees  as bigint
		Declare @totalPresent  as int
		Declare @totalPreLeave  as int
		Declare @totalPostLeave as int
		Declare @totalAbsent as int
		Declare @presentPercentage as decimal(16,2)
		Declare @absentPercentage as decimal(16,2)

		Set @totalEmployees = (Select Count(*) as totalEmployees from AspNetUsers
							  where Status != 'Inactive' and 
									Status != 'Deleted' and 
									(
										Designation ='2' or
										Designation ='5' or
										Designation ='6' or
										Designation ='7' or
										Designation ='8' 
									))

			   
		Set @totalPresent = (Select Count(*) as totalPresent  From JobCards j
							Left Join
							AspNetUsers u
							ON j.UserId = u.Id Where j.SubmitDate between @FromDate And @ToDate)


	

		Set @totalPreLeave= (Select Count(*) as totalPreLeave From LeaveApplications la
		Left Join
		AspNetUsers u
		ON la.UserId = u.Id Where la.Status != 'Rejected' and @FromDate between la.StartDate And la.EndDate)


		

		Set @totalPostLeave = @totalEmployees-(@totalPresent+@totalPreLeave)
		Set @totalAbsent =@totalPreLeave + @totalPostLeave
	
		

		  IF (@totalEmployees <= 0)
			BEGIN
					 Set @presentPercentage =ROUND((CAST(@totalPresent as decimal(16,2))/ CAST(1 as decimal(16,2)))*100.0, 0 )
			END
			ELSE
			BEGIN
		           Set @presentPercentage = ROUND((CAST(@totalPresent as decimal(16,2))/ CAST(@totalEmployees as decimal(16,2)))*100.0, 0)
				   
			END


        
		Set @absentPercentage = (100-@presentPercentage)
	
		
		
	    SELECT CAST(null as varchar(8000)) AS ColumnName,CAST(null as int) AS ColumnValue into #SUMMARY
        delete from #SUMMARY

		Insert Into #SUMMARY(ColumnName,ColumnValue) Values('TotalPresent',@totalPresent),('TotalAbsent',@totalAbsent)
		


		SELECT CAST(null as varchar(8000)) AS ColumnName,CAST(null as varchar(8000)) AS ColumnValue into #RETURNVALUE
        delete from #RETURNVALUE
	
	    Insert Into #RETURNVALUE(ColumnName,ColumnValue) Values('Total Employees',CAST(@totalEmployees as varchar(200) )),('Total Present',CAST(@totalPresent  as varchar(200))),('Total Absent',CAST(@totalAbsent  as varchar(200))),
		('Pre Leave',CAST(@totalPreLeave  as varchar(200))),('Post Leave',CAST(@totalPostLeave  as varchar(200))),('Present Percentage',CAST(CAST(@presentPercentage as bigint) as varchar(200))+'%'),('Absent Percentage',CAST(CAST(@absentPercentage as bigint) as varchar(200))+'%')
		
		Select * from #RETURNVALUE
		SELECT ColumnName,ColumnValue FROM #SUMMARY
		




		DROP TABLE #RETURNVALUE
		DROP TABLE #SUMMARY
		

	  END TRY
	  BEGIN CATCH


	  END CATCH
END

