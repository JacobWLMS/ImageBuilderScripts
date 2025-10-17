# Azure Image Builder – Persist UK (en-GB) Language Pack

## Goal
Create a Windows 11 AVD image (pooled) that retains the UK English (en-GB) language after sysprep, with default user profile settings.

## Scripts Location
The PowerShell scripts are hosted in this GitHub repo:

| Step | Script | URI |
|------|--------|-----|
| 1 | disable cleanup | `https://raw.githubusercontent.com/JacobWLMS/ImageBuilderScripts/refs/heads/main/SetOSLanguagePack/1-disable-language-cleanup.ps1` |
| 2 | install en-GB | `https://raw.githubusercontent.com/JacobWLMS/ImageBuilderScripts/refs/heads/main/SetOSLanguagePack/2-install-en-gb.ps1` |
| 3 | set default | `https://raw.githubusercontent.com/JacobWLMS/ImageBuilderScripts/refs/heads/main/SetOSLanguagePack/3-set-default-en-gb.ps1` |

---

## 🔧 Azure Portal Setup (Image Builder Template)

1. In the Azure Portal, go to **Image Templates → + Create → Custom Image Template**  
2. Select your Windows 11 multi-session Gen2 base image  
3. In the **Customize** section, add the following steps **in order**:

   | Order | Type | Script / Built-in | Notes |
   |------:|------|--------------------|-------|
   | 1 | Built-in | **Apply Windows Updates** | Ensure system is patched |
   | 2 | Custom Script | Use URI: `1-disable-language-cleanup.ps1` | Set “Source URI” to the GitHub raw link above; run **as SYSTEM** |
   | 3 | Built-in | **Windows Restart** | Let registry changes apply |
   | 4 | Custom Script | Use URI: `2-install-en-gb.ps1` | Raw link install script; run **as SYSTEM** |
   | 5 | Built-in | **Windows Restart** | Confirm language pack is present |
   | 6 | Custom Script | Use URI: `3-set-default-en-gb.ps1` | Raw link default-setting script; run **as SYSTEM** |
   | 7 | Built-in | **Windows Restart** | Finalize before sysprep |

4. Continue through the template (destination image gallery, etc.) and **Create**  
5. Build the image. Once complete, any VM deployed from that image will default to **English (United Kingdom)** for display, locale, keyboard, etc.

---

## ✅ What to Expect on Deployed VMs

- Display language: English (United Kingdom)  
- System locale / regional format: en-GB  
- Keyboard layout: UK  
- Date/time format: UK style (dd/MM/yyyy)  
- Default profile and new users will inherit these settings  

---

## 🧠 Important Notes

- Do **not** use the built-in “Install languages” or “Set default OS language” artifacts — the scripts handle that reliably.  
- The registry key `BlockCleanupOfUnusedPreinstalledLangPacks = 1` prevents sysprep from stripping the language pack.  
- The order is critical: disable cleanup → reboot → install → reboot → set defaults → reboot.  
- Because scripts are fetched at runtime from GitHub, ensure the build VM has internet access and that the raw URLs are reachable.

---