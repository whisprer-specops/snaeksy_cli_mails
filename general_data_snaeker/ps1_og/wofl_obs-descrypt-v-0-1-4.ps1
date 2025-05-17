<#
.SYNOPSIS
    A versatile tool for encrypting and obfuscating files and folders with secure deletion capabilities.
    
.DESCRIPTION
    This script provides functionality to encrypt, obfuscate, and decrypt files and folders.
    It uses PowerShell's secure string capabilities to protect file contents and includes
    military-grade multi-pass secure deletion for original files and cleanup of empty folders.
    
.PARAMETER Mode
    The operation mode: Encrypt, Decrypt, or ListEncrypted.
    
.PARAMETER Path
    Path to the file or folder to process.
    
.PARAMETER OutputPath
    Optional. Path where the encrypted/decrypted files will be saved.
    If not specified, outputs to the same directory with .enc.xml or .dec extension.
    
.PARAMETER Recursive
    Process all files in subfolders recursively when Path is a folder.
    
.PARAMETER Force
    Overwrite existing output files without prompting.
    
.PARAMETER SecureDelete
    Securely delete original files after successful encryption/decryption.
    Uses DOD-compliant multi-pass overwrite before deletion.
    
.PARAMETER ShredPasses
    Number of overwrite passes to use when securely deleting files.
    Default is 3 passes (zeros, ones, and random data).
    
.PARAMETER CleanEmptyFolders
    Remove empty folders after file processing when using SecureDelete.
    Only removes folders that become empty due to the secure deletion process.
    
.EXAMPLE
    .\wofl_obs-descrypt-v-0-1-3.ps1 -Mode Encrypt -Path "C:\path\to\file.txt"
    
.EXAMPLE
    .\wofl_obs-descrypt-v-0-1-3.ps1 -Mode Encrypt -Path "C:\path\to\folder" -Recursive -OutputPath "C:\encrypted"
    
.EXAMPLE
    .\wofl_obs-descrypt-v-0-1-3.ps1 -Mode Decrypt -Path "C:\path\to\file.enc.xml" -OutputPath "C:\decrypted\file.txt"
    
.EXAMPLE
    .\wofl_obs-descrypt-v-0-1-3.ps1 -Mode ListEncrypted -Path "C:\encrypted"

.EXAMPLE
    .\wofl_obs-descrypt-v-0-1-3.ps1 -Mode Encrypt -Path "C:\secret_files" -Recursive -SecureDelete -ShredPasses 7
    # Encrypts all files and securely wipes originals with 7 passes
    
.EXAMPLE
    .\wofl_obs-descrypt-v-0-1-3.ps1 -Mode Encrypt -Path "C:\secret_files" -Recursive -SecureDelete -CleanEmptyFolders
    # Encrypts all files, securely wipes originals, and removes empty folders
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Encrypt", "Decrypt", "ListEncrypted")]
    [string]$Mode,
    
    [Parameter(Mandatory=$true)]
    [string]$Path,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Recursive,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [switch]$SecureDelete,
    
    [Parameter(Mandatory=$false)]
    [int]$ShredPasses = 3,
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanEmptyFolders
)

# Function to create directory if it doesn't exist
function Ensure-Directory {
    param ([string]$DirectoryPath)
    
    if (-not (Test-Path $DirectoryPath)) {
        New-Item -Path $DirectoryPath -ItemType Directory -Force | Out-Null
        Write-Verbose "Created directory: $DirectoryPath"
    }
}

# Function to securely delete a file
function Secure-Delete {
    param (
        [string]$FilePath,
        [int]$Passes = 3
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            Write-Verbose "Warning: File '$FilePath' not found for secure deletion."
            return $false
        }
        
        $fileInfo = New-Object System.IO.FileInfo($FilePath)
        $fileLength = $fileInfo.Length
        
        if ($fileLength -eq 0) {
            Remove-Item -Path $FilePath -Force
            Write-Verbose "Securely deleted empty file '$FilePath'"
            return $true
        }
        
        Write-Verbose "Securely deleting file '$FilePath' with $Passes passes..."
        
        $fileStream = New-Object System.IO.FileStream($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write)
        $buffer = New-Object byte[] 8192
        $random = New-Object System.Random
        
        for ($pass = 1; $pass -le $Passes; $pass++) {
            Write-Progress -Activity "Secure File Deletion" -Status "Pass $pass of $Passes" -PercentComplete (($pass - 1) / $Passes * 100)
            $fileStream.Position = 0
            $fullBuffers = [Math]::Floor($fileLength / $buffer.Length)
            $remainder = $fileLength % $buffer.Length
            
            $pattern = switch ($pass % 3) {
                0 { 0x00 }
                1 { 0xFF }
                2 { $null }
            }
            
            if ($pattern -ne $null) {
                for ($i = 0; $i -lt $buffer.Length; $i++) {
                    $buffer[$i] = $pattern
                }
            }
            
            for ($i = 0; $i -lt $fullBuffers; $i++) {
                if ($pattern -eq $null) {
                    $random.NextBytes($buffer)
                }
                $fileStream.Write($buffer, 0, $buffer.Length)
            }
            
            if ($remainder -gt 0) {
                if ($pattern -eq $null) {
                    $random.NextBytes($buffer)
                }
                $fileStream.Write($buffer, 0, $remainder)
            }
            
            $fileStream.Flush()
        }
        
        $fileStream.Close()
        $fileStream.Dispose()
        Remove-Item -Path $FilePath -Force
        
        Write-Verbose "Successfully securely deleted '$FilePath'"
        return $true
    }
    catch {
        Write-Warning "Failed to securely delete file '$FilePath': $_"
        return $false
    }
    finally {
        Write-Progress -Activity "Secure File Deletion" -Completed
    }
}

# Function to clean up empty directories
function Clean-EmptyDirectories {
    param (
        [string]$DirectoryPath,
        [bool]$Recursive = $true
    )
    
    try {
        if (-not (Test-Path $DirectoryPath)) {
            Write-Verbose "Warning: Directory '$DirectoryPath' not found for cleanup."
            return 0
        }
        
        $deletedFolders = 0
        
        if ($Recursive) {
            $subDirectories = Get-ChildItem -Path $DirectoryPath -Directory -Recurse | Sort-Object -Property FullName -Descending
            foreach ($dir in $subDirectories) {
                $isEmpty = (-not (Get-ChildItem -Path $dir.FullName -File)) -and (-not (Get-ChildItem -Path $dir.FullName -Directory))
                if ($isEmpty) {
                    Write-Verbose "Removing empty directory: $($dir.FullName)"
                    Remove-Item -Path $dir.FullName -Force
                    $deletedFolders++
                }
            }
        }
        
        $isEmpty = (-not (Get-ChildItem -Path $DirectoryPath -File)) -and (-not (Get-ChildItem -Path $DirectoryPath -Directory))
        if ($isEmpty) {
            Write-Verbose "Removing empty root directory: $DirectoryPath"
            Remove-Item -Path $DirectoryPath -Force
            $deletedFolders++
        }
        
        return $deletedFolders
    }
    catch {
        Write-Warning "Error cleaning up empty directories: $_"
        return 0
    }
}

# Function to encrypt a single file
function Encrypt-File {
    param (
        [string]$FilePath,
        [string]$OutputFilePath,
        [bool]$PerformSecureDelete = $false,
        [int]$ShredPasses = 3
    )
    
    try {
        $fileContent = Get-Content $FilePath -Raw -ErrorAction Stop
        ConvertTo-SecureString -String $fileContent -AsPlainText -Force | Export-Clixml -Path $OutputFilePath -Force
        Write-Verbose "Encrypted '$FilePath' to '$OutputFilePath'"
        
        if ($PerformSecureDelete) {
            if (Secure-Delete -FilePath $FilePath -Passes $ShredPasses) {
                Write-Verbose "Original file securely deleted after encryption."
            }
            else {
                Write-Warning "Failed to securely delete original file after encryption."
            }
        }
        
        return $true
    }
    catch {
        Write-Warning "Failed to encrypt file '$FilePath': $_"
        return $false
    }
}

# Function to decrypt a single file
function Decrypt-File {
    param (
        [string]$FilePath,
        [string]$OutputFilePath,
        [bool]$PerformSecureDelete = $false,
        [int]$ShredPasses = 3
    )
    
    try {
        $secureString = Import-Clixml -Path $FilePath -ErrorAction Stop
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        $decryptedContent = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        
        [System.IO.File]::WriteAllText($OutputFilePath, $decryptedContent)
        Write-Verbose "Decrypted '$FilePath' to '$OutputFilePath'"
        
        if ($PerformSecureDelete) {
            if (Secure-Delete -FilePath $FilePath -Passes $ShredPasses) {
                Write-Verbose "Encrypted file securely deleted after decryption."
            }
            else {
                Write-Warning "Failed to securely delete encrypted file after decryption."
            }
        }
        
        return $true
    }
    catch {
        Write-Warning "Failed to decrypt file '$FilePath': $_"
        return $false
    }
}

# Build an output file path
function Build-OutputPath {
    param (
        [string]$InputPath,
        [string]$BaseOutputPath,
        [string]$Operation
    )
    
    $fileName = [System.IO.Path]::GetFileName($InputPath)
    $directoryName = [System.IO.Path]::GetDirectoryName($InputPath)
    
    if ([string]::IsNullOrEmpty($BaseOutputPath)) {
        if ($Operation -eq "Encrypt") {
            return [System.IO.Path]::Combine($directoryName, "$fileName.enc.xml")
        }
        else {
            $baseName = $fileName -replace "\.enc\.xml$", ""
            if ($baseName -eq $fileName) {
                return [System.IO.Path]::Combine($directoryName, "$baseName.dec")
            }
            else {
                return [System.IO.Path]::Combine($directoryName, $baseName)
            }
        }
    }
    else {
        if (Test-Path -Path $BaseOutputPath -PathType Container) {
            if ($Operation -eq "Encrypt") {
                return [System.IO.Path]::Combine($BaseOutputPath, "$fileName.enc.xml")
            }
            else {
                $baseName = $fileName -replace "\.enc\.xml$", ""
                if ($baseName -eq $fileName) {
                    return [System.IO.Path]::Combine($BaseOutputPath, "$baseName.dec")
                }
                else {
                    return [System.IO.Path]::Combine($BaseOutputPath, $baseName)
                }
            }
        }
        else {
            return $BaseOutputPath
        }
    }
}

# Build relative output path for recursive processing
function Build-RelativeOutputPath {
    param (
        [string]$InputPath,
        [string]$BasePath,
        [string]$BaseOutputPath,
        [string]$Operation
    )
    
    $relativePath = $InputPath.Substring($BasePath.Length).TrimStart('\', '/')
    
    if ($Operation -eq "Encrypt") {
        $outputFilePath = [System.IO.Path]::Combine($BaseOutputPath, "$relativePath.enc.xml")
    }
    else {
        $relativePath = $relativePath -replace "\.enc\.xml$", ""
        if ($relativePath -eq $InputPath.Substring($BasePath.Length).TrimStart('\', '/')) {
            $outputFilePath = [System.IO.Path]::Combine($BaseOutputPath, "$relativePath.dec")
        }
        else {
            $outputFilePath = [System.IO.Path]::Combine($BaseOutputPath, $relativePath)
        }
    }
    
    return $outputFilePath
}

# List encrypted files
function List-EncryptedFiles {
    param (
        [string]$DirectoryPath,
        [bool]$ProcessRecursively
    )
    
    $searchOption = if ($ProcessRecursively) { "AllDirectories" } else { "TopDirectoryOnly" }
    $files = [System.IO.Directory]::GetFiles($DirectoryPath, "*.enc.xml", [System.IO.SearchOption]::$searchOption)
    
    Write-Host "Found $($files.Count) encrypted files in $DirectoryPath" -ForegroundColor Cyan
    foreach ($file in $files) {
        $relativePath = $file.Substring($DirectoryPath.Length).TrimStart('\', '/')
        Write-Host $relativePath -ForegroundColor Green
    }
}

# Process a directory
function Process-Directory {
    param (
        [string]$DirectoryPath,
        [string]$OutputDirectoryPath,
        [string]$Operation,
        [bool]$ProcessRecursively,
        [bool]$PerformSecureDelete = $false,
        [int]$ShredPasses = 3,
        [bool]$CleanEmptyFolders = $false
    )
    
    # Normalize directory path
    $DirectoryPath = [System.IO.Path]::GetFullPath($DirectoryPath).TrimEnd('\', '/')
    Write-Verbose "Processing directory: '$DirectoryPath'"
    
    $searchOption = if ($ProcessRecursively) { "AllDirectories" } else { "TopDirectoryOnly" }
    try {
        $files = [System.IO.Directory]::GetFiles($DirectoryPath, "*", [System.IO.SearchOption]::$searchOption)
    }
    catch {
        Write-Warning "Failed to access directory '$DirectoryPath': $_"
        return
    }
    
    $totalFiles = $files.Count
    $successCount = 0
    $failureCount = 0
    
    Write-Verbose "Processing $totalFiles files in $DirectoryPath..."
    
    foreach ($file in $files) {
        $relativePath = $file.Substring($DirectoryPath.Length).TrimStart('\', '/')
        $outputFilePath = Build-RelativeOutputPath -InputPath $file -BasePath $DirectoryPath -BaseOutputPath $OutputDirectoryPath -Operation $Operation
        
        $outputDirectory = [System.IO.Path]::GetDirectoryName($outputFilePath)
        Ensure-Directory -DirectoryPath $outputDirectory
        
        if ($Operation -eq "Encrypt" -and -not $file.EndsWith(".enc.xml")) {
            if ($Force -or (-not (Test-Path $outputFilePath) -or (Get-OverwriteConfirmation -FilePath $outputFilePath -ConfirmAll ([ref]$confirmAllOverwrite)))) {
                $success = Encrypt-File -FilePath $file -OutputFilePath $outputFilePath -PerformSecureDelete $PerformSecureDelete -ShredPasses $ShredPasses
                if ($success) { $successCount++ } else { $failureCount++ }
            }
            else {
                Write-Verbose "Skipped '$file' (output file exists)"
            }
        }
        elseif ($Operation -eq "Decrypt" -and $file.EndsWith(".enc.xml")) {
            if ($Force -or (-not (Test-Path $outputFilePath) -or (Get-OverwriteConfirmation -FilePath $outputFilePath -ConfirmAll ([ref]$confirmAllOverwrite)))) {
                $success = Decrypt-File -FilePath $file -OutputFilePath $outputFilePath -PerformSecureDelete $PerformSecureDelete -ShredPasses $ShredPasses
                if ($success) { $successCount++ } else { $failureCount++ }
            }
            else {
                Write-Verbose "Skipped '$file' (output file exists)"
            }
        }
        else {
            Write-Verbose "Skipped '$file' (not applicable for $Operation)"
        }
    }
    
    if ($CleanEmptyFolders -and $PerformSecureDelete) {
        Write-Verbose "Cleaning up empty directories..."
        $deletedFolders = Clean-EmptyDirectories -DirectoryPath $DirectoryPath -Recursive $ProcessRecursively
        Write-Verbose "Removed $deletedFolders empty directories."
    }
    
    Write-Host "Directory processing complete." -ForegroundColor Cyan
    Write-Host "Total files: $totalFiles" -ForegroundColor White
    Write-Host "Successfully processed: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failureCount" -ForegroundColor Red
    Write-Host "Skipped: $($totalFiles - $successCount - $failureCount)" -ForegroundColor Yellow
}

# Confirm secure deletion
function Confirm-SecureDeletion {
    param (
        [string]$Path,
        [bool]$IsDirectory = $false,
        [bool]$IncludeEmptyFolders = $false
    )
    
    $descriptor = if ($IsDirectory) { "all files in directory" } else { "file" }
    $folderNote = if ($IncludeEmptyFolders) { " Empty folders will also be deleted after processing." } else { "" }
    $message = "WARNING: You are about to SECURELY DELETE the original $descriptor after processing.`nThis operation CANNOT be undone!$folderNote`n`nAre you sure you want to proceed? (Y/N): "
    
    $response = Read-Host -Prompt $message
    return $response.ToUpper() -eq 'Y'
}

# Get overwrite confirmation
function Get-OverwriteConfirmation {
    param (
        [string]$FilePath,
        [ref]$ConfirmAll
    )
    
    if ($ConfirmAll.Value) {
        return $true
    }
    
    $response = Read-Host "File '$FilePath' already exists. Overwrite? (Y/N/All - Y to overwrite this file, N to skip, All to overwrite all)"
    $upperResponse = $response.ToUpper()
    
    if ($upperResponse -eq "ALL") {
        $ConfirmAll.Value = $true
        return $true
    }
    elseif ($upperResponse -eq "Y") {
        return $true
    }
    else {
        return $false
    }
}

# Main script logic
$confirmAllOverwrite = $false
try {
    # Normalize path to remove trailing backslashes and ensure consistency
    $Path = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    Write-Verbose "Normalized Path: '$Path'"

    # Verify path exists
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Path '$Path' does not exist or is inaccessible."
        exit 1
    }
    
    # Verify path is a directory for Recursive mode
    if ($Recursive -and -not (Test-Path -Path $Path -PathType Container)) {
        Write-Error "Path '$Path' must be a directory when using -Recursive."
        exit 1
    }

    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = [System.IO.Path]::GetFullPath($OutputPath).TrimEnd('\', '/')
        Write-Verbose "Normalized OutputPath: '$OutputPath'"
        $pathIsDirectory = Test-Path -Path $Path -PathType Container
        if ($Mode -ne "ListEncrypted" -and $pathIsDirectory) {
            Ensure-Directory -DirectoryPath $OutputPath
        }
        elseif (-not $pathIsDirectory) {
            Ensure-Directory -DirectoryPath ([System.IO.Path]::GetDirectoryName($OutputPath))
        }
    }
    
    $performSecureDelete = $false
    if ($SecureDelete -and ($Mode -eq "Encrypt" -or $Mode -eq "Decrypt")) {
        $isDirectory = Test-Path -Path $Path -PathType Container
        $performSecureDelete = Confirm-SecureDeletion -Path $Path -IsDirectory $isDirectory -IncludeEmptyFolders $CleanEmptyFolders
        if (-not $performSecureDelete) {
            Write-Warning "Secure deletion cancelled. Continuing without deleting original files."
            $CleanEmptyFolders = $false
        }
        else {
            Write-Host "Secure deletion confirmed. Original files will be securely deleted after processing." -ForegroundColor Red
            Write-Verbose "Files will be overwritten with $ShredPasses passes using zeros, ones, and random data."
            if ($CleanEmptyFolders) {
                Write-Verbose "Empty folders will be removed after processing."
            }
        }
    }
    
    switch ($Mode) {
        "Encrypt" {
            if (Test-Path -Path $Path -PathType Container) {
                $outputDir = if ([string]::IsNullOrEmpty($OutputPath)) { $Path } else { $OutputPath }
                Process-Directory -DirectoryPath $Path -OutputDirectoryPath $outputDir -Operation "Encrypt" -ProcessRecursively $Recursive -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses -CleanEmptyFolders $CleanEmptyFolders
            }
            else {
                $outputFilePath = Build-OutputPath -InputPath $Path -BaseOutputPath $OutputPath -Operation "Encrypt"
                Ensure-Directory -DirectoryPath ([System.IO.Path]::GetDirectoryName($outputFilePath))
                if ($Force -or (-not (Test-Path $outputFilePath) -or (Get-OverwriteConfirmation -FilePath $outputFilePath -ConfirmAll ([ref]$confirmAllOverwrite)))) {
                    Encrypt-File -FilePath $Path -OutputFilePath $outputFilePath -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses
                }
                else {
                    Write-Warning "Operation cancelled for '$Path'."
                }
            }
        }
        "Decrypt" {
            if (Test-Path -Path $Path -PathType Container) {
                $outputDir = if ([string]::IsNullOrEmpty($OutputPath)) { $Path } else { $OutputPath }
                Process-Directory -DirectoryPath $Path -OutputDirectoryPath $outputDir -Operation "Decrypt" -ProcessRecursively $Recursive -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses -CleanEmptyFolders $CleanEmptyFolders
            }
            else {
                $outputFilePath = Build-OutputPath -InputPath $Path -BaseOutputPath $OutputPath -Operation "Decrypt"
                Ensure-Directory -DirectoryPath ([System.IO.Path]::GetDirectoryName($outputFilePath))
                if ($Force -or (-not (Test-Path $outputFilePath) -or (Get-OverwriteConfirmation -FilePath $outputFilePath -ConfirmAll ([ref]$confirmAllOverwrite)))) {
                    $success = Decrypt-File -FilePath $Path -OutputFilePath $outputFilePath -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses
                    if (-not $success) {
                        Write-Warning "Failed to decrypt '$Path'."
                    }
                }
                else {
                    Write-Warning "Operation cancelled for '$Path'."
                }
            }
        }
        "ListEncrypted" {
            if (Test-Path -Path $Path -PathType Container) {
                List-EncryptedFiles -DirectoryPath $Path -ProcessRecursively $Recursive
            }
            else {
                Write-Error "Path must be a directory when using ListEncrypted mode."
                exit 1
            }
        }
    }
    
    exit 0
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}