SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ApplicantsTransfer_Applicants_MERGE]
    -- Add the parameters for the stored procedure here
    
AS
BEGIN
	


MERGE Applicants AS t  
     USING (SELECT * from ApplicantsTransfer) AS s  
     ON t.applicantNumber = s.applicantNumber  AND t.choiceNumber = s.choiceNumber

    WHEN MATCHED 
        THEN UPDATE SET 
             t.ucasID = s.ucasID ,
            t.applicationStatus = s.applicationStatus ,
            t.applicationDescription = s.applicationDescription ,
            t.choiceNumber = s.choiceNumber ,
            t.emailAddress = s.emailAddress ,
            t.title = s.title ,
            t.forename = s.forename ,
            t.surname = s.surname ,
            t.homeOseasRUK = s.homeOseasRUK ,
            t.hesaNationality = s.hesaNationality ,
            t.ppioCode = s.ppioCode ,
            t.progCode = s.progCode ,
            t.progConsecutiveVersion = s.progConsecutiveVersion ,
            t.progConcurrentVersion = s.progConcurrentVersion ,
            t.progDeptCode = s.progDeptCode ,
            t.progDeptName = s.progDeptName ,
            t.progDescription = s.progDescription ,
            t.modeOfAttendance = s.modeOfAttendance ,
            t.progClassification = s.progClassification ,
            t.deliveryMode = s.deliveryMode ,
            t.progStartDate = s.progStartDate ,
            t.selectionGroups = s.selectionGroups ,
            t.primarySession = s.primarySession ,
            t.admissionsCode = s.admissionsCode ,
            t.acadYear = s.acadYear ,
            t.sessionStartDate = s.sessionStartDate ,
            t.preAllocRegNumber = s.preAllocRegNumber ,
	        t.contactPrefValue = s.contactPrefValue ,
            t.Updated = GetDate()

    WHEN NOT MATCHED BY TARGET THEN  
        INSERT ([ucasID]
           ,[applicantNumber]
           ,[applicationStatus]
           ,[applicationDescription]
           ,[choiceNumber]
           ,[emailAddress]
           ,[title]
           ,[forename]
           ,[surname]
           ,[homeOseasRUK]
           ,[hesaNationality]
           ,[ppioCode]
           ,[progCode]
           ,[progConsecutiveVersion]
           ,[progConcurrentVersion]
           ,[progDeptCode]
           ,[progDeptName]
           ,[progDescription]
           ,[modeOfAttendance]
           ,[progClassification]
           ,[deliveryMode]
           ,[progStartDate]
           ,[selectionGroups]
           ,[primarySession]
           ,[admissionsCode]
           ,[acadYear]
           ,[sessionStartDate]
           ,[preAllocRegNumber] 
	       ,[contactPrefValue]
        )
     VALUES ([ucasID]
           ,[applicantNumber]
           ,[applicationStatus]
           ,[applicationDescription]
           ,[choiceNumber]
           ,[emailAddress]
           ,[title]
           ,[forename]
           ,[surname]
           ,[homeOseasRUK]
           ,[hesaNationality]
           ,[ppioCode]
           ,[progCode]
           ,[progConsecutiveVersion]
           ,[progConcurrentVersion]
           ,[progDeptCode]
           ,[progDeptName]
           ,[progDescription]
           ,[modeOfAttendance]
           ,[progClassification]
           ,[deliveryMode]
           ,[progStartDate]
           ,[selectionGroups]
           ,[primarySession]
           ,[admissionsCode]
           ,[acadYear]
           ,[sessionStartDate]
           ,[preAllocRegNumber] 
	       ,[contactPrefValue]
     )

    WHEN NOT MATCHED BY SOURCE   
        THEN DELETE  
    OUTPUT 
        $action AS Action, 
        IIF($action = 'delete', Deleted.applicantNumber, Inserted.applicantNumber) As ApplicantNumber, 
        IIF($action = 'delete', Deleted.choiceNumber, Inserted.choiceNumber) AS ChoiceNumber
        ;
END
GO
