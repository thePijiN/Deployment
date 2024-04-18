# Set the power settings to 'Never' using powercfg
$powerSettingsGUIDs = @(
    '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e',  # Turn off the display
    '29f6c1db-86da-48c5-9fdb-f2b67b1f44da',  # Put the computer to sleep
    '94ac6d29-73ce-41a6-809f-6363ba21b47e'   # Turn off hard disk after
)

foreach ($guid in $powerSettingsGUIDs) {
    # Set power settings to 'Never'
    powercfg -change -monitor-timeout-ac 0
    powercfg -change -monitor-timeout-dc 0

    powercfg -change -standby-timeout-ac 0
    powercfg -change -standby-timeout-dc 0

    powercfg -change -disk-timeout-ac 0
    powercfg -change -disk-timeout-dc 0
}

Write-Host "Power and sleep settings set to 'Never' for the active power plan."
