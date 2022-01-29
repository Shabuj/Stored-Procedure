IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetUserNotificationSettings')
DROP PROCEDURE GetUserNotificationSettings

GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetUserNotificationSettings]
   @MenuID nvarchar(max) = NULL, 
   @UserID nvarchar(max) = NULL 

   --	EXEC GetUserNotificationSettings '1500001, 1500002', '007e0249-dd0b-47e7-9a54-0ba1895c391e, 009ae7ab-639a-458c-b773-438f71ee2e1f, 02429c41-ff61-400c-8971-747e276ee0a2'

AS
SET NOCOUNT ON
BEGIN            
    
    BEGIN TRY        

		SELECT AspNetUsers.Id AS UserId, AspNetUsers.UserName,AspNetRoles.Name AS RoleName into #temp
		FROM AspNetUsers
		LEFT JOIN AspNetUserRoles ON AspNetUsers.Id = AspNetUserRoles.UserId
		LEFT JOIN AspNetRoles ON AspNetUserRoles.RoleId = AspNetRoles.Id

		SELECT RoleName, UserName, CML.MenuName FROM #temp
		CROSS JOIN
		CmnMenuLists as CML 
		
		WHERE 
		CML.MenuId IN (SELECT * FROM dbo.SplitString(@MenuID, ',')) 
		AND UserId IN (SELECT * FROM dbo.SplitString(@UserID, ',')) ;

		DROP TABLE #temp


    END TRY
    BEGIN CATCH -- Error Trapping Section
        DECLARE @ErrorMessage nvarchar(4000);
        DECLARE @ErrorSeverity int;
        DECLARE @ErrorState int;
        
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
        RETURN -1  
    END CATCH

 

    RETURN 0 
END

--GO
--EXEC GetUserNotificationSettings '1500001, 1500002', '007e0249-dd0b-47e7-9a54-0ba1895c391e,009ae7ab-639a-458c-b773-438f71ee2e1f,02429c41-ff61-400c-8971-747e276ee0a2'
