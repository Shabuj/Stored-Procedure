IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetUnseenMessageByUserId')
DROP PROCEDURE GetUnseenMessageByUserId

GO
/****** Object:  StoredProcedure [dbo].[GetUserEmailByMenuId]    Script Date: 4/15/2021 12:22:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



Create PROCEDURE [dbo].[GetUnseenMessageByUserId](

	@UserId as nvarchar(MAX)	

)
AS

BEGIN
	
	  BEGIN TRY
   
       
	    SELECT COUNT(*) AS UnseenMessageCount FROM Messages WHERE ReceiverId =@UserId and IsMessageSeen =0
	    
	
	  END TRY
	  BEGIN CATCH


	  END CATCH
END


