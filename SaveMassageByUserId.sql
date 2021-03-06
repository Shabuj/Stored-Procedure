IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SaveMassageByUserId')
DROP PROCEDURE SaveMassageByUserId

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go


CREATE PROCEDURE [dbo].[SaveMassageByUserId](

    
	@SenderId as nvarchar(MAX),
	@Message as nvarchar(MAX),
	@ReceiverId as nvarchar(MAX),
	@HasAttachment as bit

)
AS

BEGIN
	
	  BEGIN TRY
  

		Insert Into Messages(MessageId,SenderId,Msg,ReceiverId,Date,IsMessageSeen,HasAttachments,TeamName) Values(NEWID(),@SenderId,@Message,@ReceiverId,SYSDATETIME(),'0',@HasAttachment,'')


	  END TRY
	  BEGIN CATCH


	  END CATCH
END


go
