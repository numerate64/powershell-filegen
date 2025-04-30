# PowerShell File Generator

This project contains a PowerShell script to generate a specified number of folders, each with a specified number of text files of random sizes between 4KB and 128KB. Each folder and file has a random name, and files are filled with random data.

## Usage

1. Make sure you have PowerShell 7.0+ installed.
2. Run the script:
   ```powershell
   ./Generate-RandomFiles.ps1
   ```
   You can optionally specify parameters:
   ```powershell
   ./Generate-RandomFiles.ps1 -FolderCount 10 -FilesPerFolder 10 -MinFileSizeKB 4 -MaxFileSizeMB 0.125 -Parallelism 64
   ```
   - `-FolderCount`: Number of folders to create (default: 10)
   - `-FilesPerFolder`: Files per folder (default: 10)
   - `-MinFileSizeKB`: Minimum file size in KB (default: 4)
   - `-MaxFileSizeMB`: Maximum file size in MB (default: 0.125, i.e., 128KB)
   - `-Parallelism`: Number of parallel folder jobs (default: 64)
   - `-help`, `-?`: Show help/usage information
3. The generated folders and files will be in the `files` directory.

## Help / Usage

You can view usage information at any time:
```powershell
./Generate-RandomFiles.ps1 -help
```

## Output Details

- As the script runs, it prints a message for each folder when it completes, and any errors encountered are displayed in red.
  ```
  [FolderName] Completed: 10 files (added 3), 12.19 MB written. Errors: 0
  Error writing C:\path\to\file.txt: [error details]
  ```
- At the end, a summary is displayed:
  ```
  Summary:
    Total folders: 10
    Total files: 100
    Total size: 1.19 GB (1219.92 MB)
    Total errors: 0
    Time elapsed: 00:00:02.92
  Done!
  ```
- Output from folders may appear in any order due to parallel execution.

## Resumable Runs

- The script is fully resumable. If interrupted or re-run, it will:
  - Reuse previously generated folder names.
  - Skip folders that already exist and have the required number of files.
  - Only create missing files in incomplete folders.
  - No duplicate folders or files will be created if parameters are unchanged.
- This allows you to safely interrupt and resume large jobs without wasting time or disk space.

## Requirements
- PowerShell 7.0 or later

## Notes
- This script uses parallel processing for faster execution. The default is 64 parallel jobs, which is suitable for high-core-count systems. Adjust the `-Parallelism` parameter based on your system's CPU and memory. Using too many threads on a low-resource machine may slow down execution or cause errors.
- The script may take significant time and disk space due to the large number and size of files generated. Adjust parameters as needed to fit your system's capabilities.
- Errors encountered during folder or file creation are reported, but the script will continue processing other folders/files.
