^Esc:: ; This hotkey triggers when you press Ctrl + Esc
    ExitApp  ; Terminates the AHK script
return

^1:: ; Configure Power & Sleep settings
	Send, {Ctrl up}{LWin}
	Sleep, 2000
	Send, power{space}sleep
	Sleep, 2000
	Send, {Enter}
	Sleep, 2000
	Loop 4 
	{
		Send, {n}{tab}
		Sleep, 100
	}
	Send, !{F4} ; Close app
return

^2:: ; Disable UAC
	Send, {Ctrl up}{LWin}
	Sleep, 1000
	Send, uac
	Sleep, 1000
	Send, {Enter}
	Sleep, 2000
	Loop 5
	{
		Send, {Down}
		Sleep, 100
	}
	Send, {Tab}{Enter}
	Sleep, 2000
	Send, {Left}{Enter}
return

^3:: ; Disable HELLO
    Run, gpedit.msc ; Open GP Edit
    WinWaitActive, ahk_exe MMC.exe ; Wait for window to become active
    Sleep, 500
	Send, {a}
	Sleep, 500
    CoordMode, Mouse, Window
    MouseClick, left, 440, 260, 2 ; Double Click 'Windows Components'
	Sleep, 500
	MouseMove, 749, 135 ; Move to scrollbar
	Click, Down ; Click down on it
	MouseMove, 749, 440 ; Scroll down
	Click, Up
	MouseClick, left, 470, 180, 2 ; Double click 'Windows Hello for Business'
	Sleep, 500
	MouseClick, left, 480, 295, 2 ; Double click 'Use Windows Hello for Business'
	Sleep, 1000
	WinWaitActive, ahk_exe MMC.exe ; Wait for new window to become active
	Sleep, 150
	MouseClick, left, 23, 154 ; Select 'Disable'
	Sleep, 250
	Send, {Enter}
    Sleep, 250
	WinWaitActive, ahk_exe MMC.exe ; Wait for new window to become active
	Send, !{F4} ; Close app
return

^`::
	
return


