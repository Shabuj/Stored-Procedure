IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetNoticeByUserId')
DROP PROCEDURE GetNoticeByUserId

GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GetNoticeByUserId](@UserId as nvarchar(max))
AS
BEGIN
	
	BEGIN TRY

		DECLARE @TeamNames NVARCHAR(max)
		DECLARE @RoleId NVARCHAR(max)


		SET @TeamNames = (SELECT TeamNames FROM AspNetUsers AS ANU WHERE Id = @UserId)
		SET @RoleId = (SELECT TOP 1 RoleId FROM AspNetUserRoles WHERE UserId = @UserId)
		

		SELECT Id 
		INTO #TeamIds
		from (SELECT * FROM dbo.SplitString(@TeamNames, ',')) as TNS
		INNER JOIN Teams on TeamName = TNS.Item
		

		SELECT * 
		INTO #FILTERED_DATA
		FROM NoticeSetups
		WHERE EXISTS(SELECT * FROM dbo.SplitString(RoleIdList, ',') WHERE Item = @RoleId) AND 
		(
			(TeamIdList IS NULL OR TeamIdList = '') OR (@TeamNames IS NULL OR @TeamNames = '') OR 
			EXISTS (SELECT * FROM #TeamIds INTERSECT SELECT * FROM dbo.SplitString(TeamIdList, ',')) 
		) AND StartDate <=  GETDATE() AND EndDate >=  GETDATE()


		SELECT GETDATE() AS Date, Id AS [NoticeSetupId],Title As [Title], Description, @UserId AS UserId, 1 AS [IsActive], 0 AS [IsDeleted], 0 AS [IsNotified], 0 AS [IsNoticeSeen], 0 AS [IsUpdated]
		FROM #FILTERED_DATA


		DROP TABLE #TeamIds
		DROP TABLE #FILTERED_DATA

	END TRY
	BEGIN CATCH

	END CATCH

END

GO