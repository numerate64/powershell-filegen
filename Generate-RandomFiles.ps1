# PowerShell script to generate random folders and files of varying sizes

param(
    [Parameter(HelpMessage = "Number of folders to create (default: 10)")]
    [int]$FolderCount = 10,
    [Parameter(HelpMessage = "Files per folder (default: 10)")]
    [int]$FilesPerFolder = 10,
    [Parameter(HelpMessage = "Minimum file size in KB (default: 4)")]
    [int]$MinFileSizeKB = 4,
    [Parameter(HelpMessage = "Maximum file size in MB (default: 0.125, i.e., 128KB)")]
    [double]$MaxFileSizeMB = 0.125,
    [Parameter(HelpMessage = "Number of parallel folder jobs (default: 64)")]
    [int]$Parallelism = 64
)

if ($PSBoundParameters.ContainsKey('help') -or $PSBoundParameters.ContainsKey('?')) {
    Write-Host "\nUsage:"
    Write-Host "  ./Generate-RandomFiles.ps1 [-FolderCount <int>] [-FilesPerFolder <int>] [-MinFileSizeKB <int>] [-MaxFileSizeMB <double>] [-Parallelism <int>] [-help|-?]"
    Write-Host "\nParameters:"
    Write-Host "  -FolderCount      Number of folders to create (default: 10)"
    Write-Host "  -FilesPerFolder   Files per folder (default: 10)"
    Write-Host "  -MinFileSizeKB    Minimum file size in KB (default: 4)"
    Write-Host "  -MaxFileSizeMB    Maximum file size in MB (default: 0.125, i.e., 128KB)"
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

if (!(Test-Path $BasePath)) {
    New-Item -ItemType Directory -Path $BasePath | Out-Null
}

Write-Host "Starting (resumable) generation of $FolderCount folders, each with $FilesPerFolder files (sizes: $MinFileSizeKB KB to $MaxFileSizeMB MB) using $Parallelism parallel jobs..."
$startTime = Get-Date

# Get or create folder names for resumability
$folderNames = @()
if (Test-Path $BasePath) {
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

$results = $folderNames | ForEach-Object -Parallel {
    param($folderName)
    function Get-RandomString($length = 10) {
        -join ((65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_})
    }
    $folderPath = Join-Path $using:BasePath $folderName
    if (!(Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
    }
    $existingFiles = @()
    if (Test-Path $folderPath) {
        $existingFiles = Get-ChildItem -Path $folderPath -File | ForEach-Object { $_.Name }
    }
    $filesCreated = $existingFiles.Count
    $bytesWritten = 0
    $errorCount = 0
    for ($j = $filesCreated + 1; $j -le $using:FilesPerFolder; $j++) {
        $fileName = (Get-RandomString 10) + ".txt"
        while ($existingFiles -contains $fileName) { $fileName = (Get-RandomString 10) + ".txt" }
        $filePath = Join-Path $folderPath $fileName
        $fileSizeKB = Get-Random -Minimum $using:MinFileSizeKB -Maximum ($using:MaxFileSizeMB * 1024)
        try {
            $buffer = New-Object byte[] ($fileSizeKB * 1024)
            [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buffer)
            [IO.File]::WriteAllBytes($filePath, $buffer)
            $bytesWritten += ($fileSizeKB * 1024)
        } catch {
            Write-Host "Error writing $filePath: $_" -ForegroundColor Red
            $errorCount++
        }
    }
    Write-Host "[$folderName] Completed: $using:FilesPerFolder files (added $($using:FilesPerFolder - $filesCreated)), $([math]::Round($bytesWritten/1MB,2)) MB written. Errors: $errorCount"
    [PSCustomObject]@{Folder=$folderName; Files=$using:FilesPerFolder; Bytes=$bytesWritten; Errors=$errorCount}
} -ThrottleLimit $Parallelism

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
