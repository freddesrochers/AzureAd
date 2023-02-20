<#useful link
https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.directorymanagement/new-mgdevice?view=graph-powershell-1.0
https://github.com/chadmcox/Azure_Active_Directory/blob/d021369a52bde8f46d6b2a59ac644be96816d958/Devices/readme.md

#>

if (-Not(Get-Module -ListAvailable -Name "Microsoft.Graph.Identity.DirectoryManagement")) {

    Install-Module -Name "Microsoft.Graph.Identity.DirectoryManagement" -Repository PSGallery -Force -AllowClobber

}


Connect-MgGraph -Scopes "Directory.AccessAsUser.All"
Select-MgProfile -Name beta

$AzureHybridAdjoin = @()

$AzureHybridAdjoin = Get-MgDevice -filter "trustType eq 'ServerAd'" -all | Select `
Id,displayname, operatingsystem, accountenabled, profiletype, trusttype,DeviceId, `
@{N="enrollmentType";Expression={$_.AdditionalProperties.enrollmentType}}, `
@{N="enrollmentProfileName";Expression={$_.AdditionalProperties.enrollmentProfileName}}, `
@{N="createdDateTime";Expression={(get-date $_.AdditionalProperties.createdDateTime).tostring('yyyy-MM-dd')}}





$params = @{
    AccountEnabled = $false #we want to disable all devices. Sync was not supposed to happen
}


foreach ($device in $AzureHybridAdjoin)
{
    if($device.AccountEnabled -eq $true)
    {
        Update-MgDevice -DeviceId $device.Id -BodyParameter $params
        if ($?)
        {
            Write-host "SUCCESS: $($device.DisplayName) have been changed to $false" -ForegroundColor green
        }else
        {
            write-warning "ERROR : $($device.DisplayName) have NOT been changed " -ForegroundColor red
    
        }

    }
  
}

<#test change on one device
Get-MgDevice -DeviceId $device.Id | Select Id,displayname, operatingsystem, accountenabled, profiletype, trusttype,DeviceId
Get-MgDevice -DeviceId $AzureAdregistered[0].Id | Select Id,displayname, operatingsystem, accountenabled, profiletype, trusttype,DeviceId
#>





$AzureAdregistered = @()

$AzureAdregistered = Get-MgDevice -filter "trustType eq 'workplace'" -all | Select `
Id,displayname, operatingsystem, accountenabled, profiletype, trusttype,DeviceId, `
@{N="enrollmentType";Expression={$_.AdditionalProperties.enrollmentType}}, `
@{N="enrollmentProfileName";Expression={$_.AdditionalProperties.enrollmentProfileName}}, `
@{N="createdDateTime";Expression={(get-date $_.AdditionalProperties.createdDateTime).tostring('yyyy-MM-dd')}}




$params = @{
    AccountEnabled = $true #
}


foreach ($device in $AzureAdregistered)
{
    if($device.AccountEnabled -eq $false)
    {
        Update-MgDevice -DeviceId $device.Id -BodyParameter $params
        if ($?)
        {
            Write-host "SUCCESS: $($device.DisplayName) have been changed to $true" -ForegroundColor green
        }else
        {
            write-warning "ERROR : $($device.DisplayName) have NOT been changed " -ForegroundColor red
    
        }

    }
  
}


    Disconnect-Graph

