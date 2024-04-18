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
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/nitro_pro13.exe" -OutFile "$installersDirectory\Nitro_Pro13.exe"

$nitroInstallerPath = "C:\xpercare\installers\nitro_pro13.exe"

# Check if the installer file exists
if (Test-Path $nitroInstallerPath -PathType Leaf) {
    try {
        Write-Host "Starting Nitro Pro 13 installation..." -ForegroundColor Yellow
        # Start the installation process silently
        $process = Start-Process -FilePath $nitroInstallerPath -PassThru
        # Wait for the installation process to finish
        $process.WaitForExit()
        if ($process.ExitCode -eq 0) {
            Write-Host "Nitro Pro 13 installation completed successfully." -ForegroundColor Green
        } else {
            Write-Host "Nitro Pro 13 installation failed with exit code $($process.ExitCode)." -ForegroundColor Red
        }
    } catch {
        Write-Host "Failed to install Nitro Pro 13 silently." -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "Nitro Pro 13 installer not found at path: $nitroInstallerPath" -ForegroundColor Red
}
