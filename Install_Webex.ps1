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
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/Webex.exe" -OutFile "$installersDirectory\Webex.exe"


# Define the path to the WebEx installer
$webExInstallerPath = "C:\xpercare\installers\webex.exe"

# Check if the installer file exists
if (Test-Path $webExInstallerPath -PathType Leaf) {
    # Start the installation process silently without waiting
    Start-Process -FilePath $webExInstallerPath -ArgumentList "/S"

    Write-Host "Installing Cisco WebEx..."

    # Wait for 30 seconds for the installation to complete
    Write-Host "Waiting 40 seconds for installation to finish..."
    Start-Sleep -Seconds 40

    # Send key strokes to accept the license agreement
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Write-Host "Accepted Cisco WebEx license agreement.`nWaiting 5 more seconds for installation to finalize..."
    # Wait for 5 seconds
    Start-Sleep -Seconds 5

    # Kill the ciscocollabhost.exe process
    Get-Process -Name ciscocollabhost | Stop-Process -Force

    Write-Host "Cisco WebEx installation completed successfully." -ForegroundColor Green
} else {
    Write-Host "WebEx installer not found at the specified path." -ForegroundColor Red
}
