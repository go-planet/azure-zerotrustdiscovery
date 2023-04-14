#This script gathers all the users in Azure AD privileged roles and checks to see whether or not Office licenses are assigned. If licenses are assigned a list of the assignments is generated as well.

# Import the Azure AD module
Import-Module AzureAD

# Connect to Azure AD
Connect-AzureAD

# Get all Azure AD roles that contain "administrator"
$roles = Get-AzureADDirectoryRole | Where-Object {$_.DisplayName -like "*Administrator*"}

# Get all users assigned to the roles
$roleMembers = foreach ($role in $roles) {
    Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId | Select-Object ObjectId, DisplayName, UserPrincipalName
}

# Get all users assigned to privileged roles who have Office licenses applied
$privilegedUsers = foreach ($member in $roleMembers) {
    $user = Get-AzureADUser -ObjectId $member.ObjectId
    $licenses = Get-AzureADUserLicenseDetail -ObjectId $user.ObjectId | Where-Object {$_.ServicePlans -like "*OFFICE*"} | Select-Object -ExpandProperty ServicePlans
    if ($licenses) {
        $licenseStatus = "Licensed"
    } else {
        $licenseStatus = "Not licensed"
    }
    $user | Select-Object DisplayName, UserPrincipalName, @{Name="Roles";Expression={$roles.DisplayName -join ";"}}, @{Name="LicenseStatus";Expression={$licenseStatus}}, @{Name="Licenses";Expression={$licenses.ServicePlanName -join ";"}} 
}

# Export the list of privileged users to a CSV file
$privilegedUsers | Export-Csv -Path "c:\scripts\licensed-privileged-users.csv" -NoTypeInformation
