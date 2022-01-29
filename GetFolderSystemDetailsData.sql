IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetFolderSystemDetailsData')
DROP PROCEDURE GetFolderSystemDetailsData

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE GetFolderSystemDetailsData
(
	@ClientId AS NVARCHAR(MAX),
	@FromDate AS Datetime2,
	@ToDate AS Datetime2
)
AS
BEGIN
	
	BEGIN TRY

		SELECT CIL.Id AS ClientId, ClientName, Date, RawPath, Status, COUNT(*) AS StatusCount
		INTO #TEMP
		FROM ServerImageTrackers AS SIT
		INNER JOIN ClientImageLocations AS CIL
		ON SIT.ClientImageLocationId = CIL.Id
		WHERE ClientImageLocationId = @ClientId
		AND Date BETWEEN @FromDate AND @ToDate
		GROUP BY CIL.Id, ClientName, Date, RawPath, Status



		SELECT ClientId, ClientName, Date, RawPath,
			
			SUM( CASE WHEN Status = 'Not Assigned' THEN  StatusCount ELSE 0 END ) AS NotAssigned,

			SUM( CASE WHEN Status = 'In Production' THEN  StatusCount ELSE 0 END ) AS InProduction,

			SUM( CASE WHEN Status = 'Production Done' THEN  StatusCount ELSE 0 END ) AS ProductionDone,

			SUM( CASE WHEN Status = 'In QC' THEN  StatusCount ELSE 0 END ) AS InQc,

			SUM( CASE WHEN Status = 'QC Reject' THEN  StatusCount ELSE 0 END ) AS QcReject,

			SUM( CASE WHEN Status = 'Completed' THEN  StatusCount ELSE 0 END ) AS Completed

		INTO #CLIENT_WISE_DETAILS
		FROM #TEMP
		GROUP BY ClientId, ClientName, Date, RawPath



		SELECT ClientId, ClientName, Date, RawPath, (NotAssigned+InProduction+ProductionDone+InQc+QcReject+Completed) AS Raw,
				NotAssigned, InProduction, ProductionDone, InQc, QcReject, Completed
		FROM #CLIENT_WISE_DETAILS




		DROP TABLE #TEMP
		DROP TABLE #CLIENT_WISE_DETAILS


	END TRY

	BEGIN CATCH


	END CATCH

END


GO

EXEC GetFolderSystemDetailsData '49561498-E001-42CE-A629-3002E3A2193D', '2021-08-11 00:00:00.0000000', '2021-08-12 00:00:00.0000000'

