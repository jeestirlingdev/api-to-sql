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
## GLOBAL VARIABLES
############################
$debug = $false;
# $debug = $true;

$getAPI = $true
# set false to skip API and use existing files
# $getAPI = $false; 

# API to call
$serviceName = "pvg_pgde_api"

$pathRoot = "d:\PS\ApplicantTransfer";
# NOTE path is hard coded in the stored proc to d:\PS\ApplicantTransfer\LIVE-pvg_pgde_api.json
$filePath = "$pathRoot\Test_$serviceName.json"
$archivePath = "$pathRoot\ARCHIVE_Test_$serviceName.json"
$envIH = "DEV"

# SQL Server variables
$SQLServer = "LOCALHOST\SQLEXPRESS" ;
$SQLLoadDatabase = "ApplicantTransfer" ;
# NOTE path is hard coded in the stored proc to d:\PS\ApplicantTransfer\LIVE-pvg_pgde_api.json
$SQLLoadProc = "dbo.ApplicantsTransfer_LoadJSON" ;
$SQLMergeProc = "dbo.ApplicantsTransfer_Applicants_MERGE" ;



############################
## STATIC VARIABLES
############################
$proceed = $true
$logCmd = $serviceName

# Set security
Add-Type -AssemblyName System.Web
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# Set SMTP server
$PSEmailServer = "campus-mail-hub.strath.ac.uk";

<# *********************************************************************************************
*   Hub Environments
********************************************************************************************* #>
# cannot replace with splats because varibles used in various places not as command parameters
### Regenerate using integration-hub-login.ps1

$apiDEV = @{}
$apiDEV.Add('deviceID',"")
$apiDEV.Add('tokenID', "")
$apiDEV.Add('apiHost', "https://api-dev.is.strath.ac.uk/") # DEV only
$apiDEV.Add('securityEnabled', $false)


$apiTEST = @{}
$apiTEST.Add('deviceID', '.25813702644750905564118893957422968624')
$apiTEST.Add('tokenID', 'B0686C80A3FCF7EF9261BBD585ABB3FB90F9A96F44F01A761BCDB0DBCEB8F316MIS10010908239100')
$apiTEST.Add('apiHost', "https://api-test.is.strath.ac.uk/") #  testing
$apiTEST.Add('securityEnabled', $true)


$apiVT = @{}
$apiVT.Add('deviceID', '.15949923890194858250944396319086752187')
$apiVT.Add('tokenID', 'B0686C80A3FCF7EF271100127014C59320D65F955A579680F90A4C846E877057MIS10010793443650')
$apiVT.Add('apiHost', "https://api-vt.is.strath.ac.uk/") # volume testing
$apiVT.Add('securityEnabled', $true)


$apiLIVE = @{}
### Regenerate using login_api.ps1
$apiLIVE.Add('deviceID','.49586398839555847681679764695362417986')
$apiLIVE.Add('tokenID','B0686C80A3FCF7EFAF731DC407B1006DE30084B5134AB917AD5AF97BBA17E622MIS10010-206732287')
$apiLIVE.Add('apiHost', "https://hub.is.strath.ac.uk/")
$apiLIVE.Add('securityEnabled', $true)

$apiAPI = @{}
### Regenerate using login_api.ps1
$apiAPI.Add('deviceID','.63714095958276241193134999984677907521')
$apiAPI.Add('tokenID','B0686C80A3FCF7EFB2B9B71F931592A5894560EE8303BFE34C4CE1D99EE88E7EMIS10010-206592346')
$apiAPI.Add('apiHost', "https://api.is.strath.ac.uk/")
$apiAPI.Add('securityEnabled', $true)

# hash of hashes to lookup from command line
$apiList = @{}
$apiList.Add("TEST", $apiTEST)
$apiList.Add("VT", $apiVT)
$apiList.Add("LIVE", $apiLIVE)
$apiList.Add("API", $apiAPI)
$apiList.Add("DEV", $apiDEV)




############################
## FUNCTIONS
############################

#*=============================================
#* Function: makesqlProcFunc
#* Variables: $sqlProc (the SQL query)
#*            ,$sLogMsg message to log
#*            ,$SQLLoadDatabase (taken from global variables)
#*            ,$SQLServer (taken from global variables)
#*=============================================
#* Purpose:
#* trap errors in sql queries and end script
#*=============================================
function makesqlProcFunc ([string]$sqlProc,[string]$sLogMsg) {

	# sqlProcFunc "exec $sqlProc" $SQLLoadDatabase $SQLServer
    sqlProcQuery $sqlProc
	$logType = "Info";
	logFunc $logCmd $portal $logType $sLogMsg ([System.Data.DataSet]$ds);
}



#*=============================================
#* Function: sqlProcQuery
#* Variables: $pQuery (the stored proc)
#*            
#*=============================================
#* Purpose:
#* trap errors in sql queries and end script
#*=============================================
function sqlProcQuery([string]$pQuery)
{
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand

    $sqlDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCmd

    $sqlResults = New-Object System.Data.DataTable

    try {

        $sqlConnection.ConnectionString = $con.ConnectionString

        $sqlCmd.Connection = $sqlConnection
        $sqlCmd.CommandText = $pQuery
        $sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $sqlCmd.CommandTimeout = 300

        $sqlConnection.Open()

        $sqlDataAdapter.Fill($sqlResults) | Out-Null

    }
    catch {
        #$noError = $false
        $logMsg = $_.Exception.Message;
        $logType = "Error";
	    logFunc $logCmd $portal $logType $LogMsg ([System.Data.DataSet]$ds);
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
#* Variables: $logCmd (the PS command generating the message)
#*            ,$portal (always 0), $logType (type of log entry, i.e. warning, error, etc.)
#*            ,$logMsg (the text of the message),$dsx (the dataset holding the entry)
#*=============================================
#* Purpose:
#* commits the log message through ADO.NET
#*=============================================
function logFunc ([string]$logCmd,[int]$portal,[string]$logType,[string]$logMsg,[System.Data.DataSet]$dsx) {
	if($debug){
		Write-Host $logMsg;
	} else {
		$dt = $dsx.tables["PSLog"]
		$newRow = $dt.NewRow()
		$newRow["PSLogCommand"] = $logCmd
		$newRow["PSLogType"] = $logType
		$newRow["PSLogMessage"] = $logMsg
		$newrow["PortalID"] = $portal
		$dt.Rows.Add($newRow)


		$cmd = New-Object System.Data.SqlClient.SqlCommand
		$cmd.CommandText = "INSERT INTO dbo.EWDS_PSLog
		(PSLogCommand, PortalID, PSLogType, PSLogMessage)
		VALUES (@PSLogCommand, @PortalID, @PSLogType, @PSLogMessage)"
		$cmd.Connection = $con

		# Add parameters to pass values to the INSERT statement
		$cmd.Parameters.Add("@PSLogCommand", "nvarchar", 250, "PSLogCommand") | Out-Null
		$cmd.Parameters.Add("@PSLogType", "nvarchar", 50, "PSLogType") | Out-Null
		$cmd.Parameters.Add("@PSLogMessage", "nvarchar", 2000, "PSLogMessage") | Out-Null
		$cmd.Parameters.Add("@PortalID", "int", 0,"PortalID") | Out-Null

		# Set the InsertCommand property
		$da.InsertCommand = $cmd

		# Update the database
		$RowsInserted = $da.Update($dt)

	}

	# Display the number of rows inserted
	# Write-Host Number of rows inserted: $RowsInserted

	if ($logType -eq "Error") {
        Send-MailMessage -From ewds@strath.ac.uk -To ewds@strath.ac.uk -Subject "EWDS5 Applicant Transfer service error" -Body "ApplicantTransfer service query error. The error message was:  $logMsg" ;
        $con.close()
        break
    }

}

<# *********************************************************************************************
*   API Tools Section (replace with Azure AD)
********************************************************************************************* #>
function GenerateMAC([string] $serviceName, [string] $deviceID, [string] $tokenID, [string] $timeStamp)
{
    
    [string] $initialConcat = -join($serviceName.ToUpper(), $tokenID, $timeStamp)

    [int] $asciiTotal = 0

    foreach ($c in $initialConcat.ToCharArray()) {
        $asciiTotal += [int]$c
    }

    [string] $valueToHash = -join([string]$asciiTotal, $deviceID)

    $md5Object = New-Object System.Security.Cryptography.MD5CryptoServiceProvider

    $hashedValue = $md5Object.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($valueToHash));

    [string] $returnValue = [System.BitConverter]::ToString($hashedValue)

    $returnValue = $returnValue.Replace("-", "")

    return $returnValue
}
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

function CallAPI([string] $url, [bool] $securityEnabled, [string] $tokenID, [string] $timestamp, [string] $mac)
{
    $headers = @{}

    if($securityEnabled -eq $true)
    {
        $headers.Add("x-strath-api-tokenid", $tokenID)
        $headers.Add("x-strath-api-timestamp", $timestamp)
        $headers.Add("x-strath-api-mac", $mac)
    }

    # Build search parameters from the separate function
    # $searchParameters = SearchParameters
    # $url = -join($url, $searchParameters)

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
#TODO this is not robust. Check that the value is valid
if($Args[0]){
    $envIH = $Args[0]
    #$apiService = $Args[0]
    if($apiList.ContainsKey( $envIH ) ){
        $apiService = $apiList[$envIH]
        $filePath = "$pathRoot\$envIH-$serviceName.json"
        $archivePath = "$pathRoot\ARCHIVE_$envIH_$serviceName.json"
    } else {
        #LogFunc $thisCmd $portal "Error" "No API Service"
        Exit
    }
} else {
    $apiService = $apiList.$envIH
}

if($Args[1]){
    if($Args[1] -eq "DEBUG"){
        $debug = $true
    }
}

if($apiService.apiHost -eq "https://api-dev.is.strath.ac.uk/"){
    $debug = $true
}


# Open EWDS_PSLog:
# ===========
# Create SqlConnection object and define connection string
$con = New-Object System.Data.SqlClient.SqlConnection
$con.ConnectionString = "Server=$SQLServer; Database=$SQLLoadDatabase; Integrated Security=true"
$con.open()

# Create SqlDataAdapter object and set the command
$da = New-Object System.Data.SqlClient.SqlDataAdapter
# Create the DataSet object
$ds = New-Object System.Data.DataSet

# Instantiate datatable for use by logging function
# Create SqlCommand object, define command text, and set the connection
$cmdGetLog = New-Object System.Data.SqlClient.SqlCommand
$cmdGetLog.CommandText = "SELECT TOP 1 * FROM [dbo].[EWDS_PSLog]"
# need at least one record to work with table

$cmdGetLog.Connection = $con
$da.SelectCommand = $cmdGetLog
$da.Fill($ds, "PSLog") | Out-Null

# initialise logging
$logType = "Start"
$logMsg = "$serviceName in $envIH update process initiated"
logFunc $logCmd $portal $logType $logMsg ([System.Data.DataSet]$ds)

if($getAPI){
    # TRY-CATCH get data from API 
    # save as variable
    # ==================
    try {

        # service name defined at beginning of the script
        $serviceNameLower = $serviceName.ToLower()
        $apiUrl = $apiService.apiHost + "api/service/$serviceNameLower"

        # timestamp is hardcoded
        $timeStamp = "1463060420"

        $mac = GenerateMAC $serviceName $apiService.deviceID $apiService.tokenID $timeStamp

        $response = CallAPI $apiUrl $apiService.securityEnabled $apiService.tokenID $timeStamp $mac

        ## BREAKPOINT HERE ##
        if(!$response.data){
            $logType = "Warning";
            $logMsg = "No Data: response.header.description = " + $response.header.description + ": " + $response.header.result_description
                logFunc $logCmd $portal $logType $logMsg ([System.Data.DataSet]$ds)
            Exit
        }
        else{

                # save a copy of the raw data
                $rptostring = $response.data | ConvertTo-Json -Compress
                $countA = $response.data.applicants.count
                
                $logType = "Info";
                $logMsg = "Records found $countA"
                    logFunc $logCmd $portal $logType $logMsg ([System.Data.DataSet]$ds)

        }

    
    }
    catch {
        $proceed = $false
        $ErrorMessage = $_.Exception.Message

        if ($debug ) {
            write-host $ErrorMessage
        } else {
            $logType = "Error";
            $logMsg = "EWDS5 ApplicantTransfer failed up update data from IH. The error message was: $ErrorMessage"
            Send-MailMessage -From ewds@strath.ac.uk -To ewds@strath.ac.uk -Subject "HaSS Applicant Transfer Read failure" -Body $logMsg;
                logFunc $logCmd $portal $logType $logMsg ([System.Data.DataSet]$ds)

        }

    }
}


# Clean up files
# ===============
if (($proceed) -and ($getAPI)){

	# delete backup json file
	If (Test-Path $archivePath){
		Remove-Item $archivePath ;
		$logType = "Info";
		$logMsg = "Previous $envIH-$serviceName archive deleted";
		logFunc $logCmd $portal $logType $logMsg ([System.Data.DataSet]$ds);
	} else {
		$logType = "Info";
		$logMsg = "Previous $envIH-$serviceName archive NOT found";
		logFunc $logCmd $portal $logType $logMsg ([System.Data.DataSet]$ds);
	}

	# rename previous day's json file
    If (Test-Path $filePath){
		Copy-Item $filePath $archivePath ;
		Remove-Item $filePath
		$logType = "Info";
		$logMsg = "Previous $filePath copied to archive";
		logFunc $logCmd $portal $logType $logMsg ([System.Data.DataSet]$ds);
	} else {
		$logType = "Info";
		$logMsg = "Previous $filePath NOT found";
		logFunc $logCmd $portal $logType $logMsg ([System.Data.DataSet]$ds);
	}

    # Save current data to file
    $rptostring  | Out-File -FilePath $filePath
    $logType = "Info";
    $logMsg = "$filePath created";
    logFunc $logCmd $portal $logType $logMsg ([System.Data.DataSet]$ds);
}

# Import new JSON file
# ===============
if ($proceed) {
    If ((Test-Path $filePath) -and ($filePath -eq "d:\PS\ApplicantTransfer\LIVE-pvg_pgde_api.json")){ 
        # NOTE path is hard coded in the stored proc to d:\PS\ApplicantTransfer\LIVE-pvg_pgde_api.json

        # do sql to load in        
        $logMsg = "Import new JSON into ApplicantsTransfer table";
	    makesqlProcFunc $SQLLoadProc $logMsg
       
        # do sql to merge
        $logMsg = "Merge ApplicantsTransfer table into Applicants table";
	    makesqlProcFunc $SQLMergeProc $logMsg

    } else {
        $logType = "Error";
        $logMsg = "EWDS5 ApplicantTransfer JSON file not found"
        if(!$debug){
            Send-MailMessage -From ewds@strath.ac.uk -To ewds@strath.ac.uk -Subject "HaSS Applicant Transfer Read failure" -Body $logMsg;
        }
        logFunc $logCmd $portal $logType $logMsg ([System.Data.DataSet]$ds)

    }

}

$logType = "End";
$logMsg = "$envIH-$serviceName update process completed"
logFunc $logCmd $portal $logType $logMsg ([System.Data.DataSet]$ds);

if ($proceed) {
    # Close the connection
    $con.close();
}