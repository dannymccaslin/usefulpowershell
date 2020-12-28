<#check-registry.ps1
.SYNOPSIS
  Checks the registry to make sure that a few keys related to IOCs are correctly configured
.DESCRIPTION
  Checks the registry for Indicators of Compromise. 
  ** EnableLUA set to 0 means that UAC is disabled. 
  ** UseLogonCredentials means that logon usernames and passwords are unencrypted in memory. 
  ** LocalAccountTokenFilterPolicy means that UAC is disabled in RDP 
  ** DisablePasswordChange means tha the machine account password never changes. 
  I got these from a great presentation at RVASec 2019: https://www.youtube.com/watch?v=3wyPyEvs3O4&t=1394s 
.NOTES
  Version:        1.0
  Author:         Danny McCaslin
  Creation Date:  3/4/2019
  Purpose/Change: Initial script development
#>

#Write a function to check the registry. The input is the preferred value
function CheckReg {
param( [string]$key, [string]$path, [int]$val )
$regprop = Get-ItemProperty -Path $path -Name $key | Select-Object -ExpandProperty $key
if($regprop -eq $val -or !$regprop ) { #For what we are going, not having the registry property is as preferable to having it set to a value we don't want., the one exception being EnableLUA, which is built into the OS and not something that you would add after the fact.
    Write-EventLog -LogName Application -Source "regMonitor" -EntryType Information -EventID 1 -Message " The registry value  $key has been properly configured."
    #Write an event to the log if everything is okay

} else {
    Write-EventLog -LogName Application -Source "regMonitor" -EntryType Warning -EventID 10 -Message " The registry value  $key has been improperly configured. It is set to $regprop and it should be $val"
    #Write an event to the log if everything is not okay. We can trigger another Task off of this.
}
}

#See if the regMonitor exists as an Application source. If not, create it.
try {
    Get-EventLog -LogName Application -Source "regMonitor" -ErrorAction Stop
} catch  {
    New-EventLog -LogName Application -Source "regMonitor" 
}

#I tried a few different ways to create the objects we are looking for. honestly, this was the shortest
$keys = @("EnableLUA","UseLogonCredentials","LocalAccountTokenFilterPolicy","DisablePasswordChange")
$paths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\",'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest', "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\","HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters")
$values = @(1,0,0,0)

#run everything through a for loop off of the length of `keys` and run the CheckReg function
for ($i=0; $i -lt $keys.length; $i++) {
    CheckReg -key $keys[$i] -path $paths[$i] -val $values[$i]
}

