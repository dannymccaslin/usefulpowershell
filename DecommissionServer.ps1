<#
.SYNOPSIS
  Ddecommissions a server in AD and DNS and deletes server from VMWare
.DESCRIPTION
  Takes a name as input, decommissions the server in Active Directory and DNS and removes server from VSphere. VMWare Tools 
  must be installed in order to remove the VM from VMWare. This script assumes that you have the VMWare PowerCLI module for
  Powershell installed and have used the New-VICredentialStoreItem cmdlet in the past and stored your vCenter credentials. 
  If you need help, use 'get-help New-VICredentialStireItem' to see how its done, or 'get-help Connect-VIServer' for information
  on how to authenticate in the script itself.
.NOTES
  Version:        2.0
  Author:         Danny McCaslin
  Creation Date:  8/21/2019
  Purpose/Change: Fixed errors relating to VMWare Tools, added notes
.EXAMPLE
  .\DecommissionServer.ps1 fileserver1
#>
#DecommissionServer.ps1
$zone = "" # Domain zone, like example.com
$viserver = "" # Name of your vCenter server
$sendingEmail = " " #Email you want your notification to send from
$recipient = " " # Email that you want your notification to send to
$smtp = " " # smtp server, like mail.example.com


function ServerDecom {
    $serverName = "$args"
    Write-Host "Decommissioning $servername"
    Write-Host $serverName.GetType()
    $ServerIP = ([System.Net.Dns]::GetHostAddresses("$servername.$zone")).ipaddresstostring
    # Split out the IP address to get the reverse zone for DNS. If you don't use PTR records you can remove this
    $a,$b,$c,$d = $ServerIP.split('.')
    $reverseZone  = "$c.$b.$a.in-addr.arpa"
    $reverseHost = $d
    write-host $reverseZone
    write-host $reverseHost
    # Get the server from AD and remove it
    get-adcomputer -Identity $serverName  |  Remove-ADComputer -Confirm:$False
    Remove-DnsServerResourceRecord -ZoneName "$zone" -ComputerName dc1 -RRType A -Name $serverName -force
    Remove-DnsServerResourceRecord -ZoneName "$reverseHost" -ComputerName dc1 -RRType PTR -Name $d -force # Remove this line if you don't use PTR records
    connect-viserver -server vcenter.fcsa-water.local  
    # The mane of your VM may not match your actual computer name, so we rely on an IP address lookup. This only works if the server has VMWare Tools installed
    $TargetVM = (Get-VM) | Where-Object {$_.Guest.IPAddress -eq $ServerIP}
    if ($TargetVM) { #I wrapped this all in an if statement so that if the server doesn't have VMWare tools installed and the script can't find it it will exit gracefully
    Stop-VM $TargetVM -Confirm:$False
    Remove-VM -VM $TargetVM -DeletePermanently -Confirm:$False
    } else {
    Write-Host "The VM was not found. VMWare Tools may not have been installed"
    }
} 

ServerDecom $args[0]
 Send-MailMessage -from $sendingEmail -to $recipient -Subject "Server Decommissioned" -SmtpServer $smtp -Body "Server $args has been decommissioned."
