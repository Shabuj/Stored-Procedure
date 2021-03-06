IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SaveMassageByTeam')
DROP PROCEDURE SaveMassageByTeam

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go


CREATE PROCEDURE [dbo].[SaveMassageByTeam](

    @Team as nvarchar(MAX),
	@SenderId as nvarchar(MAX),
	@Message as nvarchar(MAX),
	@HasAttachment as bit
)
AS

BEGIN
	
	  BEGIN TRY
  
       Insert Into TeamMessages(TeamMessageId,SenderId,Msg,TeamName,Date,IsMessageSeen,HasAttachments) Values(NEWID(),@SenderId,@Message,@Team,SYSDATETIME(),'0',@HasAttachment)
	

	  END TRY
	  BEGIN CATCH


	  END CATCH
END
go