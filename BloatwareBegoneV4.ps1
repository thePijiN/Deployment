$packageNames = @(
	#Windows
    "*3Dviewer*",
    "*Microsoft.BingWeather*",
	"Microsoft.BingNews", 
	"Microsoft.GamingApp", 
    "*Microsoft.MicrosoftSolitaireCollection*",
    "*xbox*",
    "*Microsoft.SkypeApp*",
    "*GetHelp*", 
    "*Disney*",
    "*SpotifyAB.SpotifyMusic*",
    "*BingTranslator*",
    "*3dbuilder*",
    "*bingfinance*", 
    "*BingNews*", 
    "*oneconnect*", 
    "*bingsports*", 
    "*twitter*", 
    "*royalrevolt2*", 
    "*marchofempires*", 
    "*candycrushsodasaga*", 
    "*messaging*", 
    "*autodesksketchbook*", 
    "*bubblewitch3saga*", 
    "*keepersecurityinc*", 
    "*HPJumpStart*", 
    "*DiscoverHPTouchpointManager*", 
    "*Keeper*", 
    "*networkspeedtest*", 
    "*MinecraftUWP*", 
    "*RemoteDesktop*", 
    "*MicrosoftPowerBIForWindows*", 
    "*Office.Sway*", 
    "*AdobePhotoshopExpress*", 
    "*EclipseManager*", 
    "*Duolingo-LearnLanguagesforFree*", 
    "*562882FEEB491*", 
    "*29680B314EFC2*", 
    "*Print3D*", 
    "*FreshPaint*", 
    "*Flipboard*", 
    "*BingTranslator*", 
    "*SpotifyMusic*", 
    "*29680B314EFC2*",
	"*Microsoft.Advertising.Xaml*", 
	"*Microsoft.XboxGameCallableUI*",
	"*Microsoft.MixedReality.Portal*", 
	"*Microsoft.XboxSpeechToTextOverlay*", 
	"*Microsoft.XboxGameOverlay*", 
	"*Microsoft.Xbox.TCUI*", 
	"*Microsoft.XboxApp*", 
	"Microsoft.XboxIdentityProvider", 
	#Dell
	"DellInc.PartnerPromo_",
	"DellInc.DellSupportAssistforPCs_htrsf667h5kn2", 
	"DellInc.DellPowerManager", 
	"HONHAIPRECISIONINDUSTRYCO.DellWatchdogTimer", 
	"DellInc.DellOptimizer", 
	"htrsf667h5kn2", 
	#HP
	"AD2F1837.HPDisplayCenter", 
	"AD2F1837.HPPowerManager", 
	"AD2F1837.HPSystemInformation", 
	"AD2F1837.HPQuickDrop", 
	"AD2F1837.HPPrivacySettings", 
	"AD2F1837.HPPCHardwareDiagnosticsWindows", 
	"AD2F1837.HPEasyClean", 
	"AD2F1837.myHP", 
	"AD2F1837.HPSupportAssistant", 
	"AD2F1837.HPProgrammableKey", 
	"SynapticsIncorporated.SynHPCommercialStykDApp", 
	#Other
	"DolbyLaboratories.DolbyVisionAccess", 
	"DolbyLaboratories.DolbyAccessOEM"
	# Add more packages as needed
)
$xpercareDirectory = "C:\xpercare\"
#Create C:\xpercare if it doesn't already exists
if (!(Test-Path $xpercareDirectory -PathType Container)) {
	    New-Item -ItemType Directory -Force -Path $xpercareDirectory
	    Write-Host "Created C:\xpercare\"
    } else {
	    Write-Host "C:\xpercare already exists!"
	}
		
# Display the prompt for user selection
Write-Host "Select an option:"
Write-Host "1. Gather Application Package Information (Saves to C:\xpercare)"
Write-Host "2. Purge Bloatware"

# Read the user's input
$selection = Read-Host "Enter selection:"

# Process the user's selection
switch ($selection) {
    '1' {
		#Get the computer's serial number
		$serialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber
		# Construct the file name using the serial number
		$fileName = "InstalledApps_$serialNumber.txt"
        $installedapps = Get-AppxPackage -allusers
        $installedapps | Out-File -FilePath "C:\xpercare\$fileName.txt"
    }
    '2' {
        $RemovedAppsTotal = 0
        foreach ($packageName in $packageNames) {
            try {
                $app = Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue
                if ($null -eq $app) {
                    Write-Host "App $packageName not found."
                }

                if ($null -ne $app) {
                    Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like $packageName } | Remove-AppxPackage -ErrorAction Stop
                    Remove-AppxProvisionedPackage -Online -PackageName $packageName -ErrorAction Stop
                    $RemovedAppsTotal++
                    Write-Host "Removed: $packageName"
                }
            } catch {
                Write-Host "Failed to remove: $packageName"
                Write-Host $_.Exception.Message
            }
        }
    }
}

