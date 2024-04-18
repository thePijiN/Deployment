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

# Disable 'Show People on the Taskbar' and 'Show Task View Button' - unsure if this can be accomplished via registry modifications
