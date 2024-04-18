@echo off
set /p choice="Enter '1' to Create or '2' to Remove: "

if "%choice%"=="1" (
    color a
    net user /add xpertechs 32vD82JkjXCS
    net localgroup Administrators xpertechs /add
) elseif "%choice%"=="2" (
    color a
    net user /delete xpertechs
    rmdir /s /q "C:\users\xpertechs"
) else (
    echo Invalid choice. Please enter '1' or '2'.
)

echo Done.
