# Define the registry path
$registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb"

# Define the registry value name
$registryValueName = "ProtectionPolicy"

# Define the value to set (1 in this case)
$registryValueData = 1

# Create the registry key if it doesn't exist
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
}

# Set the registry value
New-ItemProperty -Path $registryPath -Name $registryValueName -Value $registryValueData -PropertyType DWORD -Force

Write-Host "Registry key 'ProtectionPolicy' created and set to '1'."
