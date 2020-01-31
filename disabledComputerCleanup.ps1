<#disabledCleanup.ps1
.SYNOPSIS
  Disables computers and moves them to a Disabled Computers OU
.DESCRIPTION
  Finds computers that were last logged into more than 60 days ago, disables them, and moves them to a disabled OU.
.NOTES
  Version:        1.0
  Author:         Danny McCaslin
  Creation Date:  8/23/2019
  Purpose/Change: Initial script development
#>
$date =  Get-Date
$olddate =  $date.AddDays(-60)
$computerOU = ""
$disabledComputerOU = ""
$adcomputers = get-adcomputer -filter {(lastlogontimestamp -lt $olddate) -and (enabled -eq $True) -and (operatingsystem -notlike "*Windows 10*") } -SearchBase $computerOU -Properties lastlogontimestamp,operatingsystem

$fromAddress = "" #Add sending address for email
$toAddress = "" #Add recipient address for email
$smtp = "mail.example.com" #Add your smtp address

Send-MailMessage -from $fromAddress -to $toAddress -Subject "Active Directory Computers Inactive" -SmtpServer $smtp -Body "The following Active Directory computers have been disabled and moved due to being inactive for 60 days. $adcomputers"

$adcomputers | Set-ADComputer -Enabled $false

get-adcomputer -filter * -Properties lastlogondate, enabled | Where-Object {$_.enabled -eq $false} | Move-ADObject -TargetPath $disabledComputerOU
