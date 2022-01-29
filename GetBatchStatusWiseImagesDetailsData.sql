IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetBatchStatusWiseImagesDetailsData')
DROP PROCEDURE GetBatchStatusWiseImagesDetailsData

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

set nocount on;

go

CREATE PROCEDURE GetBatchStatusWiseImagesDetailsData
(
	@Batch NVARCHAR(MAX),
	@Status NVARCHAR(MAX) = NULL
)
AS
BEGIN
	
	BEGIN TRY
		
		IF @Status IS NULL
		BEGIN
			SET @Status = 'All'
		END
		
		SELECT SIT.Id, RawPath, RawImageName , ImageSize, SIT.Status, 
					SIT.EditorId AS EditorId, anuForEditor.UserName AS EditorUserId, anuForEditor.FullName AS EditorName,
					SIT.QcId AS QcId, anuForQc.UserName AS QcUserId, anuForQc.FullName AS QcName,
					IsAssignedFromEditorUI, IsDownloadedAssignedImagesFromEditorUI, IsUploadedDoneImagesFromEditorUI,
					IsDownloadedAssignedImagesFromQcUI, IsUploadedDoneImagesFromQcUI,
					IsUploadedRejectedImagesFromQcUI, IsDownloadedRejectedImagesFromEditorUI,
					RawTime, IsReleased, ReleaseTime, ReleasedById, EditorAssignedBeforeReleaseId 

		INTO #TEMP
		FROM ServerImageTrackers AS SIT
		LEFT JOIN AspNetUsers AS anuForEditor
		ON SIT.EditorId = anuForEditor.Id
		LEFT JOIN AspNetUsers AS anuForQc
		ON SIT.QcId = anuForQc.Id
		WHERE RawPath = @Batch
		AND (SIT.Status = @Status OR @Status = 'All')

		SELECT #TEMP.Id, #TEMP.RawPath, #TEMP.RawImageName , #TEMP.ImageSize, #TEMP.Status, 
					#TEMP.EditorId, #TEMP.EditorUserId, #TEMP.EditorName,
					#TEMP.QcId, #TEMP.QcUserId, #TEMP.QcName,
					#TEMP.IsAssignedFromEditorUI, #TEMP.IsDownloadedAssignedImagesFromEditorUI, #TEMP.IsUploadedDoneImagesFromEditorUI,
					#TEMP.IsDownloadedAssignedImagesFromQcUI, #TEMP.IsUploadedDoneImagesFromQcUI,
					#TEMP.IsUploadedRejectedImagesFromQcUI, #TEMP.IsDownloadedRejectedImagesFromEditorUI,
					#TEMP.RawTime, #TEMP.IsReleased, #TEMP.ReleaseTime, #TEMP.ReleasedById, #TEMP.EditorAssignedBeforeReleaseId ,

			MIN(CASE
				WHEN WorkType = 'Edit' THEN InProductionTime
				ELSE NULL
			END) AS InProductionTime,


			MIN(CASE
				WHEN WorkType = 'Edit' AND DoneTime <> '0001-01-01 00:00:00.0000000' THEN DoneTime
				ELSE NULL
			END) AS ProductionDoneTime,


			MIN(CASE
				WHEN WorkType = 'QC' THEN InProductionTime
				ELSE NULL
			END) AS InQcTime,


			MIN(CASE
				WHEN WorkType = 'QC' AND DoneTime <> '0001-01-01 00:00:00.0000000' THEN DoneTime
				ELSE NULL
			END) AS CompletedTime,


			MAX(CASE
				WHEN WorkType = 'QC' THEN RejectedCount
				ELSE 0
			END) AS RejectedCount,


			MIN(CASE
				WHEN WorkType = 'QC' AND RejectedTime <> '0001-01-01 00:00:00.0000000' THEN RejectedTime
				ELSE NULL
			END) AS LastRejectedTime

		INTO #RESULT			
		FROM #TEMP
		LEFT JOIN ServerUserJobDetails AS SUJ
		ON #TEMP.Id = SUJ.ServerImageTrackerId 

		GROUP BY #TEMP.Id, #TEMP.RawPath, #TEMP.RawImageName , #TEMP.ImageSize, #TEMP.Status, 
					#TEMP.EditorId, #TEMP.EditorUserId, #TEMP.EditorName,
					#TEMP.QcId, #TEMP.QcUserId, #TEMP.QcName,
					#TEMP.IsAssignedFromEditorUI, #TEMP.IsDownloadedAssignedImagesFromEditorUI, #TEMP.IsUploadedDoneImagesFromEditorUI,
					#TEMP.IsDownloadedAssignedImagesFromQcUI, #TEMP.IsUploadedDoneImagesFromQcUI,
					#TEMP.IsUploadedRejectedImagesFromQcUI, #TEMP.IsDownloadedRejectedImagesFromEditorUI,
					#TEMP.RawTime , #TEMP.IsReleased, #TEMP.ReleaseTime, #TEMP.ReleasedById, #TEMP.EditorAssignedBeforeReleaseId

		
		SELECT RS.*, anuForReleasedBy.FullName AS ReleasedByName, anuForEditorAssignedBeforeRelease.FullName AS EditorAssignedBeforeReleaseName
		FROM #RESULT AS RS
		LEFT JOIN AspNetUsers AS anuForReleasedBy
		ON RS.ReleasedById = anuForReleasedBy.Id
		LEFT JOIN AspNetUsers AS anuForEditorAssignedBeforeRelease
		ON RS.EditorAssignedBeforeReleaseId = anuForEditorAssignedBeforeRelease.Id


		DROP TABLE #TEMP
		DROP TABLE #RESULT

	END TRY

	BEGIN CATCH


	END CATCH

END

GO

--EXEC GetBatchStatusWiseImagesDetailsData '2021/August/27.08.2021/Raw/SC-Boston/COW-2021-08-26~21_BOSx_RBK-Footwear-ShadowClip-A/', 'All'
