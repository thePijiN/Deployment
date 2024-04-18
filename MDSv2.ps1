# Define the directory paths
$mainDirectory = "C:\xpercare"
$subDirectory = "$mainDirectory\MDS"

# Check if main directory exists, create if not
if (-not (Test-Path $mainDirectory -PathType Container)) {
    New-Item -Path $mainDirectory -ItemType Directory -Force
    Write-Host "Created directory: $mainDirectory"
}

# Check if sub directory exists, create if not
if (-not (Test-Path $subDirectory -PathType Container)) {
    New-Item -Path $subDirectory -ItemType Directory -Force
    Write-Host "Created directory: $subDirectory"
}

# Define the content for scripts
$ConfigurePowerContent = @'
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
'@
$DisableHELLOContent = @'
# Define the registry path for the Windows Hello for Business setting
$registryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Biometrics'

# Define the registry value name for the Windows Hello for Business setting
$registryValue = 'Enabled'

# Set the registry value to 0 to disable Windows Hello for Business
New-Item -Path $registryPath -Force | Out-Null
Set-ItemProperty -Path $registryPath -Name $registryValue -Value 0

Write-Host "Windows Hello for Business has been disabled."
'@
$NeverNotifyUACContent = @'
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
'@
$SetTimeZoneContent = @'
Set-TimeZone -Id "Eastern Standard Time"
w32tm /resync
'@
$ConfigureTaskbarContent = @'
# Disable News & Interest
$feedsKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds'
$feedsValueName = 'ShellFeedsTaskbarViewMode'
$feedsExpectedValue = 2

if (-not (Test-Path $feedsKey)) {
    New-Item -Path $feedsKey -Force
}

if (-not (Test-Path "$feedsKey\$feedsValueName")) {
    New-ItemProperty -Path $feedsKey -Name $feedsValueName -Value $feedsExpectedValue -PropertyType DWORD -Force
	Write-Host "Created DWORD key for News & Interests"
} else {
    $currentValue = (Get-ItemProperty -Path "$feedsKey\$feedsValueName").$feedsValueName
    if ($currentValue -ne $feedsExpectedValue) {
        Set-ItemProperty -Path "$feedsKey\$feedsValueName" -Name $feedsValueName -Value $feedsExpectedValue
		Write-Host "Disabled News & Interests on taskbar"
    }
}

# Disable Task-View button
$explorerKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$taskViewButtonValueName = 'ShowTaskViewButton'
$taskViewButtonExpectedValue = 0

if (-not (Test-Path $explorerKey)) {
    New-Item -Path $explorerKey -Force
}

if (-not (Test-Path "$explorerKey\$taskViewButtonValueName")) {
    New-ItemProperty -Path $explorerKey -Name $taskViewButtonValueName -Value $taskViewButtonExpectedValue -PropertyType DWORD -Force
	Write-Host "Created DWORD key for Task-View button"
} else {
    $currentValue = (Get-ItemProperty -Path "$explorerKey\$taskViewButtonValueName").$taskViewButtonValueName
    if ($currentValue -ne $taskViewButtonExpectedValue) {
        Set-ItemProperty -Path "$explorerKey\$taskViewButtonValueName" -Name $taskViewButtonValueName -Value $taskViewButtonExpectedValue
		Write-Host "Disabled Task-View button on taskbar"
    }
}

# Set Search Bar to show icon only
$searchKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
$searchValueName = 'SearchboxTaskbarMode'
$searchExpectedValue = 1

if (-not (Test-Path $searchKey)) {
    New-Item -Path $searchKey -Force
}

if (-not (Test-Path "$searchKey\$searchValueName")) {
    New-ItemProperty -Path $searchKey -Name $searchValueName -Value $searchExpectedValue -PropertyType DWORD -Force
	Write-Host "Created DWORD key for Search Bar preferences"
} else {
    $currentValue = (Get-ItemProperty -Path "$searchKey\$searchValueName").$searchValueName
    if ($currentValue -ne $searchExpectedValue) {
        Set-ItemProperty -Path "$searchKey\$searchValueName" -Name $searchValueName -Value $searchExpectedValue
		Write-Host "Set Search Bar to 'icon-only'"
    }
}

# Remove Cortana button from taskbar
$shell = New-Object -ComObject "Shell.Application"
$folder = $shell.Namespace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}')
$item = $folder.Parsename('Cortana.lnk')

if ($item -ne $null) {
    $item.InvokeVerb('unpin from taskbar')
} else {
    Write-Host "Cortana not found on the taskbar."
}
'@
$BloatwareBegoneContent = @'
$packageNames = @(
	#Windows
    "*3Dviewer*",
    "*Microsoft.BingWeather*",
	"Microsoft.BingNews", 
	"Microsoft.GamingApp", 
    "*Microsoft.MicrosoftSolitaireCollection*",
    "*xbox*",
    "*Microsoft.SkypeApp*",
    "*GetHelp*", 
    "*Disney*",
    "*SpotifyAB.SpotifyMusic*",
    "*BingTranslator*",
    "*3dbuilder*",
    "*bingfinance*", 
    "*BingNews*", 
    "*oneconnect*", 
    "*bingsports*", 
    "*twitter*", 
    "*royalrevolt2*", 
    "*marchofempires*", 
    "*candycrushsodasaga*", 
    "*messaging*", 
    "*autodesksketchbook*", 
    "*bubblewitch3saga*", 
    "*keepersecurityinc*", 
    "*HPJumpStart*", 
    "*DiscoverHPTouchpointManager*", 
    "*Keeper*", 
    "*networkspeedtest*", 
    "*MinecraftUWP*", 
    "*RemoteDesktop*", 
    "*MicrosoftPowerBIForWindows*", 
    "*Office.Sway*", 
    "*AdobePhotoshopExpress*", 
    "*EclipseManager*", 
    "*Duolingo-LearnLanguagesforFree*", 
    "*562882FEEB491*", 
    "*29680B314EFC2*", 
    "*Print3D*", 
    "*FreshPaint*", 
    "*Flipboard*", 
    "*BingTranslator*", 
    "*SpotifyMusic*", 
    "*29680B314EFC2*",
	"*Microsoft.Advertising.Xaml*", 
	"*Microsoft.XboxGameCallableUI*",
	"*Microsoft.MixedReality.Portal*", 
	"*Microsoft.XboxSpeechToTextOverlay*", 
	"*Microsoft.XboxGameOverlay*", 
	"*Microsoft.Xbox.TCUI*", 
	"*Microsoft.XboxApp*", 
	"Microsoft.XboxIdentityProvider", 
	#Dell
	"DellInc.PartnerPromo_1.0.21.0_x64__htrsf667h5kn2",
	"DellInc.DellSupportAssistforPCs", 
	"DellInc.DellPowerManager", 
	"HONHAIPRECISIONINDUSTRYCO.DellWatchdogTimer", 
	"DellInc.DellOptimizer", 
	#HP
	"AD2F1837.HPDisplayCenter", 
	"AD2F1837.HPPowerManager", 
	"AD2F1837.HPSystemInformation", 
	"AD2F1837.HPQuickDrop", 
	"AD2F1837.HPPrivacySettings", 
	"AD2F1837.HPPCHardwareDiagnosticsWindows", 
	"AD2F1837.HPEasyClean", 
	"AD2F1837.myHP", 
	"AD2F1837.HPSupportAssistant", 
	"AD2F1837.HPProgrammableKey", 
	"SynapticsIncorporated.SynHPCommercialStykDApp", 
	#Other
	"DolbyLaboratories.DolbyVisionAccess", 
	"DolbyLaboratories.DolbyAccessOEM"
	# Add more packages as needed
)
$xpercareDirectory = "C:\xpercare\"
#Create C:\xpercare if it doesn't already exists
if (!(Test-Path $xpercareDirectory -PathType Container)) {
	    New-Item -ItemType Directory -Force -Path $xpercareDirectory
	    Write-Host "Created C:\xpercare\"
    } else {
	    Write-Host "C:\xpercare already exists!"
	}

        $RemovedAppsTotal = 0
	foreach ($packageName in $packageNames) {
		$app = Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue
		if ($null -ne $app) {
			Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like $packageName } | Remove-AppxPackage
			Remove-AppxProvisionedPackage -Online -PackageName $packageName
			$RemovedAppsTotal++
			if ($RemovedAppsTotal -gt 0) {
				Write-Host $packageName
			}
		}
	}
'@
$BloatwareBegoneHPContent = @'
$UninstallPackages = @(
    "AD2F1837.HPJumpStarts"
    "AD2F1837.HPPCHardwareDiagnosticsWindows"
    "AD2F1837.HPPowerManager"
    "AD2F1837.HPPrivacySettings"
    "AD2F1837.HPSupportAssistant"
    "AD2F1837.HPSureShieldAI"
    "AD2F1837.HPSystemInformation"
    "AD2F1837.HPQuickDrop"
    "AD2F1837.HPWorkWell"
    "AD2F1837.myHP"
    "AD2F1837.HPDesktopSupportUtilities"
    "AD2F1837.HPQuickTouch"
    "AD2F1837.HPEasyClean"
    "AD2F1837.HPSystemInformation"
)

# List of programs to uninstall
$UninstallPrograms = @(
    "HP Client Security Manager"
    "HP Connection Optimizer"
    "HP Documentation"
    "HP MAC Address Manager"
    "HP Notifications"
    "HP Security Update Service"
    "HP System Default Settings"
    "HP Sure Click"
    "HP Sure Click Security Browser"
    "HP Sure Run"
    "HP Sure Recover"
    "HP Sure Sense"
    "HP Sure Sense Installer"
    "HP Wolf Security"
    "HP Wolf Security Application Support for Sure Sense"
    "HP Wolf Security Application Support for Windows"
)

$HPidentifier = "AD2F1837"

$InstalledPackages = Get-AppxPackage -AllUsers `
            | Where-Object {($UninstallPackages -contains $_.Name) -or ($_.Name -match "^$HPidentifier")}

$ProvisionedPackages = Get-AppxProvisionedPackage -Online `
            | Where-Object {($UninstallPackages -contains $_.DisplayName) -or ($_.DisplayName -match "^$HPidentifier")}

$InstalledPrograms = Get-Package | Where-Object {$UninstallPrograms -contains $_.Name}

# Remove appx provisioned packages - AppxProvisionedPackage
ForEach ($ProvPackage in $ProvisionedPackages) {

    Write-Host -Object "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."

    Try {
        $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
        Write-Host -Object "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
    }
    Catch {Write-Warning -Message "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"}
}

# Remove appx packages - AppxPackage
ForEach ($AppxPackage in $InstalledPackages) {
                                            
    Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."

    Try {
        $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
        Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
    }
    Catch {Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]"}
}

# Remove installed programs
$InstalledPrograms | ForEach-Object {

    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."

    Try {
        $Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    }
    Catch {Write-Warning -Message "Failed to uninstall: [$($_.Name)]"}
}

# Fallback attempt 1 to remove HP Wolf Security using msiexec
Try {
    MsiExec /x "{0E2E04B0-9EDD-11EB-B38C-10604B96B11E}" /qn /norestart
    Write-Host -Object "Fallback to MSI uninistall for HP Wolf Security initiated"
}
Catch {
    Write-Warning -Object "Failed to uninstall HP Wolf Security using MSI - Error message: $($_.Exception.Message)"
}

# Fallback attempt 2 to remove HP Wolf Security using msiexec
Try {
    MsiExec /x "{4DA839F0-72CF-11EC-B247-3863BB3CB5A8}" /qn /norestart
    Write-Host -Object "Fallback to MSI uninistall for HP Wolf 2 Security initiated"
}
Catch {
    Write-Warning -Object  "Failed to uninstall HP Wolf Security 2 using MSI - Error message: $($_.Exception.Message)"
}
'@
$ConfigureTeamsTrafficContent = @'
# Function to check if a NetQoS policy exists
function Test-NetQosPolicy {
    param (
        [string]$PolicyName
    )
    
    $policy = Get-NetQosPolicy -Name $PolicyName -ErrorAction SilentlyContinue
    return [bool]($policy -ne $null)
}

# Function to create a NetQoS policy and notify the user
function Create-NetQosPolicy {
    param (
        [string]$PolicyName,
        [string]$PolicyDescription,
        [string]$AppPathNameMatchCondition,
        [int]$IPSrcPortStartMatchCondition,
        [int]$IPSrcPortEndMatchCondition,
        [int]$DSCPAction
    )

    # Create the NetQoS policy
    new-NetQosPolicy -Name $PolicyName -AppPathNameMatchCondition $AppPathNameMatchCondition -IPProtocolMatchCondition Both -IPSrcPortStartMatchCondition $IPSrcPortStartMatchCondition -IPSrcPortEndMatchCondition $IPSrcPortEndMatchCondition -DSCPAction $DSCPAction -NetworkProfile All
    
    # Notify the user
    Write-Host "Created '$PolicyDescription' policy." -ForegroundColor Green
}

# Check if Teams Audio policy exists
if (-not (Test-NetQosPolicy -PolicyName "Teams Audio")) {
    Create-NetQosPolicy -PolicyName "Teams Audio" -PolicyDescription "Teams Audio" -AppPathNameMatchCondition "Teams.exe" -IPSrcPortStartMatchCondition 50000 -IPSrcPortEndMatchCondition 50019 -DSCPAction 46
} else {
    Write-Host "'Teams Audio' policy already exists." -ForegroundColor Yellow
}

# Check if Teams Video policy exists
if (-not (Test-NetQosPolicy -PolicyName "Teams Video")) {
    Create-NetQosPolicy -PolicyName "Teams Video" -PolicyDescription "Teams Video" -AppPathNameMatchCondition "Teams.exe" -IPSrcPortStartMatchCondition 50020 -IPSrcPortEndMatchCondition 50039 -DSCPAction 34
} else {
    Write-Host "'Teams Video' policy already exists." -ForegroundColor Yellow
}

# Check if Teams Share policy exists
if (-not (Test-NetQosPolicy -PolicyName "Teams Share")) {
    Create-NetQosPolicy -PolicyName "Teams Share" -PolicyDescription "Teams Share" -AppPathNameMatchCondition "Teams.exe" -IPSrcPortStartMatchCondition 50040 -IPSrcPortEndMatchCondition 50059 -DSCPAction 18
} else {
    Write-Host "'Teams Share' policy already exists." -ForegroundColor Yellow
}
'@
$ConfigurePublicDesktopContent = @'
# Define the app paths
$apps = @{
    'Outlook'    = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk'
    'Word'       = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk'
    'Excel'      = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Excel.lnk'
    'PowerPoint' = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk'
    'OneDrive'   = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'
    'Teams'      = 'C:\Program Files\WindowsApps\MSTeams_23285.3607.2525.937_x64__8wekyb3d8bbwe\ms-teams.exe'
}

# Define additional paths for checks
$teamsOldPath = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Teams\current\Teams.exe"
$oneDriveOldPath = "C:\Program Files\Microsoft OneDrive\onedrive.exe"

# Define the public desktop path
$publicDesktop = 'C:\Users\Public\Desktop'

# Check and create shortcuts
foreach ($app in $apps.GetEnumerator()) {
    $appName = $app.Key
    $appPath = $app.Value
    $shortcutPath = Join-Path -Path $publicDesktop -ChildPath "$appName.lnk"

    if (Test-Path $shortcutPath) {
        Write-Host "Detected $appName shortcut on public desktop."
    } else {
        if (Test-Path $appPath) {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $appPath
            $shortcut.Save()
            Write-Host "Created $appName shortcut on public desktop."
        } elseif ($appName -eq 'Teams' -and (Test-Path $teamsOldPath)) {
            Write-Host "New Teams was not detected, but old Teams was. Run Teams and update to New Teams!"
        } elseif ($appName -eq 'OneDrive' -and (Test-Path $oneDriveOldPath)) {
            Write-Host "OneDrive needs to be updated! Skipping this shortcut."
        } else {
            Write-Host "Did NOT find $appName at the expected location! Skipping this shortcut!"
        }
    }
}
$goToMeetingPath = "C:\users\public\desktop\GoToMeeting.lnk"

if (Test-Path $goToMeetingPath) {
    Remove-Item $goToMeetingPath -Force
    Write-Host "The 'GoToMeeting' shortcut has been deleted."
} else {
    Write-Host "The 'GoToMeeting' shortcut was not found."
}
'@
$ActivateBitlockerContent = @'
# Check if BitLocker is enabled on the C: drive
$bitlockerVolume = Get-BitLockerVolume -MountPoint "C:"
if ($bitlockerVolume.VolumeStatus -ne "FullyEncrypted") {
	# Enable BitLocker on the C: drive if not already enabled
	Enable-BitLocker -MountPoint "C:" -UsedSpaceOnly -EncryptionMethod "AES256" -TpmProtector
	Write-Output "Attempted to enable Bitlocker on C:\ drive. Reboot required to finish encryption!"
} else {
	Write-Output "BitLocker is already enabled on C:\ drive."
}
'@
$UpdateWindowsContent = @'
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)] [ValidateSet('Soft', 'Hard', 'None', 'Delayed')] [String] $Reboot = 'None',
    [Parameter(Mandatory=$False)] [Int32] $RebootTimeout = 120
)

Process
{

# If we are running as a 32-bit process on an x64 system, re-launch as a 64-bit process
if ("$env:PROCESSOR_ARCHITEW6432" -ne "ARM64")
{
    if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe")
    {
        & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath" -Reboot $Reboot -RebootTimeout $RebootTimeout
        Exit $lastexitcode
    }
}

# Create a tag file just so Intune knows this was installed
if (-not (Test-Path "$($env:ProgramData)\Microsoft\UpdateOS"))
{
    Mkdir "$($env:ProgramData)\Microsoft\UpdateOS"
}
Set-Content -Path "$($env:ProgramData)\Microsoft\UpdateOS\UpdateOS.ps1.tag" -Value "Installed"

# Start logging
Start-Transcript "$($env:ProgramData)\Microsoft\UpdateOS\UpdateOS.log"

# Main logic
$needReboot = $false

# Load module from PowerShell Gallery
$ts = get-date -f "yyyy/MM/dd hh:mm:ss tt"
Write-Host "$ts Importing NuGet and PSWindowsUpdate"
$null = Install-PackageProvider -Name NuGet -Force
$null = Install-Module PSWindowsUpdate -Force
Import-Module PSWindowsUpdate

# Install all available updates
$ts = get-date -f "yyyy/MM/dd hh:mm:ss tt"
Write-Host "$ts Installing updates."
Install-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose | Select Title, KB, Result | Format-Table
$needReboot = (Get-WURebootStatus -Silent).RebootRequired

# Specify return code
$ts = get-date -f "yyyy/MM/dd hh:mm:ss tt"
if ($needReboot) {
    Write-Host "$ts Windows Update indicated that a reboot is needed."
} else {
    Write-Host "$ts Windows Update indicated that no reboot is required."
}

# For whatever reason, the reboot needed flag is not always being properly set.  So we always want to force a reboot.
# If this script (as an app) is being used as a dependent app, then a hard reboot is needed to get the "main" app to
# install.
$ts = get-date -f "yyyy/MM/dd hh:mm:ss tt"
if ($Reboot -eq "Hard") {
    Write-Host "$ts Exiting with return code 1641 to indicate a hard reboot is needed."
    Stop-Transcript
    Exit 1641
} elseif ($Reboot -eq "Soft") {
    Write-Host "$ts Exiting with return code 3010 to indicate a soft reboot is needed."
    Stop-Transcript
    Exit 3010
} elseif ($Reboot -eq "Delayed") {
    Write-Host "$ts Rebooting with a $RebootTimeout second delay"
    & shutdown.exe /r /t $RebootTimeout /c "Rebooting to complete the installation of Windows updates."
    Exit 0
} else {
    Write-Host "$ts Skipping reboot based on Reboot parameter (None)"
    Exit 0
}

}
'@

# Define the paths for the script files
$ConfigurePowerPath = "$subDirectory\ConfigurePower.ps1"
$DisableHELLOPath = "$subDirectory\DisableHELLO.ps1"
$NeverNotifyUACPath = "$subDirectory\NeverNotifyUAC.ps1"
$SetTimeZonePath = "$subDirectory\SetTimeZone.ps1"
$ConfigureTaskbarPath = "$subDirectory\ConfigureTaskbar.ps1"
$BloatwareBegonePath = "$subDirectory\BloatwareBegone.ps1"
$BloatwareBegoneHPPath = "$subDirectory\BloatwareBegoneHP.ps1"
$ConfigureTeamsTrafficPath = "$subDirectory\ConfigureTeamsTraffic.ps1"
$ConfigurePublicDesktopPath = "$subDirectory\ConfigurePublicDesktop.ps1"
$ActivateBitlockerPath = "$subDirectory\ActivateBitlocker.ps1"
$UpdateWindowsPath = "$subDirectory\UpdateWindows.ps1"

# Create scripts
$ConfigurePowerContent | Out-File -FilePath $ConfigurePowerPath -Encoding ascii
$DisableHELLOContent | Out-File -FilePath $DisableHELLOPath -Encoding ascii
$NeverNotifyUACContent | Out-File -FilePath $NeverNotifyUACPath -Encoding ascii
$SetTimeZoneContent | Out-File -FilePath $SetTimeZonePath -Encoding ascii
$ConfigureTaskbarContent | Out-File -FilePath $ConfigureTaskbarPath -Encoding ascii
$BloatwareBegoneContent | Out-File -FilePath $BloatwareBegonePath -Encoding ascii
$BloatwareBegoneHPContent | Out-File -FilePath $BloatwareBegoneHPPath -Encoding ascii
$ConfigureTeamsTrafficContent | Out-File -FilePath $ConfigureTeamsTrafficPath -Encoding ascii
$ConfigurePublicDesktopContent | Out-File -FilePath $ConfigurePublicDesktopPath -Encoding ascii
$ActivateBitlockerContent | Out-File -FilePath $ActivateBitlockerPath -Encoding ascii
$UpdateWindowsContent | Out-File -FilePath $UpdateWindowsPath -Encoding ascii

# Define the directory containing the scripts
$scriptDirectory = "C:\xpercare\MDS"

# Get all script files in the directory
$scriptPaths = Get-ChildItem -Path $scriptDirectory -Filter "*.ps1" -File | ForEach-Object { $_.FullName }

# Loop through each script path and execute the script
foreach ($scriptPath in $scriptPaths) {
    try {
        Write-Host "Running script: $scriptPath"
        & $scriptPath
        Write-Host "Script completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while running script: $scriptPath" -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Yellow
    }
}


<#
# Run the scripts one at a time with admin rights
Start-Process powershell.exe -ArgumentList "-File $SetConfigurePower" -Verb RunAs -Wait
Start-Process powershell.exe -ArgumentList "-File $SetDisableHELLO" -Verb RunAs -Wait
Start-Process powershell.exe -ArgumentList "-File $SetNeverNotifyUAC" -Verb RunAs -Wait
Start-Process powershell.exe -ArgumentList "-File $SetSetTimeZone" -Verb RunAs -Wait
Start-Process powershell.exe -ArgumentList "-File $SetConfigureTaskbar" -Verb RunAs -Wait
Start-Process powershell.exe -ArgumentList "-File $SetBloatwareBegone" -Verb RunAs -Wait
Start-Process powershell.exe -ArgumentList "-File $SetBloatwareBegoneHP" -Verb RunAs -Wait
Start-Process powershell.exe -ArgumentList "-File $SetConfigureTeamsTraffic" -Verb RunAs -Wait
Start-Process powershell.exe -ArgumentList "-File $SetConfigurePublicDesktop" -Verb RunAs -Wait
Start-Process powershell.exe -ArgumentList "-File $SetActivateBitlocker" -Verb RunAs -Wait
Start-Process powershell.exe -ArgumentList "-File $SetUpdateWindows" -Verb RunAs -Wait
#>
