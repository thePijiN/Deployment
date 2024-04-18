<#
.SYNOPSIS
	Utility to enable Windows Hello and Web sign on. For use with temporary access pass to configure workstations without users password
.NOTES
	Author: David Just
	Date: 08/02/2023
#>
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

function Menu
{
	$opening = @'
**************************************************
   _  __                 __            __        
  | |/ /____  ___  _____/ /____  _____/ /_  _____
  |   // __ \/ _ \/ ___/ __/ _ \/ ___/ __ \/ ___/
 /   |/ /_/ /  __/ /  / /_/  __/ /__/ / / (__  ) 
/_/|_/ .___/\___/_/   \__/\___/\___/_/ /_/____/  
    /_/

*************************************************
'@
	
	Write-Host $opening -ForegroundColor Yellow
	Write-Host "`nWindows Passwordless Helper Utility v1.0`n" -ForegroundColor Green -BackgroundColor Black
	Write-Host "Options:`n[1] Enable Web sign in and Windows Hello`n[2] Disable Web Sign In`n[3] Remove Windows Hello PIN`n[4] Exit"
	[int]$MenuSelection = Read-Host "Please enter a selection by number (1-3)"
	switch ($MenuSelection)
	{
		1{ EnablePasswordlessSignon; Clear-Host }
		2{ DisableWebSignon; Clear-Host }
		3 { ClearPin; Clear-Host}
		4{ Exit 0 }
	}
}
while ($True)
{
	Menu
}


