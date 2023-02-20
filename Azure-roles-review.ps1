
$date = Get-Date -Format “MM/dd/yyyy”

Import-Module Microsoft.Graph.Groups

Connect-MgGraph -Scopes RoleManagement.Read.Directory

$TotalAssignments = @()
#Role assignments
$Definitions = Get-MgRoleManagementDirectoryRoleDefinition

$Definitions | ForEach-Object {

    $RoleName = $_.DisplayName
    $RoleId = $_.Id
    $Assignments = Get-MgRoleManagementDirectoryRoleAssignment -Filter "roledefinitionID eq '$RoleId'"

    if ($Assignments) {

        foreach ($Assignment in $Assignments) {

            $AADObject=  Get-MgDirectoryObject -DirectoryObjectId $Assignment.PrincipalId
            #$AADObject=  Get-MgDirectoryObject -DirectoryObjectId 8c30e2eb-9b69-4244-bb47-c7f0e8137c83
            $AADObject = $AADObject.AdditionalProperties
            if($AADObject.'@odata.type' -eq "#microsoft.graph.group")
            {
                $GroupMembers = Get-MgGroupMember -GroupId $Assignment.PrincipalId| ForEach-Object {  @{ UserId=$_.Id}} | get-MgUser | Select-Object id, DisplayName, Mail
                foreach ($User in $GroupMembers)
                {
                    $UserObject = [PSCustomObject]@{
                    
                        RoleName = $RoleName
                        RoleId = $RoleId
                        PrincipalType = "User"
                        PrincipalId = $Assignment.PrincipalId
                        DisplayName = $User.DisplayName
                        UserPrincipalName = $User.UserPrincipalName
                        ParentGroup = $AADObject.displayName
                    }
                        [array]$TotalAssignments += $UserObject

                }
            }
            elseif($AADObject.'@odata.type' -eq "#microsoft.graph.user")
            {
                        
                $User = Get-MgUser -UserId $Assignment.PrincipalId -ErrorAction SilentlyContinue

                #if ($User) {

                $UserObject = [PSCustomObject]@{
                    
                    RoleName = $RoleName
                    RoleId = $RoleId
                    PrincipalType = "User"
                    PrincipalId = $Assignment.PrincipalId
                    DisplayName = $User.DisplayName
                    UserPrincipalName = $User.UserPrincipalName
                    ParentGroup = "User Assigned directly"
                }

                [array]$TotalAssignments += $UserObject
            }
          else {
                
                $ServicePrincipal = Get-MgServicePrincipal -ServicePrincipalId $Assignment.PrincipalId -ErrorAction SilentlyContinue

                if ($ServicePrincipal) {

                    $SpObject = [PSCustomObject]@{
                        
                        RoleName = $RoleName
                        RoleId = $RoleId
                        PrincipalType = "Service"
                        PrincipalId = $Assignment.PrincipalId
                        DisplayName = $ServicePrincipal.DisplayName
                        AppId = $ServicePrincipal.AppId
                        ParentGroup = "ServicePrincipal"
                    }
    
                    [array]$TotalAssignments += $SpObject
                }

            }

        }
          
    }

}

$TotalAssignments |Out-File ".\reports\$($date)_Azure-roles-review-byusers.csv"


#$TotalAssignments |select DisplayName