IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetFolderSystemSummaryData')
DROP PROCEDURE GetFolderSystemSummaryData

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE GetFolderSystemSummaryData
(
	@FromDate AS Datetime2,
	@ToDate AS Datetime2
)
AS
BEGIN

	BEGIN TRY
		

		SELECT CIL.Id AS ClientId, ClientName, Status, COUNT(*) AS StatusCount
		INTO #TEMP
		FROM ServerImageTrackers as SIT
		INNER JOIN ClientImageLocations AS CIL
		ON SIT.ClientImageLocationId = CIL.Id
		WHERE Date BETWEEN @FromDate AND @ToDate
		GROUP BY CIL.Id, ClientName, Status
		


		SELECT ClientId, ClientName, 
			
			SUM( CASE WHEN Status = 'Not Assigned' THEN  StatusCount ELSE 0 END ) AS NotAssigned,

			SUM( CASE WHEN Status = 'In Production' THEN  StatusCount ELSE 0 END ) AS InProduction,

			SUM( CASE WHEN Status = 'Production Done' THEN  StatusCount ELSE 0 END ) AS ProductionDone,

			SUM( CASE WHEN Status = 'In QC' THEN  StatusCount ELSE 0 END ) AS InQc,

			SUM( CASE WHEN Status = 'QC Reject' THEN  StatusCount ELSE 0 END ) AS QcReject,

			SUM( CASE WHEN Status = 'Completed' THEN  StatusCount ELSE 0 END ) AS Completed

		INTO #CLIENT_WISE_SUMMARY
		FROM #TEMP
		GROUP BY ClientId, ClientName
		



		SELECT ClientId, ClientName, (NotAssigned+InProduction+ProductionDone+InQc+QcReject+Completed) AS Raw,
				NotAssigned, InProduction, ProductionDone, InQc, QcReject, Completed
		FROM #CLIENT_WISE_SUMMARY





		DROP TABLE #TEMP
		DROP TABLE #CLIENT_WISE_SUMMARY

	END TRY

	BEGIN CATCH

	END CATCH

END


GO



EXEC GetFolderSystemSummaryData '2021-08-11 00:00:00.0000000', '2021-08-11 00:00:00.0000000'

