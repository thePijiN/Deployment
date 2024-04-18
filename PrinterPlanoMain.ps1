# Plano main office printer install
$DriverDownloadURL = 'https://xpershare.blob.core.windows.net/labtechscripts/PlanoPrinterDrivers.zip?sv=2023-01-03&st=2024-01-31T18%3A59%3A46Z&se=2035-01-31T18%3A59%3A00Z&sr=b&sp=r&sig=HbzrM8AyAUlNZmNtByI9YzDWUbsYKQFEwjTEfHo0G0w%3D'
$DriverFileName = "PlanoPrinters.zip"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12;

#Remove Old Printers
Get-Printer | where computername -eq pcserver1 | Remove-Printer -ErrorAction SilentlyContinue
Get-Printer | where computername -eq pcserver1.pcdomain.local | Remove-Printer -ErrorAction SilentlyContinue
Remove-Printer -Name "10.0.0.100" -ErrorAction SilentlyContinue
Remove-Printer -Name "C60-C70-C41D PCL6" -ErrorAction SilentlyContinue
Remove-Printer -Name "Generic / Text Only" -ErrorAction SilentlyContinue
Remove-Printer -Name "PCCopyRoom-New" -ErrorAction SilentlyContinue
Remove-Printer -Name "Savin IM C6500 (PCCopyRoom-New)" -ErrorAction SilentlyContinue
Remove-Printer -Name "PCLargeProjects" -ErrorAction SilentlyContinue
Remove-Printer -Name "VersaLink C7030 PCL6-2" -ErrorAction SilentlyContinue
Remove-Printer -Name "10.0.0.20" -ErrorAction SilentlyContinue
Remove-Printer -Name "PCBackOffice-New" -ErrorAction SilentlyContinue
Remove-Printer -Name "Savin IM C3000LT (PCBackOffice-New)" -ErrorAction SilentlyContinue


#Check if printers are already installed
$InstalledPrinters = (Get-Printer).Name
# If printer is already installed, just exit
if ('Precon' -in $InstalledPrinters){
    exit 0
}
# If printer is already installed, just exit
if ('CopyRoom' -in $InstalledPrinters){
    exit 0
}
# If printer is already installed, just exit
if ('Operations' -in $InstalledPrinters){
    exit 0
}

#Setup printdrivers folder
if (-Not (Test-Path "C:\printerdrivers")){
    New-Item -Itemtype Directory -path "C:\printerdrivers"
}

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -uri $DriverDownloadURL -outfile "C:\PrinterDrivers\$DriverFileName"
Expand-Archive "C:\printerdrivers\$DriverFileName" -DestinationPath C:\printerdrivers -Force
get-childitem C:\printerdrivers -Recurse -Filter *.inf | foreach {& pnputil.exe /add-driver $_.fullname}

Add-PrinterPort -Name '10.0.0.20' -PrinterHostAddress '10.0.0.20'
Add-PrinterPort -Name '10.0.0.100' -PrinterHostAddress '10.0.0.100'
Add-PrinterPort -Name '10.0.0.129' -PrinterHostAddress '10.0.0.129'

Add-PrinterDriver -Name "SAVIN IM C3000 PCL 6"
Add-PrinterDriver -Name "SAVIN IM C6500 PCL 6"
Add-PrinterDriver -Name "Xerox VersaLink C7030 V4 PCL6"

Add-Printer -Name "Precon" -PortName "10.0.0.20" -DriverName "SAVIN IM C3000 PCL 6"
Add-Printer -Name "CopyRoom" -PortName "10.0.0.100" -DriverName "SAVIN IM C6500 PCL 6"
Add-Printer -Name "Operations" -PortName "10.0.0.129" -DriverName "Xerox VersaLink C7030 V4 PCL6"

Set-PrintConfiguration -printername "precon" -color $false -DuplexingMode 'OneSided'
Set-PrintConfiguration -printername "CopyRoom" -color $false -DuplexingMode 'OneSided'
Set-PrintConfiguration -printername "Operations" -color $false -DuplexingMode 'OneSided'

remove-item C:\printerdrivers -Recurse