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

<#
# Define the app paths
$apps = @{
    'Outlook'    = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk'
    'Word'       = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk'
    'Excel'      = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Excel.lnk'
    'PowerPoint' = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk'
    'OneDrive'   = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'
    'Teams'      = 'C:\Program Files\WindowsApps\MSTeams_23285.3607.2525.937_x64__8wekyb3d8bbwe\ms-teams.exe'
}

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
        } else {
            Write-Host "Did NOT find $appName at the expected location! Skipping this shortcut!"
        }
    }
}
#>