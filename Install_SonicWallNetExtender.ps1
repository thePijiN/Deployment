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
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/NetExtender-x64-10.2.331.msi" -OutFile "$installersDirectory\NetExtender-x64-10.2.331.msi"

$msiPath = "$installersDirectory\NetExtender-x64-10.2.331.msi"

# Check if the MSI file exists
if (Test-Path $msiPath -PathType Leaf) {
    # Attempt to install the MSI silently
    try {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$msiPath`"", "/qn", "/norestart" -Wait -NoNewWindow
        Write-Host "SonicWall NetExtender installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing SonicWall NetExtender." -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "Error: MSI file not found at $msiPath" -ForegroundColor Red
}
