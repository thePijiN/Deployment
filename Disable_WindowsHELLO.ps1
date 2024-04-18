# Define the registry path for the Windows Hello for Business setting
$registryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Biometrics'

# Define the registry value name for the Windows Hello for Business setting
$registryValue = 'Enabled'

# Set the registry value to 0 to disable Windows Hello for Business
New-Item -Path $registryPath -Force | Out-Null
Set-ItemProperty -Path $registryPath -Name $registryValue -Value 0

Write-Host "Windows Hello for Business has been disabled."
