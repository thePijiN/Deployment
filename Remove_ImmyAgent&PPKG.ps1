# Universal Uninstaller

function Get-RegUninstallKey
{
$DisplayName = "ImmyBot Agent"
	$ErrorActionPreference = 'Continue'
	#$UserSID = ([System.Security.Principal.NTAccount](Get-CimInstance -ClassName Win32_ComputerSystem).UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value
	$uninstallKeys = @(
		"registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall"
		"registry::HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
		#"registry::HKU\$usersid\Software\Microsoft\Windows\CurrentVersion\Uninstall"
		)
	$softwareTable =@()
	
	foreach ($key in $uninstallKeys)
	{
		$softwareTable += Get-Childitem $key | Get-ItemProperty | Where-Object { $_.displayname } | Sort-Object -Property displayname
	}
	if ($DisplayName)
	{
		$softwareTable | Where-Object { $_.displayname -eq "$DisplayName" }
	}
	else
	{
		$softwareTable | Sort-Object -Property displayname -Unique
	}
	
}

function RunUninstall {
    param(
        [String]$SoftwareName,
        [String]$ArgumentList = ' '
    )
    $UninstallKey = Get-RegUninstallKey -DisplayName $SoftwareName | select -first 1
    if (-Not $UninstallKey){
      Write-Error "Uninstall key not found"
      return
      }
    $UnInstallString = ($UninstallKey).uninstallstring
    $QuietUninstallString = ($UninstallKey).QuietUninstallString
    # Test if Uninstall string is using MSIExec
if ($UnInstallString -match 'msiexec'){
    # Find the MSI Product code by getting the uninstall string and doing some simple string manipulation
    $MsiProductCode = ((($UnInstallString) -split '{') -split '}')[1]

    # Test the MSIProduct code by type casting to GUID. This will throw a terminating error if incorrect
    try {
        [GUID]$MsiProductCode | Out-Null
    }
    Catch {
        # Catch the error and output to file
        $_ | Out-File "C:\temp\$SoftwareName-Uninstall.log"
        # Output the registry key to the same log file for thoroughness 
        Get-RegUninstallKey -displayname $SoftwareName | Out-File "$env:temp\$SoftwareName-Uninstall.log" -Append
    }
    # Run Uninstall command with logging
        "Running MSI Uninstall on product code {$MsiProductCode} displayname $($UninstallKey.DisplayName)"
        $MSIUninstall = Start-process msiexec.exe -ArgumentList "/x `"{$MsiProductCode}`" /qn /norestart /l*v `"$env:temp\$SoftwareName-Uninstall.log`"" -wait -PassThru
        return "MSI ExitCode {0}" -f $MSIUninstall.ExitCode
}
else {
    # Uninstall string does not contain MSIExec, try quietuninstall string
    if (-Not $QuietUninstallString){
        # If quiet uninstall string is not found in reg key, log to file, then quit script
        "Running $UninstallString $ArgumentList"
        $Uninstall = Start-Process $UnInstallString -ArgumentList $ArgumentList -Wait -PassThru
        return "{0} : Exit Code : {1}" -f $UninstallString,$Uninstall.ExitCode
    }
    # Execute QuietUninstallString
    $QuietUninstall = Start-Process $QuietUninstallString -Wait -PassThru
    return "{0} : Exit Code : {1}" -f $QuietUninstallString,$QuietUninstall.ExitCode
 }
}
#Uninstall ImmyAgent
RunUninstall -SoftwareName "Immybot"
#Remove Immy ProvisioningPackage
Uninstall-ProvisioningPackage -PackageId {c3a64491-810d-487b-8c3a-f43a6ba742e6}
