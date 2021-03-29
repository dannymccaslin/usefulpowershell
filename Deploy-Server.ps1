#Deploy-Server.ps1
<#
.SYNOPSIS
Deploy-Server deploys a windows server from VCenter template,
.DESCRIPTION
What I just said above but more complicated
.PARAMETER Name
The name of the new vCenter VM and the name of the host. Must be distinct;
cannot be the name of an existing VM or Active Directory host
.PARAMETER IPAddress
The desired IP Address of the server
.PARAMETER ServerType
The type of installation, either "Core" or 'GUI" for Server Core or Desktop
Experience, respectively
.PARAMETER DataStore
The type of VM DataStore in vCenter. Default is Silver
.PARAMETER ESXiHost
The ESXi Host number on which the new VM will be installed. 
This should ne a 1 or 2. Default is 2
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, HelpMessage="Name of the Virtual Machine You want to create. This will also become the name of the Windows Server")]
    [string]
    $Name,

    [Parameter(Mandatory, HelpMessage="IP Address of the new server")]
    [string]
    $IPAddress,

    [Parameter(Mandatory, HelpMessage="Enter 'Core' for Server Core or 'GUI' for Server with Desktop Experience")]
    [ValidateSet("Core","GUI")]
    [string]
    $ServerType,

    [Parameter(HelpMessage="Choose Gold, Silver, or Tin for Simplivity Datastore (Default is Silver)")]
    [ValidateSet("Gold","Silver","Tin")]
    [string]
    $DataStore = "Silver",

    [Parameter(HelpMessage="Choose 1 for the first ESXI host, 2 for the second (Default is 2)")]
    [ValidateSet(1,2)]
    [int]
    $ESXiHost = 2
)
#Variables
$vcenterServer = vcenter.example.com
$vmHost1 = esxi1.example.com
$vmHost2 = esxi2.example.com
$VeeamServer = veeam.example.com
$ServerTargetOU = "OU=Servers,DC=example,DC=com"
$customSpecName = "Windows Custom Spec"
$SubnetMask = "255.255.255.0"
$Gateway = "192.168.1.1"
$dns1 = "192.168.1.2"
$dns2 = "192.168.1.3"
$localBackupLocation = "Local Backup Job"
$awsBackupLocation = "S3 Backup Job"

connect-viServer $vcenterServer
Write-Host "Setting the Customization Spec Nic Mapping . . . "    -BackgroundColor White -ForegroundColor DarkBlue

$customSpec = Get-OSCustomizationSpec -Name $customSpecName
Get-OSCustomizationNicMapping -OSCustomizationSpec $customSpec | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $IPAddress -SubnetMask $SubnetMask -DefaultGateway $Gateway -Dns $dns1,$dns2 -Confirm:$false
Get-OSCustomizationNicMapping -OSCustomizationSpec $customSpec

if ($ServerType -eq "GUI") {
    $VMTemplate = Get-Template -Name "GUI Template"
} elseif ($ServerType -eq "Core") {
    $VMTemplate = Get-Template -Name "CoreTemplate"
}

if ($ESXiHost -eq 1) {
    $VMHost = $vmHost1
} elseif ($ESXiHost -eq 2) {
    $VMHost = $vmHost2
}

if ($DataStore -eq "Silver"){
    $ds = "DatastoreSilver"
} elseif ($DataStore -eq "Gold") {
    $ds = "DatastoreGold"
} else {
    $ds = "Tin - NO BACKUPS"
    }

Write-Host "Creating VM From Template . . . "    -BackgroundColor White -ForegroundColor DarkBlue
New-VM -Name $Name -Template $VMTemplate -OSCustomizationSpec $customSpec -VMHost $VMHost -Datastore $ds | Start-VM

Write-Host "Adding new server to Veeam . . . " -BackgroundColor White -ForegroundColor DarkBlue
$session = New-Pssession -computername $VeeamServer
Invoke-command -session $session  -ScriptBlock {
    Import-Module -Name veeam.backup.powershell
    $backupJob = get-VBRJob -name $localBackupLocation
    $awsBackupJob = get-vbrJob -Name $awsBackupLocation
    Find-VBRViEntity -Name $args[0] | Add-VBRViJobObject -Job $backupJob 
    Find-VBRViEntity -Name $args[0] | Add-VBRViJobObject -Job $awsBackupJob 
    WriteHost "Local Backup Jobs:" -BackgroundColor White -ForegroundColor DarkBlue
    $backupJob.GetObjectsInJob() | Select-object Name, Type,ApproxSizeString,Location| ft
    Write-Host "S3 Backup Jobs" -BackgroundColor White -ForegroundColor DarkBlue
    $awsBackupJob.getObjectsInJob() | Select-object Name, Type,ApproxSizeString,Location| ft
} -Args $Name

Write-Host "Verifying that the server is added to Active Directory . . . " -BackgroundColor White -ForegroundColor DarkBlue

do {
    $ADCount = (Get-ADComputer $Name | Measure-Object).count
    sleep -s 30
} until ($ADCount -eq 1)

Write-Host "Moving Server to the proper OU . . . " -BackgroundColor White -ForegroundColor DarkBlue
Get-ADComputer $Name | Move-ADObject -TargetPath $ServerTargetOU
