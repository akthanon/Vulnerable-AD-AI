############################################
# ESPERAR ACTIVE DIRECTORY FUNCIONAL
############################################

Import-Module ActiveDirectory
Import-Module GroupPolicy

do {
    Start-Sleep -Seconds 5
    try {
        $Domain = Get-ADDomain -ErrorAction Stop
    } catch {
        $Domain = $null
    }
} until ($Domain)

$BaseDN     = $Domain.DistinguishedName
$UPNSuffix = $Domain.DNSRoot

############################################
# OUs
############################################

$OUs = @(
    "Usuarios",
    "Computadoras",
    "Servidores",
    "Grupos",
    "Departamentos"
)

foreach ($OU in $OUs) {
    if (-not (Get-ADOrganizationalUnit -LDAPFilter "(ou=$OU)" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $OU -Path $BaseDN
    }
}

############################################
# GRUPOS
############################################

$Groups = @("GG_IT","GG_HR","GG_Finance","GG_Marketing")

foreach ($Group in $Groups) {
    if (-not (Get-ADGroup -LDAPFilter "(cn=$Group)" -ErrorAction SilentlyContinue)) {
        New-ADGroup `
            -Name $Group `
            -GroupScope Global `
            -GroupCategory Security `
            -Path "OU=Grupos,$BaseDN"
    }
}

############################################
# FORZAR RESOLUCION DE GRUPOS (CRITICO)
############################################

Start-Sleep -Seconds 5
foreach ($Group in $Groups) {
    [void](Get-ADGroup $Group)
}

############################################
# USUARIOS DE EJEMPLO
############################################

$Users = @(
    @{Name="Juan IT"; User="juan.it"; Group="GG_IT"},
    @{Name="Ana HR"; User="ana.hr"; Group="GG_HR"},
    @{Name="Luis Finance"; User="luis.fin"; Group="GG_Finance"}
)

foreach ($U in $Users) {

    if (-not (Get-ADUser -LDAPFilter "(sAMAccountName=$($U.User))" -ErrorAction SilentlyContinue)) {

        New-ADUser `
            -Name $U.Name `
            -SamAccountName $U.User `
            -UserPrincipalName "$($U.User)@$UPNSuffix" `
            -AccountPassword (ConvertTo-SecureString "User123!" -AsPlainText -Force) `
            -Enabled $true `
            -Path "OU=Usuarios,$BaseDN"
    }

    Add-ADGroupMember -Identity $U.Group -Members $U.User -ErrorAction SilentlyContinue
}

############################################
# PASSWORD POLICY
############################################

Set-ADDefaultDomainPasswordPolicy `
    -MinPasswordLength 10 `
    -PasswordHistoryCount 10 `
    -MaxPasswordAge (New-TimeSpan -Days 90) `
    -ComplexityEnabled $true `
    -Identity $Domain.DistinguishedName

############################################
# AUDITORIA
############################################

auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Account Lockout" /success:enable /failure:enable
auditpol /set /subcategory:"Directory Service Changes" /success:enable /failure:enable

############################################
# DNS REVERSE
############################################

$ReverseZone = "1.168.192.in-addr.arpa"

if (-not (Get-DnsServerZone -Name $ReverseZone -ErrorAction SilentlyContinue)) {
    Add-DnsServerPrimaryZone `
        -NetworkId "192.168.1.0/24" `
        -ReplicationScope Forest
}


############################################
# FILE SERVER LOCAL
############################################

if (-not (Test-Path "C:\Shares\IT")) {
    New-Item -Path "C:\Shares\IT" -ItemType Directory
}

if (-not (Get-SmbShare -Name "IT" -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name "IT" -Path "C:\Shares\IT" -FullAccess "MODOMINIO\GG_IT"
}

############################################
# GPO BLOQUEO PANEL DE CONTROL
############################################

if (-not (Get-GPO -Name "Bloqueo Panel de Control" -ErrorAction SilentlyContinue)) {

    $GPO = New-GPO -Name "Bloqueo Panel de Control"

    Set-GPRegistryValue `
        -Name $GPO.DisplayName `
        -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
        -ValueName "NoControlPanel" `
        -Type DWord `
        -Value 1

    New-GPLink `
        -Name $GPO.DisplayName `
        -Target "OU=Usuarios,$BaseDN"
}

Write-Host "Script 03 completado correctamente."
