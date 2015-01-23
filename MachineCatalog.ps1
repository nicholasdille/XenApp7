Set-StrictMode -Version 2

Add-PSSnapin Citrix*

function New-MachineCatalog {
    <#
    .SYNOPSIS
    Creates or duplicates a new catalog
    .DESCRIPTION
    XXX
    .PARAMETER Name
    Name of the new catalog
    .PARAMETER Description
    Description of the new catalog
    .PARAMETER AllocationType
    Allocation type of the catalog
    .PARAMETER ProvisioningType
    Provisioning type of the catalog
    .PARAMETER PersistUserChanges
    Whether and how to persist user changes
    .PARAMETER SessionSupport
    How many sessions are permitted
    .PARAMETER CatalogParams
    Hash of settings for new broker catalog
    .PARAMETER MasterImageVM
    Path to master image
    .PARAMETER CpuCount
    Number of vCPUs for virtual machines
    .PARAMETER MemoryMB
    Memory in MB for virtual machines
    .PARAMETER CleanOnBoot
    Whether to discard changes on boot
    .PARAMETER UsePersonalVDiskStorage
    Whether to use Personal vDisk
    .PARAMETER NamingScheme
    Naming scheme for new virtual machines
    .PARAMETER NamingSchemeType
    Type of naming scheme
    .PARAMETER OU
    Organizational unit for new virtual machines
    .PARAMETER Domain
    Domain for new virtual machines
    .PARAMETER HostingUnitName
    Hosting connection to use
    .PARAMETER Suffix
    Suffix to be added to name of the catalog
    .EXAMPLE
    XXX Explicit
    .EXAMPLE
    Get-BrokerCatalog | New-MachineCatalog -Suffix 'test'
    .NOTES
    Thanks to Aaron Parker (@stealthpuppy) for the original code (http://stealthpuppy.com/xendesktop-mcs-machine-catalog-powershell/)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Name of the new catalog',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory=$False,HelpMessage='Description of the new catalog',ParameterSetName='Explicit')]
        #[ValidateNotNullOrEmpty()]
        [string]
        $Description
        ,
        [Parameter(Mandatory=$True,HelpMessage='Allocation type of the catalog',ParameterSetName='Explicit')]
        [ValidateSet('Static','Permanent','Random')]
        [string]
        $AllocationType
        ,
        [Parameter(Mandatory=$True,HelpMessage='Provisioning type of the catalog',ParameterSetName='Explicit')]
        [ValidateSet('Manual','PVS','MCS')]
        [string]
        $ProvisioningType
        ,
        [Parameter(Mandatory=$True,HelpMessage='Whether and how to persist user changes',ParameterSetName='Explicit')]
        [ValidateSet('OnLocal','Discard','OnPvd')]
        [string]
        $PersistUserChanges
        ,
        [Parameter(Mandatory=$True,HelpMessage='How many sessions are permitted',ParameterSetName='Explicit')]
        [ValidateSet('SingleSession','MultiSession')]
        [string]
        $SessionSupport
        ,
        [Parameter(Mandatory=$True,HelpMessage='Path to master image',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [string]
        $MasterImageVM
        ,
        [Parameter(Mandatory=$True,HelpMessage='Number of vCPUs for virtual machines',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [int]
        $CpuCount
        ,
        [Parameter(Mandatory=$True,HelpMessage='Memory in MB for virtual machines',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [int]
        $MemoryMB
        ,
        [Parameter(Mandatory=$True,HelpMessage='Whether to discard changes on boot',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [bool]
        $CleanOnBoot
        ,
        [Parameter(Mandatory=$False,HelpMessage='Whether to use Personal vDisk',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [bool]
        $UsePersonalVDiskStorage = $False
        ,
        [Parameter(Mandatory=$True,HelpMessage='Naming scheme for new virtual machines',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [string]
        $NamingScheme
        ,
        [Parameter(Mandatory=$True,HelpMessage='Type of naming scheme',ParameterSetName='Explicit')]
        [ValidateSet('Numeric','Alphabetic')]
        [string]
        $NamingSchemeType
        ,
        [Parameter(Mandatory=$True,HelpMessage='Organizational unit for new virtual machines',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OU
        ,
        [Parameter(Mandatory=$True,HelpMessage='Domain for new virtual machines',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Domain
        ,
        [Parameter(Mandatory=$True,HelpMessage='Hosting connection to use',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [string]
        $HostingUnitName
        ,
        [Parameter(Mandatory=$True,HelpMessage='Collection of catalogs to be duplicated',ParameterSetName='CreateCatalogFromParam',ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [psobject[]]
        $CatalogParams
        ,
        [Parameter(Mandatory=$False,HelpMessage='Suffix to be added to name of the catalog',ParameterSetName='CreateCatalogFromParam')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Suffix = ''
    )

    Begin {
        Write-Debug ('[{0}] Process' -f $MyInvocation.MyCommand)
    }

    Process {
        if ($CatalogParams) {
            foreach ($Catalog in $CatalogParams) {
                $Catalog.Name += $Suffix
                $Catalog.CleanOnBoot = $Catalog.CleanOnBoot -eq 'True'
                Write-Verbose ('[{0}] Calling recursively to create catalog with name {1}' -f $MyInvocation.MyCommand, $Catalog.Name)
                New-MachineCatalog `                    -Name $Catalog.Name -Description $Catalog.Description -AllocationType $Catalog.AllocationType -ProvisioningType $Catalog.ProvisioningType -PersistUserChanges $Catalog.PersistUserChanges -SessionSupport $Catalog.SessionSupport `
                    -Domain $Catalog.Domain -OU $Catalog.OU -NamingScheme $Catalog.NamingScheme -NamingSchemeType $Catalog.NamingSchemeType `
                    -MasterImageVM $Catalog.MasterImageVM -CpuCount $Catalog.CpuCount -MemoryMB $Catalog.MemoryMB -CleanOnBoot $Catalog.CleanOnBoot `
                    -HostingUnitName $Catalog.HostingUnitName
            }

        } else {
            if (Get-BrokerCatalog -Name $Name -Verbose:$False -ErrorAction SilentlyContinue) {
                throw ('[{0}] Broker catalog with name {1} already exists. Aborting.' -f $MyInvocation.MyCommand, $Name)
            }
            Write-Verbose ('[{0}] Creating broker catalog with name {1}' -f $MyInvocation.MyCommand, $Name)
            $NewBrokerCatalog = New-BrokerCatalog -Name $Name -Description $Description -AllocationType $AllocationType -ProvisioningType $ProvisioningType -PersistUserChanges $PersistUserChanges -SessionSupport $SessionSupport -Verbose:$False
            
            if (Get-AcctIdentityPool -IdentityPoolName $Name -Verbose:$False -ErrorAction SilentlyContinue) {
                throw ('[{0}] Account identity pool with name {1} already exists. Aborting.' -f $MyInvocation.MyCommand, $Name)
            }
            Write-Verbose ('[{0}] Creating account identity pool with name {1}' -f $MyInvocation.MyCommand, $Name)
            $NewAcctIdentityPool = New-AcctIdentityPool -Domain $Domain -IdentityPoolName $Name -NamingScheme $NamingScheme -NamingSchemeType $NamingSchemeType -OU $OU -Verbose:$False
            Set-BrokerCatalogMetadata -CatalogId $NewBrokerCatalog.Uid -Name 'Citrix_DesktopStudio_IdentityPoolUid' -Value ([guid]::NewGuid()) -Verbose:$False
            
            if (Get-ProvScheme -ProvisioningSchemeName $Name -Verbose:$False -ErrorAction SilentlyContinue) {
                throw ('[{0}] Provisioning scheme with name {1} already exists. Aborting.' -f $MyInvocation.MyCommand, $Name)
            }
            Write-Verbose ('[{0}] Creating provisioning scheme with name {1}' -f $MyInvocation.MyCommand, $Name)
            $NewProvTaskId = New-ProvScheme -ProvisioningSchemeName $Name -HostingUnitName $HostingUnitName -IdentityPoolName $Name -MasterImageVM $MasterImageVM -VMCpuCount $CpuCount -VMMemoryMB $MemoryMB -CleanOnBoot:$CleanOnBoot -RunAsynchronously -Verbose:$False

            $ProvTask = Get-ProvTask -TaskId $NewProvTaskId
            Write-Debug ('[{0}] Tracking progress of creation process for provisioning scheme with name {1}' -f $MyInvocation.MyCommand, $Name)
            $CurrentProgress = 0
            While ($ProvTask.Active) {
                Try { $CurrentProgress = If ( $ProvTask.TaskProgress ) { $ProvTask.TaskProgress } Else {0} } Catch { }

                Write-Progress -Activity ('[{0}] Creating Provisioning Scheme with name {1} (copying and composing master image)' -f $MyInvocation.MyCommand, $Name) -Status ('' + $CurrentProgress + '% Complete') -PercentComplete $CurrentProgress
                Start-Sleep -Seconds 10
                $ProvTask = Get-ProvTask -TaskID $NewProvTaskId
            }
            $NewProvScheme = Get-ProvScheme -ProvisioningSchemeName $Name

            if (-Not $ProvTask.WorkflowStatus -eq 'Completed') {
                throw ('[{0}] Creation of provisioning scheme with name {1} failed. Aborting.' -f $MyInvocation.MyCommand, $Name)

            } else {
                Set-BrokerCatalog -Name $Name -ProvisioningSchemeId $NewProvScheme.ProvisioningSchemeUid -Verbose:$False
                $Controllers = Get-BrokerController -Verbose:$False | select -ExpandProperty DNSName -Verbose:$False
                Add-ProvSchemeControllerAddress -ProvisioningSchemeName $Name -ControllerAddress $Controllers -Verbose:$False
            }
        }
    }

    End {
        Write-Debug ('[{0}] End' -f $MyInvocation.MyCommand)
    }
}

#TODO
function Sync-MachineCatalog {
    <#
    .SYNOPSIS
    Ensures the same amount of resource in the new broker catalog
    .DESCRIPTION
    Creates the same number of VMs in the new broker catalog as there are VMS present in the old broker catalog
    .PARAMETER BrokerCatalog
    The currently active broker catalog
    .PARAMETER NewBrokerCatalog
    The new broker catalog
    .EXAMPLE
    Sync-ProvVM -BrokerCatalog 'BrokenCatalog' -NewBrokerCatalog 'FixedBrokerCatalog'
    .NOTES
    Future improvements: Accept active broker catalogs on the pipeline or parameter and assume that new broker catalogs have the same name with a given suffix
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='The currently active broker catalog',ParameterSetName='Sync')]
        [Parameter(Mandatory=$True,HelpMessage='The new broker catalog',ParameterSetName='Count')]
        [ValidateNotNullOrEmpty()]
        [string]
        $BrokerCatalog
        ,
        [Parameter(Mandatory=$True,HelpMessage='The new broker catalog',ParameterSetName='Sync')]
        [ValidateNotNullOrEmpty()]
        [string]
        $NewBrokerCatalog
        ,
        [Parameter(Mandatory=$True,HelpMessage='The new broker catalog',ParameterSetName='Count')]
        [ValidateNotNullOrEmpty()]
        [int]
        $Count
    )

    if ($BrokerCatalog -And $NewBrokerCatalog) {
        $VmCount = Get-ProvVM -ProvisioningSchemeUid $BrokerCatalog.ProvisioningSchemeId | Measure-Object -Line | Select-Object -ExpandProperty Lines
        Sync-MachineCatalog -BrokerCatalog $NewBrokerCatalog -Count $VmCount
    }

    $AcctIdentityPool = Get-AcctIdentityPool -IdentityPoolName $BrokerCatalog.Name
    $ProvScheme = Get-ProvScheme -ProvisioningSchemeName $BrokerCatalog.Name

    $AdAccounts = New-AcctADAccount -IdentityPoolName $AcctIdentityPool.IdentityPoolName -Count $VmCount
    $ProvTaskId = New-ProvVM -ADAccountName @($AdAccounts.SuccessfulAccounts) -ProvisioningSchemeName $ProvScheme.ProvisioningSchemeName -RunAsynchronously
    $ProvTask = Get-ProvTask -TaskId $ProvTaskId

    $CurrentProgress = 0
    While ( $ProvTask.Active -eq $True ) {
        Try { $CurrentProgress = If ( $ProvTask.TaskProgress ) { $ProvTask.TaskProgress } Else {0} } Catch { }

        Write-Progress -Activity 'Creating Virtual Machines' -Status ($CurrentProgress + '% Complete') -PercentComplete $CurrentProgress
        Start-Sleep -Seconds 10
        $ProvTask = Get-ProvTask -TaskID $ProvTaskId
    }

    $ProvVMs = Get-ProvVM -AdminAddress $adminAddress -ProvisioningSchemeUid $ProvScheme.ProvisioningSchemeUid
    ForEach ($ProvVM in $ProvVMs) {
        Lock-ProvVM -ProvisioningSchemeName $ProvScheme.ProvisioningSchemeName -Tag 'Brokered' -VMID @($ProvVM.VMId)
        New-BrokerMachine -CatalogUid $catalogUid.Uid -MachineName $ProvVM.ADAccountName
    }
}

function ConvertFrom-MachineCatalog {
    <#
    .SYNOPSIS
    Convert a broker catalog to a hash
    .DESCRIPTION
    XXX
    .PARAMETER BrokerCatalog
    Collection of broker catalog to convert to a hash
    .PARAMETER ExcludeProvScheme
    Whether to exclude the provisioning scheme
    .PARAMETER ExcludeAcctIdentityPool
    Whether to exclude the account identity pool
    .PARAMETER ExcludeHostingUnit
    Whether to exclude the hosting unit
    .EXAMPLE
    ConvertFrom-MachineCatalog -BrokerCatalog (Get-BrokerCatalog)
    .EXAMPLE
    Get-BrokerCatalog | ConvertFrom-MachineCatalog
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Collection of broker catalog to convert to a hash',ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [Citrix.Broker.Admin.SDK.Catalog[]]
        $BrokerCatalog
        ,
        [Parameter(Mandatory=$False,HelpMessage='Whether to exclude the provisioning scheme')]
        [switch]
        $ExcludeProvScheme
        ,
        [Parameter(Mandatory=$False,HelpMessage='Whether to exclude the account identity pool')]
        [switch]
        $ExcludeAcctIdentityPool
        ,
        [Parameter(Mandatory=$False,HelpMessage='Whether to exclude the hosting unit')]
        [switch]
        $ExcludeHostingUnit
    )

    Process {
        Write-Debug ('[{0}] Enumerating members of BrokerCatalog' -f $MyInvocation.MyCommand)

        foreach ($Catalog in $BrokerCatalog) {
            Write-Verbose ('[{0}] [{1}] Processing BrokerCatalog.Name={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $Catalog.Name)

            $CatalogParams = New-Object psobject -Property @{
                    Name               = $Catalog.Name
                    Description        = $Catalog.Description
                    AllocationType     = $Catalog.AllocationType
                    ProvisioningType   = $Catalog.ProvisioningType
                    PersistUserChanges = $Catalog.PersistUserChanges
                    SessionSupport     = $Catalog.SessionSupport
            }

            if (-Not $Catalog.ProvisioningSchemeId) {
                Write-Verbose ('[{0}] [{1}] No provisioning scheme specified' -f $MyInvocation.MyCommand, $Catalog.UUID)
                $CatalogParams
                continue
            }

            if (-Not $ExcludeProvScheme) {
                Write-Debug ('[{0}] [{1}] Accessing ProvisioningScheme' -f $MyInvocation.MyCommand, $Catalog.UUID)
                $ProvScheme = Get-ProvScheme -ProvisioningSchemeUid $Catalog.ProvisioningSchemeId -Verbose:$False
                Write-Verbose ('[{0}] [{1}] Retrieved ProvisioningScheme.Name={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $Catalog.Name)

                $CatalogParams | Add-Member -NotePropertyMembers @{
                        #ProvisioningSchemeName  = $ProvScheme.ProvisioningSchemeName
                        MasterImageVM           = $ProvScheme.MasterImageVM
                        CpuCount                = $ProvScheme.CpuCount
                        MemoryMB                = $ProvScheme.MemoryMB
                        CleanOnBoot             = $ProvScheme.CleanOnBoot
                        #UsePersonalVDiskStorage = $ProvScheme.UsePersonalVDiskStorage
                }
            }

            if (-Not $ExcludeAcctIdentityPool) {
                Write-Debug ('[{0}] [{1}] Accessing AcctIdentityPool' -f $MyInvocation.MyCommand, $Catalog.UUID)
                $AcctIdentityPool = Get-AcctIdentityPool -IdentityPoolUid $ProvScheme.IdentityPoolUid -Verbose:$False
                Write-Verbose ('[{0}] [{1}] Retrieved AcctIdentityPool.IdentityPoolName={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $AcctIdentityPool.IdentityPoolName)

                $CatalogParams | Add-Member -NotePropertyMembers @{
                        #IdentityPoolName   = $AcctIdentityPool.IdentityPoolName
                        NamingScheme       = $AcctIdentityPool.NamingScheme
                        NamingSchemeType   = $AcctIdentityPool.NamingSchemeType
                        OU                 = $AcctIdentityPool.OU
                        Domain             = $AcctIdentityPool.Domain
                }
            }

            if (-Not $ExcludeHostingUnit) {
                Write-Debug ('[{0}] [{1}] Accessing HostingUnit' -f $MyInvocation.MyCommand, $Catalog.UUID)
                $HostingUnit = Get-ChildItem XDHyp:\HostingUnits -Verbose:$False | Where-Object HostingUnitUid -eq $ProvScheme.HostingUnitUid -Verbose:$False
                Write-Verbose ('[{0}] [{1}] Retrieved HostingUnit.HostingUnitName={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $HostingUnit.HostingUnitName)

                $CatalogParams | Add-Member -NotePropertyMembers @{
                        HostingUnitName    = $HostingUnit.HostingUnitName
                }
            }

            Write-Debug ('[{0}] [{1}] Returning custom object with parameters for BrokerCatalog.Name={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $Catalog.Name)
            $CatalogParams
            Write-Debug ('[{0}] [{1}] Finished processing BrokerCatalog.Name={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $Catalog.Name)
        }
    }
}

function ConvertTo-MachineCatalog {
    <#
    .SYNOPSIS
    Creates broker catalogs from a CSV file
    .DESCRIPTION
    The contents of the specified file is parsed using ConvertFrom-Csv and piped to New-MachineCatalog
    .PARAMETER Path
    Path of CSV file to import catalogs from
    .EXAMPLE
    ConvertTo-MachineCatalog -Path .\Catalogs.csv
    .NOTES
    Future improvement: Accept content on pipeline as well as parameter - instead of path
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Path of CSV file to import catalogs from')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    if (-Not (Test-Path -Path $Path)) {
        throw ('[{0}] File <{1}> does not exist. Aborting.' -f $MyInvocation.MyCommand, $Path)
    }

    Get-Content -Path $Path | ConvertFrom-Csv | New-MachineCatalog
}

function Export-MachineCatalog {
    <#
    .SYNOPSIS
    Exports all broker catalogs to the specified CSV file
    .DESCRIPTION
    The output of Get-BrokerCatalog is piped through ConvertFrom-MachineCatalog and written to a CSV file
    .PARAMETER Path
    Path of the CSV file to export broker catalogs to
    .EXAMPLE
    Export-MachineCatalog -Path .\Catalogs.csv
    .NOTES
    Future improvement: Accept BrokerCatalog from pipeline and parameter, all catalogs should be default
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Path of the CSV file to export broker catalogs to')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    if (Test-Path -Path $Path) {
        throw ('[{0}] File <{1}> already exists. Aborting.' -f $MyInvocation.MyCommand, $Path)
    }

    Get-BrokerCatalog | ConvertFrom-MachineCatalog | ConvertTo-Csv | Out-File -FilePath $Path
}

function Remove-MachineCatalog {
    <#
    .SYNOPSIS
    Removes a machine catalog with all associated objects
    .DESCRIPTION
    The following objects will be removed: virtual machines, computer accounts, broker catalog, account identity pool, provisioning scheme
    .PARAMETER Name
    Name of the objects to remove
    .EXAMPLE
    Remove-BrokerCatalog -Name 'test'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Name of the objects to remove')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    Get-BrokerMachine | Where-Object CatalogName -eq $Name | Remove-BrokerMachine
    Get-ProvVM -ProvisioningSchemeName $Name | foreach {
        Unlock-ProvVM -ProvisioningSchemeName $Name -VMID $_.VMId
        Remove-ProvVM -ProvisioningSchemeName $Name -VMName $_.VMName
    }
    Get-AcctADAccount    -IdentityPoolName $Name       -ErrorAction SilentlyContinue | Remove-AcctADAccount -IdentityPoolName $Name
    Get-BrokerCatalog    -Name $Name                   -ErrorAction SilentlyContinue | Remove-BrokerCatalog
    Get-AcctIdentityPool -IdentityPoolName $Name       -ErrorAction SilentlyContinue | Remove-AcctIdentityPool
    Get-ProvScheme       -ProvisioningSchemeName $Name -ErrorAction SilentlyContinue | Remove-ProvScheme
}

function Rename-MachineCatalog {
    <#
    .SYNOPSIS
    Renames a machine catalog
    .DESCRIPTION
    The following objects are renamed: BrokerCatalog, ProvScheme, AcctIdentityPool
    .PARAMETER Name
    Name of the existing catalog
    .PARAMETER NewName
    New name for the catalog
    .EXAMPLE
    Rename-MachineCatalog -Name 'OldName' -NewName 'NewName'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Name of the existing catalog')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory=$True,HelpMessage='New name for the catalog')]
        [ValidateNotNullOrEmpty()]
        [string]
        $NewName
    )

    Rename-BrokerCatalog    -Name                   $Name -NewName                   $NewName
    Rename-ProvScheme       -ProvisioningSchemeName $Name -NewProvisioningSchemeName $NewName
    Rename-AcctIdentityPool -IdentityPoolName       $Name -NewIdentityPoolName       $NewName
}

#TODO
function Update-DeliveryGroup {
    # Add-BrokerMachine
    # Remove-BrokerMachine
}