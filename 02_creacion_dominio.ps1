############################################
# CONFIGURACION
############################################

$DomainName   = "modominio.local"
$NetBIOS      = "MODOMINIO"
$SafeModePass = ConvertTo-SecureString "Admin123!" -AsPlainText -Force

############################################
# VALIDACION PREVIA (REAL)
############################################

if (
    (Get-WindowsFeature AD-Domain-Services).InstallState -eq "Installed" -and
    (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS")
) {
    Write-Host "Este servidor ya es un Controlador de Dominio. Promoviendo a DC."
    ############################################
    # PROMOCION A DC
    ############################################

    Install-ADDSForest `
        -DomainName $DomainName `
        -DomainNetbiosName $NetBIOS `
        -SafeModeAdministratorPassword $SafeModePass `
        -InstallDNS `
        -Force

    Write-Host "Promocion completada. REINICIA el servidor antes de continuar con el Script 03."
}


