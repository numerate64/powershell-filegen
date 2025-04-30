# PowerShell script to generate random folders and files of varying sizes

param(
    [int]$FolderCount = 224,
    [int]$FilesPerFolder = 1000,
    [int]$MinFileSizeKB = 4,      # Minimum file size in KB
    [int]$MaxFileSizeMB = 128,    # Maximum file size in MB
    [int]$Parallelism = 8         # Number of parallel folder jobs
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "This script requires PowerShell 7.0 or later for parallel processing."
    exit 1
}

$BasePath = Join-Path -Path $PSScriptRoot -ChildPath "output"

function Get-RandomString($length = 8) {
    -join ((65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_})
}

if (!(Test-Path $BasePath)) {
    New-Item -ItemType Directory -Path $BasePath | Out-Null
}

Write-Host "Starting generation of $FolderCount folders, each with $FilesPerFolder files (sizes: $MinFileSizeKB KB to $MaxFileSizeMB MB) using $Parallelism parallel jobs..."
$startTime = Get-Date

$indices = 1..$FolderCount
$results = $indices | ForEach-Object -Parallel {
    param($i)
    function Get-RandomString($length = 8) {
        -join ((65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_})
    }
    $folderName = Get-RandomString 12
    $folderPath = Join-Path $using:BasePath $folderName
    New-Item -ItemType Directory -Path $folderPath | Out-Null
    $filesCreated = 0
    $bytesWritten = 0

    for ($j = 1; $j -le $using:FilesPerFolder; $j++) {
        $fileName = (Get-RandomString 10) + ".txt"
        $filePath = Join-Path $folderPath $fileName
        $fileSizeKB = Get-Random -Minimum $using:MinFileSizeKB -Maximum ($using:MaxFileSizeMB * 1024)
        $buffer = New-Object byte[] ($fileSizeKB * 1024)
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buffer)
        [IO.File]::WriteAllBytes($filePath, $buffer)
        $filesCreated++
        $bytesWritten += ($fileSizeKB * 1024)
        if ($j % 100 -eq 0) {
            Write-Host "[$folderName] $filesCreated/$using:FilesPerFolder files created..."
        }
    }
    Write-Host "[$folderName] Completed: $filesCreated files, $([math]::Round($bytesWritten/1MB,2)) MB written."
    [PSCustomObject]@{Folder=$folderName; Files=$filesCreated; Bytes=$bytesWritten}
} -ThrottleLimit $Parallelism

$endTime = Get-Date
$totalFiles = ($results | Measure-Object -Property Files -Sum).Sum
$totalBytes = ($results | Measure-Object -Property Bytes -Sum).Sum
$duration = $endTime - $startTime
Write-Host "\nSummary:"
Write-Host "  Total folders: $FolderCount"
Write-Host "  Total files: $totalFiles"
Write-Host "  Total size: $([math]::Round($totalBytes/1GB,2)) GB ($([math]::Round($totalBytes/1MB,2)) MB)"
Write-Host "  Time elapsed: $($duration.ToString())"
Write-Host "Done!"
