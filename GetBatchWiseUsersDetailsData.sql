IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetBatchWiseUsersDetailsData')
DROP PROCEDURE GetBatchWiseUsersDetailsData

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE GetBatchWiseUsersDetailsData
(
	@Batch NVARCHAR(MAX)
)
AS
BEGIN

	BEGIN TRY
		
		SELECT UserId, WorkType, COUNT(*) AS IMAGES--, SUM(WorkDuration) AS WorkDuration
		INTO #TEMP
		FROM ServerImageTrackers AS SIT
		INNER JOIN ServerUserJobDetails AS SUJD
		ON SIT.Id = SUJD.ServerImageTrackerId
		WHERE RawPath = @Batch
		GROUP BY UserId, WorkType


		SELECT UserId, ANU.FullName, ANU.UserName, WorkType, IMAGES 
		FROM #TEMP
		INNER JOIN AspNetUsers AS ANU
		ON UserId = ID


		
		DROP TABLE #TEMP

	END TRY

	BEGIN CATCH
		


	END CATCH

END


GO

EXEC GetBatchWiseUsersDetailsData '2021/August/13.08.2021/Raw/A170557-ADI-eCom-FTW/20210804/GV7391/'

