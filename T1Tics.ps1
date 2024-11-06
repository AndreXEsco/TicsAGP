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

# Archivo de log
$logFile = "C:\Chocolatey_Install_Log.txt"
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp - $message" | Out-File -Append -FilePath $logFile
}

# Función para mostrar barra de progreso
function Show-ProgressBar {
    param (
        [string]$program,
        [int]$currentProgram,
        [int]$totalPrograms
    )

    $progress = [math]::Round(($currentProgram / $totalPrograms) * 100)
    Write-Progress -Activity "Instalando programas" -Status "Instalando: $program" -PercentComplete $progress
}

# Función para verificar la conectividad a Internet sin realizar solicitudes HTTP
function Test-InternetConnection {
    $hosts = @("google.com", "bing.com", "github.com")  # Lista de servidores para hacer ping
    foreach ($host in $hosts) {
        try {
            $ping = Test-Connection -ComputerName $host -Count 1 -Quiet
            if ($ping) {
                Write-Host "Conexión exitosa a $host."
                return $true
            } else {
                Write-Host "No se puede hacer ping a $host."
            }
        } catch {
            Write-Host "Error al intentar hacer ping a $host $($_.Exception.Message)"
        }
    }
    Write-Host "No se pudo establecer conexión a Internet."
    return $false
}

# Verificar conexión a Internet
if (-not (Test-InternetConnection)) {
    Write-Host "No hay conexión a Internet. No se pueden instalar los programas."
    Write-Log "Error: No hay conexión a Internet."
    return
}

# Comprobación de versión de Chocolatey
function Check-ChocolateyVersion {
    $currentVersion = choco --version
    $latestVersion = Invoke-RestMethod -Uri "https://api.github.com/repos/chocolatey/choco/releases/latest" | Select-Object -ExpandProperty tag_name

    if ($currentVersion -ne $latestVersion) {
        Write-Host "Chocolatey no está actualizado. La versión actual es $currentVersion, pero la última versión es $latestVersion."
        Write-Host "Actualizando Chocolatey..."
        Write-Log "Actualizando Chocolatey desde $currentVersion a $latestVersion."
        Invoke-Expression "choco upgrade chocolatey -y"
    } else {
        Write-Host "Chocolatey está actualizado."
    }
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

# Función para instalar programas
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
            Write-Log "Instalando $program..."

            # Comando de instalación con omisión de checksum
            $chocoCommand = "choco install $program -y --ignore-checksums"
            
            # Si estamos actualizando, modificamos el comando
            if ($update) {
                $chocoCommand = "choco upgrade $program -y --ignore-checksums"
            }
            
            # Ejecutar el comando de instalación/actualización
            Invoke-Expression $chocoCommand
            Write-Host "$program instalado/actualizado correctamente."
            Write-Log "$program instalado/actualizado correctamente."

            # Mostrar progreso
            Show-ProgressBar -program $program -currentProgram $currentProgram -totalPrograms $totalPrograms

        } catch {
            # Manejo de excepciones específicas
            $errorMessage = $_.Exception.Message
            Write-Host "Error al instalar $program $errorMessage"
            Write-Log "Error al instalar $program $errorMessage"

            # Agregar el programa fallido a la lista
            $failedPrograms += $program
        }
    }

    return $failedPrograms
}

# Función para comprobar si un programa está instalado
function Is-ProgramInstalled {
    param (
        [string]$program
    )

    $installed = choco list --local-only | Select-String $program
    return $installed -ne $null
}

# Mostrar menú interactivo
function Show-Menu {
    Write-Host "Seleccione una opción:"
    Write-Host "1: Instalar programas"
    Write-Host "2: Actualizar programas"
    Write-Host "3: Verificar estado de instalación"
    Write-Host "4: Salir"
}

# Función para verificar el estado de la instalación
function Check-InstallationStatus {
    Write-Host "Comprobando el estado de instalación..."
    foreach ($program in $chocoPrograms) {
        if (Is-ProgramInstalled -program $program) {
            Write-Host "$program está instalado."
        } else {
            Write-Host "$program no está instalado."
        }
    }
}

# Preguntar al usuario si desea actualizar programas
$updatePrograms = $false
$response = Read-Host "¿Desea actualizar los programas existentes? (s/n)"
if ($response -eq 's') {
    $updatePrograms = $true
}

# Ejecución principal con menú
Show-Menu
$selection = Read-Host "Ingresa el número de la opción deseada"

switch ($selection) {
    1 {
        Write-Host "Instalando programas..."
        $failedPrograms = Install-Programs -programs $chocoPrograms -update $false
        if ($failedPrograms.Count -eq 0) {
            Write-Host "Instalación completa. Todos los programas han sido instalados."
        } else {
            Write-Host "Los siguientes programas no se pudieron instalar: $($failedPrograms -join ', ')"
        }
    }
    2 {
        Write-Host "Actualizando programas..."
        $failedPrograms = Install-Programs -programs $chocoPrograms -update $true
        if ($failedPrograms.Count -eq 0) {
            Write-Host "Actualización completa. Todos los programas han sido actualizados."
        } else {
            Write-Host "Los siguientes programas no se pudieron actualizar: $($failedPrograms -join ', ')"
        }
    }
    3 {
        Check-InstallationStatus
    }
    4 {
        Write-Host "Saliendo..."
        exit
    }
    default {
        Write-Host "Opción no válida."
    }
}

Write-Host "Desarrollado por TRSHWKUP O_O."
Write-Host "Implementado en Área de Sistemas Ducol Group. Version 2.2.1 Desplegada 5/11/2024"
Write-Log "Script ejecutado exitosamente."
