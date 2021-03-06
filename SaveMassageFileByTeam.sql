IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SaveMassageFileByTeam')
DROP PROCEDURE SaveMassageFileByTeam

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go




CREATE PROCEDURE [dbo].[SaveMassageFileByTeam](

    
	@Team as nvarchar(MAX),
	@Location as nvarchar(MAX)
	

)
AS

BEGIN
	
	  BEGIN TRY
  
        Declare @TeamMessageId as varchar(200)
		Set @TeamMessageId=(Select top(1) TeamMessageId From TeamMessages where TeamName=@Team order by Date Desc)
		Insert Into TeamMessageAttachments(TeamMessageAttachmentId,TeamMessageId,Location,Date) Values(NEWID(),@TeamMessageId,@Location,SYSDATETIME())


	  END TRY
	  BEGIN CATCH


	  END CATCH
END

Go