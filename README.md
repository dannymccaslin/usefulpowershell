# usefulpowershell
This is a collection of useful Powershell scripts I have created over the years.

# Repository Contents 
* __admin-monitor.ps1__ ------ Monitor for admin account creation in a domain 
* __replicateGroupMembership.ps1__ ------ Male a user a member of all of the same groups as another user 
* __disabledComputerCleanup.ps1__ ------ Disables unused computers and moves them to a segregated OU 
* __disableUser.ps1__ ------ Disables a user account,sets their mailbox type as Shared, and removes their Office365 License 
* __disabledUserMgmt.ps1__ ------ Finds disabled users who last logged in 90 days ago and moves them to a quarantined disabled user OU, also removes group membership. 
* __DecommissionServer.ps1__ ------ Removes a server from Active Directory, and deletes it from VCenter. Perfect for getting rid of servers you have upgraded.
* __check-registry.ps1__ ------ Checks the registry for some IOCs found in a lecture here: https://www.youtube.com/watch?v=3wyPyEvs3O4&t=1394s
* __updateVMTools.ps1__ ------ updates VMTools on all of your VMWare Virtual Machines that need an update, with no restart.