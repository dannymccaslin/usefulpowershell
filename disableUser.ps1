<#
.SYNOPSIS
  Disables user account and cleans up O365
.DESCRIPTION
  Disables the user in Active Directory, then moves the user's email to a shared mailbox 
  in MSOL, and removes user licesing. As it requires MSOL and we have 2FA turned on, 
  running this script requires you to enter an O365 username and password for an 
  administrator account.
.INPUTS
  username of user to be disabled, with no domain name. 
.NOTES
  Version:        1.0
  Author:         Danny McCaslin
  Creation Date:  1/15/2020
  Purpose/Change: Initial script development
.EXAMPLE
  disableUser.ps1 danny.mccaslin
#>
$user = $args[0]
Write-Host "Disabling $user"
$userprincipalname = (get-aduser -Identity $user).userprincipalname
set-aduser -Identity $user -Enabled $false
$connectAddress = ""
#Change the user's mailbox to a shared mailbox


$Session = New-PSSession –ConfigurationName Microsoft.Exchange –ConnectionUri $connectAddress -Authentication Kerberos

Import-PSSession $Session -DisableNameChecking -AllowClobber

Set-RemoteMailbox -Identity $userprincipalname -Type Shared

#Connect to Office365 portal. Will prompt for valid credentials
import-module MsOnline
Connect-MsolService
$AccountSKU = ""

#Remove Office365 Licenses
Set-MsolUserLicense -UserPrincipalName $userprincipalname -RemoveLicenses $AccountSKU 