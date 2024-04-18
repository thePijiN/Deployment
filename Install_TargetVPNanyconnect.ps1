# Define the list of MSI files in the desired installation order
$msiFiles = @(
    "1anyconnect-win-4.10.07062-core-vpn-predeploy-k9.msi",
    "2anyconnect-win-4.10.07062-iseposture-predeploy-k9.msi",
    "3cisco-secure-client-win-4.3.3534.8192-isecompliance-predeploy-k9.msi",
    "4anyconnect-win-4.10.07062-dart-predeploy-k9.msi"
)

# Define the source and destination paths for the XML file
$xmlSource = ".\tgt_default_vend.xml"
$xmlDestination = "C:\ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile\tgt_default_vend.xml"

# Check if the destination directory exists, if not, create it
if (-not (Test-Path -Path "C:\ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile")) {
    New-Item -ItemType Directory -Path "C:\ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile" | Out-Null
}

# Loop through each MSI file and install it
foreach ($msiFile in $msiFiles) {
    Write-Host "Installing $msiFile ..."
    Start-Process msiexec.exe -ArgumentList "/i `"$msiFile`" /quiet /qn" -Wait

    if ($LASTEXITCODE -eq 0) {
        Write-Host "$msiFile installation completed successfully." -ForegroundColor Green
    } else {
        Write-Host "Failed to install $msiFile. Exit code: $LASTEXITCODE" -ForegroundColor Red
    }
}

# Copy the XML file to the destination directory
try {
    Copy-Item -Path $xmlSource -Destination $xmlDestination -Force
    Write-Host "XML file copied to $xmlDestination" -ForegroundColor Green
} catch {
    Write-Host "Failed to copy XML file to $xmlDestination" -ForegroundColor Red
}
