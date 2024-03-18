
<# Copies a user account from  Production AD to Revenue Test AD. Imports SAMAccountName list from ./Userist.csv and exports Displayname, Email and Password to ./Report.csv
This script uses relative paths so the whole folder can be copied to another server as long as the server can reach both domains
  #>



  Function New-SecurePassword {
    $letters = "abcdefghijkmnopqrstuvwxyz".tochararray()
     $letters = ($letters | Get-Random -Count 10) -Join ''
    $numbers = "23456789".tochararray()
     $numbers = ($numbers | Get-Random -Count 1) -Join ''
    $symbols = "!@#$%&*".tochararray()
     $symbols =  ($symbols | Get-Random -Count 1) -Join ''
    $password = ($letters,$numbers,$symbols) -join''
    Return $password
<#
.Description
Creates a random password 12 characters long with a number and symbol.
Password length can be changed by editing the -Count values
#>
    }
    
    
    
$fromDomain = "****"
$toDomain = "****"
$OU = "****"

$csv = Import-Csv -Path $PSScriptRoot\UserList.csv
$Description = $(Write-Host "Enter Request Number" -BackgroundColor Green -ForegroundColor Black; Read-Host)
$creds = $(Write-Host "Enter your domain credentials" -BackgroundColor Green -ForegroundColor Black; Get-Credential)


$csv | ForEach-Object{
    $name = $_."SAMAccountName"
    try {
        Get-ADUser -Server $toDomain -Identity $name | Null
        Write-Host "$name already exists in ****domain"
        $account = [PSCustomObject]@{
            Name     = Get-ADUser -Server $toDomain -Identity $name -Properties DisplayName
            Email = Get-ADUser -Server $toDomain -Identity $name -Properties Email
            Password = ''
            State    = 'Already exists'
        }
        $account | Export-Csv -Path $PSScriptRoot\Report.csv -NoTypeInformation
    }
    catch {
        $TempPassword  = New-SecurePassword
        $AccountPassword = ConvertTo-SecureString $TempPassword -AsPlainText -Force
        
        $user = Get-ADUser -Server $fromDomain -Credential $creds -Identity $name -properties *
        $GivenName = $user.GivenName
        $Surname = $user.Surname
        $DisplayName = $user.DisplayName
        $OfficePhone = $user.OfficePhone
        $SAMAccountName = $user.sAMAccountName
        $title = $user.title
        $department = $user.department
        $company = $user.company
        $employeeID = $user.employeeID
        $mailNickname = $user.mailNickname
        $extensionAttribute4 = $user.extensionAttribute4
        $generationQualifier = $user.generationQualifier
        $govGENNid = $user.govGENNid
        
        $Mail = $user.mail.Replace("@**email**","@**upn**")
        $userPrincipalName = $user.userPrincipalName.Replace("@**email**","@**upn**")
        
        New-ADUser -Server $toDomain -Path $OU -GivenName $GivenName -Surname $Surname -DisplayName $DisplayName -Description $Description `
        -OfficePhone $OfficePhone -SamAccountName $SAMAccountName -Title $title `
        -Department $department -Company $company -EmployeeID $employeeID `
        -userPrincipalName $userPrincipalName -AccountPassword $AccountPassword -Name $DisplayName
        
        if ($govGENNid) {
        SET-ADUSER -Server $toDomain -Identity $SAMAccountName -add @{govGENNid="$govGENNid"} }
        if ($mailNickname) {
        SET-ADUSER -Server $toDomain -Identity $SAMAccountName -add @{mailNickname="$mailNickname"} }
        if ($Mail) {
        SET-ADUSER -Server $toDomain -Identity $SAMAccountName -add @{Mail="$Mail"} }
        if ($extensionAttribute4) {
        SET-ADUSER -Server $toDomain -Identity $SAMAccountName -add @{extensionAttribute4="$extensionAttribute4"} }
        if ($generationQualifier) {
        SET-ADUSER -Server $toDomain -Identity $SAMAccountName -add @{generationQualifier="$generationQualifier"} }
        
        Enable-ADAccount -Server $toDomain -Identity $SAMAccountName

        Write-Host "$name created"

        $account = [PSCustomObject]@{
            Name = $DisplayName
            Email = $Mail
            Password = $TempPassword
            State = 'Created'
        }
        $account | Export-Csv -Path $PSScriptRoot\Report.csv -NoTypeInformation -append
    }
    }

Write-Host "Remember to delete Report.csv after" -BackgroundColor Green -ForegroundColor Black


