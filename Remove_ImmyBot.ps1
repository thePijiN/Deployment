$AppName = "ImmyBot Agent"

# Find the application by name
$App = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$AppName*" }

if ($App -ne $null) {
    # Uninstall the application
    $App.Uninstall()
    Write-Host "$AppName has been uninstalled."
} else {
    Write-Host "$AppName is not installed on this computer."
}
