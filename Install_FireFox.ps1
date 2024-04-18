# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/Firefox%20Installer.exe" -OutFile "$installersDirectory\FireFox Installer.exe"

$firefoxInstallerPath = "C:\xpercare\installers\firefox installer.exe"

# Check if the installer file exists
if (Test-Path $firefoxInstallerPath -PathType Leaf) {
    try {
        # Start the installation process silently
        Start-Process -FilePath $firefoxInstallerPath -ArgumentList "/S" -Wait -ErrorAction Stop
        Write-Host "Firefox installation completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing Firefox:" $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "Firefox installer not found at path: $firefoxInstallerPath" -ForegroundColor Red
}
