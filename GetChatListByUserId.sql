
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetChatListByUserId')
DROP PROCEDURE GetChatListByUserId

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go



CREATE PROCEDURE [dbo].[GetChatListByUserId](

	@UserId as nvarchar(MAX)	

)
AS

BEGIN
	
	  BEGIN TRY
   
       
	    SELECT DISTINCT SenderId INTO #TempSenderIdTable From Messages where ReceiverId=@UserId Or SenderId=@UserId

	    Select Id,UserName, Name,ProfilePicturePath INTO #TempUser FROM AspNetUsers  Where Id in (Select * From #TempSenderIdTable)

	    Select CAST(null as varchar(8000)) AS UserId,CAST(null as varchar(8000)) AS UserName,CAST(null as varchar(8000)) AS Name,CAST(null as varchar(8000)) AS UserMessage, 
		CAST(null as varchar(8000)) AS SenderId,CAST(null as varchar(8000)) AS ProfilePath,
		CAST(null as bit) AS IsMessageSeen,CAST(null as bit) AS HasAttachment,CAST(null as datetime2(7)) AS Date
	    into #MessageTable
        delete from #MessageTable


		DECLARE @SenderId as varchar(8000)

		DECLARE curBindData  cursor for 
	    SELECT SenderId FROM #TempSenderIdTable 
		OPEN curBindData FETCH NEXT FROM curBindData INTO @SenderId
		WHILE @@FETCH_STATUS =0
		BEGIN

		Insert Into #MessageTable(UserId,UserName,Name,UserMessage,ProfilePath,SenderId,IsMessageSeen,HasAttachment,Date)
		Select TOP(1) u.Id, u.UserName,u.Name, m.Msg,u.ProfilePicturePath ,m.SenderId,m.IsMessageSeen,m.HasAttachments,m.Date
		From 
		Messages  m LEFT JOIN AspNetUsers u   ON u.Id =m.SenderId 
		where 
		(m.ReceiverId = @UserId AND m.SenderId = @SenderId)
         OR    (m.ReceiverId = @SenderId AND m.SenderId = @UserId ) 
         ORDER BY m.Date  Desc
		

		
		FETCH NEXT FROM curBindData INTO @SenderId
		END
		CLOSE curBindData
		DEALLOCATE curBindData
       


	   SELECT UserId,UserName,Name,ProfilePath,SenderId,UserMessage as Message,HasAttachment,Date FROM #MessageTable Order by Date


	  DROP Table #MessageTable
	  DROP Table #TempSenderIdTable
	  DROP Table #TempUser
	

	  END TRY
	  BEGIN CATCH


	  END CATCH
END
GO
