@echo off
set /p choice="Enter '1' to Create or '2' to Remove: "

if "%choice%"=="1" (
    color a
    net user /add ImmyTest 32vD82JkjXCS
    net localgroup Administrators ImmyTest /add
) elseif "%choice%"=="2" (
    color a
    net user /delete ImmyTest
    rmdir /s /q "C:\users\ImmyTest"
) else (
    echo Invalid choice. Please enter '1' or '2'.
)

echo Done.
