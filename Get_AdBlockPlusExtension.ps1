# Check if Microsoft Edge is installed
if (Test-Path "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe") {
    # Open Microsoft Edge to Adblock Plus extension page
    Start-Process "msedge" "https://microsoftedge.microsoft.com/addons/detail/adblock-plus-free-ad-bl/gmgoamodcdcjnbaobigkjelfplakmdhh"
}

# Check if Google Chrome is installed
if (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") {
    # Open Google Chrome to Adblock Plus extension page
    Start-Process "chrome" "https://chrome.google.com/webstore/detail/adblock-plus-free-ad-bloc/cfhdojbkjhnklbpkdaibdccddilifddb"
}

# Check if Mozilla Firefox is installed
if (Test-Path "C:\Program Files\Mozilla Firefox\firefox.exe") {
    # Open Mozilla Firefox to Adblock Plus extension page
    Start-Process "firefox" "https://addons.mozilla.org/en-US/firefox/addon/adblock-plus/"
}
