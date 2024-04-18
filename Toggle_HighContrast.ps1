# Prompt the user to select an option
Write-Host "Select an option:"
Write-Host "1. Enable High Contrast Mode"
Write-Host "2. Disable High Contrast Mode"

# Read the user's input
$selection = Read-Host "Enter 1 to enable or 2 to disable:"

# Check the user's input and set the registry value accordingly
if ($selection -eq '1') {
    Set-ItemProperty -Path 'HKCU:\Control Panel\Accessibility' -Name 'HighContrast' -Value 1
    Write-Host "High Contrast Mode enabled."
} elseif ($selection -eq '2') {
    Set-ItemProperty -Path 'HKCU:\Control Panel\Accessibility' -Name 'HighContrast' -Value 0
    Write-Host "High Contrast Mode disabled."
} else {
    Write-Host "Invalid input. Please enter 1 or 2 to enable or disable High Contrast Mode."
}
