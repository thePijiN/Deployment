$EnrollmentKey = Get-ChildItem HKLM:\Software\Microsoft\Enrollments -recurse | Where-Object { $_.name -like "*firstsync*" }
$EnrollmentKey | Set-Itemproperty -name SkipDeviceStatusPage -value 1 -Force
$EnrollmentKey | Set-Itemproperty -name SkipUserStatusPage -value 1 -Force
Get-Process "winlogon" | stop-process -Force