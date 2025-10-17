# Azure Image Builder – Persist UK (en-GB) Language Pack

## Goal
Create a Windows 11 AVD image that *retains* the UK English (en-GB) language after sysprep.

## Requirements
- Use **Azure Portal → Custom Image Template**
- Use only built-in steps and PowerShell customizations

---

## 🔧 Steps in Azure Portal

1. **Open Azure Portal → Image Builder → + Create Template**

2. Under **Customize**, add the following steps **in order**:

   | Order | Step Type | Script / Option | Purpose |
   |--------|------------|------------------|----------|
   | 1 | Built-in | Apply Windows Updates | Prepares the image |
   | 2 | Custom Script | `1-disable-language-cleanup.ps1` | Prevents language cleanup |
   | 3 | Built-in | Windows Restart | Apply policy |
   | 4 | Custom Script | `2-install-en-gb.ps1` | Installs en-GB language pack |
   | 5 | Built-in | Windows Restart | Ensures installation persistence |
   | 6 | Custom Script | `3-set-default-en-gb.ps1` | Sets en-GB as default |
   | 7 | Built-in | Windows Restart | Finalize settings before sysprep |

3. Continue with other steps as usual, then build the image.

---

## ✅ Validation
When deploying a VM from the image:
- OS display language → **English (United Kingdom)**
- Region → **United Kingdom**
- Keyboard layout → **UK**
- Date/Time format → **dd/MM/yyyy**

---

## 🧠 Notes
- Do **not** run “Set default OS language” or “Install languages” built-in steps — your scripts replace those.
- The `BlockCleanupOfUnusedPreinstalledLangPacks` registry key is critical to surviving sysprep.
- Works with AVD pooled or personal host images.