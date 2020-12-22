<#
.SYNOPSIS
    Gets VMWare Virtual Machines whose VMWare Tools need to be updated and updates them
.DESCRIPTION
    This is a one-liner that takes the name of the VMWare Server as an input and 
    updates any VMTools that need updated. 
.NOTES
    Version:        1.0
    Updated: 2020-12-22   
    Released: 2020-12-22
    Author: Danny McCaslin <danny.mccaslin[at]frederickwater[dot]com.
.EXAMPLE
    updateVMTools vcenter.internal.example.com
#>
$viServer = $args[0]
connect-viserver -server $viServer

get-vm  | % {Get-view $_.id} |  select name, @{Name="ToolsVersion"; Expression={$_.config.tools.
toolsversion}}, @{ Name="ToolStatus"; Expression={$_.Guest.ToolsVersionStatus}}| Where-Object {$_.ToolStatus -eq 'guestT
oolsNeedUpgrade'} | Update-Tools -NoReboot -VM {$_.Name} -Verbose