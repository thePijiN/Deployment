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
	"DellInc.PartnerPromo_1.0.21.0_x64__htrsf667h5kn2",
	"DellInc.DellSupportAssistforPCs", 
	"DellInc.DellPowerManager", 
	"HONHAIPRECISIONINDUSTRYCO.DellWatchdogTimer", 
	"DellInc.DellOptimizer", 
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

        $RemovedAppsTotal = 0
foreach ($packageName in $packageNames) {
    $app = Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue
    if ($app -ne $null) {
        # Attempt to remove the app
        Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like $packageName } | Remove-AppxPackage -ErrorAction SilentlyContinue

        # Attempt to remove the provisioned package
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $packageName -ErrorAction Stop
        } catch {
            Write-Host "Error removing provisioned package: $_"
        }

        $RemovedAppsTotal++
        if ($RemovedAppsTotal -gt 0) {
            Write-Host "Removed app: $packageName"
        }
    }
}
