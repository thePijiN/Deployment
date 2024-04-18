$installDirectory = "C:\xpercare\Office Deployment"
$xmlFilePath = "$installDirectory\Remove_Foreign.xml"
$downloadUrl = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_17126-20132.exe"

# Create the installation directory if it doesn't exist
if (-not (Test-Path -Path $installDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $installDirectory
}

# Download Office Deployment Tool
Invoke-WebRequest -Uri $downloadUrl -OutFile "$installDirectory\officedeploymenttool.exe"

# Start the Office Deployment Tool and simulate keypresses to accept license terms
$officeDeploymentToolPath = "$installDirectory\officedeploymenttool.exe"
$process = Start-Process -FilePath $officeDeploymentToolPath -PassThru
Start-Sleep -Seconds 2  # Adjust the sleep duration as needed

# Simulate keypresses to accept license terms
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('{TAB}')
Start-Sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait('{TAB}')
Start-Sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait('A')
Start-Sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait('{TAB}')
Start-Sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait('~')  # Simulate 'Enter' to accept license terms

# Wait for the Office Deployment Tool process to complete
Wait-Process -InputObject $process

# Bring 'Browse For Folder' window to the foreground
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
"@
Add-Type @"
    public class WindowTools {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@
Start-Sleep -Seconds 1
$browseForFolderWindow = Get-Process | Where-Object { $_.MainWindowTitle -eq 'Browse For Folder' } | Select-Object -First 1
[WindowTools]::SetForegroundWindow($browseForFolderWindow.MainWindowHandle)

# Simulate keypresses to navigate and extract files
[System.Windows.Forms.SendKeys]::SendWait('~')  # Simulate 'Enter' to select 'This PC'
Start-Sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait('this')
Start-Sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait('{RIGHT}')  # Simulate 'Right Arrow' to expand selection
Start-Sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait('xper')
Start-Sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait('office')
Start-Sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait('~')  # Simulate 'Enter' to extract files
Start-Sleep -Seconds 1

# Close the Office Deployment Tool
[System.Windows.Forms.SendKeys]::SendWait('~')  # Simulate 'Enter' to close the application

# Create XML configuration file
@"
<Configuration>
    <Remove>
        <Product ID="O365ProPlusRetail">
            <Language ID="nl-nl" />
            <Language ID="fr-fr" />
            <Language ID="de-de" />
            <Language ID="it-it" />
            <Language ID="es-es" />
            <Language ID="pl-pl" />
            <Language ID="cs-cz" />
            <Language ID="ro-ro" />
            <Language ID="sk-sk" />
        </Product>
        <Product ID="OneNote">
            <Language ID="nl-nl" />
            <Language ID="fr-fr" />
            <Language ID="de-de" />
            <Language ID="it-it" />
            <Language ID="es-es" />
            <Language ID="pl-pl" />
            <Language ID="cs-cz" />
            <Language ID="ro-ro" />
            <Language ID="sk-sk" />
        </Product>
    </Remove>
    <Updates Enabled="TRUE" />
</Configuration>
"@ | Set-Content -Path $xmlFilePath

# Run Office Deployment Tool with the configuration file
Start-Process -FilePath "$installDirectory\setup.exe" -ArgumentList "/configure `"$xmlFilePath`"" -Wait
