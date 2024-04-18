# Check if Clipboard History is enabled
$ClipboardHistoryEnabled = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory").EnableClipboardHistory

# Toggle Clipboard History
if ($ClipboardHistoryEnabled -eq 1) {
    # Clipboard History is enabled, turn it off
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Value 0
    Write-Host "Clipboard History has been turned off."
} else {
    # Clipboard History is disabled, turn it on
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Value 1
    Write-Host "Clipboard History has been turned on."
}
