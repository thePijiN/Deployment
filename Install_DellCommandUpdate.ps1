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
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/DellCommandUpdate.EXE" -OutFile "$installersDirectory\DellCommandUpdate.exe"

$dellUpdatePath = "C:\xpercare\installers\DellCommandUpdate.exe"

# Check if the installer file exists
if (Test-Path $dellUpdatePath -PathType Leaf) {
    try {
        # Start the installation process silently
        Start-Process -FilePath $dellUpdatePath -Wait -ErrorAction Stop
        Write-Host "DellCommandUpdate installation completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing DellCommandUpdate:" $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "DellCommandUpdate installer not found at path: $dellUpdatePath" -ForegroundColor Red
}
