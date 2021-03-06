IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetAllUsers')
DROP PROCEDURE GetAllUsers
GO

CREATE PROCEDURE [dbo].[GetAllUsers]
    @ID as bigint    
AS
SET NOCOUNT ON
BEGIN            
    
    BEGIN TRY        

        DECLARE @IsSettled1 as bit
        DECLARE @Count1 as int

		SELECT * FROM AspNetUsers; 

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

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'TempGetAllUsers')
DROP PROCEDURE GetAllUsers

GO

CREATE PROCEDURE [dbo].[TempGetAllUsers]
    @ID as bigint    
AS
SET NOCOUNT ON
BEGIN            
    
    BEGIN TRY        

        DECLARE @IsSettled as bit
        DECLARE @Count as int

		SELECT * FROM AspNetUsers; 

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
