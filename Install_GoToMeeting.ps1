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
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/Ninite-GoToMeeting%20Installer.exe" -OutFile "$installersDirectory\NiniteGTM.exe"
# Install Ninite silently
Start-Process -FilePath "$installersDirectory\NiniteGTM.exe" -Wait
# Remove the desktop shortcut
Remove-Item -Path "C:\users\public\desktop\gotomeeting.lnk" -Force
