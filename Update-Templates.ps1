<#
.SYNOPSIS
  Updates server templates in VMWare
.DESCRIPTION
  This script will take your Windows VM templates, create VMs, update them, and save them again as Templates
  Add your vCenter server and set up a templatepasswd.txt file using (Get-Credential).Password | ConvertFrom-SecureString | Out-File "C:\Scripts\templatepasswd.txt".
  You also need to edit the $templates object to match your template names.
  This script requires a bit of prep. The templates have to have IP addresses, they have to have PSWindowsUpdate installed, and they have to have VM Tools installed. 
  Combine this with a Customization Spec in vCenter and you can get servers up in minutes with little updating required.  
.NOTES
  Version:        1.0
  Author:         Danny McCaslin
  Creation Date:  2/25/2021
  Purpose/Change: First Version
.EXAMPLE
  .\Update-Templates.ps1
#>
#Update-Templates.ps1
$templateuser = 'administrator'
$file = 'C:\Scripts\templatepasswd.txt'
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $templateuser, (Get-Content $file | ConvertTo-SecureString)

#Connect to vCenter
Connect-VIServer -Server vcenter.fcsa-water.local

#List VM Templates to Update
$templates = "GUI Template", "CoreTemplate"

foreach ($template in $templates) {
    #Convert to VM and Power On
    Set-Template -Template $template -ToVM
    Start-VM -VM $template -Confirm:$false
    Start-Sleep -s 10
    Get-VM -Name $template
    
    #Wait until VM Tools is running
    Write-Host "Waiting for VM Tools to start"
    do {
    $toolsStatus = (Get-VM $template | Get-View).Guest.ToolsStatus
    Write-Host $toolsStatus
    Start-Sleep -Seconds 3
    } until ($toolsStatus -eq 'toolsOk')

    #Invoke-Script to updatew the VM
    Invoke-VMScript -VM $template -ScriptText {Get-WindowsUpdate -Install -AcceptAll -AutoReboot} -GuestCredential $cred

    #Power Down and Convert back to Template
    Stop-VM -VM $template -Confirm:$false
    Set-VM -VM $template -ToTemplate -Confirm:$false
}

