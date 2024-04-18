# Path to the text file
$filePath = "C:\Windows\LTSvc\lterrors.txt"

# Read the content of the file
$fileContent = Get-Content -Path $filePath

# Join the content into a single string
$joinedContent = [string]::Join("`n", $fileContent)

# Use regex to find the pattern and extract the 5 digits after it
$pattern = "Signed Up with ID:\s*(\d{5})"
$match = [regex]::Match($joinedContent, $pattern)

# Check if a match is found
if ($match.Success) {
    # Extract the 5 digits from the match
    $agentID = $match.Groups[1].Value

    # Print the extracted digits
    Write-Host "Agent ID extracted: $agentID"
} else {
    Write-Host "The pattern 'Signed Up with ID:' followed by 5 digits was not found in the file."
}
#Pause and wait for input
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')