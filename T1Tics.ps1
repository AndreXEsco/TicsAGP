# Archivo de log
$logFile = "C:\Chocolatey_Install_Log.txt"
function Write-Log {
    param (
        [string]$message,
        [string]$level = "INFO"  # Niveles: INFO, WARNING, ERROR
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp [$level] - $message" | Out-File -Append -FilePath $logFile
}

# Verificar e instalar Chocolatey si no está presente
if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey no está instalado. Iniciando la instalación..."
    Write-Log "Chocolatey no está instalado. Iniciando la instalación..." -level "WARNING"

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        Write-Host "Chocolatey se ha instalado correctamente."
        Write-Log "Chocolatey instalado correctamente." -level "INFO"
    } catch {
        Write-Host "Error durante la instalación de Chocolatey: $_"
        Write-Log "Error durante la instalación de Chocolatey: $_" -level "ERROR"
        return
    }
} else {
    Write-Host "Chocolatey ya está instalado."
    Write-Log "Chocolatey ya estaba instalado." -level "INFO"
}

# Función para mostrar barra de progreso
function Show-ProgressBar {
    param (
        [string]$program,
        [int]$currentProgram,
        [int]$totalPrograms
    )

    $progress = [math]::Round(($currentProgram / $totalPrograms) * 100)
    Write-Progress -Activity "Instalando la lista de programas" -Status "Se esta Instalando: $program" -PercentComplete $progress
}

# Función para verificar la conectividad a Internet
function Test-InternetConnection {
    $pingHosts = @("google.com", "bing.com", "github.com")
    $internetConnected = $false

    foreach ($pingHost in $pingHosts) {
        try {
            $ping = Test-Connection -ComputerName $pingHost -Count 1 -Quiet
            if ($ping) {
                Write-Host "Conexión exitosa a $pingHost."
                $internetConnected = $true
                break
            }
        } catch {
            Write-Host "Error al intentar conectarte a $pingHost $($_.Exception.Message)"
        }
    }

    if (-not $internetConnected) {
        Write-Host "No tienes conexion a internet. Detendremos el script te recomendamos revisar tu conexion a internet."
        Write-Log "Error: No hay conexión a Internet." -level "ERROR"
        return $false
    }

    Write-Host "Conexión a Internet confirmada."
    return $true
}

# Función para verificar y actualizar Chocolatey
function Check-ChocolateyVersion {
    try {
        Write-Host "Comprobando actualizaciones de Chocolatey..."
        $upgradeAvailable = choco outdated | Select-String -Pattern "chocolatey"
        if ($upgradeAvailable) {
            Write-Host "Chocolatey no está actualizado. Actualizando..."
            Write-Log "Actualizando Chocolatey." -level "WARNING"
            choco upgrade chocolatey -y
        } else {
            Write-Host "Chocolatey está actualizado."
            Write-Log "Chocolatey está actualizado." -level "INFO"
        }
    } catch {
        Write-Host "Error al comprobar la versión de Chocolatey: $($_.Exception.Message)"
        Write-Log "Error al comprobar la versión de Chocolatey: $($_.Exception.Message)" -level "ERROR"
    }
}

# Lista inicial de programas
$chocoPrograms = @(
    "googlechrome",
    "vlc",
    "foxitreader",
    "7zip",
    "tsprintclient",
    "webview2-runtime",
    "lightshot",
    "",
    "microsoft-teams-new-bootstrapper"
)

# Función para comprobar si un programa está instalado
function Is-ProgramInstalled {
    param (
        [string]$program
    )

    $installed = choco list --local-only | Select-String $program
    return $installed -ne $null
}

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
        $currentProgram++
        try {
            if ($update -or -not (Is-ProgramInstalled -program $program)) {
                $action = if ($update) { "Actualizando" } else { "Instalando" }
                Write-Host "$action $program..."
                Write-Log "$action $program..." -level "INFO"

                $chocoCommand = if ($update) {
                    "choco upgrade $program -y --ignore-checksums"
                } else {
                    "choco install $program -y --ignore-checksums"
                }

                Invoke-Expression $chocoCommand
                Write-Host "$program $action correctamente."
                Write-Log "$program $action correctamente." -level "INFO"
            } else {
                Write-Host "$program ya está instalado. Omitiendo."
                Write-Log "$program ya está instalado. Omitiendo." -level "INFO"
            }

            Show-ProgressBar -program $program -currentProgram $currentProgram -totalPrograms $totalPrograms
        } catch {
            Write-Host "Error al $action $program $($_.Exception.Message)"
            Write-Log "Error al $action $program $($_.Exception.Message)" -level "ERROR"
            $failedPrograms += $program
        }
    }

    return $failedPrograms
}

# Función para gestionar la lista de programas
function Manage-ProgramList {
    do {
        Write-Host "Gestión de programas:"
        Write-Host "1: Ver lista de programas"
        Write-Host "2: Agregar un programa"
        Write-Host "3: Eliminar un programa"
        Write-Host "4: Volver al menú principal"
        $choice = Read-Host "Seleccione una opción"

        switch ($choice) {
            1 {
                Write-Host "Lista actual de programas:"
                $chocoPrograms | ForEach-Object { Write-Host "- $_" }
            }
            2 {
                $newProgram = Read-Host "Ingrese el nombre del programa para agregar"
                if (-not ($chocoPrograms -contains $newProgram)) {
                    $chocoPrograms += $newProgram
                    Write-Host "$newProgram agregado a la lista."
                    Write-Log "$newProgram agregado a la lista." -level "INFO"
                } else {
                    Write-Host "El programa ya está en la lista."
                }
            }
            3 {
                $removeProgram = Read-Host "Ingrese el nombre del programa para eliminar"
                if ($chocoPrograms -contains $removeProgram) {
                    $chocoPrograms = $chocoPrograms | Where-Object { $_ -ne $removeProgram }
                    Write-Host "$removeProgram eliminado de la lista."
                    Write-Log "$removeProgram eliminado de la lista." -level "INFO"
                } else {
                    Write-Host "El programa no está en la lista."
                }
            }
            4 { break }
            default { Write-Host "Opción no válida." }
        }
    } while ($choice -ne 4)
}

# Función para verificar el estado de los programas
function Check-InstallationStatus {
    Write-Host "Comprobando el estado de instalación..."
    foreach ($program in $chocoPrograms) {
        if (Is-ProgramInstalled -program $program) {
            Write-Host "$program está instalado."
            Write-Log "$program está instalado." -level "INFO"
        } else {
            Write-Host "$program no está instalado."
            Write-Log "$program no está instalado." -level "WARNING"
        }
    }
}

# Mostrar menú interactivo
function Show-Menu {
    Write-Host "Seleccione una opción:"
    Write-Host "1: Instalar programas"
    Write-Host "2: Actualizar programas"
    Write-Host "3: Verificar estado de instalación"
    Write-Host "4: Gestionar lista de programas"
    Write-Host "5: Buscar paquetes en la comunidad de Chocolatey"
    Write-Host "6: Salir"
}

# Ejecución principal con menú
do {
    Show-Menu
    $selection = Read-Host "Ingrese el número de la opción deseada"

    if ($selection -match '^[1-6]$') {
        switch ($selection) {
            1 {
                if (Test-InternetConnection) {
                    $failedPrograms = Install-Programs -programs $chocoPrograms -update $false
                    if ($failedPrograms.Count -eq 0) {
                        Write-Host "Instalación completa. Todos los programas han sido instalados."
                    } else {
                        Write-Host "Los siguientes programas no se pudieron instalar: $($failedPrograms -join ', ')"
                    }
                }
            }
            2 {
                if (Test-InternetConnection) {
                    $failedPrograms = Install-Programs -programs $chocoPrograms -update $true
                    if ($failedPrograms.Count -eq 0) {
                        Write-Host "Actualización completa. Todos los programas han sido actualizados."
                    } else {
                        Write-Host "Los siguientes programas no se pudieron actualizar: $($failedPrograms -join ', ')"
                    }
                }
            }
            3 {
                Check-InstallationStatus
            }
            4 {
                Manage-ProgramList
            }
            5 {
                Search-ChocolateyPackages
            }
            6 {
                Write-Host "Saliendo..."
                exit
            }
            default {
                Write-Host "Opción no válida."
            }
        }
    } else {
        Write-Host "Opción no válida. Por favor, elija un número entre 1 y 6."
    }
} while ($selection -ne "6")
