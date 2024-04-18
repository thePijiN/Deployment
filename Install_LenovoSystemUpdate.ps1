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
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/LenovoSystemUpdate.exe" -OutFile "$installersDirectory\LenovoSystemUpdate.exe"

$lenovoSysPath = "C:\xpercare\installers\LenovoSystemUpdate.exe"

# Check if the installer file exists
if (Test-Path $lenovoSysPath -PathType Leaf) {
    try {
        # Start the installation process silently
        Start-Process -FilePath $lenovoSysPath -ArgumentList "/S" -Wait -ErrorAction Stop
        Write-Host "LenovoSystemUpdate installation completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing LenovoSystemUpdate:" $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "LenovoSystemUpdate installer not found at path: $lenovoSysPath" -ForegroundColor Red
}
