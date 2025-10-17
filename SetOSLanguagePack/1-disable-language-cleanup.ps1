Write-Host "Disabling cleanup of unused language packs..."
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Control Panel\International" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Control Panel\International" `
  -Name "BlockCleanupOfUnusedPreinstalledLangPacks" `
  -Value 1 -PropertyType DWord -Force | Out-Null
Write-Host "Language pack cleanup disabled."