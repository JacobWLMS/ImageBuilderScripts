<#
.SYNOPSIS
    Install UK Language Pack and configure regional settings for Azure Image Builder
.DESCRIPTION
    This script installs the English (United Kingdom) language pack and configures 
    all regional settings for UK locale
.AUTHOR
    Jacob Williams
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# Create working directory
$workingDir = "C:\AIBTemp\Production\Configurations"
New-Item -ItemType Directory -Path $workingDir -Force | Out-Null

try {
    Write-Host "=== PHASE 1: Installing UK Language Pack ===" -ForegroundColor Cyan
    $stepStart = Get-Date
    
    # Download the language pack installation script
    $scriptUrl = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27/InstallLanguagePacks.ps1"
    $scriptPath = Join-Path $workingDir "installLanguagePacks.ps1"
    
    Write-Host "Downloading language pack installer..."
    Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath
    
    Write-Host "Installing English (United Kingdom) language pack..."
    & $scriptPath -LanguageList "English (United Kingdom)"
    
    $duration = (Get-Date) - $stepStart
    Write-Host "Language pack installation completed in $($duration.ToString())" -ForegroundColor Green
    
    Write-Host "`n=== PHASE 2: Configuring UK Regional Settings ===" -ForegroundColor Cyan
    $stepStart = Get-Date
    
    $LanguageTag = "en-GB"
    
    Write-Host "Setting Win User Language List to prioritise: $LanguageTag"
    $OldList = Get-WinUserLanguageList
    $UserLanguageList = New-WinUserLanguageList -Language $LanguageTag
    $UserLanguageList += $OldList | Where-Object { $_.LanguageTag -ne $LanguageTag }
    Set-WinUserLanguageList -LanguageList $UserLanguageList -Force
    
    Write-Host "Setting system preferred UI language to: $LanguageTag"
    Set-SystemPreferredUILanguage -Language $LanguageTag
    
    Write-Host "Setting system locale to: $LanguageTag"
    Set-WinSystemLocale -SystemLocale $LanguageTag
    
    # Copy settings to default user profile
    Write-Host "Copying settings to default user profile..."
    $defaultUserPath = "C:\Users\Default\NTUSER.DAT"
    if (Test-Path $defaultUserPath) {
        reg load HKU\DefaultUser $defaultUserPath 2>&1 | Out-Null
        reg copy "HKCU\Control Panel\International" "HKU\DefaultUser\Control Panel\International" /s /f 2>&1 | Out-Null
        
        # Set UK-specific regional settings in default user profile
        reg add "HKU\DefaultUser\Control Panel\International" /v Locale /t REG_SZ /d "00000809" /f | Out-Null
        reg add "HKU\DefaultUser\Control Panel\International" /v LocaleName /t REG_SZ /d "en-GB" /f | Out-Null
        reg add "HKU\DefaultUser\Control Panel\International" /v sCurrency /t REG_SZ /d "£" /f | Out-Null
        reg add "HKU\DefaultUser\Control Panel\International" /v sShortDate /t REG_SZ /d "dd/MM/yyyy" /f | Out-Null
        reg add "HKU\DefaultUser\Control Panel\International\Geo" /v Name /t REG_SZ /d "GB" /f | Out-Null
        reg add "HKU\DefaultUser\Control Panel\International\Geo" /v Nation /t REG_SZ /d "242" /f | Out-Null
        
        [gc]::Collect()
        Start-Sleep -Seconds 2
        reg unload HKU\DefaultUser 2>&1 | Out-Null
    }
    
    $duration = (Get-Date) - $stepStart
    Write-Host "Regional settings configured in $($duration.ToString())" -ForegroundColor Green
    
    Write-Host "`nNOTE: A system restart is required for language settings to fully apply" -ForegroundColor Yellow
    
    Write-Host "`n=== Configuration Complete ===" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
} finally {
    # Cleanup
    if (Test-Path $workingDir) {
        Remove-Item -Path $workingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}