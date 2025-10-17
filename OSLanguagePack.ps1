<#Author       : Jacob Williams
# Usage        : Install Language packs
#>

#######################################
#    Install language packs           #
#######################################


[CmdletBinding()]
  Param (
        [Parameter(
            Mandatory
        )]
        [ValidateSet("Arabic (Saudi Arabia)","Bulgarian (Bulgaria)","Chinese (Simplified, China)","Chinese (Traditional, Taiwan)","Croatian (Croatia)","Czech (Czech Republic)","Danish (Denmark)","Dutch (Netherlands)", "English (United Kingdom)", "Estonian (Estonia)", "Finnish (Finland)", "French (Canada)", "French (France)", "German (Germany)", "Greek (Greece)", "Hebrew (Israel)", "Hungarian (Hungary)", "Italian (Italy)", "Japanese (Japan)", "Korean (Korea)", "Latvian (Latvia)", "Lithuanian (Lithuania)", "Norwegian, Bokmål (Norway)", "Polish (Poland)", "Portuguese (Brazil)", "Portuguese (Portugal)", "Romanian (Romania)", "Russian (Russia)", "Serbian (Latin, Serbia)", "Slovak (Slovakia)", "Slovenian (Slovenia)", "Spanish (Mexico)", "Spanish (Spain)", "Swedish (Sweden)", "Thai (Thailand)", "Turkish (Turkey)", "Ukrainian (Ukraine)", "English (Australia)", "English (United States)")]
        [System.String[]]$LanguageList
    )

function Install-LanguagePack {
  
   
    <#
    Function to install language packs along with features on demand: 
    https://learn.microsoft.com/en-gb/powershell/module/languagepackmanagement/install-language?view=windowsserver2022-ps
    #>

    BEGIN {
        
        $templateFilePathFolder = "C:\AVDImage"
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Write-host "Starting AVD AIB Customization: Install Language packs: $((Get-Date).ToUniversalTime()) "

         # populate dictionary
         $LanguagesDictionary = @{}
         $LanguagesDictionary.Add("English (United Kingdom)",	"en-GB")

         # Disable LanguageComponentsInstaller while installing language packs
         # See Bug 45044965: Installing language pack fails with error: ERROR_SHARING_VIOLATION for more details
         Disable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\Installation"
         Disable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources"
    } # Begin
    PROCESS {

        foreach ($Language in $LanguageList) {

            # retry in case we hit transient errors
            for($i=1; $i -le 5; $i++) {
                 try {
                    Write-Host "*** AVD AIB CUSTOMIZER PHASE : Install language packs -  Attempt: $i ***"   
                    $LanguageCode =  $LanguagesDictionary.$Language
                    Install-Language -Language $LanguageCode -ErrorAction Stop
                    Write-Host "*** AVD AIB CUSTOMIZER PHASE : Install language packs -  Installed language $LanguageCode ***"   
                    break
                }
                catch {
                    Write-Host "*** AVD AIB CUSTOMIZER PHASE : Install language packs - Exception occurred***"
                    Write-Host $PSItem.Exception
                    continue
                }
            }
        }
    } #Process
    END {
        # Set the first language as default
        $PrimaryLanguageCode = $LanguagesDictionary.$LanguageList[0]
        
        Write-Host "*** AVD AIB CUSTOMIZER PHASE : Setting $PrimaryLanguageCode as default language ***"
        
        try {
            # Method 1: Use DISM (most reliable for image building)
            Write-Host "Setting language via DISM..."
            DISM.exe /Online /Set-AllIntl:$PrimaryLanguageCode
            
            # Method 2: Set system locale
            Write-Host "Setting system locale..."
            Set-WinSystemLocale -SystemLocale $PrimaryLanguageCode
            
            # Method 3: Set for current user (which becomes template)
            Write-Host "Setting user language list..."
            $langList = New-WinUserLanguageList $PrimaryLanguageCode
            Set-WinUserLanguageList $langList -Force
            
            # Method 4: Copy to default user profile via registry
            Write-Host "Copying settings to default user profile..."
            
            # Load the default user hive
            $defaultUserPath = "C:\Users\Default\NTUSER.DAT"
            if (Test-Path $defaultUserPath) {
                reg load HKU\DefaultUser $defaultUserPath 2>&1 | Out-Null
                
                # Copy international settings
                reg copy "HKCU\Control Panel\International" "HKU\DefaultUser\Control Panel\International" /s /f 2>&1 | Out-Null
                
                # Unload the hive
                [gc]::Collect()
                Start-Sleep -Seconds 2
                reg unload HKU\DefaultUser 2>&1 | Out-Null
            }
            
            Write-Host "*** AVD AIB CUSTOMIZER PHASE : Default language configuration complete ***"
        }
        catch {
            Write-Host "*** AVD AIB CUSTOMIZER PHASE : Language configuration error ***"
            Write-Host $PSItem.Exception
        }

        #Cleanup
        if ((Test-Path -Path $templateFilePathFolder -ErrorAction SilentlyContinue)) {
            Remove-Item -Path $templateFilePathFolder -Force -Recurse -ErrorAction Continue
        }

        # Enable LanguageComponentsInstaller after language packs are installed
        Enable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\Installation"
        Enable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources"
        
        $stopwatch.Stop()
        $elapsedTime = $stopwatch.Elapsed
        Write-Host "*** AVD AIB CUSTOMIZER PHASE : Install language packs -  Exit Code: $LASTEXITCODE ***"    
        Write-Host "Ending AVD AIB Customization : Install language packs - Time taken: $elapsedTime"
    } 
}

 Install-LanguagePack -LanguageList $LanguageList

 #############
#    END    #
#############