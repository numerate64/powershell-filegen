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

1..$FolderCount | ForEach-Object -Parallel {
    param($i, $FilesPerFolder, $MinFileSizeKB, $MaxFileSizeMB, $BasePath)
    function Get-RandomString($length = 8) {
        -join ((65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_})
    }
    $folderName = Get-RandomString 12
    $folderPath = Join-Path $BasePath $folderName
    New-Item -ItemType Directory -Path $folderPath | Out-Null
    Write-Host "Created folder: $folderPath"

    for ($j = 1; $j -le $FilesPerFolder; $j++) {
        $fileName = (Get-RandomString 10) + ".txt"
        $filePath = Join-Path $folderPath $fileName
        $fileSizeKB = Get-Random -Minimum $MinFileSizeKB -Maximum ($MaxFileSizeMB * 1024)
        $buffer = New-Object byte[] ($fileSizeKB * 1024)
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buffer)
        [IO.File]::WriteAllBytes($filePath, $buffer)
    }
    Write-Host "  -> Created $FilesPerFolder files in $folderName"
} -ArgumentList $_, $FilesPerFolder, $MinFileSizeKB, $MaxFileSizeMB, $BasePath -ThrottleLimit $Parallelism

Write-Host "Done! Created $FolderCount folders, each with $FilesPerFolder files of random sizes between $MinFileSizeKB KB and $MaxFileSizeMB MB, using $Parallelism parallel jobs."
