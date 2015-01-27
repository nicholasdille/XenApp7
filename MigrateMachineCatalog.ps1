. (Join-Path -Path $PSScriptRoot -ChildPath 'MachineCatalog.ps1')

New-HostingConnection -Name vcenter-01 -ConnectionType VCenter -HypervisorAddress https://vcenter-01.example.com/sdk -HypervisorCredential (Get-Credential)
New-HostingResource -Name cluster-01 -HypervisorConnectionName vcenter-01 -ClusterName cluster-01 -NetworkName ('vlan_100','vlan_101') -StorageName ('datastore1','datastore2')

Export-MachineCatalog -Path .\MachineCatalog.csv
# correct data as needed (e.g. HostingUnitName and MasterVMImage)

Get-Content .\MachineCatalog.csv | ConvertFrom-Csv | New-MachineCatalog -Suffix '-new' -Verbose

# for every catalog (example: Catalog_Office_DEV)
Sync-MachineCatalog -BrokerCatalogName Catalog_Office_DEV -NewBrokerCatalogName Catalog_Office_DEV-new -Verbose
Update-DeliveryGroup -Name Catalog_Office_DEV -CatalogName Catalog_Office_DEV-new
Remove-MachineCatalog -Name Catalog_Office_DEV
Rename-MachineCatalog -Name Catalog_Office_DEV-new -NewName Catalog_Office_DEV -Verbose