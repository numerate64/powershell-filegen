# PowerShell File Generator

PowerShell 7 script for generating random folders and binary files for storage, copy, and performance testing.

## File

- `Generate-RandomFiles.ps1` - creates a `files/` directory beside the script and fills it with random folders and files.

## Usage

```powershell
.\Generate-RandomFiles.ps1 -FolderCount 10 -FilesPerFolder 10 -MinFileSizeKB 4 -MaxFileSizeKB 128 -Parallelism 64
```

The generator is resumable. If `files/` already contains generated folders, the script reuses them and adds missing files up to the requested count.
