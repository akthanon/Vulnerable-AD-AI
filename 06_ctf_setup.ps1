############################################
# CTF SETUP - ACTIVE DIRECTORY LAB
############################################

Write-Host "=== CONFIGURANDO ESCENARIO CTF DE ACTIVE DIRECTORY ===" -ForegroundColor Cyan

Import-Module ActiveDirectory

$Domain  = Get-ADDomain
$BaseDN  = $Domain.DistinguishedName
$DNSRoot = $Domain.DNSRoot
$DCName  = $env:COMPUTERNAME

############################################
# 1. DIRECTORIO CTF
############################################

$CTFPath = "C:\CTF"

if (-not (Test-Path $CTFPath)) {
    New-Item $CTFPath -ItemType Directory | Out-Null
}

############################################
# 2. FLAGS DE PROGRESO
############################################

"FLAG{user_compromised}" |
Out-File "$CTFPath\flag_user.txt" -Force

"FLAG{backup_operator_abuse}" |
Out-File "$CTFPath\flag_backup.txt" -Force

"FLAG{domain_admin_owned}" |
Out-File "$CTFPath\flag_domain_admin.txt" -Force

############################################
# 3. CREDENCIALES FILTRADAS (ERROR HUMANO)
############################################

New-Item "$CTFPath\docs" -ItemType Directory -Force | Out-Null

@"
Usuario: legacy
Password: 12345

NOTA:
No cambiar la contraseña.
Sistema legacy aun depende de esta cuenta.
"@ | Out-File "$CTFPath\docs\legacy_credentials.txt" -Force

############################################
# 4. SERVICE ACCOUNT CONFIG FILE
############################################

@"
db_user=svc_sql
db_pass=Service123
server=$DCName
"@ | Out-File "$CTFPath\db.conf" -Force

############################################
# 5. GPP PASSWORD (SYSVOL)
############################################

$GppGuid = "{6F9619FF-8B86-D011-B42D-00C04FC964FF}"
$SysvolPath = "\\$DCName\SYSVOL\$DNSRoot\Policies\$GppGuid"

New-Item $SysvolPath -ItemType Directory -Force | Out-Null

@"
<?xml version="1.0" encoding="utf-8"?>
<Groups clsid="{3125E937-EB16-4b4c-9934-544FC6D24D9F}">
  <User clsid="{DF5F1855-51E5-4d24-8B1A-D9B2B9D4C50B}"
        name="helpdesk"
        image="2"
        changed="2023-01-01 12:00:00"
        uid="{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}">
    <Properties action="U"
                userName="helpdesk"
                cpassword="gpp_encrypted_password"
                changeLogon="0"
                noChange="1"
                neverExpires="1"
                acctDisabled="0"
                subAuthority="RID_ADMIN"/>
  </User>
</Groups>
"@ | Out-File "$SysvolPath\Groups.xml" -Force

############################################
# 6. TAREA PROGRAMADA COMO SYSTEM
############################################

$TaskScript = "$CTFPath\backup.ps1"

"FLAG{scheduled_task_abuse}" |
Out-File "$CTFPath\flag_schtask.txt" -Force

@"
Start-Sleep 5
"@ | Out-File $TaskScript -Force

schtasks /create `
 /tn "DailyBackupTask" `
 /tr "powershell.exe -ExecutionPolicy Bypass -File $TaskScript" `
 /sc daily `
 /ru SYSTEM `
 /f | Out-Null

############################################
# 7. SHARE CON PISTAS
############################################

$SharePath = "C:\Shares\Public"

@"
Bienvenido al laboratorio AD.

Objetivo:
- Enumerar el dominio
- Escalar privilegios
- Obtener Domain Admin

Pistas:
- Revisa permisos ACL
- Revisa SYSVOL
- Revisa cuentas de servicio
"@ | Out-File "$SharePath\README.txt" -Force

############################################
# 8. FLAG FINAL (SOLO PARA DA)
############################################

$DAFlag = "C:\Windows\System32\flag_DA.txt"

"FLAG{FULL_DOMAIN_COMPROMISE}" |
Out-File $DAFlag -Force

icacls $DAFlag /inheritance:r | Out-Null
icacls $DAFlag /grant "Domain Admins:F" | Out-Null

############################################
# FINAL
############################################

Write-Host "`n=== CTF LISTO ===" -ForegroundColor Green
Write-Host "Objetivo final: leer C:\Windows\System32\flag_DA.txt" -ForegroundColor Yellow
Write-Host "Buena suerte" -ForegroundColor Red
