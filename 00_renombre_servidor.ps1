############################################
# CONFIGURACION
############################################

$ServerName = "DCW01"

############################################
# RENOMBRE SEGURO
############################################

if ($env:COMPUTERNAME -eq $ServerName) {
    Write-Host "El servidor ya tiene el nombre correcto ($ServerName)."
    exit
}

Rename-Computer -NewName $ServerName
Write-Host "Servidor renombrado a $ServerName."
Write-Host "REINICIA el servidor antes de ejecutar el Script 01."