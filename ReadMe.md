# PowerShell sample API to SQL Server
The repo demonstrates an approach for using PowerShell to 
* query an API
* load the response to a holding table on SQL server
* synchronise/merge the new data with an existing table

## Rationale
The approach was developed to run nightly loads from the corporate ERP to populate a local data cache that is drives business processes running on a satellite system. 

The approach is intended to be fault tolerant. At no point is the local data cache cleared, but is updated via a SQL Merge procedure that inserts, updates and deletes records extracted from the API.

The components are 
1. PowerShell Script
1. SQL scripts (load and merge)

## PowerShell script: CallAPIAndLoad.ps1
The script is designed to be as generic as possible. 
* The API connection code is a simple stub that uses GET request headers for security
* logging is to the console but uses a function than can be adapted to save to the database, etc.
* File paths are required for the SQL load script, but placeholders are used here

### Anatomy
* SCRIPT variables - define variables specific to the running of the script
* STATIC variables - internal process variables
* Functions - called by the MAIN part of the script (each has its own notes)
* Main - the script body
    * read commandline variables
    * start logging
    * call the API
    * check for results
    * save results to disk (copy previous results file to archive)
    * call **load** stored proc
    * call **merge** stored proc
    * close log

## SQL SCripts
### Load
The load procedure drops the load table and recreates it from the JSON file downloaded by the PS script.

The script is taken from a live import.

### Merge
The procedure performs a MERGE to synchronise the load table with the **target** table that is active in the application. This avoids record locks, etc.

The target table includes 2 columns not in the load table
* created - defaults to GetDate(), set when an item is inserted
* updated - defaults to GetDate(), set when an item is inserted and updated

The output recordset itemises all the changes made to the Target table
* Action - INSERT, UPDATE or DELETE
* ApplicantNumber and ChoiceNumber - the composite key in this example
