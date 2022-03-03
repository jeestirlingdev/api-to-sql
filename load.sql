SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ApplicantsTransfer_LoadJSON]
    -- Add the parameters for the stored procedure here
    
AS
BEGIN
	DROP TABLE IF EXISTS ApplicantsTransfer

    DECLARE @JSON varchar(max)
    SELECT @JSON=BulkColumn
    FROM OPENROWSET (BULK 'd:\PS\ApplicantTransfer\LIVE-pvg_pgde_api.json', SINGLE_NCLOB) import

    SELECT * INTO ApplicantsTransfer
    FROM OPENJSON (@JSON, '$.applicants')
    WITH (
        [ucasID] [int] ,
        [applicantNumber] [int] ,
        [applicationStatus] [varchar](10) ,
        [applicationDescription] [varchar](250) ,
        [choiceNumber] [smallint] ,
        [emailAddress] [varchar](250) ,
        [title] [varchar](10) ,
        [forename] [varchar](250) ,
        [surname] [varchar](250) ,
        [homeOseasRUK] [varchar](10) ,
        [hesaNationality] [varchar](250) ,
        [ppioCode] [int] ,
        [progCode] [int] ,
        [progConsecutiveVersion] [int] ,
        [progConcurrentVersion] [int] ,
        [progDeptCode] [int] ,
        [progDeptName] [varchar](250) ,
        [progDescription] [varchar](250) ,
        [modeOfAttendance] [varchar](30) ,
        [progClassification] [varchar](10) ,
        [deliveryMode] [varchar](30) ,
        [progStartDate] [date] ,
        [selectionGroups] [nvarchar](max) ,
        [primarySession] [varchar](50) ,
        [admissionsCode] [varchar](10) ,
        [acadYear] [int] ,
        [sessionStartDate] [date] ,
        [preAllocRegNumber] [int] ,
	[contactPrefValue] [char]

    )
END
GO
