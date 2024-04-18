# Check if running with elevated (admin) privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script as an administrator."
    Exit
}

# Define the registry path for the UAC setting
$registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'

# Define the registry value name for the UAC setting
$registryValue = 'EnableLUA'

# Set the registry value to 0 to set UAC to 'Never notify'
Set-ItemProperty -Path $registryPath -Name $registryValue -Value 0

Write-Host "UAC has been set to 'Never notify'. Changes will take effect after a system restart."
