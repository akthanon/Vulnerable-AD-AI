############################################
# CONFIGURACION
############################################

$IP       = "192.168.1.10"
$Gateway  = "192.168.1.1"
$DNS      = "127.0.0.1"
$Prefix   = 24

############################################
# INTERFAZ DE RED
############################################

$Interface = Get-NetAdapter |
    Where-Object {
        $_.Status -eq "Up" -and
        $_.Name -notmatch "Virtual|vEthernet|Loopback"
    } |
    Select-Object -First 1

if (-not $Interface) {
    throw "No se encontro una interfaz de red valida"
}

############################################
# IP ESTATICA
############################################

if (-not (Get-NetIPAddress -InterfaceIndex $Interface.ifIndex -IPAddress $IP -ErrorAction SilentlyContinue)) {
    New-NetIPAddress `
        -InterfaceIndex $Interface.ifIndex `
        -IPAddress $IP `
        -PrefixLength $Prefix `
        -DefaultGateway $Gateway
}

Set-DnsClientServerAddress `
    -InterfaceIndex $Interface.ifIndex `
    -ServerAddresses $DNS

############################################
# ROLES NECESARIOS
############################################

if ((Get-WindowsFeature AD-Domain-Services).InstallState -ne "Installed") {
    Install-WindowsFeature AD-Domain-Services, DNS, GPMC -IncludeManagementTools
}

Write-Host "Script 01 completo."
Write-Host "Si se instalaron roles por primera vez, REINICIA antes del Script 02."
Restart-Computer -Force
