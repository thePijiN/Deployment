^Esc:: ; CTRL+ESC TO IMMEDIATELY EXIT SCRIPT
    ExitApp
return
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~ HOTSTRINGS ~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~ EMAILS
::signemail::{Enter}Thank you,{Enter}{Enter}Alex DeMey{Enter}Support Specialist{Enter}Xpertechs{Enter}410.884.4357
::xperphone::410.884.4357
::xperaddress::9240 Rumsey Rd Suite B, Columbia, MD 21045
::pwemail::Hello USER,{Enter}{Enter}We're setting up a new computer for you, but in order to proceed we'll need to reset your current password. Please call our service desk at 410.884.4357, when you're available for us to provide you with a temporary password to use for the duration of this computer set up. Once you receive the new device, we recommend you reset your password once more.{Enter}Don't hesitate to let us know if you have any questions, concerns, or updates regarding this hardware refresh.{Enter}{Enter}Thank you,{Enter}{Enter}Alex DeMey{Enter}Support Specialist{Enter}Xpertechs{Enter}410.884.4357
::fuemail::Hello USER,{Enter}{Enter}I'm reaching out in regards to your new MODEL computer, DEVICENAME. Once you get a chance to try this device out a bit, please let us know how it's performing for you.{Enter}Don't hesitate to let us know, or call our service desk at 410.884.4357, if you'd like any assistance getting set up with this computer.{Enter}{Enter}Thank you,{Enter}{Enter}Alex DeMey{Enter}Support Specialist{Enter}Xpertechs{Enter}410.884.4357
::shippedemail::Hello USER,{Enter}{Enter}We are excited to let you know that your HARDWARE has shipped. You can track the status of your package using the following FedEx tracking number: TRACKING.{Enter}{Enter}If you have any questions or concerns please feel free to reply to this email and the XPERTECHS Support Team will reach out.{Enter}{Enter}We kindly ask that you keep a close eye on your package by using the provided tracking number noted above. XPERTECHS is not responsible for lost or delayed shipments as a result of 3rd party carriers.{Enter}{Enter}Thank you,{Enter}{Enter}Alex DeMey{Enter}Support Specialist{Enter}Xpertechs{Enter}410.884.4357
::fuclose::USER,{Enter}{Enter}Excellent{!} Glad to hear the new computer's working well for you. In that case, we'll go ahead and mark this ticket complete for now, but you can re-open it by replying to this email in the event you encounter anything you'd like assistance getting set up with.{Enter}{Enter}Please don't hesitate to reach out to us, or call our service desk at 410.884.4357, should you ever require any technical assistance.{Enter}{Enter}Thank you,{Enter}{Enter}Alex DeMey{Enter}Support Specialist{Enter}Xpertechs{Enter}410.884.4357 
; ~~~~~ Ticket Names
::MACnew::MAC - New Hire - Hardware Request - USER - DATE
::MACrefresh::MAC - Hardware Request - USER
::MACeq::Equipment Retrieval - MAC - DEVICENAME
::MACrma::RMA - DEVICE - ISSUE
::MACspare::Re-image SERIAL as a spare
; ~~~~~ REGISTRY
::reguserremove::Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\
; ~~~~~ CMD
::getwindowskey::wmic path softwarelicensingservice get OA3xOriginalProductKey
::makeadmin::net localgroup administrators AzureAD\EMAIL /add
::createxpertechs::net user /add Xpertechs 32vD82JkjXCS
::movetopublic::Move-Item -Path "ORIGIN" -Destination "C:\Users\Public\Desktop"
; ~~~~~ PowerShell
::enableps::Set-ExecutionPolicy RemoteSigned
::disableps::Set-ExecutionPolicy Restricted
; ~~~~~ OTHER
::publicdesktop::C:\users\public\desktop
::oapps::Word, Excel, PowerPoint
::wasd::{Shift down}{3}{Shift up}~~~~~~~~~~~~~~~~~~~~~~~~~~~~{Enter}{Shift down}{3}{Shift up}~~~~~~~~~~~~~~~~~~~~~~~~~~~~{Enter}{Shift down}{3}{Shift up}~~~~~~~~~~~~~~~~~~~~~~~~~~~~{Enter}
::bitlockerstatus::Get-BitLockerVolume | Select-Object MountPoint, VolumeStatus, EncryptionPercentage, LockStatus, AutoUnlockEnabled{Enter}
::cominfo::Device name: NAME, Serial Number: SERIAL, Model: MODEL, Warranty exp. date: DATE
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~ HOTKEYS ~~~~~~~~~~~~~~~~~~~~~~~~~~~

XButton1:: ; Mouse Thumb Button (Paste)
    SendInput, {Ctrl down}v{Ctrl up}
return

XButton2:: ; Mouse Thumb Button (Copy)
    SendInput, {Ctrl down}c{Ctrl up}
return

^#s:: ; Startup Apps 
	Run, C:\Users\AlexDeMey\AppData\Local\authy\app-2.5.0\Authy Desktop.exe ; AUTHY
	Run, C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk ; OUTLOOK
	Run, C:\ProgramData\Microsoft\Windows\Start Menu\Programs\ConnectWise Automate\Automate Control Center.lnk ; AUTOMATE
	Run, C:\ProgramData\Microsoft\Windows\Start Menu\Programs\ConnectWise Manage.lnk ; MANAGE
	Run, C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Firefox.lnk ; FireFox
	Run, C:\ProgramData\Microsoft\Windows\Start Menu\Unity Client.lnk ; Unity
	Run, C:\Program Files (x86)\Sizer\sizer.exe ; Sizer
return

; End = toggle mute
End::
	Send, {Ctrl down}{Shift down}m{Shift up}{Ctrl up}
return

; XperDeploymentUtility
^!x::
Run, powershell_ise.exe "C:\Users\AlexDeMey\OneDrive - XPERTECHS\Documents\00 - Scripts\xperdeploymentutility.ps1"
return

; Disable keys
Home::return
PgUp::return
PgDn::return


^`:: ; Troubleshooting hotkey
	
return