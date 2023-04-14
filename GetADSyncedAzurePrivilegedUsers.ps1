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

# Get all synchronized Azure AD users among the role members
$privilegedUsers = foreach ($member in $roleMembers) {
    Get-AzureADUser -ObjectId $member.ObjectId | Where-Object {$_.DirSyncEnabled -eq $true} | Select-Object DisplayName, UserPrincipalName, @{Name="Roles";Expression={$roles.DisplayName -join ";"}}
}

# Export the list of privileged users to a CSV file
$privilegedUsers | Export-Csv -Path "C:\scripts\privileged-users1.csv" -NoTypeInformation
