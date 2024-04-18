# Disable sleep and hibernate
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0

# Set screen lock timeout to 5 minutes (5 minutes)
powercfg /change monitor-timeout-ac 5

#Create Reg key to enable the Power Management tab in Network Adapter Configuration
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Power" -Name "PlatformAoAcOverride" -Value 0 -PropertyType DWORD -Force
