# Create C:\xpercare if it doesn't already exist
$folderPath = "C:\xpercare"
if (!(Test-Path $folderPath -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $folderPath
    Write-Host "Created C:\xpercare directory."
} else {
    Write-Host "C:\xpercare already exists!"
}

# Check if BitLocker is already enabled on C:\
$encryptionStatus = Get-BitLockerVolume -MountPoint "C:\" | Select-Object -ExpandProperty VolumeStatus

if ($encryptionStatus -ne "FullyEncrypted") {
    # Enable BitLocker on C:\
    Enable-BitLocker -MountPoint "C:\" -UsedSpaceOnly -EncryptionMethod "AES256" -TpmProtector
    Write-Output "Attempted to enable Bitlocker on C:\ drive. Reboot required to finish encryption!"
} else {
    Write-Output "BitLocker is already enabled on C:\ drive."
	Write-Host "'Saved BitlockerRecoveryKey.txt' to 'C:\xpercare'"
	(Get-BitLockerVolume -MountPoint C).KeyProtector > $env:C:\xpercare\BitLockerRecoveryKey.txt
	return $true
}