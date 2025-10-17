Write-Host "Setting en-GB as the default language and system locale..."

$LangList = New-WinUserLanguageList en-GB
Set-WinUserLanguageList $LangList -Force
Set-SystemPreferredUILanguage -Language en-GB
Set-WinSystemLocale -SystemLocale en-GB
Set-Culture -CultureInfo en-GB
Set-WinHomeLocation -GeoId 242  # United Kingdom
Set-WinUILanguageOverride -Language en-GB
Set-WinSystemLocale en-GB

Write-Host "Default language set to en-GB successfully."
