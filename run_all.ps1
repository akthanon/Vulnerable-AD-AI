############################################
# ORQUESTADOR TOTAL AD LAB
############################################

# --- CONFIG ---
$BasePath = "C:\Scripts"
$StepFile = "$BasePath\step.state"
$LogFile  = "$BasePath\run_all.log"

# --- LOGGING ---
function Log {
    param ($msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $msg" | Tee-Object -FilePath $LogFile -Append
}

# --- AUTO-ELEVACION ---
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Log "Re-ejecutando como Administrador"
    Start-Process powershell `
        "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

# --- INICIALIZAR ESTADO ---
if (-not (Test-Path $StepFile)) {
    "00" | Out-File $StepFile -Encoding ASCII
    Log "Estado inicial creado: 00"
}

$Step = Get-Content $StepFile

Log "Paso actual: $Step"

try {

    switch ($Step) {

        "00" {
            Log "Ejecutando 00_renombre_servidor.ps1"
            & "$BasePath\00_renombre_servidor.ps1"
            "01" | Out-File $StepFile
            Log "Reinicio requerido (rename)"
            Restart-Computer -Force
        }

        "01" {
            Log "Ejecutando 01_preparacion_servidor.ps1"
            & "$BasePath\01_preparacion_servidor.ps1"
            "02" | Out-File $StepFile
        }

        "02" {
            Log "Ejecutando 02_creacion_dominio.ps1"
            & "$BasePath\02_creacion_dominio.ps1"
            "03" | Out-File $StepFile
            Log "Reinicio requerido (ADDS)"
            Restart-Computer -Force
        }

        "03" {
            Log "Ejecutando 03_configuracion_ad.ps1"
            & "$BasePath\03_configuracion_ad.ps1"
            "04" | Out-File $StepFile
        }

        "04" {
            Log "Ejecutando 04_crear_vulnerabilidades.ps1"
            & "$BasePath\04_crear_vulnerabilidades.ps1"
            "05" | Out-File $StepFile
        }

        "05" {
            Log "Ejecutando 05_verificar_vulnerabilidades.ps1"
            & "$BasePath\05_verificar_vulnerabilidades.ps1"
            "06" | Out-File $StepFile
        }

        "06" {
            Log "Ejecutando 06_ctf_setup.ps1"
            & "$BasePath\06_ctf_setup.ps1"
            Remove-Item $StepFile -Force
            Log "LAB COMPLETADO CON EXITO"
        }

        default {
            throw "Estado desconocido: $Step"
        }
    }

}
catch {
    Log "ERROR CRITICO: $_"
    throw
}
