# PowerShell File Generator

This project contains a PowerShell script to generate 224 folders, each with at least 1000 text files of random sizes between 4KB and 128MB. Each folder and file has a random name, and files are filled with random data.

## Usage

1. Open PowerShell 7 or later and navigate to this directory.
2. Run the script:
   ```powershell
   .\Generate-RandomFiles.ps1
   ```
   You can optionally specify parameters:
   ```powershell
   .\Generate-RandomFiles.ps1 -FolderCount 224 -FilesPerFolder 1000 -MinFileSizeKB 4 -MaxFileSizeMB 128 -Parallelism 64
   ```
   - `FolderCount`: Number of folders to create (default: 224)
   - `FilesPerFolder`: Files per folder (default: 1000)
   - `MinFileSizeKB`: Minimum file size in KB (default: 4)
   - `MaxFileSizeMB`: Maximum file size in MB (default: 128)
   - `Parallelism`: Number of parallel folder jobs (default: 64)
3. The generated folders and files will be in the `files` directory.

## Output Details

- As the script runs, it prints a progress message for each folder when it completes:
  ```
  [FolderName] Completed: 10 files, 540.19 MB written.
  ```
- At the end, a summary is displayed:
  ```
  Summary:
    Total folders: 10
    Total files: 100
    Total size: 5.79 GB (5925.92 MB)
    Time elapsed: 00:00:02.9236890
  Done!
  ```
- Output from folders may appear in any order due to parallel execution.

## Requirements
- PowerShell 7.0 or later (ForEach-Object -Parallel is used for multi-threading)

## Notes
- This script uses multi-threading for faster execution via ForEach-Object -Parallel. The default is 64 parallel jobs, which is suitable for high-core-count systems. Adjust the `-Parallelism` parameter based on your system's CPU and memory. Using too many threads on a low-resource machine may slow down execution or cause errors.
- The script may take significant time and disk space due to the large number and size of files generated. Adjust parameters as needed to fit your system's capabilities.
