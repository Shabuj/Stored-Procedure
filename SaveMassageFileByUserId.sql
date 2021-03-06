IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SaveMassageFileByUserId')
DROP PROCEDURE SaveMassageFileByUserId

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE [dbo].[SaveMassageFileByUserId](

    
	@SenderId as nvarchar(MAX),
	@Location as nvarchar(MAX)
	

)
AS

BEGIN
	
	  BEGIN TRY
  
        Declare @MessageId as varchar(200)
		Set @MessageId=(Select top(1) MessageId From Messages where SenderId=@SenderId order by Date Desc)
		Insert Into MessageAttachments(MessageAttachmentId,MessageId,Location,Date) Values(NEWID(),@MessageId,@Location,SYSDATETIME())


	  END TRY
	  BEGIN CATCH


	  END CATCH
END

GO