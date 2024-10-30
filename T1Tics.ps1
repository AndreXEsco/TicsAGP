# Verificación de Chocolatey e instalación si no está presente
if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey no está instalado. Iniciando la instalación..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; 

    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        Write-Host "Chocolatey se ha instalado correctamente."
    } catch {
        Write-Host "Error durante la instalación de Chocolatey: $_"
        return
    }
} else {
    Write-Host "Chocolatey ya está instalado."
}

# Lista de programas a instalar
$chocoPrograms = @(
    "googlechrome",
    "vlc",
    "adobereader",
    "7zip",
    "tsprintclient",
    "webview2-runtime",
    "lightshot",
    "anydesk",
    "microsoft-teams-new-bootstrapper"
)

# Función para instalar o actualizar programas
function Install-Programs {
    param (
        [string[]]$programs,
        [bool]$update = $false
    )

    $totalPrograms = $programs.Count
    $currentProgram = 0
    $failedPrograms = @()

    foreach ($program in $programs) {
        try {
            $currentProgram++
            Write-Host "Instalando $program..."
            
            # Elegir el comando según si es una instalación o actualización
            if ($update) {
                choco upgrade $program -y
                Write-Host "$program actualizado correctamente."
            } else {
                choco install $program -y
                Write-Host "$program instalado correctamente."
            }
            
            # Actualiza la barra de progreso
            $progress = [math]::Round(($currentProgram / $totalPrograms) * 100)
            Write-Progress -Activity "Instalando programas" -Status "$program instalado" -PercentComplete $progress

        } catch {
            Write-Host "Error al instalar $program $_"
            $failedPrograms += $program
        }
    }

    return $failedPrograms
}

# Preguntar al usuario si desea actualizar programas
$updatePrograms = $false
$response = Read-Host "¿Desea actualizar los programas existentes? (s/n)"
if ($response -eq 's') {
    $updatePrograms = $true
}

# Instalación o actualización de programas
$failedPrograms = Install-Programs -programs $chocoPrograms -update $updatePrograms

# Mensaje final
if ($failedPrograms.Count -eq 0) {
    Write-Host "Instalación/actualización completa. Todos los programas han sido instalados/actualizados."
} else {
    Write-Host "Los siguientes programas no se pudieron instalar/actualizar: $($failedPrograms -join ', ')"
}

Write-Host "Developed By TRSHWKUP O_O."
Write-Host "Implementado en Área de Sistemas Ducol Group. Version 2.1 Desplegada 30/10/2024"
