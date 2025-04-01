# Verificar e instalar Chocolatey si no está presente
if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey no está instalado. Iniciando la instalación..."

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
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
        return $false
    }

    Write-Host "Conexión a Internet confirmada."
    return $true 
}

# Función para verificar y actualizar Chocolatey
function Test-ChocolateyVersion {
    try {
        Write-Host "Comprobando actualizaciones de Chocolatey..."
        $upgradeAvailable = choco outdated | Select-String -Pattern "chocolatey"
        if ($upgradeAvailable) {
            Write-Host "Chocolatey no está actualizado. Actualizando..."
            choco upgrade chocolatey -y
        } else {
            Write-Host "Chocolatey está actualizado."
        }
    } catch {
        Write-Host "Error al comprobar la versión de Chocolatey: $($_.Exception.Message)"
    }
}

# Lista inicial de programas
$chocoPrograms = @(
    "googlechrome",
    "foxitreader",
    "7zip.install",
    "tsprintclient",
    "webview2-runtime",
    "lightshot",
    "microsoft-teams-new-bootstrapper",
    "posfordotnet.install",
    "dotnet4.5.2",
    "dotnet3.5",
    "splashtop-streamer"
)

# Preguntar al usuario qué fondo quiere instalar
$opcion = Read-Host "

*Elija que Fondo de Pantalla quiere Usar*

1-Agropaisa
2-Agromilenio
3-Ducol

"

# Definir URLs de las imágenes
$fondoAgropaisa = "http://192.168.99.14:8880/DESCARGAS/10.Fondo/Fondo/NUEVO%20AGROPAISA.png"
$fondoAgromilenio = "http://192.168.99.14:8880/DESCARGAS/10.Fondo/Fondo/fondo%20agromilenio.jpg"
$fondoDucol = "http://192.168.99.14:8880/DESCARGAS/10.Fondo/Fondo/FONDO%20DUCOL.png"

# Definir ruta local para guardar el fondo
$fondoLocal = "$env:USERPROFILE\Desktop\wallpaper.jpg"

# Seleccionar el fondo según la opción ingresada
switch ($opcion) {
    "1" { $urlFondo = $fondoAgropaisa }
    "2" { $urlFondo = $fondoAgromilenio }
    "3" { $urlFondo = $fondoDucol }
    default {
        Write-Host "Opción no válida. Saliendo..." -ForegroundColor Red
        exit
    }
}

### Pequeñas Modificaciones y Tweaks ###

# Descargar la imagen
Invoke-WebRequest -Uri $urlFondo -OutFile $fondoLocal

# Aplicar el fondo de pantalla en la política de Windows
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "Wallpaper" -Value $fondoLocal -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "WallpaperStyle" -Value 2 -Force

# Bloquear cambio de fondo de pantalla
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" -Name "NoChangingWallPaper" -Value 1 -Force

# Cambiar el nombre de la Maquina
$nombreMaquina = Read-Host "Ingrese el nombre de el equipo"
Write-Host "Si desea omitir el cambio de nombre de la maquina, presione Enter sin escribir nada."
if ($nombreMaquina -eq "") {
    Write-Host "Omitiendo el cambio de nombre de la máquina."
} else {
    Write-Host "Cambiando el nombre de la máquina a $nombreMaquina..."
}   
Rename-Computer -NewName $nombreMaquina -Force

# Cambiar la zona horaria a Colombia UTC-5 y sincronizar La Hora al servidor time.windows.com
Set-TimeZone -Id "SA Pacific Standard Time"
w32tm /config /manualpeerlist:time.windows.com /syncfromflags:manual /update
Restart-Service w32time
w32tm /resync


# Desactivar Hotspot Móvil
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections" -Name "NC_ShowSharedAccessUI" -Value 0 -Force

# Desactivar servicios de Gaming (Trazabilidad y demas Bloatware)
Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\Gaming\AllowGameDVR" -Name "Value" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\Games\AllowAdvancedGamingServices" -Name "Value" -Value 0 -Force


Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public static void SetWallpaper(string path) {
        SystemParametersInfo(20, 0, path, 3);
    }
}
"@ -Language CSharp

[Wallpaper]::SetWallpaper($fondoLocal)

Write-Host "Fondo de pantalla aplicado y bloqueado correctamente." -ForegroundColor Green 
Write-Host "Hotspot móvil desactivado." -ForegroundColor Green
write-host "Nombre de la maquina cambiado a $nombreMaquina, Veras los cambios aplicados despues de Reiniciar :)" -ForegroundColor Green


# Función para comprobar si un programa está instalado
function Get-ProgramInstalled {
    param (
        [string]$program
    )

    $installed = choco list --local-only | Select-String $program
    return $null -ne $installed
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
            if ($update -or -not (Get-ProgramInstalled -program $program)) {
                $action = if ($update) { "Actualizando" } else { "Instalando" }
                Write-Host "$action $program..."

                $chocoCommand = if ($update) {
                    "choco upgrade $program -y --ignore-checksums"
                } else {
                    "choco install $program -y --ignore-checksums"
                }

                Invoke-Expression $chocoCommand
                Write-Host "$program $action correctamente."
            } else {
                Write-Host "$program ya está instalado. Omitiendo."
            }

            Show-ProgressBar -program $program -currentProgram $currentProgram -totalPrograms $totalPrograms
        } catch {
            Write-Host "Error al $action $program $($_.Exception.Message)"
            $failedPrograms += $program
        }
    }

    return $failedPrograms
}

# Función para gestionar la lista de programas
function Edit-ProgramList {
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
                } else {
                    Write-Host "El programa ya está en la lista."
                }
            }
            3 {
                $removeProgram = Read-Host "Ingrese el nombre del programa para eliminar"
                if ($chocoPrograms -contains $removeProgram) {
                    $chocoPrograms = $chocoPrograms | Where-Object { $_ -ne $removeProgram }
                    Write-Host "$removeProgram eliminado de la lista."
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
function Test-InstallationStatus {
    Write-Host "Comprobando el estado de instalación..."
    foreach ($program in $chocoPrograms) {
        if (Get-ProgramInstalled -program $program) {
            Write-Host "$program está instalado."
        } else {
            Write-Host "$program no está instalado."
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
                Test-InstallationStatus
            }
            4 {
                Edit-ProgramList
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


### "Futuras Mejoras y Actualizaciones" 
# - [ ] Agregar la función de búsqueda de paquetes en la comunidad de Chocolatey.
# - [ ] Agregar la función de desinstalación de programas.
# - [ ] Agregar la función de actualización de Chocolatey Automatica.
# - [ ] Integrar la interfaz Grafica en WFP (Windows Presentation Foundation).
# - [ ] Integrar la interfaz Grafica en WinForms (Windows Forms).


