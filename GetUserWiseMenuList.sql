IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetUserWiseMenuList')
DROP PROCEDURE GetUserWiseMenuList

GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetUserWiseMenuList]
    @ID as nvarchar(50)    
AS
SET NOCOUNT ON
BEGIN            
    
    BEGIN TRY        

    SELECT DISTINCT

		ANUR.UserId, 
		ANUR.RoleId,
		ANR.Name Role, 
		CML.*

	FROM AspNetUserRoles ANUR
	INNER JOIN AspNetRoles ANR ON ANUR.RoleId = ANR.Id
	INNER JOIN CmnMenuPermissionToGroups CMG ON ANR.Id = CMG.RoleId  
	INNER JOIN CmnMenuLists CML ON CMG.MenuID = CML.MenuID 
	
	WHERE ANUR.UserId = @ID

	ORDER BY CML.MenuName

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

GO