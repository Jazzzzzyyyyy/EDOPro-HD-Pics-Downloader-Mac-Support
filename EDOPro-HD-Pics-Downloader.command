#!/bin/bash

# Wrapper script for double-click execution on macOS
# This allows users to run the downloader by double-clicking the file

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to script directory
cd "$SCRIPT_DIR"

# Run the main script with GUI mode
bash "$SCRIPT_DIR/EDOPro-HD-Pics-Downloader.sh" --gui

# Keep terminal open on completion
echo ""
echo "Press any key to close this window..."
read -n 1 -s
