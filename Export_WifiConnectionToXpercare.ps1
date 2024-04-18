$folderPath = "C:\xpercare\"

if (!(Test-Path $xpercareDirectory -PathType Container)) {
	    New-Item -ItemType Directory -Force -Path $xpercareDirectory
	    Write-Host "Created C:\xpercare\"
    } else {
	    Write-Host "C:\xpercare already exists!"
    }
	
netsh wlan export profile folder=$folderPath