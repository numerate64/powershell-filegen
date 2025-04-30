# PowerShell script to generate random folders and files of varying sizes

param(
    [Parameter(HelpMessage = "Number of folders to create (default: 10)")]
    [int]$FolderCount = 10,
    [Parameter(HelpMessage = "Files per folder (default: 10)")]
    [int]$FilesPerFolder = 10,
    [Parameter(HelpMessage = "Minimum file size in KB (default: 4)")]
    [int]$MinFileSizeKB = 4,
    [Parameter(HelpMessage = "Maximum file size in KB (default: 128)")]
    [int]$MaxFileSizeKB = 128,
    [Parameter(HelpMessage = "Number of parallel folder jobs (default: 64)")]
    [int]$Parallelism = 64
)

if ($PSBoundParameters.ContainsKey('help') -or $PSBoundParameters.ContainsKey('?')) {
    Write-Host "\nUsage:"
    Write-Host "  ./Generate-RandomFiles.ps1 [-FolderCount <int>] [-FilesPerFolder <int>] [-MinFileSizeKB <int>] [-MaxFileSizeKB <int>] [-Parallelism <int>] [-help|-?]"
    Write-Host "\nParameters:"
    Write-Host "  -FolderCount      Number of folders to create (default: 10)"
    Write-Host "  -FilesPerFolder   Files per folder (default: 10)"
    Write-Host "  -MinFileSizeKB    Minimum file size in KB (default: 4)"
    Write-Host "  -MaxFileSizeKB    Maximum file size in KB (default: 128)"
    Write-Host "  -Parallelism      Number of parallel folder jobs (default: 64)"
    Write-Host "  -help, -?         Show this help message"
    exit 0
}

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "This script requires PowerShell 7.0 or later for parallel processing."
    exit 1
}

$BasePath = Join-Path -Path $PSScriptRoot -ChildPath "files"

function Get-RandomString($length = 12) {
    -join ((65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_})
}

if (!(Test-Path -Path $BasePath -PathType Container)) {
    New-Item -Path $BasePath -ItemType Directory | Out-Null
}

Write-Host "Starting (resumable) generation of $FolderCount folders, each with $FilesPerFolder files (sizes: $MinFileSizeKB KB to $MaxFileSizeKB KB) using $Parallelism parallel jobs..."
$startTime = Get-Date

# Get or create folder names for resumability
$folderNames = @()
if (Test-Path -Path $BasePath -PathType Container) {
    $existingFolders = Get-ChildItem -Path $BasePath -Directory | ForEach-Object { $_.Name }
    $folderNames += $existingFolders
}
while ($folderNames.Count -lt $FolderCount) {
    $newName = Get-RandomString 12
    if ($folderNames -notcontains $newName) {
        $folderNames += $newName
    }
}
$folderNames = $folderNames[0..($FolderCount-1)]

Write-Host "[DEBUG] Folder names to be created: $($folderNames -join ', ')"

$results = foreach ($folderName in $folderNames) {
    & {
        param($folderName)
        function Get-RandomString($length = 10) {
            -join ((65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_})
        }
        # Use variables directly (no $using: needed)
        Write-Host "[DEBUG] Processing folderName: '$folderName'"
        $folderPath = Join-Path -Path $BasePath -ChildPath $folderName

        $null = New-Item -Path $folderPath -ItemType Directory -Force -ErrorAction SilentlyContinue
        if (!(Test-Path -Path $folderPath -PathType Container)) {
            Write-Host "[ERROR] Failed to create folder: $folderPath" -ForegroundColor Red
            return
        } else {
            Write-Host "[DEBUG] Created/ensured folder: $folderPath"
        }

        $existingFiles = @()
        if (Test-Path -Path $folderPath -PathType Container) {
            $existingFiles = Get-ChildItem -Path $folderPath -File | ForEach-Object { $_.Name }
        }
        $filesCreated = $existingFiles.Count
        $bytesWritten = 0
        $errorCount = 0
        for ($j = $filesCreated + 1; $j -le $FilesPerFolder; $j++) {
            $fileName = (Get-RandomString 10) + ".txt"
            while ($existingFiles -contains $fileName) { $fileName = (Get-RandomString 10) + ".txt" }
            $filePath = Join-Path -Path $folderPath -ChildPath $fileName
            $fileSizeKB = Get-Random -Minimum $MinFileSizeKB -Maximum $MaxFileSizeKB
            try {
                $buffer = New-Object byte[] ($fileSizeKB * 1024)
                [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buffer)
                [IO.File]::WriteAllBytes($filePath, $buffer)
                $bytesWritten += ($fileSizeKB * 1024)
            } catch {
                Write-Host ("Error writing ${filePath}: $_") -ForegroundColor Red
                $errorCount++
            }
        }
        Write-Host "[$folderName] Completed: $FilesPerFolder files (added $($FilesPerFolder - $filesCreated)), $([math]::Round($bytesWritten/1MB,2)) MB written. Errors: $errorCount"
        [PSCustomObject]@{Folder=$folderName; Files=$FilesPerFolder; Bytes=$bytesWritten; Errors=$errorCount}
    } $folderName
}

$endTime = Get-Date
$totalFiles = $results.Count * $FilesPerFolder
$totalBytes = ($results | Measure-Object -Property Bytes -Sum).Sum
$totalErrors = ($results | Measure-Object -Property Errors -Sum).Sum
$duration = $endTime - $startTime
Write-Host "\nSummary:"
Write-Host "  Total folders: $FolderCount"
Write-Host "  Total files: $totalFiles"
Write-Host "  Total size: $([math]::Round($totalBytes/1GB,2)) GB ($([math]::Round($totalBytes/1MB,2)) MB)"
Write-Host "  Total errors: $totalErrors"
Write-Host "  Time elapsed: $($duration.ToString())"
Write-Host "Done!"
