<#
.SYNOPSIS
    The purpose of this script is to get the group memberships of one user and replicate them to another user
.DESCRIPTION
    The script prtopmts the user for the usernames of each user and runs a sanity check against Active Directory to verify that they exist.`
    If they exist, it will grab the group memberships of the first user and copy them to the second user. The script exits if you enter `
    a user who does not exist.
.NOTES
    Version:        2.0
    Updated: 2020-01-15   
    Released: 2019-06-17
    Purpose/Change: Added ability to run the script as a one-liner with arguments
    Author: Danny McCaslin <danny.mccaslin[at]frederickwater[dot]com.
.EXAMPLE
  replicateGroupMembership.ps1 danny.mccaslin craig.grubb
#>


function Find-Names { # Query Active Directory to verify that a particular username is valid
   try { Get-ADUser -Identity $args[0] -ErrorAction Stop 
        Write-Host "OK!"}
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        "I'm sorry. That user does not exist"
        break 
        } 
}
# If the script is run with arguments, it will use those usernames as arguments. Otherwise 
# it will prompt for usernames
if ($args[0]){
   $firstuser = $args[0]
}
else {
$firstUser = Read-Host "Enter the Username of the user whose groups you want to copy: "
}

Find-Names $firstUser
if ($args[1]) {
    $secondUser = $args[1]
}
else {
$secondUser = Read-Host "Enter the Username of the use you want to copy group membership to: "
}
Find-Names $secondUser
# Copy group membership from one user to another
Write-Host "Copying group permissions of $firstuser to $secondUser"
$groups = (Get-ADuser -Identity $firstUser -Properties memberof).memberof
$groups | get-adgroup | Select-Object name |sort-object name 
foreach ($group in $groups) {Add-ADGroupMember $group -Members $secondUser}