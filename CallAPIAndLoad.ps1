############################
##
## Import SRS HaSS applicant data through Integration Hub API
##
##  call with the identifier for the Hyb environment targetted:  .\hassapplicanttransfer.ps1 [DEV|TEST|VT|LIVE]
##
## v 0.1: initial build
##
##
##
## *	When debugging add a breakpoint after  ## BREAKPOINT HERE ## because of hashing
##
############################

############################
## SCRIPT VARIABLES
############################
$debug = $false
# $debug = $true

# API to call
$serviceName = "https://myapiendpoint.apiserver.com/pvg_pgde_api"

# Location to save JSON on file system and the archive copy
$pathRoot = "d:\PS\ApplicantTransfer"
# NOTE path is hard coded in the stored proc to d:\PS\ApplicantTransfer\LIVE-pvg_pgde_api.json
$filePath = "$pathRoot\Test_$serviceName.json"
$archivePath = "$pathRoot\ARCHIVE_Test_$serviceName.json"

# SQL Server variables
$SQLServer = "LOCALHOST\SQLEXPRESS" 
$SQLLoadDatabase = "ApplicantTransfer" 
# NOTE path is hard coded in the stored proc to d:\PS\ApplicantTransfer\LIVE-pvg_pgde_api.json
$SQLLoadProc = "dbo.ApplicantsTransfer_LoadJSON" 
$SQLMergeProc = "dbo.ApplicantsTransfer_Applicants_MERGE" 

# Set SMTP server
$PSEmailServer = "smtp.strath.ac.uk"
# send error report email from this user
$errorFrom = "ewds@strath.ac.uk"
# send error report email to this user
$errorTo = "ewds@strath.ac.uk"

############################
## STATIC VARIABLES
############################
# utility variable for tracking success of steps
$proceed = $true

# Set security for API call
Add-Type -AssemblyName System.Web
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# SQL connection string
$ConnectionString = "Server=$SQLServer Database=$SQLLoadDatabase Integrated Security=true"


############################
## FUNCTIONS
############################

#*=============================================
#* Function: makesqlProcFunc
#* Variables: $sqlProc (the SQL query)
#*            ,$sLogMsg message to log
#*=============================================
#* Purpose:
#* log the sucess of the stored procedure call
#*=============================================
function makesqlProcFunc ([string]$sqlProc,[string]$sLogMsg) {

	# sqlProcFunc "exec $sqlProc" $SQLLoadDatabase $SQLServer
    sqlProcQuery $sqlProc
	$logType = "Info"
	logFunc $logType $sLogMsg 
}



#*=============================================
#* Function: sqlProcQuery
#* Variables: $pQuery (the stored proc)
#*            
#*=============================================
#* Purpose:
#* Execute a parameter-less stored procedure
#* trap errors and log them
#*=============================================
function sqlProcQuery([string]$pQuery)
{
 
    # Create SqlConnection object and define connection string

    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand

    $sqlDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCmd
    $sqlResults = New-Object System.Data.DataTable

    try {

        $sqlConnection.ConnectionString = $ConnectionString

        $sqlCmd.Connection = $sqlConnection
        $sqlCmd.CommandText = $pQuery
        $sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $sqlCmd.CommandTimeout = 300

        $sqlConnection.Open()

        $sqlDataAdapter.Fill($sqlResults) | Out-Null

    }
    catch {
        #$noError = $false
        $logMsg = $_.Exception.Message
        $logType = "Error"
	    logFunc $logType $LogMsg 
        Break
    }
    finally {

        $sqlConnection.Close()
        $sqlConnection.Dispose()
        $sqlCmd.Dispose()
        $sqlDataAdapter.Dispose()
    }

    # return ,$sqlResults
}





#*=============================================
#* Function: logFunc
#* Variables: $logType (type of log entry, i.e. warning, error, etc.)
#*            ,$logMsg (the text of the message),$dsx (the dataset holding the entry)
#*=============================================
#* Purpose:
#* Stub for logging
#*=============================================
function logFunc ([string]$logType,[string]$logMsg) {
	if($debug){
		Write-Host $logMsg
	} else {
        # insert logging code here

	}

	# If there is an error
    # Send email and stop script
	if ($logType -eq "Error") {
        Send-MailMessage -From $errorFrom -To $errorTo -Subject "API service error" -Body "API error. The error message was:  $logMsg" 
        break
    }

}

#*=============================================
#* Function: searchParameters
#* Variables: 
#*=============================================
#* Purpose:
#* Concatenate parameters form a querystring for the API GET
#* as an example it adds a static "includeNulls=true" parameter and a dynamic "ChangesSince" parameter
#*=============================================
function SearchParameters
{
    $parameters = "?"

    $parameters = -join($parameters, "includeNulls=true")

    #Changes Since
    $changesSinceValue = ChangesSince

    $changesSince = -join("changesSince=", $changesSinceValue)

    # Finish
    $parameters = -join($parameters, "&", $changesSince)

    return $parameters
}


#*=============================================
#* Function: CallAPI
#* Variables: $url (URL of the API endpoint)
#*            ,$tokenID (example API token)
#*            
#*=============================================
#* Purpose:
#* Stub for logging
#*=============================================
function CallAPI([string] $url, [string] $tokenID)
{
    $headers = @{}
    $headers.Add("Authorization", "Basic $tokenID")
   

    # Build search parameters from the separate function
    $searchParameters = SearchParameters
    $url = -join($url, $searchParameters)

    if($debug){
        Write-Host "Invoke URL: $url "
    }

    $response = Invoke-RestMethod $url -Headers $headers -ContentType 'application/json'

    return $response
}

<# *********************************************************************************************
*
*	MAIN
*
********************************************************************************************* #>

# Get envrionment
# ===============

# Get command line variables
if($Args[0]){
    if($Args[0] -eq "DEBUG"){
        $debug = $true
    }
}

# initialise logging
$logType = "Start"
$logMsg = "$serviceName in $envIH update process initiated"
logFunc $logType $logMsg 


# TRY-CATCH get data from API 
# save as variable
# ==================
try {

    # service name defined at beginning of the script
    $apiUrl = $serviceName.ToLower()

    # authentication will vary according the implementation
    # there are several methods for storing credentials securely
    $tokenID = "sometokenstring"
    

    # call the api and store response in variable
    $response = CallAPI $apiUrl $tokenID 

    # this example checks for the existence of a data element in the response JSON
    # where to check will vary according to the API
    if(!$response.data){
        $logType = "Warning"
        $logMsg = "No Data: response.header.description = " + $response.header.description + ": " + $response.header.result_description
            logFunc $logType $logMsg 
        Exit
    }
    else{

            # save a copy of the raw data
            $rptostring = $response.data | ConvertTo-Json -Compress
            
            # log the count of items found
            # in this example the payload is in the date.applicants element
            $countA = $response.data.applicants.count
            
            $logType = "Info"
            $logMsg = "Records found $countA"
                logFunc $logType $logMsg 

    }


}
catch {
    # API call failed
    $proceed = $false
    $ErrorMessage = $_.Exception.Message

    if ($debug ) {
        write-host $ErrorMessage
    } else {
        $logType = "Error"
        $logMsg = "The script failed to retrieve data from $apiUrl. The error message was: $ErrorMessage"
        Send-MailMessage -From ewds@strath.ac.uk -To ewds@strath.ac.uk -Subject "HaSS Applicant Transfer Read failure" -Body $logMsg
            logFunc $logType $logMsg 

    }

}



# The script saves the response to a JSON file on disk
# The previously saved file is copied as an "archive" 
# The previous archive file is deleted
# ===============

# only process if the previous steps have succeed
if ($proceed) {

	# delete backup json file
	If (Test-Path $archivePath){
		Remove-Item $archivePath 
		$logType = "Info"
		$logMsg = "Previous $envIH-$serviceName archive deleted"
		logFunc $logType $logMsg 
	} else {
		$logType = "Info"
		$logMsg = "Previous $envIH-$serviceName archive NOT found"
		logFunc $logType $logMsg 
	}

	# rename previous json file
    If (Test-Path $filePath){
		Copy-Item $filePath $archivePath 
		Remove-Item $filePath
		$logType = "Info"
		$logMsg = "Previous $filePath copied to archive"
		logFunc $logType $logMsg 
	} else {
		$logType = "Info"
		$logMsg = "Previous $filePath NOT found"
		logFunc $logType $logMsg 
	}

    # Save current data to file
    $rptostring  | Out-File -FilePath $filePath
    $logType = "Info"
    $logMsg = "$filePath created"
    logFunc $logType $logMsg 
}

# Execute Stored Procedures 
# ===============
if ($proceed) {
    If ((Test-Path $filePath) -and ($filePath -eq "d:\PS\ApplicantTransfer\LIVE-pvg_pgde_api.json")){ 
        # NOTE path is hard coded in the stored proc to d:\PS\ApplicantTransfer\LIVE-pvg_pgde_api.json

        # do sql to load in        
        $logMsg = "Import new JSON into ApplicantsTransfer table"
	    makesqlProcFunc $SQLLoadProc $logMsg
       
        # do sql to merge
        $logMsg = "Merge ApplicantsTransfer table into Applicants table"
	    makesqlProcFunc $SQLMergeProc $logMsg

    } else {
        $logType = "Error"
        $logMsg = "JSON file not found"

        logFunc $logType $logMsg 

    }

}

# close logging
$logType = "End"
$logMsg = "$envIH-$serviceName update process completed"
logFunc $logType $logMsg 