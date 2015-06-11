function Remove-XDDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $AdminAddress = ('localhost')
    )

    Process {
        foreach ($Controller in $AdminAddress) {
            Write-Verbose ('[{0}] Configuring database for controller {1}' -f $MyInvocation.MyCommand, $Controller)

            Set-ConfigDBConnection                     -DBConnection $null -AdminAddress $Controller
            Set-AcctDBConnection                       -DBConnection $null -AdminAddress $Controller
            Set-HypDBConnection                        -DBConnection $null -AdminAddress $Controller
            Set-ProvDBConnection                       -DBConnection $null -AdminAddress $Controller
            Set-BrokerDBConnection                     -DBConnection $null -AdminAddress $Controller
            Set-EnvTestDBConnection                    -DBConnection $null -AdminAddress $Controller
            Set-SfDBConnection                         -DBConnection $null -AdminAddress $Controller
            Set-MonitorDBConnection -Datastore Monitor -DBConnection $null -AdminAddress $Controller
            Reset-MonitorDataStore  -DataStore Monitor
            Set-MonitorDBConnection                    -DBConnection $null -AdminAddress $Controller
            Set-LogDBConnection     -DataStore Logging -DBConnection $null -AdminAddress $Controller
            Reset-LogDataStore      -DataStore Logging
            Set-LogDBConnection                        -DBConnection $null -AdminAddress $Controller
            Set-AdminDBConnection                      -DBConnection $null -AdminAddress $Controller

            Write-Verbose ('[{0}] Done' -f $MyInvocation.MyCommand)
        }
    }
}

function Set-XDDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionString
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $AdminAddress = ('localhost')
    )

    Process {
        foreach ($Controller in $AdminAddress) {
            Write-Verbose ('[{0}] Configuring database for controller {1}' -f $MyInvocation.MyCommand, $Controller)

            Set-AdminDBConnection   -DBConnection $ConnectionString -AdminAddress $Controller
            Set-LogDBConnection     -DBConnection $ConnectionString -AdminAddress $Controller
            Set-ConfigDBConnection  -DBConnection $ConnectionString -AdminAddress $Controller
            Set-AcctDBConnection    -DBConnection $ConnectionString -AdminAddress $Controller
            Set-HypDBConnection     -DBConnection $ConnectionString -AdminAddress $Controller
            Set-ProvDBConnection    -DBConnection $ConnectionString -AdminAddress $Controller
            Set-BrokerDBConnection  -DBConnection $ConnectionString -AdminAddress $Controller
            Set-EnvTestDBConnection -DBConnection $ConnectionString -AdminAddress $Controller
            Set-SfDBConnection      -DBConnection $ConnectionString -AdminAddress $Controller
            Set-MonitorDBConnection -DBConnection $ConnectionString -AdminAddress $Controller
            Set-MonitorDBConnection -DBConnection $ConnectionString -AdminAddress $Controller -DataStore Monitor
            Set-LogDBConnection     -DBConnection $ConnectionString -AdminAddress $Controller -Datastore Logging

            Write-Verbose ('[{0}] Done' -f $MyInvocation.MyCommand)
        }
    }
}