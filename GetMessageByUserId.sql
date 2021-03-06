IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetMessageByUserId')
DROP PROCEDURE GetMessageByUserId

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go


Create PROCEDURE [dbo].[GetMessageByUserId](

    @SenderId as nvarchar(MAX),
	@ReceiverId as nvarchar(MAX)
	

)
AS

BEGIN
	
	  BEGIN TRY
  
       SELECT m.MessageId,m.SenderId as SenderId,m.Msg as Message,m.ReceiverId as ReceiverId ,m.HasAttachments as HasAttachments,m.Date,m.IsMessageSeen,u.ProfilePicturePath as  ProfilePath
	   INTO #Message
	   FROM Messages m LEFT JOIN AspNetUsers u ON u.id = m.ReceiverId
       WHERE (m.ReceiverId = @ReceiverId AND m.SenderId = @SenderId)
       OR    (m.ReceiverId = @SenderId AND m.SenderId = @ReceiverId ) 
       ORDER BY m.Date 

	   Select MessageId INTO #TempMessageId FROM #Message where (IsMessageSeen=0 and ReceiverId=@ReceiverId)


	   Update Messages SET IsMessageSeen=1 Where MessageId in (Select * FROM #TempMessageId)

	   Select  m.*,ma.Location INTO #MESSAGEFILE FROM #Message m Left Join MessageAttachments ma ON m.MessageId=ma.MessageId order by m.Date desc

	   SELECT SenderId,Message,ReceiverId,HasAttachments as HasAttachment,ISNULL(Location,'') as Location,ISNULL(ProfilePath,'') as ProfilePath FROM #MESSAGEFILE Order by Date



	  

	  END TRY
	  BEGIN CATCH


	  END CATCH
END


Go