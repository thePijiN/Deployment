Write-Host "Initiating installation of O365..."
	# Define URLs for ODT setup and configuration file
$odtSetupUrl = "https://xpershare.blob.core.windows.net/installers/ODT_Setup.exe"
$odtConfigUrl = "https://xpershare.blob.core.windows.net/installers/ODT_O365forBusiness_en.xml"

# Define local directory to save downloaded files
$installersDir = "C:\xpercare\installers\odt"

# Create directory if it doesn't exist
if (-not (Test-Path $installersDir -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDir | Out-Null
}

# Define local paths to save downloaded files
$odtSetupFilePath = Join-Path -Path $installersDir -ChildPath "ODT_setup.exe"
$odtConfigFilePath = Join-Path -Path $installersDir -ChildPath "ODT_O365forBusiness_en.xml"

# Download ODT setup executable
Invoke-WebRequest -Uri $odtSetupUrl -OutFile $odtSetupFilePath

# Download ODT configuration file
Invoke-WebRequest -Uri $odtConfigUrl -OutFile $odtConfigFilePath

# Run ODT setup executable with administrative privileges and wait for completion
Start-Process -FilePath $odtSetupFilePath -ArgumentList "/configure", "$odtConfigFilePath" -Wait -Verb RunAs
Write-Host "Finished!"