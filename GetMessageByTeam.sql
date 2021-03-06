
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetMessageByTeam')
DROP PROCEDURE GetMessageByTeam

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go



CREATE PROCEDURE [dbo].[GetMessageByTeam](

	@Team as nvarchar(MAX)

)
AS

BEGIN
	
	  BEGIN TRY
  
       SELECT TeamMessageId,SenderId as SenderId,Msg as Message ,HasAttachments as HasAttachment,Date,u.ProfilePicturePath as ProfilePath
	   INTO #TeamMessage
	   FROM TeamMessages t LEFT JOIN AspNetUsers u ON t.SenderId = u.Id WHERE TeamName=@Team ORDER BY Date 


	   Select  m.*,ma.Location INTO #MESSAGEFILE FROM #TeamMessage m Left Join TeamMessageAttachments ma ON m.TeamMessageId=ma.TeamMessageId order by m.Date 

	   SELECT SenderId,Message,HasAttachment,ISNULL(Location,'') as Location,ISNULL(ProfilePath,'') as ProfilePath FROM #MESSAGEFILE order by Date

	  END TRY
	  BEGIN CATCH


	  END CATCH
END

GO
