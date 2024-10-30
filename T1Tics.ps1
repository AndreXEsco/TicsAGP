# Instalación de Chocolatey (si no está instalado)
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

# Lista de programas para instalar con Chocolatey
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

# Función para instalar programas
function Install-Programs {
    param (
        [string[]]$programs
    )

    $totalPrograms = $programs.Count
    $currentProgram = 0
    $failedPrograms = @()

    foreach ($program in $programs) {
        try {
            $currentProgram++
            Write-Host "Instalando $program..."
            
            # Inicia la instalación del programa
            choco install $program -y
            
            # Actualiza la barra de progreso
            $progress = [math]::Round(($currentProgram / $totalPrograms) * 100)
            Write-Progress -Activity "Instalando programas" -Status "$program instalado" -PercentComplete $progress
            
            Write-Host "$program instalado correctamente."
        } catch {
            Write-Host "Error al instalar $program: $_"
            $failedPrograms += $program
        }
    }

    return $failedPrograms
}

# Instalación de programas
$failedPrograms = Install-Programs -programs $chocoPrograms

# Mensaje final
Write-Host "Instalación completa. Todos los programas han sido instalados."
if ($failedPrograms.Count -gt 0) {
    Write-Host "Los siguientes programas no se pudieron instalar: $($failedPrograms -join ', ')"
}
Write-Host "Developed By TRSHWKUP O_O."
Write-Host "Implementado en Área de Sistemas Ducol Group. Version 2.0 Desplegada 05/10/2024"

# Mensaje final
Write-Host "Instalación completa. Todos los programas han sido instalados."
Write-Host "Developed By TRSHWKUP O_O."
Write-Host "Implementado en Área de Sistemas Ducol Group. Version 2.1 Desplegada 30/10/2024"
