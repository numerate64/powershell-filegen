# PowerShell script to generate random folders and files of varying sizes

param(
    [int]$FolderCount = 224,
    [int]$FilesPerFolder = 1000,
    [int]$MinFileSizeKB = 4,      # Minimum file size in KB
    [int]$MaxFileSizeMB = 128     # Maximum file size in MB
)

$BasePath = Join-Path -Path $PSScriptRoot -ChildPath "output"

# Helper function to generate a random string for folder/file names
function Get-RandomString($length = 8) {
    -join ((65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_})
}

# Create base output directory
if (!(Test-Path $BasePath)) {
    New-Item -ItemType Directory -Path $BasePath | Out-Null
}

for ($i = 1; $i -le $FolderCount; $i++) {
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
}

Write-Host "Done! Created $FolderCount folders, each with $FilesPerFolder files of random sizes between $MinFileSizeKB KB and $MaxFileSizeMB MB."
