# Add Power Management tab to network adapter properties if not present
reg add "HKLM\System\CurrentControlSet\Control\Power" /v "PlatformAoAcOverride" /t REG_DWORD /d 0 /f

# Get network adapters
$networkAdapters = Get-NetAdapter

# Disable 'Allow the computer to turn off this device to save power' setting for each adapter
foreach ($adapter in $networkAdapters) {
    $adapterName = $adapter.Name
    Write-Host "Configuring settings for network adapter: $adapterName"

    # Disable power saving setting for the adapter
    $powerMgmtSettingPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$($adapter.PnpInstanceID)\PowerSettings"
    $powerMgmtSettingGuid = (Get-ItemProperty -Path $powerMgmtSettingPath).FriendlyName -like '*power saving*'
    if ($powerMgmtSettingGuid) {
        $powerMgmtSetting = Get-ItemProperty -Path "$powerMgmtSettingPath\$($powerMgmtSettingGuid[0].guid)"
        $powerMgmtSettingAttributes = $powerMgmtSetting.Attributes
        $powerMgmtSettingAttributes &= 0xFFFFFFFE
        Set-ItemProperty -Path "$powerMgmtSettingPath\$($powerMgmtSettingGuid[0].guid)" -Name Attributes -Value $powerMgmtSettingAttributes
        Write-Host "Power saving setting disabled for $adapterName"
    } else {
        Write-Host "Power saving setting not found for $adapterName"
    }

    # Disable Energy Efficient Ethernet for Ethernet adapters
    if ($adapter.InterfaceDescription -like '*Ethernet*') {
        $energyEfficientEthernetSetting = Get-NetAdapterAdvancedProperty -Name $adapterName -DisplayName 'Energy Efficient Ethernet'
        if ($energyEfficientEthernetSetting) {
            Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName 'Energy Efficient Ethernet' -DisplayValue 'Disabled'
            Write-Host "Energy Efficient Ethernet disabled for $adapterName"
        } else {
            Write-Host "Energy Efficient Ethernet setting not found for $adapterName"
        }
    }
}
