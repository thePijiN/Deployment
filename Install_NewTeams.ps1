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
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/NewTeams-x64.msix" -OutFile "$installersDirectory\NewTeams.exe"

# Install New Teams
# Path to the downloaded MSIX package
$msixPackagePath = "C:\xpercare\installers\NewTeams-x64.msix"

# Check if the MSIX package file exists
if (Test-Path $msixPackagePath -PathType Leaf) {
    try {
        # Install the MSIX package
        Add-AppxPackage -Path $msixPackagePath -ErrorAction Stop
        Write-Host "New Teams installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing New Teams." -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "The MSIX package file does not exist at the specified location." -ForegroundColor Red
}
