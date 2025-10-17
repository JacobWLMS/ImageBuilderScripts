<#
        ____        ____         _____           _____          _____                                         
       |    |  ____|\   \    ___|\    \     ____|\    \    ___|\     \                                        
       |    | /    /\    \  /    /\    \   /     /\    \  |    |\     \                                       
       |    ||    |  |    ||    |  |    | /     /  \    \ |    | |     |                                      
 ____  |    ||    |__|    ||    |  |____||     |    |    ||    | /_ _ /                                       
|    | |    ||    .--.    ||    |   ____ |     |    |    ||    |\    \                                        
|    | |    ||    |  |    ||    |  |    ||\     \  /    /||    | |    |                                       
|\____\|____||____|  |____||\ ___\/    /|| \_____\/____/ ||____|/____/|                                       
| |    |    ||    |  |    || |   /____/ | \ |    ||    | /|    /     ||                                       
 \|____|____||____|  |____| \|___|    | /  \|____||____|/ |____|_____|/                                                                             
                                                                                                                                                                                  
  _____            ____  ____         ____         ____        ____        ______  _______            ______  
 |\    \   _____  |    ||    |       |    |       |    |  ____|\   \      |      \/       \       ___|\     \ 
 | |    | /    /| |    ||    |       |    |       |    | /    /\    \    /          /\     \     |    |\     \
 \/     / |    || |    ||    |       |    |       |    ||    |  |    |  /     /\   / /\     |    |    |/____/|
 /     /_  \   \/ |    ||    |  ____ |    |  ____ |    ||    |__|    | /     /\ \_/ / /    /| ___|    \|   | |
|     // \  \   \ |    ||    | |    ||    | |    ||    ||    .--.    ||     |  \|_|/ /    / ||    \    \___|/ 
|    |/   \ |    ||    ||    | |    ||    | |    ||    ||    |  |    ||     |       |    |  ||    |\     \    
|\ ___/\   \|   /||____||____|/____/||____|/____/||____||____|  |____||\____\       |____|  /|\ ___\|_____|   
| |   | \______/ ||    ||    |     |||    |     |||    ||    |  |    || |    |      |    | / | |    |     |   
 \|___|/\ |    | ||____||____|_____|/|____|_____|/|____||____|  |____| \|____|      |____|/   \|____|_____|   
    \(   \|____|   
#>

<#
.SYNOPSIS
    Install and configure UK language pack for Azure Image Builder
.DESCRIPTION
    Implements the verified ModernWorkspaceHub solution with pre/post Windows Updates
.AUTHOR
    Jacob Williams
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

try {
    Write-Host "=== PHASE 1: Installing Language Pack ===" -ForegroundColor Cyan
    
    # Download Microsoft's official script
    $scriptUrl = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27/InstallLanguagePacks.ps1"
    $scriptPath = "C:\AIBTemp\installLanguagePacks.ps1"
    
    New-Item -ItemType Directory -Path "C:\AIBTemp" -Force | Out-Null
    Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath
    
    Write-Host "Installing English (United Kingdom) language pack..."
    & $scriptPath -LanguageList "English (United Kingdom)"
    
    Write-Host "`n=== PHASE 2: Configuring System Language ===" -ForegroundColor Cyan
    
    $LanguageTag = "en-GB"
    
    # Add to language list (don't replace)
    Write-Host "Adding $LanguageTag to language list..."
    $LanguageList = Get-WinUserLanguageList
    $LanguageList.Add($LanguageTag)
    Set-WinUserLanguageList $LanguageList -Force
    
    # Set as system preferred UI language
    Write-Host "Setting system preferred UI language..."
    Set-SystemPreferredUILanguage -Language $LanguageTag
    
    # Set system locale
    Write-Host "Setting system locale..."
    Set-WinSystemLocale -SystemLocale $LanguageTag
    
    Write-Host "`n=== PHASE 3: Configuring Default User Registry ===" -ForegroundColor Cyan
    
    # Load default user hive
    $TempKey = "HKU\TEMP"
    $DefaultRegPath = "C:\Users\Default\NTUSER.DAT"
    
    Write-Host "Loading default user registry hive..."
    reg load $TempKey $DefaultRegPath | Out-Null
    
    # UK regional settings
    Write-Host "Applying UK regional settings to default user profile..."
    reg add "$TempKey\Control Panel\International" /v Locale /t REG_SZ /d "00000809" /f | Out-Null
    reg add "$TempKey\Control Panel\International" /v LocaleName /t REG_SZ /d "en-GB" /f | Out-Null
    reg add "$TempKey\Control Panel\International" /v sCountry /t REG_SZ /d "United Kingdom" /f | Out-Null
    reg add "$TempKey\Control Panel\International" /v sCurrency /t REG_SZ /d "`u00A3" /f | Out-Null
    reg add "$TempKey\Control Panel\International" /v sShortDate /t REG_SZ /d "dd/MM/yyyy" /f | Out-Null
    reg add "$TempKey\Control Panel\International\Geo" /v Nation /t REG_SZ /d "242" /f | Out-Null
    reg add "$TempKey\Control Panel\International\Geo" /v Name /t REG_SZ /d "GB" /f | Out-Null
    reg add "$TempKey\Keyboard Layout\Preload" /v 1 /t REG_SZ /d "00000809" /f | Out-Null
    
    # Unload hive
    [gc]::Collect()
    Start-Sleep -Seconds 2
    reg unload $TempKey | Out-Null
    
    # Apply to .DEFAULT for welcome screen
    Write-Host "Applying settings to welcome screen..."
    reg add "HKU\.DEFAULT\Control Panel\International" /v Locale /t REG_SZ /d "00000809" /f | Out-Null
    reg add "HKU\.DEFAULT\Keyboard Layout\Preload" /v 1 /t REG_SZ /d "00000809" /f | Out-Null
    
    Write-Host "`n=== Configuration Complete ===" -ForegroundColor Green
    Write-Host "Language pack installed and configured successfully"
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
