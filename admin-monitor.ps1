<#
.SYNOPSIS
    Monitors event log for Admin user creation
.DESCRIPTION
    The script monitors the event log for creation of administrator accounts. This is useful to determine
    if someone has created an account with elevated privileges. run this script on the creation of 
    an event with InstanceId 4728.
.NOTES
    Version:        2.0
    Updated: 2020-01-15   
    Released: 2019-06-17
    Author: Danny McCaslin <danny.mccaslin[at]frederickwater[dot]com.
#>
$event = Get-eventlog security -InstanceId 4728 -Newest 1 -ComputerName dc1 
$user = $event.ReplacementStrings[0]
$group = $event.ReplacementStrings[2]
$admin = $event.ReplacementStrings[6]

# for Mail
$fromAddress = ""
$toAddress = ""
$smtp = "mail.example.com"

Send-MailMessage -From $fromAddress -To $toAddress -Subject "Admin Created - Possible Security Breach" -Body "The user $user was granted access to the $group Group by the administrator account $admin. Please check the logs to ensure that this is not a security breach."  -SmtpServer $smtp
