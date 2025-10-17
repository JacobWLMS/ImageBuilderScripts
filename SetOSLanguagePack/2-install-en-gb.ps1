Write-Host "Installing en-GB language pack and features..."

# Ensure Windows capability packages are available
Install-Language -Language en-GB -ErrorAction Stop

# Optional: explicitly install extra features (handwriting, OCR, etc.)
$features = @(
    "Language.Basic~~~en-GB~0.0.1.0",
    "Language.Handwriting~~~en-GB~0.0.1.0",
    "Language.OCR~~~en-GB~0.0.1.0",
    "Language.Speech~~~en-GB~0.0.1.0",
    "Language.TextToSpeech~~~en-GB~0.0.1.0"
)
foreach ($feature in $features) {
    try {
        Add-WindowsCapability -Online -Name $feature -ErrorAction Stop
    } catch {
        Write-Warning "Feature $feature failed to install or already present."
    }
}

Write-Host "en-GB language pack installed successfully."
