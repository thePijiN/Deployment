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
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/HPIA.exe" -OutFile "$installersDirectory\HPIA.exe"

$hpiaPath = "C:\xpercare\installers\HPIA.exe"

# Check if the installer file exists
if (Test-Path $hpiaPath -PathType Leaf) {
    try {
        # Start the installation process silently
        Start-Process -FilePath $hpiaPath -ArgumentList "/S" -Wait -ErrorAction Stop
        Write-Host "HPIA installation completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing HPIA:" $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "HPIA installer not found at path: $hpiaPath" -ForegroundColor Red
}
