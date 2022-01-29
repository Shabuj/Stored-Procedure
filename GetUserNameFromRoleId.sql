IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetUserNameFromRoleId')
DROP PROCEDURE GetUserNameFromRoleId

GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE [dbo].[GetUserNameFromRoleId]
   @RoleID nvarchar(max) = NULL  

   --	EXEC GetUserNameFromRoleId '9f7cb4dd-08dc-4083-a18e-be00eea699ec,c0a67d8f-eae6-4a84-96a8-7f8f0c9ef97f'
AS
SET NOCOUNT ON
BEGIN            
    
    BEGIN TRY        
		Select AspNetUsers.Id,AspNetUsers.Name,Email,userName,AspNetRoles.Name as RoleName
		FROM AspNetUsers
		LEFT JOIN AspNetUserRoles ON AspNetUsers.Id = AspNetUserRoles.UserId
		LEFT JOIN AspNetRoles ON AspNetUserRoles.RoleId = AspNetRoles.Id
		WHERE AspNetRoles.Id IN (SELECT * FROM dbo.SplitString(@RoleID, ',')) 

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
