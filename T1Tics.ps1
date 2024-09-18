# Instalación de Chocolatey (si no está instalado)
if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; 
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Lista de programas para instalar con Chocolatey
$chocoPrograms = @(
    "googlechrome",
    "vlc",
    "adobereader",
    "7zip",
    "tsprintclient",
    "webview2-runtime",
    ""
)

# Instalación de programas con Chocolatey
foreach ($program in $chocoPrograms) {
    choco install $program -y
}

# Lista de programas para instalar con Winget
$wingetPrograms = @(
    "Lightshot",
    "anydesk",
    "XP8BT8DW290MPQ"
)

# Instalación de programas con Winget
foreach ($program in $wingetPrograms) {
    winget install $program -e --accept-package-agreements --accept-source-agreements
}

# Mensaje final
Write-Host "Instalación completa. Todos los programas han sido instalados."
