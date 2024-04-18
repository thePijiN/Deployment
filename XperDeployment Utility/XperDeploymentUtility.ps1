# System task functions
function Check-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        Write-Host "True" -ForegroundColor Green
    } else {
        Write-Host "False! Please re-launch as administrator for full access" -ForegroundColor Red
    }
}
function Set-ExecutionPolicyUnrestricted {
    # Check if the script is running with administrative rights
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        # Set the Execution Policy to Unrestricted
        Set-ExecutionPolicy Unrestricted -Scope Process -Force
    } else {
        Write-Warning "This script requires administrative privileges to set the execution policy."
    }
}
function CreateMDS {
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
    if ($app -ne $null) {
        # Attempt to remove the app
        Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like $packageName } | Remove-AppxPackage -ErrorAction SilentlyContinue

        # Attempt to remove the provisioned package
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $packageName -ErrorAction Stop
        } catch {
            Write-Host "Error removing provisioned package: $_"
        }

        $RemovedAppsTotal++
        if ($RemovedAppsTotal -gt 0) {
            Write-Host "Removed app: $packageName"
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
$InstallNiniteContent = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/Ninite_7zipChromeReader.exe" -OutFile "$installersDirectory\Ninite.exe"
# Install Ninite silently
Start-Process -FilePath "$installersDirectory\Ninite.exe" -Wait
'@
$InstallO365Content = @'
Write-Host "Initiating installation of O365..."
	# Define URLs for ODT setup and configuration file
$odtSetupUrl = "https://xpershare.blob.core.windows.net/installers/ODT_Setup.exe"
$odtConfigUrl = "https://xpershare.blob.core.windows.net/installers/ODT_O365forBusiness_en.xml"

# Define local directory to save downloaded files
$installersDir = "C:\xpercare\installers\odt"

# Create directory if it doesn't exist
if (-not (Test-Path $installersDir -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDir | Out-Null
}

# Define local paths to save downloaded files
$odtSetupFilePath = Join-Path -Path $installersDir -ChildPath "ODT_setup.exe"
$odtConfigFilePath = Join-Path -Path $installersDir -ChildPath "ODT_O365forBusiness_en.xml"

# Download ODT setup executable
Invoke-WebRequest -Uri $odtSetupUrl -OutFile $odtSetupFilePath

# Download ODT configuration file
Invoke-WebRequest -Uri $odtConfigUrl -OutFile $odtConfigFilePath

# Run ODT setup executable with administrative privileges and wait for completion
Start-Process -FilePath $odtSetupFilePath -ArgumentList "/configure", "$odtConfigFilePath" -Wait -Verb RunAs
Write-Host "Finished!"
'@

# Define the paths for the script files
$InstallNinitePath = "$subDirectory\InstallNinite.ps1"
$InstallO365Path = "$subDirectory\InstallO365.ps1"
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
$InstallNiniteContent | Out-File -FilePath $InstallNinitePath -Encoding ascii
$InstallO365Content | Out-File -FilePath $InstallO365Path -Encoding ascii
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
}
function RunMDS{
CreateMDS

# Define the directory containing the scripts
$scriptDirectory = "C:\xpercare\MDS"

# Define the order in which scripts should be executed
$scriptOrder = @(
    "ConfigurePower.ps1",
    "ConfigureTeamsTraffic.ps1",
    "DisableHELLO.ps1",
    "NeverNotifyUAC.ps1",
    "SetTimeZone.ps1",
    "ActivateBitlocker.ps1",
    "BloatwareBegone.ps1",
    "BloatwareBegoneHP.ps1",
    #"InstallO365.ps1",
    #"InstallNinite.ps1",
    "ConfigurePublicDesktop.ps1",
    "UpdateWindows.ps1"
)

# Loop through each script in the specified order and execute them
foreach ($scriptName in $scriptOrder) {
    # Construct the full path of the script
    $scriptPath = Join-Path -Path $scriptDirectory -ChildPath $scriptName
    
    # Check if the script file exists
    if (Test-Path $scriptPath -PathType Leaf) {
        try {
            Write-Host "Running script: $scriptPath"
            & $scriptPath
            Write-Host "Script completed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error occurred while running script: $scriptPath" -ForegroundColor Red
            Write-Host "Error details: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Script not found: $scriptName" -ForegroundColor Red
    }
}
}
function RunMDSwInstall{
CreateMDS

# Define the directory containing the scripts
$scriptDirectory = "C:\xpercare\MDS"

# Define the order in which scripts should be executed
$scriptOrder = @(
    "ConfigurePower.ps1",
    "ConfigureTeamsTraffic.ps1",
    "DisableHELLO.ps1",
    "NeverNotifyUAC.ps1",
    "SetTimeZone.ps1",
    "ActivateBitlocker.ps1",
    "BloatwareBegone.ps1",
    "BloatwareBegoneHP.ps1",
    "InstallO365.ps1",
    "InstallNinite.ps1",
    "ConfigurePublicDesktop.ps1",
    "UpdateWindows.ps1"
)

# Loop through each script in the specified order and execute them
foreach ($scriptName in $scriptOrder) {
    # Construct the full path of the script
    $scriptPath = Join-Path -Path $scriptDirectory -ChildPath $scriptName
    
    # Check if the script file exists
    if (Test-Path $scriptPath -PathType Leaf) {
        try {
            Write-Host "Running script: $scriptPath"
            & $scriptPath
            Write-Host "Script completed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error occurred while running script: $scriptPath" -ForegroundColor Red
            Write-Host "Error details: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Script not found: $scriptName" -ForegroundColor Red
    }
}
}
function PullAgentID{
	$script = @'
$filePath = "C:\Windows\LTSvc\lterrors.txt"
$fileContent = Get-Content -Path $filePath
$joinedContent = [string]::Join("`n", $fileContent)
$pattern = "Signed Up with ID:\s*(\d{5})"
$match = [regex]::Match($joinedContent, $pattern)
# Check if a match is found
if ($match.Success) {
	# Extract the 5 digits from the match
	$agentID = $match.Groups[1].Value
	Write-Host "Agent ID: $agentID"
} else {
Write-Host "Unable to locate Agent ID within C:\Windows\LTSvc\LTErrors.txt!"
}
#Pause and wait for input
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function PullWindowsKey{
	$script = @'
$windowsKey = Get-WmiObject -Query "SELECT OA3xOriginalProductKey FROM SoftwareLicensingService" | Select-Object -ExpandProperty OA3xOriginalProductKey
Write-Host "Windows Activation Key: $windowsKey"
# Pause for user input before exiting
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function ConfigureDesktopAndTaskbar{
	$script = @'
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
# Define paths to applications
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# Define paths to shortcut files
$chromeShortcut = "$env:PUBLIC\Desktop\Google Chrome.lnk"
$edgeShortcut = "$env:PUBLIC\Desktop\Microsoft Edge.lnk"

# Function to create a shortcut
function Create-Shortcut {
    param(
        [string]$TargetPath,
        [string]$ShortcutPath
    )
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Save()
}

# Check if shortcuts exist, if not, create them
if (-not (Test-Path $chromeShortcut)) {
    Create-Shortcut -TargetPath $chromePath -ShortcutPath $chromeShortcut
    Write-Host "Google Chrome shortcut created."
} else {
    Write-Host "Google Chrome shortcut already exists."
}

if (-not (Test-Path $edgeShortcut)) {
    Create-Shortcut -TargetPath $edgePath -ShortcutPath $edgeShortcut
    Write-Host "Microsoft Edge shortcut created."
} else {
    Write-Host "Microsoft Edge shortcut already exists."
}
# Define the app paths
$apps = @{
    'Outlook'    = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk'
    'Word'       = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk'
    'Excel'      = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Excel.lnk'
    'PowerPoint' = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk'
    'OneDrive'   = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'
    'Teams'      = 'C:\Program Files\WindowsApps\MSTeams_23320.3014.2555.9170_x64__8wekyb3d8bbwe\ms-teams.exe'
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
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function GetAdblock{
	# Check if Microsoft Edge is installed
	if (Test-Path "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe") {
		# Open Microsoft Edge to Adblock Plus extension page
		Start-Process "msedge" "https://microsoftedge.microsoft.com/addons/detail/adblock-plus-free-ad-bl/gmgoamodcdcjnbaobigkjelfplakmdhh"
	}
	# Check if Google Chrome is installed
	if (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") {
		# Open Google Chrome to Adblock Plus extension page
		Start-Process "chrome" "https://chrome.google.com/webstore/detail/adblock-plus-free-ad-bloc/cfhdojbkjhnklbpkdaibdccddilifddb"
	}
	# Check if Mozilla Firefox is installed
	if (Test-Path "C:\Program Files\Mozilla Firefox\firefox.exe") {
		# Open Mozilla Firefox to Adblock Plus extension page
		Start-Process "firefox" "https://addons.mozilla.org/en-US/firefox/addon/adblock-plus/"
	}
}
function ActivateBitlocker{
	# Check if BitLocker is enabled on the C: drive
	$bitlockerVolume = Get-BitLockerVolume -MountPoint "C:"
	if ($bitlockerVolume.VolumeStatus -ne "FullyEncrypted") {
		# Enable BitLocker on the C: drive if not already enabled
		Enable-BitLocker -MountPoint "C:" -UsedSpaceOnly -EncryptionMethod "AES256" -TpmProtector
		Write-Output "Attempted to enable Bitlocker on C:\ drive. Reboot required to finish encryption!"
	} else {
		Write-Output "BitLocker is already enabled on C:\ drive."
	}
}
function DisableEnrollmentChecksOnSignIn{
	$script = @'
$EnrollmentKey = Get-ChildItem HKLM:\Software\Microsoft\Enrollments -recurse | Where-Object { $_.name -like "*firstsync*" }
$EnrollmentKey | Set-Itemproperty -name SkipDeviceStatusPage -value 1 -Force
$EnrollmentKey | Set-Itemproperty -name SkipUserStatusPage -value 1 -Force
Get-Process "winlogon" | stop-process -Force
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
	Write-Host "Ninite has been installed."
}
	# Dave's PasswordLess Helper functions
function EnablePasswordlessSignon{
	$Script = @'
Write-Host "Enabling web sign in" -foregroundcolor green
$RegPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\current\device\Authentication"
New-Item registry::$RegPath -force
New-ItemProperty -path registry::$Regpath -Name 'EnableWebSignIn' -value 1
New-ItemProperty -path registry::$Regpath -Name 'EnableWebSignIn_ProviderSet' -value 1
New-ItemProperty -path registry::$Regpath -Name 'EnableWebSignIn_WinningProvider' -value '3201EF00-E70D-49BA-8CFE-6D7048B31D47'
Write-Host "Enabling Windows Hello" -foregroundcolor green
$localgpo = 'C:\Windows\System32\GroupPolicy\Machine\Registry.pol'
if (test-path $localgpo){
remove-item $localgpo
}
"Updating policy"
gpupdate /force | out-null
if (-not (Test-Path hklm:\SOFTWARE\Policies\Microsoft\PassportForWork)){
new-item hklm:\SOFTWARE\Policies\Microsoft\PassportForWork -force
}
Set-itemproperty hklm:\SOFTWARE\Policies\Microsoft\PassportForWork -name enabled -value 1 -Force 
Set-itemproperty hklm:\SOFTWARE\Policies\Microsoft\PassportForWork -Name DisablePostLogonProvisioning -value 0 -Force
Write-Host "Done!" -foregroundcolor green
start-sleep -milliseconds 500
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function DisableWebSignOn{
	$Script = @'
$RegPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\current\device\Authentication"
if ((Test-Path registry::$RegPath)){
Remove-Item registry::$RegPath -recurse -force
Write-Host "Web sign on disabled" -foregroundcolor green
start-sleep -milliseconds 500
}	
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function ClearPin{
	$CurrentUser = whoami
	if ($CurrentUser -notmatch 'System'){
		write-host "YOU MUST RUN THIS AS THE SYSTEM ACCOUNT. Please switch to backstage to run this option." -foregroundcolor Red
		pause
	}
	try {
		Get-ChildItem "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc" | Remove-Item -recurse -force
		Set-itemproperty hklm:\SOFTWARE\Policies\Microsoft\PassportForWork -name enabled -value 0 -force
		Write-Host "Please reboot to complete removing the sign-in PIN."
		start-sleep 5
	}
	catch {
		$_
	}	
}
# Application (download &) installation functions
function InstallNinite {
	Write-Host "Installing Ninite..."
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/Ninite_7zipChromeReader.exe" -OutFile "$installersDirectory\Ninite.exe"
# Install Ninite silently
Start-Process -FilePath "$installersDirectory\Ninite.exe" -Verb RunAs -Wait
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
	Write-Host "Ninite has been installed."
}
function InstallGoToMeeting { 
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/Ninite-GoToMeeting%20Installer.exe" -OutFile "$installersDirectory\NiniteGTM.exe"
# Install Ninite silently
Start-Process -FilePath "$installersDirectory\NiniteGTM.exe" -Verb RunAs -Wait
# Remove the desktop shortcut
Remove-Item -Path "C:\users\public\desktop\gotomeeting.lnk" -Force
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function InstallO365 {
	Write-Host "Initiating O365 Installation..."
	$script = @'
	Write-Host "Initiating installation of O365..."
	# Define URLs for ODT setup and configuration file
$odtSetupUrl = "https://xpershare.blob.core.windows.net/installers/ODT_Setup.exe"
$odtConfigUrl = "https://xpershare.blob.core.windows.net/installers/ODT_O365.xml"

# Define local directory to save downloaded files
$installersDir = "C:\xpercare\installers\odt"

# Create directory if it doesn't exist
if (-not (Test-Path $installersDir -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDir | Out-Null
}

# Define local paths to save downloaded files
$odtSetupFilePath = Join-Path -Path $installersDir -ChildPath "ODT_setup.exe"
$odtConfigFilePath = Join-Path -Path $installersDir -ChildPath "ODT_O365.xml"

# Download ODT setup executable
Invoke-WebRequest -Uri $odtSetupUrl -OutFile $odtSetupFilePath

# Download ODT configuration file
Invoke-WebRequest -Uri $odtConfigUrl -OutFile $odtConfigFilePath

# Run ODT setup executable with administrative privileges and wait for completion
Start-Process -FilePath $odtSetupFilePath -ArgumentList "/configure", "$odtConfigFilePath" -Wait -Verb RunAs
Write-Host "Finished!"
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
	Write-Host "O365 for Business (En) has been installed."
}
function InstallO365wProjectVisio {
	Write-Host "Initiating O365 Installation..."
	$script = @'
	Write-Host "Initiating installation of O365..."
	# Define URLs for ODT setup and configuration file
$odtSetupUrl = "https://xpershare.blob.core.windows.net/installers/ODT_Setup.exe"
$odtConfigUrl = "https://xpershare.blob.core.windows.net/installers/ODT_O365%20Visio%20Project.xml"

# Define local directory to save downloaded files
$installersDir = "C:\xpercare\installers\odt"

# Create directory if it doesn't exist
if (-not (Test-Path $installersDir -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDir | Out-Null
}

# Define local paths to save downloaded files
$odtSetupFilePath = Join-Path -Path $installersDir -ChildPath "ODT_setup.exe"
$odtConfigFilePath = Join-Path -Path $installersDir -ChildPath "ODT_O365%Visio%Project.xml"

# Download ODT setup executable
Invoke-WebRequest -Uri $odtSetupUrl -OutFile $odtSetupFilePath

# Download ODT configuration file
Invoke-WebRequest -Uri $odtConfigUrl -OutFile $odtConfigFilePath

# Run ODT setup executable with administrative privileges and wait for completion
Start-Process -FilePath $odtSetupFilePath -ArgumentList "/configure", "$odtConfigFilePath" -Wait -Verb RunAs
Write-Host "Finished!"
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
	Write-Host "O365 for Business (En), Visio, and Project have been installed."
}
function InstallNewTeams{
	Write-Host "Initiating New Teams installation..."
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/NewTeams-x64.msix" -OutFile "$installersDirectory\NewTeams.msix"

# Install New Teams
# Path to the downloaded MSIX package
$msixPackagePath = "C:\xpercare\installers\NewTeams.msix"

# Check if the MSIX package file exists
if (Test-Path $msixPackagePath -PathType Leaf) {
    try {
        # Install the MSIX package
        Add-AppxPackage -Path $msixPackagePath -ErrorAction Stop
        Write-Host "New Teams installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing New Teams." -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "The MSIX package file does not exist at the specified location." -ForegroundColor Red
}
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
	Write-Host "New Teams has been installed."
}
function InstallGoogleEarthPro {
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download prereq installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/GoogleEarthProSetup.exe" -OutFile "$installersDirectory\GoogleEarthProSetup.exe"

# Install prereqs silently
Start-Process -FilePath "$installersDirectory\GoogleEarthProSetup.exe" -Wait
Write-Host "Installed Google Earth Pro"
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
	Write-Host "Google Earth Pro has been installed."
}
function InstallSonicWallNetExtender {
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/NetExtender-x64-10.2.331.msi" -OutFile "$installersDirectory\NetExtender-x64-10.2.331.msi"

$msiPath = "$installersDirectory\NetExtender-x64-10.2.331.msi"

# Check if the MSI file exists
if (Test-Path $msiPath -PathType Leaf) {
    # Attempt to install the MSI silently
    try {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$msiPath`"", "/qn", "/norestart" -Wait -NoNewWindow
        Write-Host "SonicWall NetExtender installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing SonicWall NetExtender." -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "Error: MSI file not found at $msiPath" -ForegroundColor Red
}
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
	Write-Host "SonicWallNetExtender has been installed."
}
function InstallZoom {
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/ZoomInstaller.exe" -OutFile "$installersDirectory\ZoomInstaller.exe"

# Define the path to the Zoom installer
$zoomInstallerPath = "C:\xpercare\installers\zoominstaller.exe"

# Check if the installer file exists
if (Test-Path $zoomInstallerPath -PathType Leaf) {
    # Start the installation process
    Start-Process -FilePath $zoomInstallerPath -ArgumentList "/quiet"

	# Quiet doesn't want to work for zoom, so this waits 20 seconds (for install to finish) and then kills zoom.exe
    Start-Sleep -Seconds 20

    # Get the Zoom processes and terminate them
    $zoomProcesses = Get-Process | Where-Object { $_.ProcessName -eq "Zoom" }
    if ($zoomProcesses) {
        foreach ($process in $zoomProcesses) {
            $process | Stop-Process -Force
        }
        Write-Host "Zoom process terminated successfully." -ForegroundColor Green
    } else {
        Write-Host "Zoom process not found." -ForegroundColor Yellow
    }

    Write-Host "Zoom installation completed successfully." -ForegroundColor Green
} else {
    Write-Host "Zoom installer not found at the specified path." -ForegroundColor Red
}
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function InstallWebex {
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/Webex.exe" -OutFile "$installersDirectory\Webex.exe"


# Define the path to the WebEx installer
$webExInstallerPath = "C:\xpercare\installers\webex.exe"

# Check if the installer file exists
if (Test-Path $webExInstallerPath -PathType Leaf) {
    # Start the installation process silently without waiting
    Start-Process -FilePath $webExInstallerPath -ArgumentList "/S"

    Write-Host "Installing Cisco WebEx..."

    # Wait for 30 seconds for the installation to complete
    Write-Host "Waiting 40 seconds for installation to finish..."
    Start-Sleep -Seconds 40

    # Send key strokes to accept the license agreement
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Write-Host "Accepted Cisco WebEx license agreement.`nWaiting 5 more seconds for installation to finalize..."
    # Wait for 5 seconds
    Start-Sleep -Seconds 5

    # Kill the ciscocollabhost.exe process
    Get-Process -Name ciscocollabhost | Stop-Process -Force

    Write-Host "Cisco WebEx installation completed successfully." -ForegroundColor Green
} else {
    Write-Host "WebEx installer not found at the specified path." -ForegroundColor Red
}
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function InstallFireFox {
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/Firefox%20Installer.exe" -OutFile "$installersDirectory\FireFox Installer.exe"

$firefoxInstallerPath = "C:\xpercare\installers\firefox installer.exe"

# Check if the installer file exists
if (Test-Path $firefoxInstallerPath -PathType Leaf) {
    try {
        # Start the installation process silently
        Start-Process -FilePath $firefoxInstallerPath -ArgumentList "/S" -Wait -ErrorAction Stop
        Write-Host "Firefox installation completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing Firefox:" $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "Firefox installer not found at path: $firefoxInstallerPath" -ForegroundColor Red
}
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function InstallNitro {
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/nitro_pro13.exe" -OutFile "$installersDirectory\Nitro_Pro13.exe"

$nitroInstallerPath = "C:\xpercare\installers\nitro_pro13.exe"

# Check if the installer file exists
if (Test-Path $nitroInstallerPath -PathType Leaf) {
    try {
        Write-Host "Starting Nitro Pro 13 installation..." -ForegroundColor Yellow
        # Start the installation process silently
        $process = Start-Process -FilePath $nitroInstallerPath -PassThru
        # Wait for the installation process to finish
        $process.WaitForExit()
        if ($process.ExitCode -eq 0) {
            Write-Host "Nitro Pro 13 installation completed successfully." -ForegroundColor Green
        } else {
            Write-Host "Nitro Pro 13 installation failed with exit code $($process.ExitCode)." -ForegroundColor Red
        }
    } catch {
        Write-Host "Failed to install Nitro Pro 13 silently." -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "Nitro Pro 13 installer not found at path: $nitroInstallerPath" -ForegroundColor Red
}
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function InstallHPIA {
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/HPIA.exe" -OutFile "$installersDirectory\HPIA.exe"

$hpiaPath = "C:\xpercare\installers\HPIA.exe"

# Check if the installer file exists
if (Test-Path $hpiaPath -PathType Leaf) {
    try {
        # Start the installation process silently
        Start-Process -FilePath $hpiaPath -ArgumentList "/S" -Wait -ErrorAction Stop
        Write-Host "HPIA installation completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing HPIA:" $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "HPIA installer not found at path: $hpiaPath" -ForegroundColor Red
}
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function InstallLenovoSystemUpdate {
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/LenovoSystemUpdate.exe" -OutFile "$installersDirectory\LenovoSystemUpdate.exe"

$lenovoSysPath = "C:\xpercare\installers\LenovoSystemUpdate.exe"

# Check if the installer file exists
if (Test-Path $lenovoSysPath -PathType Leaf) {
    try {
        # Start the installation process silently
        Start-Process -FilePath $lenovoSysPath -ArgumentList "/S" -Wait -ErrorAction Stop
        Write-Host "LenovoSystemUpdate installation completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing LenovoSystemUpdate:" $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "LenovoSystemUpdate installer not found at path: $lenovoSysPath" -ForegroundColor Red
}
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function InstallDellCommandUpdate {
	$script = @'
# Define the directory for storing installers
$installersDirectory = "C:\xpercare\Installers\"
# Create C:\xpercare\Installers directory if it doesn't exist
if (!(Test-Path $installersDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $installersDirectory
    Write-Host "Created $installersDirectory"
} else {
    Write-Host "$installersDirectory already exists!"
}

# Download Ninite installer
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/DellCommandUpdate.EXE" -OutFile "$installersDirectory\DellCommandUpdate.exe"

$dellUpdatePath = "C:\xpercare\installers\DellCommandUpdate.exe"

# Check if the installer file exists
if (Test-Path $dellUpdatePath -PathType Leaf) {
    try {
        # Start the installation process silently
        Start-Process -FilePath $dellUpdatePath -Wait -ErrorAction Stop
        Write-Host "DellCommandUpdate installation completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while installing DellCommandUpdate:" $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "DellCommandUpdate installer not found at path: $dellUpdatePath" -ForegroundColor Red
}	
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
# Printer installation functions
function PrinterChesapeakeMain {
	$script = @'
Start-Transcript C:\xpercare\printerinstall.log
$ProgressPreference = 'SilentlyContinue'
if (test-path C:\printerdrivers){remove-item C:\printerdrivers -recurse -force}
mkdir C:\printerdrivers -force
Invoke-WebRequest -Uri "https://xpershare.blob.core.windows.net/installers/CCRandalstownPrinters2024.zip?sv=2021-10-04&st=2024-02-27T17%3A09%3A39Z&se=2026-01-01T17%3A09%3A00Z&sr=b&sp=r&sig=yF%2BsipKLkw2O9WK7gaow3MQTxBFEZsZOl2CXhvioDyM%3D" -OutFile C:\printerdrivers\CCRandalstown.zip
Expand-Archive C:\printerdrivers\CCRandalstown.zip -DestinationPath C:\printerdrivers -Force
$ErrorActionPreference = "SilentlyContinue"
#Drivers
#XEROX Workcenter 3325 192.168.1.65
#Brother HL-L6200DW 192.168.1.67
#HP OfficeJet Pro 8210 192.168.1.100
#HQ-Brother-HL-L6200DW (2) 192.168.1.103

#removing print server printers
#Remove old printers
<#
Remove-Printer -Name "\\SERVER\Brother HL-L6200DW series Printer"
Remove-Printer -Name "\\SERVER\Xerox WorkCentre 3325"
Remove-Printer -Name "\\SERVER\HQ-Brother-HL-L6200DW"
Remove-Printer -Name "\\SERVER\HQ-Brother-HL-L6200DW (2)"
#>


#Remove old ports


#Remove old drivers


#Remove old driver files


$ErrorActionPreference = "Continue"
#add .inf file to the cert store
get-childitem C:\printerdrivers -Recurse -Filter *.inf | foreach {& pnputil.exe /add-driver $_.fullname}

#add driver
Add-PrinterDriver -Name "Xerox Global Print Driver PCL6"
Add-PrinterDriver -Name "Brother HL-L6200DW Series"
Add-PrinterDriver -Name "HP Universal Printing PCL 6"

#add ports
Add-PrinterPort -Name '192.168.1.65' -PrinterHostAddress '192.168.1.65'
Add-PrinterPort -Name '192.168.1.67' -PrinterHostAddress '192.168.1.67'
Add-PrinterPort -Name '192.168.1.100' -PrinterHostAddress '192.168.1.100'
Add-PrinterPort -Name '192.168.1.103' -PrinterHostAddress '192.168.1.103'

#Add printer using driver and port
Add-Printer -Name "HQ-Xerox-WorkCentre-3325" -PortName "192.168.1.65" -DriverName "Xerox Global Print Driver PCL6"
Add-Printer -Name "HQ-Brother-HL-L6200DW" -PortName "192.168.1.67" -DriverName "Brother HL-L6200DW Series"
Add-Printer -Name "HQ-Brother-HL-L6200DW (2)" -PortName "192.168.1.103" -DriverName "Brother HL-L6200DW Series"
Add-Printer -Name "HQ-HP-OfficeJet-Pro-8210" -PortName "192.168.1.100" -DriverName "HP Universal Printing PCL 6"
Stop-Transcript
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function PrinterChesapeakeRandalstown {
	$script = @'
$ErrorActionPreference = "SilentlyContinue"

# Check if C:\printerdrivers exists, create if not
if (-not (Test-Path -Path "C:\printerdrivers")) {
    New-Item -ItemType Directory -Path "C:\printerdrivers" | Out-Null
    Write-Host "Created directory: C:\printerdrivers"
} else {
    Write-Host "Directory found: C:\printerdrivers"
}

# Define URLs and file paths
$zipUrl = "https://xpershare.blob.core.windows.net/installers/CCRandalstownPrinters2024.zip?sv=2021-10-04&st=2024-02-27T17%3A09%3A39Z&se=2026-01-01T17%3A09%3A00Z&sr=b&sp=r&sig=yF%2BsipKLkw2O9WK7gaow3MQTxBFEZsZOl2CXhvioDyM%3D"
$zipFilePath = "C:\printerdrivers\CCRandalstown.zip"
$extractedFolderPath = "C:\printerdrivers\CCRandalstown.zip"

# Check if the zip file exists, download if not found
if (-not (Test-Path -Path $zipFilePath)) {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
    Write-Host "Downloaded CCRandalstown.zip"
} else {
    Write-Host "CCRandalstown.zip found"
}

# Check if the zip has already been extracted
if (-not (Test-Path -Path $extractedFolderPath)) {
    # Extract the zip if not found
    Expand-Archive -Path $zipFilePath -DestinationPath "C:\printerdrivers"
    Write-Host "Extracted CCRandalstown.zip"
} else {
    Write-Host "CCRandalstown.zip already extracted"
}

$ProgressPreference = 'SilentlyContinue'

$ErrorActionPreference = "Continue"
#add .inf file to the cert store
get-childitem C:\printerdrivers -Recurse -Filter *.inf | foreach {& pnputil.exe /add-driver $_.fullname}

#add driver
Add-PrinterDriver -Name "Xerox Global Print Driver PCL6"
Add-PrinterDriver -Name "Brother HL-L6200DW Series"
Add-PrinterDriver -Name "HP Universal Printing PCL 6"

#add ports
Add-PrinterPort -Name '192.168.1.65' -PrinterHostAddress '192.168.1.65'
Add-PrinterPort -Name '192.168.1.67' -PrinterHostAddress '192.168.1.67'
Add-PrinterPort -Name '192.168.1.100' -PrinterHostAddress '192.168.1.100'
Add-PrinterPort -Name '192.168.1.103' -PrinterHostAddress '192.168.1.103'

#Add printer using driver and port
Add-Printer -Name "HQ-Xerox-WorkCentre-3325" -PortName "192.168.1.65" -DriverName "Xerox Global Print Driver PCL6"
Add-Printer -Name "HQ-Brother-HL-L6200DW" -PortName "192.168.1.67" -DriverName "Brother HL-L6200DW Series"
Add-Printer -Name "HQ-Brother-HL-L6200DW (2)" -PortName "192.168.1.103" -DriverName "Brother HL-L6200DW Series"
Add-Printer -Name "HQ-HP-OfficeJet-Pro-8210" -PortName "192.168.1.100" -DriverName "HP Universal Printing PCL 6"
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function PrinterNBCAshland {
	$script = @'
# Check if C:\printerdrivers exists, create if not
if (-not (Test-Path -Path "C:\printerdrivers")) {
    New-Item -ItemType Directory -Path "C:\printerdrivers" | Out-Null
    Write-Host "Created directory: C:\printerdrivers"
} else {
    Write-Host "Directory found: C:\printerdrivers"
}

# Check if NBCPrinters2023.zip exists, download if not found
$zipFilePath = "C:\printerdrivers\NBCPrinters2023.zip"
if (-not (Test-Path -Path $zipFilePath)) {
    $zipUrl = "https://mittemp.s3.amazonaws.com/NBC+Printer+Drivers/NBCPrinters2023.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
    Write-Host "Downloaded NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip found"
}

# Check if C:\printerdrivers\IMC3500 exists, extract zip if not found
$extractedFolderPath = "C:\printerdrivers\IMC3500"
if (-not (Test-Path -Path $extractedFolderPath)) {
    Expand-Archive -Path $zipFilePath -DestinationPath "C:\printerdrivers\"
    Write-Host "Extracted NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip already extracted"
}

# Continue with printer installation
$ErrorActionPreference = "SilentlyContinue"

# Remove old printers, ports, drivers, and files
Remove-Printer -Name "Ashland Ricoh C2500" -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.11.10' -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "Generic PCL5 Printer Driver" -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\C2500" -Force -Recurse -ErrorAction SilentlyContinue

$ErrorActionPreference = "Continue"

# Add .inf file to the cert store
Invoke-Command {pnputil.exe -a "C:\printerdrivers\IMC3500\disk1\oemsetup.inf"} -ErrorAction Continue

# Add driver
Add-PrinterDriver -Name "RICOH IM C3500 PCL 6" -ErrorAction Continue

# Add port
Add-PrinterPort -Name '192.168.11.3' -PrinterHostAddress '192.168.11.3' -ErrorAction Continue

# Add printer using driver and port
Add-Printer -Name "Ashland-RicohIMC3500-Lobby" -PortName "192.168.11.3" -DriverName "RICOH IM C3500 PCL 6" -ErrorAction Continue
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function PrinterNBCBlueBell {
	$script = @'
# Check if C:\printerdrivers exists, create if not
if (-not (Test-Path -Path "C:\printerdrivers")) {
    New-Item -ItemType Directory -Path "C:\printerdrivers" | Out-Null
    Write-Host "Created directory: C:\printerdrivers"
} else {
    Write-Host "Directory found: C:\printerdrivers"
}

# Check if NBCPrinters2023.zip exists, download if not found
$zipFilePath = "C:\printerdrivers\NBCPrinters2023.zip"
if (-not (Test-Path -Path $zipFilePath)) {
    $zipUrl = "https://mittemp.s3.amazonaws.com/NBC+Printer+Drivers/NBCPrinters2023.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
    Write-Host "Downloaded NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip found"
}

# Check if C:\printerdrivers\IMC4500 exists, extract zip if not found
$extractedFolderPath = "C:\printerdrivers\IMC4500"
if (-not (Test-Path -Path $extractedFolderPath)) {
    Expand-Archive -Path $zipFilePath -DestinationPath "C:\printerdrivers\"
    Write-Host "Extracted NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip already extracted"
}

# Continue with printer installation
$ErrorActionPreference = "SilentlyContinue"

# Remove old printers, ports, drivers, and files
Remove-Printer -Name "Blue Bell Ricoh IM C3500" -ErrorAction SilentlyContinue
Remove-Printer -Name "Blue Bell Ricoh C4500" -ErrorAction SilentlyContinue
Remove-Printer -Name "Blue Bell Main Ricoh C6503" -ErrorAction SilentlyContinue
Remove-Printer -Name "Blue Bell Ricoh MP W8140" -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.5.21' -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.5.19' -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.5.23' -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "PCL6 Driver for Universal Print" -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "Generic PCL5 Printer Driver" -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "RICOH MP 6503 PS" -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "RICOH MP W8140 PS" -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\C3500" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\C4500" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\C6503" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\W8140" -Force -Recurse -ErrorAction SilentlyContinue

$ErrorActionPreference = "Continue"

# Add .inf file to the cert store
Invoke-Command {pnputil.exe -a "C:\printerdrivers\MPW6700SP\disk1\oemsetup.inf"} -ErrorAction Continue
Invoke-Command {pnputil.exe -a "C:\printerdrivers\IMC4500\disk1\oemsetup.inf"} -ErrorAction Continue

# Add drivers
Add-PrinterDriver -Name "RICOH MP W6700 PS" -ErrorAction Continue
Add-PrinterDriver -Name "RICOH IM C4500 PCL 6" -ErrorAction Continue

# Add ports
Add-PrinterPort -Name '192.168.5.24' -PrinterHostAddress '192.168.5.24' -ErrorAction Continue
Add-PrinterPort -Name '192.168.5.30' -PrinterHostAddress '192.168.5.30' -ErrorAction Continue
Add-PrinterPort -Name '192.168.5.32' -PrinterHostAddress '192.168.5.32' -ErrorAction Continue
Add-PrinterPort -Name '192.168.5.33' -PrinterHostAddress '192.168.5.33' -ErrorAction Continue

# Add printers using drivers and ports
Add-Printer -Name "BlueBell-RicohIMC4500-2ndFloor" -PortName "192.168.5.24" -DriverName "RICOH IM C4500 PCL 6" -ErrorAction Continue
Add-Printer -Name "BlueBell-RicohIMC4500-CopyRoom" -PortName "192.168.5.30" -DriverName "RICOH IM C4500 PCL 6" -ErrorAction Continue
Add-Printer -Name "BlueBell-RicohIMC4500-Back" -PortName "192.168.5.32" -DriverName "RICOH IM C4500 PCL 6" -ErrorAction Continue
Add-Printer -Name "BlueBell-RicohMPW6700SP-CopyRoom" -PortName "192.168.5.33" -DriverName "RICOH MP W6700 PS" -ErrorAction Continue
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function PrinterNBCChelmsford {
	$script = @'
# Check if C:\printerdrivers exists, create if not
if (-not (Test-Path -Path "C:\printerdrivers")) {
    New-Item -ItemType Directory -Path "C:\printerdrivers" | Out-Null
    Write-Host "Created directory: C:\printerdrivers"
} else {
    Write-Host "Directory found: C:\printerdrivers"
}

# Check if NBCPrinters2023.zip exists, download if not found
$zipFilePath = "C:\printerdrivers\NBCPrinters2023.zip"
if (-not (Test-Path -Path $zipFilePath)) {
    $zipUrl = "https://mittemp.s3.amazonaws.com/NBC+Printer+Drivers/NBCPrinters2023.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
    Write-Host "Downloaded NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip found"
}

# Check if C:\printerdrivers\IMC3500 exists, extract zip if not found
$extractedFolderPath = "C:\printerdrivers\IMC3500"
if (-not (Test-Path -Path $extractedFolderPath)) {
    Expand-Archive -Path $zipFilePath -DestinationPath "C:\printerdrivers\"
    Write-Host "Extracted NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip already extracted"
}

# Continue with printer installation
$ErrorActionPreference = "SilentlyContinue"

# Remove old printers, ports, drivers, and files
Remove-Printer -Name "Chelmsford Ricoh MP W6700" -ErrorAction SilentlyContinue
Remove-Printer -Name "Chelmsford Ricoh IM C2500" -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '172.31.0.14' -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '172.31.0.15' -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "RICOH MP W6700 PS" -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "Generic PCL5 Printer Driver" -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\WC6700" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\C2500" -Force -Recurse -ErrorAction SilentlyContinue

$ErrorActionPreference = "Continue"

# Add .inf file to the cert store
Invoke-Command {pnputil.exe -a "C:\printerdrivers\MPW6700SP\disk1\oemsetup.inf"} -ErrorAction Continue
Invoke-Command {pnputil.exe -a "C:\printerdrivers\IMC3500\disk1\oemsetup.inf"} -ErrorAction Continue

# Add drivers
Add-PrinterDriver -Name "RICOH MP W6700 PS" -ErrorAction Continue
Add-PrinterDriver -Name "RICOH IM C3500 PCL 6" -ErrorAction Continue

# Add ports
Add-PrinterPort -Name '172.31.0.18' -PrinterHostAddress '172.31.0.18' -ErrorAction Continue
Add-PrinterPort -Name '172.31.0.19' -PrinterHostAddress '172.31.0.19' -ErrorAction Continue

# Add printers using drivers and ports
Add-Printer -Name "Chelmsford-RicohMPW6700SP-PrintRoom" -PortName "172.31.0.18" -DriverName "RICOH MP W6700 PS" -ErrorAction Continue
Add-Printer -Name "Chelmsford-RicohIMC3500-PrintRoom" -PortName "172.31.0.19" -DriverName "RICOH IM C3500 PCL 6" -ErrorAction Continue
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function PrinterNBCElkridge {
	$script = @'
# Check if C:\printerdrivers exists, create if not
if (-not (Test-Path -Path "C:\printerdrivers")) {
    New-Item -ItemType Directory -Path "C:\printerdrivers" | Out-Null
    Write-Host "Created directory: C:\printerdrivers"
} else {
    Write-Host "Directory found: C:\printerdrivers"
}

# Check if NBCPrinters2023.zip exists, download if not found
$zipFilePath = "C:\printerdrivers\NBCPrinters2023.zip"
if (-not (Test-Path -Path $zipFilePath)) {
    $zipUrl = "https://mittemp.s3.amazonaws.com/NBC+Printer+Drivers/NBCPrinters2023.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
    Write-Host "Downloaded NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip found"
}

# Check if C:\printerdrivers\IMC3500 exists, extract zip if not found
$extractedFolderPath = "C:\printerdrivers\IMC3500"
if (-not (Test-Path -Path $extractedFolderPath)) {
    Expand-Archive -Path $zipFilePath -DestinationPath "C:\printerdrivers\"
    Write-Host "Extracted NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip already extracted"
}

# Continue with printer installation
$ErrorActionPreference = "SilentlyContinue"

# Remove old printers, ports, drivers, and files
Remove-Printer -Name "Elkridge Ricoh MP W8140 (Print room Wideformat/Plotter)" -ErrorAction SilentlyContinue
Remove-Printer -Name "Elkridge Print Room Ricoh C5210S" -ErrorAction SilentlyContinue
Remove-Printer -Name "Elkridge Executive File Room Ricoh IM C4500" -ErrorAction SilentlyContinue
Remove-Printer -Name "Elkridge Engineering Ricoh IM C4500 (Engineering Printer)" -ErrorAction SilentlyContinue
Remove-Printer -Name "Elkridge Accounting Ricoh IM C4500" -ErrorAction SilentlyContinue
Remove-Printer -Name "Elkridge Corporate Services Ricoh IM C2500" -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.1.56' -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.1.57' -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.1.52' -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.1.58' -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.1.51' -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.1.55' -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "RICOH MP W8140 PS" -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "RICOH Pro C5210S PS" -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "Generic PCL5 Printer Driver" -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\C2500\" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\C4500\" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\C5210S\" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\W8140\" -Force -Recurse -ErrorAction SilentlyContinue

$ErrorActionPreference = "Continue"

# Add .inf file to the cert store
Invoke-Command {pnputil.exe -a "C:\printerdrivers\MPW6700SP\disk1\oemsetup.inf"} -ErrorAction Continue
Invoke-Command {pnputil.exe -a "C:\printerdrivers\IMC4500\disk1\oemsetup.inf"} -ErrorAction Continue
Invoke-Command {pnputil.exe -a "C:\printerdrivers\IMC3500\disk1\oemsetup.inf"} -ErrorAction Continue

# Add drivers
Add-PrinterDriver -Name "RICOH MP W6700 PS" -ErrorAction Continue
Add-PrinterDriver -Name "RICOH IM C4500 PCL 6" -ErrorAction Continue
Add-PrinterDriver -Name "RICOH IM C3500 PCL 6" -ErrorAction Continue

# Add ports
Add-PrinterPort -Name '192.168.1.9' -PrinterHostAddress '192.168.1.9' -ErrorAction Continue
Add-PrinterPort -Name '192.168.1.10' -PrinterHostAddress '192.168.1.10' -ErrorAction Continue
Add-PrinterPort -Name '192.168.1.11' -PrinterHostAddress '192.168.1.11' -ErrorAction Continue
Add-PrinterPort -Name '192.168.1.12' -PrinterHostAddress '192.168.1.12' -ErrorAction Continue
Add-PrinterPort -Name '192.168.1.13' -PrinterHostAddress '192.168.1.13' -ErrorAction Continue
Add-PrinterPort -Name '192.168.1.14' -PrinterHostAddress '192.168.1.14' -ErrorAction Continue

# Add printers using drivers and ports
Add-Printer -Name "Elkridge-RicohIMC3500-AccountingDept" -PortName "192.168.1.9" -DriverName "RICOH IM C3500 PCL 6" -ErrorAction Continue
Add-Printer -Name "Elkridge-RicohIMC3500-ExecutiveFileRoom" -PortName "192.168.1.10" -DriverName "RICOH IM C3500 PCL 6" -ErrorAction Continue
Add-Printer -Name "Elkridge-RicohIMC3500-CorporateServicesDept" -PortName "192.168.1.11" -DriverName "RICOH IM C3500 PCL 6" -ErrorAction Continue
Add-Printer -Name "Elkridge-RicohMPW6700SP-PrintRoom" -PortName "192.168.1.12" -DriverName "RICOH MP W6700 PS" -ErrorAction Continue
Add-Printer -Name "Elkridge-RicohIMC4500-PrintRoom" -PortName "192.168.1.13" -DriverName "RICOH IM C4500 PCL 6" -ErrorAction Continue
Add-Printer -Name "Elkridge-RicohIMC3500-EngineeringDept" -PortName "192.168.1.14" -
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function PrinterNBCGlenAllen {
	$script = @'
# Check if C:\printerdrivers exists, create if not
if (-not (Test-Path -Path "C:\printerdrivers")) {
    New-Item -ItemType Directory -Path "C:\printerdrivers" | Out-Null
    Write-Host "Created directory: C:\printerdrivers"
} else {
    Write-Host "Directory found: C:\printerdrivers"
}

# Check if NBCPrinters2023.zip exists, download if not found
$zipFilePath = "C:\printerdrivers\NBCPrinters2023.zip"
if (-not (Test-Path -Path $zipFilePath)) {
    $zipUrl = "https://mittemp.s3.amazonaws.com/NBC+Printer+Drivers/NBCPrinters2023.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
    Write-Host "Downloaded NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip found"
}

# Check if C:\printerdrivers\IMC3500 exists, extract zip if not found
$extractedFolderPath = "C:\printerdrivers\IMC3500"
if (-not (Test-Path -Path $extractedFolderPath)) {
    Expand-Archive -Path $zipFilePath -DestinationPath "C:\printerdrivers\"
    Write-Host "Extracted NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip already extracted"
}

# Continue with printer installation
$ErrorActionPreference = "SilentlyContinue"

# Remove old printers, ports, drivers, and files
Remove-Printer -Name "Glen Allen 3rd Floor Ricoh C3000" -ErrorAction SilentlyContinue
Remove-Printer -Name "Glen Allen 1st Floor Ricoh IM C4500" -ErrorAction SilentlyContinue
Remove-Printer -Name "Glen Allen Ricoh MP W6700" -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.7.8' -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.7.180' -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.7.127' -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "RICOH MP W6700 PS" -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "Generic PCL5 Printer Driver" -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\C3000" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\C4500" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\WC6700" -Force -Recurse -ErrorAction SilentlyContinue

# Add .inf file to the cert store
Invoke-Command {pnputil.exe -a "C:\printerdrivers\MPW6700SP\disk1\oemsetup.inf"} -ErrorAction Continue
Invoke-Command {pnputil.exe -a "C:\printerdrivers\IMC3500\disk1\oemsetup.inf"} -ErrorAction Continue

# Add driver
Add-PrinterDriver -Name "RICOH MP W6700 PS" -ErrorAction Continue
Add-PrinterDriver -Name "RICOH IM C3500 PCL 6" -ErrorAction Continue

# Add ports
Add-PrinterPort -Name '192.168.7.24' -PrinterHostAddress '192.168.7.24' -ErrorAction Continue
Add-PrinterPort -Name '192.168.7.25' -PrinterHostAddress '192.168.7.25' -ErrorAction Continue
Add-PrinterPort -Name '192.168.7.26' -PrinterHostAddress '192.168.7.26' -ErrorAction Continue

# Add printer using driver and port
Add-Printer -Name "GlenAllen-RicohIMC3500-Design" -PortName "192.168.7.24" -DriverName "RICOH IM C3500 PCL 6" -ErrorAction Continue
Add-Printer -Name "GlenAllen-RicohMPW6700SP-SupplyRoom-Plotter" -PortName "192.168.7.25" -DriverName "RICOH MP W6700 PS" -ErrorAction Continue
Add-Printer -Name "GlenAllen-RicohIMC3500-SupplyRoom" -PortName "192.168.7.26" -DriverName "RICOH IM C3500 PCL 6" -ErrorAction Continue
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function PrinterNBCHanover {
	$script = @'
# Check if C:\printerdrivers exists, create if not
if (-not (Test-Path -Path "C:\printerdrivers")) {
    New-Item -ItemType Directory -Path "C:\printerdrivers" | Out-Null
    Write-Host "Created directory: C:\printerdrivers"
} else {
    Write-Host "Directory found: C:\printerdrivers"
}

# Check if NBCPrinters2023.zip exists, download if not found
$zipFilePath = "C:\printerdrivers\NBCPrinters2023.zip"
if (-not (Test-Path -Path $zipFilePath)) {
    $zipUrl = "https://mittemp.s3.amazonaws.com/NBC+Printer+Drivers/NBCPrinters2023.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
    Write-Host "Downloaded NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip found"
}

# Check if C:\printerdrivers\IMC3500 exists, extract zip if not found
$extractedFolderPath = "C:\printerdrivers\IMC3500"
if (-not (Test-Path -Path $extractedFolderPath)) {
    Expand-Archive -Path $zipFilePath -DestinationPath "C:\printerdrivers\"
    Write-Host "Extracted NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip already extracted"
}

# Now continue with the rest of your script...
$ErrorActionPreference = "SilentlyContinue"

# Remove old printers, ports, drivers, and files
Remove-Printer -Name "Linthicum Warehouse Ricoh MP C2500" -ErrorAction SilentlyContinue
Remove-PrinterPort -Name '192.168.10.5' -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "Generic PCL5 Printer Driver" -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\printerdrivers\C2500" -Force -Recurse -ErrorAction SilentlyContinue

# Add .inf file to the cert store
Invoke-Command {pnputil.exe -a "C:\printerdrivers\IMC3500\disk1\oemsetup.inf"} -ErrorAction Continue

# Add driver
Add-PrinterDriver -Name "RICOH IM C3500 PCL 6" -ErrorAction Continue

# Add ports
Add-PrinterPort -Name '192.168.10.3' -PrinterHostAddress '192.168.10.3' -ErrorAction Continue

# Add printer using driver and port
Add-Printer -Name "Hanover-RicohIMC3500-Lobby" -PortName "192.168.10.3" -DriverName "RICOH IM C3500 PCL 6" -ErrorAction Continue
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function PrinterNBCRaleigh {
	$script = @'
# Check if C:\printerdrivers exists, create if not
if (-not (Test-Path -Path "C:\printerdrivers")) {
    New-Item -ItemType Directory -Path "C:\printerdrivers" | Out-Null
    Write-Host "Created directory: C:\printerdrivers"
} else {
    Write-Host "Directory found: C:\printerdrivers"
}

# Check if NBCPrinters2023.zip exists, download if not found
$zipFilePath = "C:\printerdrivers\NBCPrinters2023.zip"
if (-not (Test-Path -Path $zipFilePath)) {
    $zipUrl = "https://mittemp.s3.amazonaws.com/NBC+Printer+Drivers/NBCPrinters2023.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
    Write-Host "Downloaded NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip found"
}

# Check if C:\printerdrivers\IMC3500 exists, extract zip if not found
$extractedFolderPath = "C:\printerdrivers\IMC3500"
if (-not (Test-Path -Path $extractedFolderPath)) {
    Expand-Archive -Path $zipFilePath -DestinationPath "C:\printerdrivers\"
    Write-Host "Extracted NBCPrinters2023.zip"
} else {
    Write-Host "NBCPrinters2023.zip already extracted"
}

# Continue with printer installation
$ErrorActionPreference = "SilentlyContinue"

# Remove old ports and drivers
Remove-PrinterPort -Name '172.30.0.16' -ErrorAction SilentlyContinue
Remove-PrinterDriver -Name "RICOH MP W6700 PS" -ErrorAction SilentlyContinue

# Remove old driver files
Remove-Item -LiteralPath "C:\printerdrivers\WC6700" -Force -Recurse -ErrorAction SilentlyContinue

$ErrorActionPreference = "Continue"

# Add .inf file to the cert store
Invoke-Command {pnputil.exe -a "C:\printerdrivers\MPW6700SP\disk1\oemsetup.inf"} -ErrorAction Continue
Invoke-Command {pnputil.exe -a "C:\printerdrivers\IMC3500\disk1\oemsetup.inf"} -ErrorAction Continue

# Add driver
Add-PrinterDriver -Name "RICOH MP W6700 PS" -ErrorAction Continue
Add-PrinterDriver -Name "RICOH IM C3500 PCL 6" -ErrorAction Continue

# Add ports
Add-PrinterPort -Name '172.30.0.24' -PrinterHostAddress '172.30.0.24' -ErrorAction Continue
Add-PrinterPort -Name '172.30.0.25' -PrinterHostAddress '172.30.0.25' -ErrorAction Continue

# Add printers using driver and port
Add-Printer -Name "Raleigh-RicohIMC3500-Hallway" -PortName "172.30.0.24" -DriverName "RICOH IM C3500 PCL 6" -ErrorAction Continue
Add-Printer -Name "Raleigh-RicohMPW6700SP-SupplyRoom" -PortName "172.30.0.25" -DriverName "RICOH MP W6700 PS" -ErrorAction Continue
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function PrinterBriaud {
	$script = @'
# Check if C:\printerdrivers exists, create if not
if (-not (Test-Path -Path "C:\printerdrivers")) {
    New-Item -ItemType Directory -Path "C:\printerdrivers" | Out-Null
    Write-Host "Created directory: C:\printerdrivers"
} else {
    Write-Host "Directory found: C:\printerdrivers"
}

# Define URLs and file paths
$zipUrl = "https://mittemp.s3.amazonaws.com/Briaud+Printer+Drivers/Briaud_BatchFour_PrinterDrivers.zip"
$zipFilePath = "C:\printerdrivers\Briaud_BatchFour_PrinterDrivers.zip"
$extractedFolderPath = "C:\printerdrivers\Briaud_BatchFour_PrinterDrivers"

# Check if the zip file exists, download if not found
if (-not (Test-Path -Path $zipFilePath)) {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
    Write-Host "Downloaded Briaud_BatchFour_PrinterDrivers.zip"
} else {
    Write-Host "Briaud_BatchFour_PrinterDrivers.zip found"
}

# Check if the zip has already been extracted
if (-not (Test-Path -Path $extractedFolderPath)) {
    # Extract the zip if not found
    Expand-Archive -Path $zipFilePath -DestinationPath "C:\printerdrivers"
    Write-Host "Extracted Briaud_BatchFour_PrinterDrivers.zip"
} else {
    Write-Host "Briaud_BatchFour_PrinterDrivers.zip already extracted"
}

$ErrorActionPreference = "SilentlyContinue"

#Drivers
#Xerox Color C315 - Xerox C315 Color MFP - 192.168.11.30 - Xerox C315 Color MFP V4 PS
#Xerox BW B310 (West) - Xerox B310 BW - 192.168.11.31 - Xerox B310 Printer V4 PS
#Xerox BW B310 (East) - Xerox B310 BW - 192.168.11.32 - Xerox B310 Printer V4 PS

#removing print server printers
Remove-Printer -Name "Xerox C315 MFP - COLOR - ASHLEY"
Remove-Printer -Name "Xerox B310 Printer - WEST"
Remove-Printer -Name "Xerox B310 Printer - EAST"
Remove-Printer -Name "Brother HL-L6200DW Natalie Pine Office"
Remove-Printer -Name "Natalie's Printer"
Remove-Printer -Name "HP Color LaserJet 3800 PCL6 Class Driver"
Remove-Printer -Name "Brother HL-L6200DW West Side"
Remove-Printer -Name "HP LJ M406"
Remove-Printer -Name "Reception"
Remove-Printer -Name "Lexmark CX310 - Reception"
Remove-Printer -Name "Brother HL-6180DW - Advisor's Wing Closet"
Remove-Printer -Name "West Side"
Remove-Printer -Name "Lexmark CS410dn"
Remove-Printer -Name "HP LJ P2055dn"

$ErrorActionPreference = "Continue"

#add .inf file to the cert store
Invoke-Command {pnputil.exe -a "C:\printerdrivers\Briaud_BatchFour_PrinterDrivers\Xerox B310 BW\Xerox_B305_B310_B315_PS.inf"}
Invoke-Command {pnputil.exe -a "C:\printerdrivers\Briaud_BatchFour_PrinterDrivers\Xerox C315 Color MFP\Xerox_C310_C315_PS.inf"}

#add driver
Add-PrinterDriver -Name "Xerox B310 Printer V4 PS"
Add-PrinterDriver -Name "Xerox C315 Color MFP V4 PS"

#add ports
Add-PrinterPort -Name '192.168.11.30' -PrinterHostAddress '192.168.11.30'
Add-PrinterPort -Name '192.168.11.31' -PrinterHostAddress '192.168.11.31'
Add-PrinterPort -Name '192.168.11.32' -PrinterHostAddress '192.168.11.32'

#Add printer using driver and port
Add-Printer -Name "Xerox Color C315" -PortName "192.168.11.30" -DriverName "Xerox C315 Color MFP V4 PS"
Add-Printer -Name "Xerox BW B310 (West)" -PortName "192.168.11.31" -DriverName "Xerox B310 Printer V4 PS"
Add-Printer -Name "Xerox BW B310 (East)" -PortName "192.168.11.32" -DriverName "Xerox B310 Printer V4 PS"

#Set Default Printer Xerox BW B310 (East)
$printer = Get-CimInstance -Class Win32_Printer -Filter "Name='Xerox BW B310 (East)'"
Invoke-CimMethod -InputObject $printer -MethodName SetDefaultPrinter
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}
function PrinterPlanoMain {
	$script = @'
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
'@
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($Script)
	$encodedCommand = [Convert]::ToBase64String($bytes)
	Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand" -Verb runas -Wait
}

function Menu
{
    $opening = @'
*****************************************************************************************
__   ________ _________________ ___________ _     _______   ____  ___ _____ _   _ _____ 
\ \ / /| ___ \  ___| ___ \  _  \  ___| ___ \ |   |  _  \ \ / /  \/  ||  ___| \ | |_   _|
 \ V / | |_/ / |__ | |_/ / | | | |__ | |_/ / |   | | | |\ V /| .  . || |__ |  \| | | |  
 /   \ |  __/|  __||    /| | | |  __||  __/| |   | | | | \ / | |\/| ||  __|| . ` | | |  
/ /^\ \| |   | |___| |\ \| |/ /| |___| |   | |___\ \_/ / | | | |  | || |___| |\  | | |  
\/   \/\_|   \____/\_| \_|___/ \____/\_|   \_____/\___/  \_/ \_|  |_/\____/\_| \_/ \_/  
Deployment Utility created by: Alex DeMey
*****************************************************************************************
'@

    Write-Host $opening -ForegroundColor Green
    Write-Host "`nXperDeployment Utility Program" -ForegroundColor Green -BackgroundColor Black
	Write-Host "Admin Rights: " -NoNewline
	Check-AdminRights
    Write-Host "`nOptions:`n[0] Exit`n[1] Install Apps`n[2] Master Deployment Script`n[3] Install Printers`n[4] Retrieve Agent ID`n[5] Retrieve Windows Activation Key`n[6] Configure Desktop and Taskbar`n[7] Get AdBlock Plus Browser Extension`n[8] Activate Bitlocker (Requires reboot)`n[9] Disable Enrollment Checks on First Sign In (will sign out!)`n[10] Passwordless Helper (Web Sign in)`n"
    [int]$MenuSelection = Read-Host "Please enter your selection by number"
    switch ($MenuSelection)
    {
        0{ Exit 0 }
		1{ # Install apps
            while ($true) {
                Write-Host "`n[0] Exit to Main Menu`n[1] Manufacturer Driver Utilities`n[2] O365 (for Business - English)`n[3] O365, Project, and Visio`n[4] Ninite (7-Zip, Chrome, Adobe Reader)`n[5] GoToMeeting`n[6] New Teams`n[7] Google Earth Pro (not silent!)`n[8] SonicWall NetExtender`n[9] Zoom`n[10] Cisco WebEx`n[11] FireFox`n[12] Nitro Pro 13 (not silent!)"
                [int]$SubmenuSelection = Read-Host "Please enter your selection by number"
                switch ($SubmenuSelection) {
                    0 { Clear-Host; return }
					1 {
						while ($true) {
							Write-Host "`n[0]Exit to Main Menu`n[1] HP Image Assistant`n[2] Dell Command Update`n[3] Lenovo System Update"
							[int]$SubmenuSelection = Read-Host "Please enter your selection by number"
							switch ($SubmenuSelection) {
								0 { Clear-Host; return }
								1 { InstallHPIA; Clear-Host; return }
								2 { InstallDellCommandUpdate; Clear-Host; return }
								3 { InstallLenovoSystemUpdate; Clear-Host; return }
							}		
						}
					}
					2 { InstallO365 ; Clear-Host }
					3 { InstallO365wProjectVisio ; Clear-Host }
                    4 { InstallNinite; Clear-Host }
					5 { InstallGoToMeeting; Clear-Host}
					6 { InstallNewTeams; Clear-Host }
					7 { InstallGoogleEarthPro; Clear-Host }
					8 { InstallSonicWallNetExtender; Clear-Host }
					9 { InstallZoom; Clear-Host }
					10 { InstallWebex; Clear-Host }
					11 { InstallFireFox; Clear-Host }
					12 { InstallNitro; Clear-Host }
                    default {                        
						Write-Host "Invalid selection. Please try again."
                    }
                }
            }
        }
		2{ # Master Deployment Script
            while ($true) {
                Write-Host "`nMDS is used to perform universal setup tasks. Please make a selection:`n[0] Exit to Main Menu`n[1] Create and Run Scripts (no installations)`n[2] Create and Run Scripts (& Install O365, Ninite, GoToMeeting)`n[3] Create Scripts (@ 'C:\xpercare\MDS')"
                [int]$SubmenuSelection = Read-Host "Please enter your selection by number"
                switch ($SubmenuSelection) {
                    0 { Clear-Host; return }
					1 { RunMDS ; Clear-Host ; return }
					2 { RunMDSwInstall ; Clear-Host ; return}
                    3 { CreateMDS; Clear-Host ; return}
                    default {                        
						Write-Host "Invalid selection. Please try again."
                    }
                }
            }
        }
		3 { # Install Printers
			while ($true) {
				Write-Host "`nSelect a client to add printers for:`n[0] Exit to Main Menu`n[1] NB+C`n[2] Briaud`n[3] Chesapeake Collisions`n[4] Plano Coudon"
				[int]$SubmenuSelection = Read-Host "Please enter your selection by number"
				switch ($SubmenuSelection) {
					0 { Clear-Host; return }
					1 { 
						while ($true) {
							Write-Host "`nNB+C`n[0] Back`n[1] Ashland Printers`n[2] BlueBell Printers`n[3] Chelmsford Printers`n[4] Elkridge Printers`n[5] GlenAllen Printers`n[6] Hanover Printers`n[7] Raleigh Printers"
							[int]$PrinterSelection = Read-Host "Please enter your selection by number"
							switch ($PrinterSelection) {
								0 { Clear-Host; return }  # Go back to the previous menu
								1 { PrinterNBCAshland; Clear-Host; return }
								2 { PrinterNBCBlueBell; Clear-Host; return }
								3 { PrinterNBCChelmsford; Clear-Host; return }
								4 { PrinterNBCElkridge; Clear-Host; return }
								5 { PrinterNBCGlenAllen; Clear-Host; return }
								6 { PrinterNBCHanover; Clear-Host; return }
								7 { PrinterNBCRaleigh; Clear-Host; return }
								default {
									Write-Host "Invalid selection. Please try again."
								}
							}
						}
					}
					2 { 
						while ($true) {
							Write-Host "`nBriaud`n[0] Back`n[1] Install Main Office Printers"
							[int]$PrinterSelection = Read-Host "Please enter your selection by number"
							switch ($PrinterSelection) {
								0 { Clear-Host; return }  # Go back to the previous menu
								1 { PrinterBriaud ; Clear-Host ; return }
								default {
									Write-Host "Invalid selection. Please try again."
								}
							}
						}
					}
					3 { 
						while ($true) {
							Write-Host "`nCheapeake Collisions`n[0] Back`n[1] Install Main Office Printers`n[2] Install Randalstown Printers"
							[int]$PrinterSelection = Read-Host "Please enter your selection by number"
							switch ($PrinterSelection) {
								0 { Clear-Host; return }  # Go back to the previous menu
								1 { PrinterChesapeakeMain ; Clear-Host ; return }
								2 { PrinterChesapeakeRandalstown ; Clear-Host ; return }
								default {
									Write-Host "Invalid selection. Please try again."
								}
							}
						}
					}
					4 { 
						while ($true) {
							Write-Host "`nPlano Coudon`n[0] Back`n[1] Install Main Office Printers"
							[int]$PrinterSelection = Read-Host "Please enter your selection by number"
							switch ($PrinterSelection) {
								0 { Clear-Host; return }  # Go back to the previous menu
								1 { PrinterPlanoMain ; Clear-Host ; return }
								default {
									Write-Host "Invalid selection. Please try again."
								}
							}
						}
					}
					default {                        
						Write-Host "Invalid selection. Please try again."
					}
				}
			}
		}
        4{ PullAgentID; Clear-Host}
        5{ PullWindowsKey; Clear-Host}
        6{ ConfigureDesktopAndTaskbar; Clear-Host}
        7{ GetAdblock; Clear-Host}
        8{ ActivateBitlocker; Clear-Host}
        9{ DisableEnrollmentChecksOnSignIn; Clear-Host}
		10{ 
            while ($true) {
                Write-Host "`nSelect an operation:`n[0] Exit to Main Menu`n[1] Enable WebSignOn (Enables HELLO)`n[2] Disable WebSignOn (Does NOT disable HELLO)`n[3] Clear Windows HELLO PIN (Must be run in backstage)"
                [int]$SubmenuSelection = Read-Host "Please enter your selection by number"
                switch ($SubmenuSelection) {
					0{ Clear-Host; return }
					1{ EnablePasswordlessSignon; Clear-Host }
					2{ DisableWebSignon; Clear-Host }
					3{ ClearPin; Clear-Host }
				}
            }
        } 
        default {
            Write-Host "Invalid selection. Please try again."
        }
    }
}

Set-ExecutionPolicyUnrestricted
while ($True)
{
    Menu
}