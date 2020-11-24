function Test-CloudFlare {
    <#
    .Synopsis
    Tests a connection to CloudFlare DNS
    .Description
    This command will test a single computer's or multiple computers' Internet connection to CloudFlare's One.One.One.One DNS Server.
    .Parameter Computername
    The Name or IP Address of the remote computer you wish to test.
    .Parameter Path
    The name of the folder where results will be saved. The default location is the current user's home directory.
    .Parameter Output
    Specifies the destination of output when script is run. Acceptable values are:
        - Host (screen)
        - Text (.txt file)
        - CSV (.csv file)
    File outputs are saved to the user's home directory. The default destination is Host.
    .EXAMPLE
    .\Test-CloudFlare -Computername DC1
    Example 1: Test connectivity to CloudFlare DNS on the specified computer
    .EXAMPLE
    .\Test-CloudFlare -Computername DC1 -Output CSV
    Test connectivity to CloudFlare and write results to a different output
    .EXAMPLE 
    .\Test-CloudFlare -Computername DC1 -Path C:\Temp
    Test connectivity to CloudFlare and change the location where results files are saved
    .NOTES
        Author: Bill Gilligan
        Last Edit: 2020-11-13
        Version 1.11 - Added exception handling to the ForEach loop
                     - Modified object creation to use [pscustomobject]
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [Alias('CN','Name')]
        [string[]]$Computername,
        [Parameter(Mandatory=$False)]
        [string]$Path = "$Env:USERPROFILE",
        [ValidateSet('Host','Text','CSV')]
        [string]$Output = "Host"
    ) #Param

    ForEach ($Computer in $Computername) {
        Try {
            #Creates a new session to the remote computer(s)
            $params = @{'Computername' = $Computer
                    'ErrorAction' = 'Stop'
            } #params
            $Session = New-PSSession @params

            Write-Verbose "Connecting to $Computer ...."

            #Remotely runs Test-NetConnection to 1.1.1.1 on target computer(s) as a background job
            Write-Verbose "Testing connection to One.One.One.One on $Computername ..."
            Enter-PSSession $Session
            $DateTime = Get-Date
            $TestCF = Test-NetConnection -ComputerName one.one.one.one -InformationLevel Detailed
            
            #Store needed properties in a new object
            $obj = [pscustomobject]@{ 'Computername' = $Computer
                        'PingSuccess' = $TestCF.PingSucceeded
                        'NameResolve' = $TestCF.NameResolutionSucceeded
                        'ResolvedAddresses' = $TestCF.ResolvedAddresses
            } #pscustomobject properties

            #Closes the session to the remote computer(s)
            Exit-PSSession
            Remove-PSSession $Session
        } Catch {
            Write-Host "Remote connection to $Computer failed." -ForegroundColor Red
        } #Try/Catch
    } #ForEach

    #Displays results based on -Output parameter
    Write-Verbose "Receiving test results ..."
    switch ($Output) {
        "Host" {$obj}
        "CSV" {
            Write-Verbose "Generating results file ..."
            $obj | Export-CSV -path $Path\TestResults.csv
        }
        "Text" {
            #Creates a text file containing the name of the computer being tested, the date/time, and the job output
            Write-Verbose "Generating results file ..."
            $obj | Out-File $Path\TestResults.txt
            Add-Content $Path\RemTestNet.txt -value "Computer Tested: $Computer"
            Add-Content $Path\RemTestNet.txt -value "Date/Time Tested: $DateTime"
            Add-Content $Path\RemTestNet.txt -value (Get-Content -path $Path\TestResults.txt)
            Remove-Item $Path\TestResults.txt
            Write-Verbose "Opening results ..."
            Notepad $Path\RemTestNet.txt
        }
    } #switch

    Write-Verbose "Finished running test."
} #function