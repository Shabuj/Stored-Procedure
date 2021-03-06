IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetOrderList')
DROP PROCEDURE GetOrderList

GO

Create PROCEDURE [dbo].[GetOrderList]
    @ID as nvarchar(50)    
AS
SET NOCOUNT ON
BEGIN            
    
    BEGIN TRY        

    SELECT DISTINCT
	/****** Script for SelectTopNRows command from SSMS  ******/
	USR.UserName,
	 ODR.[Id] as OrderNumber,
       ODR.[UserId]
	   , ODR.[UserEmail]
      , ODR.[ChargeId]
      , ODR.[ChargeStatus]
      , ODR.[ChargeAmount]
      , ODR.[UnitPrice]
      , ODR.[OrderTime]
      , ODR.[ExpectedDelivery]
      , ODR.[DeliveryTime]
      , ODR.[UploadTime]
      , ODR.[SeenTime]
      , ODR.[DownloadTime]
      , ODR.[IsCompleted]
      , ODR.[OrderStatus]
      , ODR.[ClientQcStatus]
      , ODR.[ClientJobStatus]
      , ODR.[Confirmed]
      , ODR.[IsSeenByUser]
      , ODR.[IsDownloaded]
      , ODR.[EmailSent]
	  , ODR.[ReceivedImages]
      , ODR.[ReceivedImages] TotalImage
      , ODR.[DeliveredImages]
      , ODR.[UploadedFrom]
      , ODR.[Comment]
      , ODR.[ClientComment]
      , ODR.[HasAttachments]
      , ODR.[FolderStructure]
      , ODR.[InvoiceId]
      , ODR.[LinkVerificationCode]
      , ODR.[ChargeId1]
      , ODR.[FormatedChargeId]
      , ODR.[ImageName]
      , ODR.[ImagePath]
      , ODR.[InstallationId]
      , ODR.[IsDownloadedByUser]
      , ODR.[IsProcessingCompleted]
      , ODR.[OrginalImageName]
      , ODR.[ThumnailPath]
      , ODR.[DiscountPrice]
	  --, CGR.TotalImages TotalImage
	  , CGR.TotalPrice

		--,JBS.*
		,TMS.TeamName
	FROM Orders ODR
	LEFT JOIN Jobs AS JBS ON ODR.Id = JBS.OrderNumber
	LEFT JOIN Teams AS TMS ON JBS.TeamId = TMS.Id
	LEFT JOIN Charges CGR ON ODR.ChargeId = CGR.Id
	LEFT JOIN AspNetUsers USR ON CGR.UserId = USR.Id

	where ODR.ChargeStatus IN('Pending', 'InQC', 'Completed', 'Accepted', 'Active', 'Due', 'Free')

	ORDER BY ODR.OrderTime, USR.UserName, TMS.TeamName DESC

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






