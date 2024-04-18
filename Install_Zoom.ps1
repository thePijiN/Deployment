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
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/ZoomInstaller.exe" -OutFile "$installersDirectory\ZoomInstaller.exe"

# Define the path to the Zoom installer
$zoomInstallerPath = "C:\xpercare\installers\zoominstaller.exe"

# Check if the installer file exists
if (Test-Path $zoomInstallerPath -PathType Leaf) {
    # Start the installation process
    Start-Process -FilePath $zoomInstallerPath -ArgumentList "/quiet"

	# Quiet doesn't want to work for zoom, so this waits 20 seconds (for install to finish) and then kills zoom.exe
    Start-Sleep -Seconds 20

    # Get the Zoom processes and terminate them
    $zoomProcesses = Get-Process | Where-Object { $_.ProcessName -eq "Zoom" }
    if ($zoomProcesses) {
        foreach ($process in $zoomProcesses) {
            $process | Stop-Process -Force
        }
        Write-Host "Zoom process terminated successfully." -ForegroundColor Green
    } else {
        Write-Host "Zoom process not found." -ForegroundColor Yellow
    }

    Write-Host "Zoom installation completed successfully." -ForegroundColor Green
} else {
    Write-Host "Zoom installer not found at the specified path." -ForegroundColor Red
}
