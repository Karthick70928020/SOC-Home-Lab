$base = "DC=lab,DC=local"
New-ADOrganizationalUnit -Name "LabCorp" -Path $base
foreach ($ou in "Users","Workstations","Servers","ServiceAccounts","Groups") {
    New-ADOrganizationalUnit -Name $ou -Path "OU=LabCorp,$base"
}

New-ADGroup -Name "SOC-Analysts" -GroupScope Global -Path "OU=Groups,OU=LabCorp,$base"
New-ADGroup -Name "IT-Admins"    -GroupScope Global -Path "OU=Groups,OU=LabCorp,$base"

$pw = Read-Host "Set a password for the lab users" -AsSecureString

$users = @(
    @{Name="Alice Morgan"; Sam="alice.morgan"; Group="SOC-Analysts"},
    @{Name="Ben Carter";   Sam="ben.carter";   Group="SOC-Analysts"},
    @{Name="Priya Nair";   Sam="priya.nair";   Group="IT-Admins"},
    @{Name="David Lee";    Sam="david.lee";    Group="IT-Admins"},
    @{Name="Maya Singh";   Sam="maya.singh";   Group=$null}
)

foreach ($u in $users) {
    New-ADUser -Name $u.Name -SamAccountName $u.Sam `
        -UserPrincipalName "$($u.Sam)@lab.local" `
        -Path "OU=Users,OU=LabCorp,$base" `
        -AccountPassword $pw -Enabled $true -PasswordNeverExpires $true
    if ($u.Group) { Add-ADGroupMember -Identity $u.Group -Members $u.Sam }
}