############################################
# ADVERTENCIA
############################################

Write-Host "CREANDO ENTORNO VULNERABLE DE ACTIVE DIRECTORY"
Write-Host "NO USAR EN PRODUCCION"

Import-Module ActiveDirectory
Import-Module GroupPolicy

$Domain   = Get-ADDomain
$BaseDN   = $Domain.DistinguishedName
$DNSRoot  = $Domain.DNSRoot
$DCName   = $env:COMPUTERNAME

############################################
# 1. PASSWORD POLICY DEBIL
############################################

Set-ADDefaultDomainPasswordPolicy `
    -MinPasswordLength 5 `
    -ComplexityEnabled $false `
    -PasswordHistoryCount 0 `
    -MaxPasswordAge (New-TimeSpan -Days 365) `
    -Identity $Domain.DistinguishedName

############################################
# 2. USUARIOS CON PASSWORD DEBIL
############################################

$WeakUsers = @(
    @{Name="helpdesk"; Pass="Password1"},
    @{Name="backup";   Pass="backup"},
    @{Name="legacy";   Pass="12345"}
)

foreach ($U in $WeakUsers) {

    $User = Get-ADUser -Filter "SamAccountName -eq '$($U.Name)'"

    if (-not $User) {
        New-ADUser `
            -Name $U.Name `
            -SamAccountName $U.Name `
            -UserPrincipalName "$($U.Name)@$DNSRoot" `
            -AccountPassword (ConvertTo-SecureString $U.Pass -AsPlainText -Force) `
            -Enabled $true `
            -PasswordNeverExpires $true `
            -Path "OU=Usuarios,$BaseDN"
    }
}

############################################
# 3. AS-REP ROASTING
############################################

$Helpdesk = Get-ADUser -Filter "SamAccountName -eq 'helpdesk'"
if ($Helpdesk) {
    Set-ADAccountControl `
        -Identity $Helpdesk `
        -DoesNotRequirePreAuth $true
}

############################################
# 4. KERBEROASTING
############################################

$SvcSQL = Get-ADUser -Filter "SamAccountName -eq 'svc_sql'"

if (-not $SvcSQL) {
    New-ADUser `
        -Name "SQL Service" `
        -SamAccountName svc_sql `
        -ServicePrincipalNames "MSSQLSvc/$DCName.$DNSRoot:1433" `
        -AccountPassword (ConvertTo-SecureString "Service123" -AsPlainText -Force) `
        -Enabled $true `
        -PasswordNeverExpires $true `
        -Path "OU=Usuarios,$BaseDN"
}

############################################
# 5. DELEGACION INSEGURA
############################################

$SvcSQL = Get-ADUser -Filter "SamAccountName -eq 'svc_sql'"
if ($SvcSQL) {
    Set-ADAccountControl `
        -Identity $SvcSQL `
        -TrustedForDelegation $true
}

############################################
# 6. ACL MAL CONFIGURADA (GENERICALL)
############################################

Import-Module ActiveDirectory

# Obtener usuarios (lookup correcto)
$User1 = Get-ADUser -Identity "helpdesk"
$User2 = Get-ADUser -Identity "legacy"

# Ruta AD del objeto destino
$ADPath = "AD:$($User2.DistinguishedName)"

# Obtener ACL actual
$Acl = Get-Acl -Path $ADPath

# Construir ACE GenericAll explícita (NO heredada)
$Rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule (
    $User1.SID,
    [System.DirectoryServices.ActiveDirectoryRights]::GenericAll,
    [System.Security.AccessControl.AccessControlType]::Allow
)

# Añadir regla (sin condiciones previas)
$Acl.AddAccessRule($Rule)

# Aplicar ACL
Set-Acl -Path $ADPath -AclObject $Acl

Write-Host "[OK] GenericAll otorgado: helpdesk -> legacy"


############################################
# 7. USUARIO EN GRUPO PRIVILEGIADO
############################################

$BackupUser = Get-ADUser -Filter "SamAccountName -eq 'backup'"
if ($BackupUser) {
    Add-ADGroupMember "Backup Operators" $BackupUser -ErrorAction SilentlyContinue
}

############################################
# 8. NTLMv1 HABILITADO
############################################

Set-ItemProperty `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
    -Name "LMCompatibilityLevel" `
    -Type DWord `
    -Value 1

############################################
# 9. SMB SIGNING DESACTIVADO
############################################

Set-ItemProperty `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" `
    -Name "RequireSecuritySignature" `
    -Value 0

############################################
# 10. SHARE INSEGURO
############################################

if (-not (Test-Path "C:\Shares\Public")) {
    New-Item -Path "C:\Shares\Public" -ItemType Directory
}

if (-not (Get-SmbShare -Name "Public" -ErrorAction SilentlyContinue)) {
    New-SmbShare `
        -Name "Public" `
        -Path "C:\Shares\Public" `
        -FullAccess "Everyone"
}

############################################
# 11. GPO INSEGURA
############################################

if (-not (Get-GPO -Name "GPO_Insegura" -ErrorAction SilentlyContinue)) {

    $GPO = New-GPO -Name "GPO_Insegura"

    Set-GPRegistryValue `
        -Name $GPO.DisplayName `
        -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
        -ValueName "EnableLUA" `
        -Type DWord `
        -Value 0

    New-GPLink `
        -Name $GPO.DisplayName `
        -Target $BaseDN
}

############################################
# 12. AUDITORIA MINIMA
############################################

auditpol /clear /y

Write-Host "ENTORNO VULNERABLE CREADO CON EXITO"
