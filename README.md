# PowerShell File Generator

This project contains a PowerShell script to generate 224 folders, each with at least 1000 text files of random sizes between 4KB and 128MB. Each folder and file has a random name, and files are filled with random data.

## Usage

1. Open PowerShell and navigate to this directory.
2. Run the script:
   ```powershell
   .\Generate-RandomFiles.ps1
   ```
   You can optionally specify parameters:
   ```powershell
   .\Generate-RandomFiles.ps1 -FolderCount 224 -FilesPerFolder 1000 -MinFileSizeKB 4 -MaxFileSizeMB 128
   ```
3. The generated folders and files will be in the `output` directory.

## Requirements
- PowerShell 5.1 or later (Windows, or PowerShell Core on macOS/Linux)

## Notes
- This script may take significant time and disk space due to the large number and size of files generated.
- Adjust parameters as needed to fit your system's capabilities.
