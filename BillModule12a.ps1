function Test-CloudFlare {
    <#
    .Synopsis
    Tests a connection to CloudFlare DNS
    .Description
    This command will test a single computer's or multiple computers' Internet connection to CloudFlare's One.One.One.One DNS Server.
    .Parameter Computername
    The Name or IP Address of the remote computer you wish to test.
    .EXAMPLE
    .\Test-CloudFlare -Computername DC1
    Example 1: Test connectivity to CloudFlare DNS on the specified computer.
    .NOTES
        Author: Bill Gilligan
        Last Edit: 2020-11-14
        Version 2.0: 
        - Script converted to function
        - Output commands moved to Get-PipeResults
        - Function outputs objects
        - Try/Catch added for exception handling
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [Alias('CN','Name')]
        [string[]]$Computername
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
            $TestCF = Test-NetConnection -ComputerName one.one.one.one -InformationLevel Detailed
            
            #Store needed properties in a new object
            $obj = [pscustomobject]@{ 'Computername' = $Computer
                        'PingSuccess' = $TestCF.PingSucceeded
                        'NameResolve' = $TestCF.NameResolutionSucceeded
                        'ResolvedAddresses' = $TestCF.ResolvedAddresses
            } #pscustomobject properties
            Write-Output $obj

            #Closes the session to the remote computer(s)
            Exit-PSSession
            Remove-PSSession $Session
        } Catch {
            Write-Host "Remote connection to $Computer failed." -ForegroundColor Red
        } #Try/Catch
    } #ForEach
    Write-Verbose "Finished running test."
} #function

function Get-PipeResults {
    <#
    .Synopsis
    Retrives and/or displays the results of a command from the pipeline.
    .Description
    This command will retrieve and/or display the results of the command from the pipeline based on the user's desired output.
    .Parameter InputObject
    Receives objects passed to it through the pipeline via the Write-Output cmdlet.
    .Parameter Path
    The name of the folder where results will be saved. The default location is the current user's home directory.
    .Parameter Output
    Specifies the destination of output when script is run. Acceptable values are:
        - Host (screen)
        - Text (.txt file)
        - CSV (.csv file)
    File outputs are saved to the user's home directory. The default destination is Host.
    .Parameter FileName
    The name of the file that will be saved when selecting either CSV or Text as the output parameter. The default value is PipeResults.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [object[]]$InputObject,
        [Parameter(Mandatory=$False)]
        [string]$Path = "$Env:USERPROFILE",
        [ValidateSet('Host','Text','CSV')]
        [string]$Output = "Host",
        [Parameter(Mandatory=$False)]
        [string]$FileName = "PipeResults"
    ) #Param

    ForEach ($Object in $InputObject) {
        #Displays results based on -Output parameter
        Write-Verbose "Receiving test results ..."
        $DateTime = Get-Date
        switch ($Output) {
            "Host" { $Object }
            "CSV" {
                Write-Verbose "Generating CSV Results file ..."
                $Object | Export-CSV -path $Path\$FileName.csv
            }
            "Text" {
                #Creates a text file containing the name of the computer being tested, the date/time, and the job output
                Write-Verbose "Generating results file ..."
                $Object | Out-File $Path\TestResults.txt
                $ObjCN = $Object.Computername
                Add-Content $Path\$FileName.txt -value "Computer Tested: $ObjCN"
                Add-Content $Path\$FileName.txt -value "Date/Time Tested: $DateTime"
                Add-Content $Path\$FileName.txt -value (Get-Content -path $Path\TestResults.txt)
                Remove-Item $Path\TestResults.txt
                Write-Verbose "Opening results ..."
                Notepad $Path\$FileName.txt
            }
        } #switch
    } #ForEach
} #function