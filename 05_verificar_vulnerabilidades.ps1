############################################
# COMPROBACION ENTORNO VULNERABLE AD
############################################

Import-Module ActiveDirectory
Import-Module GroupPolicy

$Domain  = Get-ADDomain
$BaseDN  = $Domain.DistinguishedName
$DNSRoot = $Domain.DNSRoot

Write-Host "`n=== COMPROBACION DE VULNERABILIDADES AD ===`n"

############################################
# 1. PASSWORD POLICY DEBIL
############################################

$Policy = Get-ADDefaultDomainPasswordPolicy

if ($Policy.MinPasswordLength -le 5 -and
    $Policy.ComplexityEnabled -eq $false -and
    $Policy.PasswordHistoryCount -eq 0) {

    Write-Host "[OK] Password Policy debil configurada"
} else {
    Write-Host "[FAIL] Password Policy NO es debil"
}

############################################
# 2. USUARIOS DEBILES
############################################

$UsersToCheck = @("helpdesk","backup","legacy")

foreach ($U in $UsersToCheck) {
    if (Get-ADUser -Filter "SamAccountName -eq '$U'") {
        Write-Host "[OK] Usuario $U existe"
    } else {
        Write-Host "[FAIL] Usuario $U NO existe"
    }
}

############################################
# 3. AS-REP ROASTING
############################################

$Helpdesk = Get-ADUser -Filter "SamAccountName -eq 'helpdesk'" -Properties DoesNotRequirePreAuth

if ($Helpdesk -and $Helpdesk.DoesNotRequirePreAuth) {
    Write-Host "[OK] AS-REP Roasting habilitado (helpdesk)"
} else {
    Write-Host "[FAIL] AS-REP Roasting NO habilitado"
}

############################################
# 4. KERBEROASTING (SPN)
############################################

$SvcSQL = Get-ADUser -Filter "SamAccountName -eq 'svc_sql'" -Properties ServicePrincipalNames

if ($SvcSQL -and $SvcSQL.ServicePrincipalNames) {
    Write-Host "[OK] Kerberoasting posible (SPN presente)"
} else {
    Write-Host "[FAIL] SPN NO configurado"
}

############################################
# 5. DELEGACION INSEGURA
############################################

$SvcSQL = Get-ADUser -Filter "SamAccountName -eq 'svc_sql'" -Properties TrustedForDelegation

if ($SvcSQL -and $SvcSQL.TrustedForDelegation) {
    Write-Host "[OK] Delegacion insegura habilitada"
} else {
    Write-Host "[FAIL] Delegacion NO habilitada"
}

############################################
# 6. ACL GENERICALL
############################################

$User1 = Get-ADUser -Identity "helpdesk"
$User2 = Get-ADUser -Identity "legacy"

$TargetSid = $User1.SID.Value

$Acl = Get-Acl "AD:$($User2.DistinguishedName)"

$Found = $false

foreach ($Ace in $Acl.Access) {

    try {
        $AceSid = $Ace.IdentityReference.Translate(
            [System.Security.Principal.SecurityIdentifier]
        ).Value
    } catch {
        continue
    }

    if (
        $AceSid -eq $TargetSid -and
        ($Ace.ActiveDirectoryRights -band
         [System.DirectoryServices.ActiveDirectoryRights]::GenericAll)
    ) {
        $Found = $true
        break
    }
}

if ($Found) {
    Write-Host "[OK] GenericAll detectado"
} else {
    Write-Host "[FAIL] GenericAll NO encontrado" -ForegroundColor Red
}

############################################
# 7. GRUPO PRIVILEGIADO
############################################

$Backup = Get-ADUser -Filter "SamAccountName -eq 'backup'"
if ($Backup) {
    $Groups = Get-ADPrincipalGroupMembership $Backup | Select-Object -ExpandProperty Name
    if ($Groups -contains "Backup Operators") {
        Write-Host "[OK] Usuario backup es Backup Operator"
    } else {
        Write-Host "[FAIL] Usuario backup NO es Backup Operator"
    }
}

############################################
# 8. NTLMv1
############################################

$NTLM = Get-ItemProperty `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
    -Name "LMCompatibilityLevel" `
    -ErrorAction SilentlyContinue

if ($NTLM.LMCompatibilityLevel -le 2) {
    Write-Host "[OK] NTLMv1 habilitado"
} else {
    Write-Host "[FAIL] NTLMv1 NO habilitado"
}

############################################
# 9. SMB SIGNING
############################################

$SMB = Get-ItemProperty `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" `
    -Name "RequireSecuritySignature" `
    -ErrorAction SilentlyContinue

if ($SMB.RequireSecuritySignature -eq 0) {
    Write-Host "[OK] SMB Signing desactivado"
} else {
    Write-Host "[FAIL] SMB Signing activo"
}

############################################
# 10. SHARE INSEGURO
############################################

$Share = Get-SmbShare -Name "Public" -ErrorAction SilentlyContinue

if ($Share) {
    Write-Host "[OK] Share Public existe"
} else {
    Write-Host "[FAIL] Share Public NO existe"
}

############################################
# 11. GPO INSEGURA
############################################

$GPO = Get-GPO -Name "GPO_Insegura" -ErrorAction SilentlyContinue

if ($GPO) {
    Write-Host "[OK] GPO insegura existe"
} else {
    Write-Host "[FAIL] GPO insegura NO existe"
}

############################################
# 12. AUDITORIA
############################################

$audit = auditpol /get /category:*

if ($audit -match "No Auditing") {
    Write-Host "[OK] Auditoria deshabilitada/minima"
} else {
    Write-Host "[WARN] Auditoria puede estar activa"
}

Write-Host "`n=== COMPROBACION FINALIZADA ==="
