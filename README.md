# <img src="https://projectignis.github.io/assets/img/ignis_logo.png" width="80"/> Armytille's EDOPro HD Pics Downloader

[![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://docs.microsoft.com/en-us/powershell/scripting/overview)  
[![Bash Version](https://img.shields.io/badge/Bash-4.0%2B-green)](https://www.gnu.org/software/bash/)  
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)  

**Armytille's EDOPro HD Pics Downloader** is a cross-platform application that allows you to easily download **HD images of Yu-Gi-Oh! cards** for **EDOPro**. Available for both **Windows** (PowerShell GUI) and **macOS** (Bash script).

---

## 🌟 Features

- Download **all Yu-Gi-Oh! cards in HD**.
- Special handling for **Field Spells cropped images**.
- Automatic support for **alternate arts**.
- Option to **force overwrite** existing images.
- **Real-time progress tracking** and **logging**.
- **Windows**: Simple Windows Forms GUI with progress bar.
- **macOS**: Command-line script with optional GUI dialogs.
- **Concurrent downloads** for faster performance.
- Automatic **error handling and retries**.

---

## 📦 Platform-Specific Instructions

### 🪟 Windows (PowerShell)

#### Installation & Usage

1. **Download the script** `EDOPro-HD-Pics-Downloader.ps1`.
2. **Place the file** at the **root of your EDOPro folder**, in the same location as the `pics` folder.  
3. **Run the script**: **Right-click → Run with PowerShell**.

#### Using the GUI

- Click **"Download All Cards"** to start downloading.
- Check **"Force Overwrite Existing"** to overwrite existing images.
- Click **"Cancel"** to stop the download at any time.
- The **progress bar** and **log window** display real-time status.
  
<img width="616" height="261" alt="image" src="https://github.com/user-attachments/assets/69c0684e-5961-4e64-a503-192aede20b93" />

#### Optional: Enable Script Execution

If needed, enable unrestricted script execution in PowerShell (Run as Admin):
```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
```

---

### 🍎 macOS (Bash)

#### Prerequisites

- macOS 10.10 or later
- `curl` (pre-installed on macOS)
- Optional: `jq` for better performance (install via Homebrew: `brew install jq`)

#### Installation & Usage

**Method 1: Double-Click Execution (Easiest)**

1. **Download the files** `EDOPro-HD-Pics-Downloader.sh` and `EDOPro-HD-Pics-Downloader.command`.
2. **Place the files** anywhere (they will auto-detect your EDOPro installation).
3. **Double-click** `EDOPro-HD-Pics-Downloader.command` to run with GUI prompts.

**Method 2: Command Line**

1. **Download the script** `EDOPro-HD-Pics-Downloader.sh`.
2. **Make it executable**:
   ```bash
   chmod +x EDOPro-HD-Pics-Downloader.sh
   ```
3. **Run the script**:
   ```bash
   ./EDOPro-HD-Pics-Downloader.sh
   ```

#### Command Line Options

```bash
./EDOPro-HD-Pics-Downloader.sh [OPTIONS]

Options:
  -f, --force    Force overwrite existing images
  -g, --gui      Show GUI prompt (macOS only)
  -h, --help     Show help message
```

#### Examples

```bash
# Basic download (skips existing files)
./EDOPro-HD-Pics-Downloader.sh

# Force overwrite all images
./EDOPro-HD-Pics-Downloader.sh --force

# Use GUI prompts
./EDOPro-HD-Pics-Downloader.sh --gui
```

#### macOS Directory Structure

The script automatically detects EDOPro at:
```
/Applications/ProjectIgnis/
├── EDOPro.app
├── pics/          (download destination)
│   └── field/     (field spell crops)
├── config/
├── sound/
└── [other directories]
```

If your EDOPro installation is in a different location, the script will prompt you to enter the path.

#### Performance Tips

For better performance on macOS, install `jq`:
```bash
brew install jq
```

This enables faster JSON parsing and progress tracking.

---

## 🔧 Technical Details

### API Source

- **API**: [YGOProDeck API](https://db.ygoprodeck.com/api/v7/cardinfo.php)
- **Images**: High-quality card images from YGOProDeck

### Features Comparison

| Feature | Windows (PowerShell) | macOS (Bash) |
|---------|---------------------|--------------|
| GUI Interface | ✅ Windows Forms | ✅ Optional AppleScript |
| Progress Bar | ✅ Real-time | ✅ Console output |
| Concurrent Downloads | ✅ (20 threads) | ✅ (20 parallel) |
| Field Spell Crops | ✅ | ✅ |
| Alternate Arts | ✅ | ✅ |
| Force Overwrite | ✅ | ✅ |
| Error Retry | ✅ (3 attempts) | ✅ (3 attempts) |
| Cancel Operation | ✅ | ⚠️ Ctrl+C |

---

## 🐛 Troubleshooting

### Windows

**Problem**: "Cannot be loaded because running scripts is disabled"
- **Solution**: Run PowerShell as Administrator and execute:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

**Problem**: Downloads are very slow
- **Solution**: Check your internet connection. The script uses 20 concurrent connections by default.

### macOS

**Problem**: "Permission denied" error
- **Solution**: Make the script executable:
  ```bash
  chmod +x EDOPro-HD-Pics-Downloader.sh
  ```

**Problem**: Script cannot find EDOPro directory
- **Solution**: When prompted, enter the full path to your EDOPro installation (e.g., `/Applications/ProjectIgnis`)

**Problem**: "Command not found: jq"
- **Solution**: This is optional. Install jq for better performance:
  ```bash
  brew install jq
  ```
  Or continue without it (the script will use a fallback parser).

**Problem**: Downloads are slow
- **Solution**: Install `jq` for faster JSON parsing. Check your internet connection.

---

## 📝 License

This project is provided as-is for the EDOPro community. Feel free to modify and distribute.

---

## 🙏 Credits

- **Original PowerShell Version**: Armytille
- **macOS Support**: Community contribution
- **Card Data**: [YGOProDeck API](https://ygoprodeck.com/)
- **EDOPro**: [Project Ignis](https://projectignis.github.io/)

---

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Ensure you have the latest version of the script
3. Verify your EDOPro installation is in the expected location
4. Check your internet connection

For Windows-specific issues, refer to the PowerShell error messages in the log window.
For macOS-specific issues, check the terminal output for detailed error messages.
