@echo off
echo Stopping Windows Installer service...
net stop msiserver
echo.
echo Starting Windows Installer service...
net start msiserver
echo.
echo Windows Installer service restarted successfully.
