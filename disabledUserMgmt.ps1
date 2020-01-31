<#disabledUserMgmt.ps1
.SYNOPSIS
  Moves disabled usersto a Disabled Computers OU
.DESCRIPTION
  Finds disabled users that were last logged into more than 90 days ago and moves them to 
  a disabled user OU. Also removes group membership for all groups excepr Domain Users.
  Useful to run on a schedule.
.NOTES
  Version:        1.0
  Author:         Danny McCaslin
  Creation Date:  1/21/2019
  Purpose/Change: Initial script development
#>

#disabledUserMgmt.ps1

$date=Get-Date
$oldDate = $date.AddDays(-90)
$sendAddress = "" #Sending email address
$recipientAddress ="" #Recipient email address
$smtp = "mail.example.com" #Your smtp server
$userSearchBase = "" #Target path for current AD users
$disabedTarget = "" #Target Path for AD Disabled users

$oldUsers = get-aduser -Filter {(enabled -eq $false) -and (lastlogontimestamp -lt $oldDate)} -Properties enabled, lastlogondate -SearchBase $userSearchBase
$names = foreach ($user in $oldUsers) {
    "<li>" + $user.name + "</li>"
    
}

Send-MailMessage -from $sendAddress -to $recipientAddress -Subject "Active Directory Users Inactive" -SmtpServer $smtp -Body "The following Active Directory users have been moved due to being inactive for 90 days. <ul> $names </ul>" -BodyAsHtml

$oldUsers |Move-ADObject -TargetPath $disabedTarget 
foreach ($user in $oldusers) {
    Get-ADPrincipalGroupMembership -Identity $user | Where-Object {$_.name -ne "Domain Users"} | Remove-ADGroupMember -Members $user -Confirm
}