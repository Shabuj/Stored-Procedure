IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetUserEmailByMenuId')
DROP PROCEDURE GetUserEmailByMenuId

GO
/****** Object:  StoredProcedure [dbo].[GetUserEmailByMenuId]    Script Date: 4/15/2021 12:22:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetUserEmailByMenuId]
   @MenuID nvarchar(max) = NULL  

   --	EXEC GetUserEmailByMenuId '10'
AS
SET NOCOUNT ON
BEGIN            
    
    BEGIN TRY        
		--SELECT DISTINCT Email from AspNetUsers where Id IN 
		--(SELECT DISTINCT nf.UserIdList  FROM NotificationMasters nf where @MenuID 
		--in (SELECT * FROM NotificationMasters dbo.SplitString(nf.MenuIdList, ','))

		SELECT DISTINCT Email FROM AspNetUsers
		LEFT JOIN NotificationMasters nf ON AspNetUsers.Id in (SELECT * FROM dbo.SplitString(nf.UserIdList, ','))
		where @MenuID 
		in (SELECT * FROM dbo.SplitString(nf.MenuIdList, ','))

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

--EXEC GetUserEmailByMenuId '7'