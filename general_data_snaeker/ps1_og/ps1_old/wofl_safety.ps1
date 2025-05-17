<#
.SYNOPSIS
    A versatile tool for encrypting and obfuscating files and folders.
    
.DESCRIPTION
    This script provides functionality to encrypt, obfuscate, and decrypt files and folders.
    It uses PowerShell's secure string capabilities to protect file contents.
    
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
    
.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\path\to\file.txt"
    
.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\path\to\folder" -Recursive -OutputPath "C:\encrypted"
    
.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode Decrypt -Path "C:\path\to\file.enc.xml" -OutputPath "C:\decrypted\file.txt"
    
.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode ListEncrypted -Path "C:\encrypted"
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Encrypt", "Decrypt", "ListEncrypted")]
    [string]$Mode,
    
    [Parameter(Mandatory=$true)]
    [string]$Path,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Recursive = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

# Function to create directory if it doesn't exist
function Ensure-Directory {
    param ([string]$DirectoryPath)
    
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        New-Item -Path $DirectoryPath -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $DirectoryPath"
    }
}

# Function to encrypt a single file
function Encrypt-File {
    param (
        [string]$FilePath,
        [string]$OutputFilePath
    )
    
    try {
        $fileContent = Get-Content $FilePath -Raw -ErrorAction Stop
        ConvertTo-SecureString -String $fileContent -AsPlainText -Force | Export-Clixml -Path $OutputFilePath -Force
        Write-Host "Encrypted '$FilePath' to '$OutputFilePath'" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to encrypt file '$FilePath': $_" -ForegroundColor Red
        return $false
    }
}

# Function to decrypt a single file
function Decrypt-File {
    param (
        [string]$FilePath,
        [string]$OutputFilePath
    )
    
    try {
        $secureString = Import-Clixml -Path $FilePath -ErrorAction Stop
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        $decryptedContent = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        
        [System.IO.File]::WriteAllText($OutputFilePath, $decryptedContent)
        Write-Host "Decrypted '$FilePath' to '$OutputFilePath'" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to decrypt file '$FilePath': $_" -ForegroundColor Red
        return $false
    }
}

# Build an output file path (used for both encryption and decryption)
function Build-OutputPath {
    param (
        [string]$InputPath,
        [string]$BaseOutputPath,
        [string]$Operation
    )
    
    $fileName = [System.IO.Path]::GetFileName($InputPath)
    $directoryName = [System.IO.Path]::GetDirectoryName($InputPath)
    
    if ([string]::IsNullOrEmpty($BaseOutputPath)) {
        # Use the original directory if no output path specified
        if ($Operation -eq "Encrypt") {
            return [System.IO.Path]::Combine($directoryName, "$fileName.enc.xml")
        }
        else {
            # For decryption, remove .enc.xml extension
            $baseName = $fileName -replace "\.enc\.xml$", ""
            # If the original file had no extension, use .dec
            if ($baseName -eq $fileName) {
                return [System.IO.Path]::Combine($directoryName, "$baseName.dec")
            }
            else {
                return [System.IO.Path]::Combine($directoryName, $baseName)
            }
        }
    }
    else {
        # Check if the output path is a directory
        if (Test-Path -Path $BaseOutputPath -PathType Container) {
            if ($Operation -eq "Encrypt") {
                return [System.IO.Path]::Combine($BaseOutputPath, "$fileName.enc.xml")
            }
            else {
                # For decryption, remove .enc.xml extension
                $baseName = $fileName -replace "\.enc\.xml$", ""
                # If the original file had no extension, use .dec
                if ($baseName -eq $fileName) {
                    return [System.IO.Path]::Combine($BaseOutputPath, "$baseName.dec")
                }
                else {
                    return [System.IO.Path]::Combine($BaseOutputPath, $baseName)
                }
            }
        }
        else {
            # Assume the output path is a full file path
            return $BaseOutputPath
        }
    }
}

# Build relative output path for recursive directory processing
function Build-RelativeOutputPath {
    param (
        [string]$InputPath,
        [string]$BasePath,
        [string]$BaseOutputPath,
        [string]$Operation
    )
    
    # Get the relative path of input file to base directory
    $relativePath = $InputPath.Substring($BasePath.Length).TrimStart('\', '/')
    
    if ($Operation -eq "Encrypt") {
        $outputFilePath = [System.IO.Path]::Combine($BaseOutputPath, "$relativePath.enc.xml")
    }
    else {
        # For decryption, remove .enc.xml extension
        $relativePath = $relativePath -replace "\.enc\.xml$", ""
        if ($relativePath -eq $InputPath.Substring($BasePath.Length).TrimStart('\', '/')) {
            # If extension wasn't removed, add .dec
            $outputFilePath = [System.IO.Path]::Combine($BaseOutputPath, "$relativePath.dec")
        }
        else {
            $outputFilePath = [System.IO.Path]::Combine($BaseOutputPath, $relativePath)
        }
    }
    
    return $outputFilePath
}

# Process a directory recursively
function Process-Directory {
    param (
        [string]$DirectoryPath,
        [string]$OutputDirectoryPath,
        [string]$Operation,
        [bool]$ProcessRecursively
    )
    
    $searchOption = if ($ProcessRecursively) { "AllDirectories" } else { "TopDirectoryOnly" }
    $files = [System.IO.Directory]::GetFiles($DirectoryPath, "*", [System.IO.SearchOption]::$searchOption)
    
    $totalFiles = $files.Count
    $successCount = 0
    $failureCount = 0
    
    Write-Host "Processing $totalFiles files in $DirectoryPath..." -ForegroundColor Cyan
    
    foreach ($file in $files) {
        $relativePath = $file.Substring($DirectoryPath.Length).TrimStart('\', '/')
        $relativeDirectory = [System.IO.Path]::GetDirectoryName($relativePath)
        
        # Determine output file path
        if ($Operation -eq "Encrypt") {
            if (-not $file.EndsWith(".enc.xml")) {
                $outputFilePath = Build-RelativeOutputPath -InputPath $file -BasePath $DirectoryPath -BaseOutputPath $OutputDirectoryPath -Operation $Operation
                
                # Ensure the output directory exists
                $outputDirectory = [System.IO.Path]::GetDirectoryName($outputFilePath)
                Ensure-Directory -DirectoryPath $outputDirectory
                
                # Process the file
                if (($Force) -or (-not (Test-Path $outputFilePath)) -or 
                    ((Test-Path $outputFilePath) -and (Read-Host "File '$outputFilePath' already exists. Overwrite? (Y/N)").ToUpper() -eq 'Y')) {
                    
                    $success = Encrypt-File -FilePath $file -OutputFilePath $outputFilePath
                    if ($success) { $successCount++ } else { $failureCount++ }
                }
                else {
                    Write-Host "Skipped '$file' (output file exists)" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "Skipped '$file' (already encrypted)" -ForegroundColor Yellow
            }
        }
        elseif ($Operation -eq "Decrypt") {
            if ($file.EndsWith(".enc.xml")) {
                $outputFilePath = Build-RelativeOutputPath -InputPath $file -BasePath $DirectoryPath -BaseOutputPath $OutputDirectoryPath -Operation $Operation
                
                # Ensure the output directory exists
                $outputDirectory = [System.IO.Path]::GetDirectoryName($outputFilePath)
                Ensure-Directory -DirectoryPath $outputDirectory
                
                # Process the file
                if (($Force) -or (-not (Test-Path $outputFilePath)) -or 
                    ((Test-Path $outputFilePath) -and (Read-Host "File '$outputFilePath' already exists. Overwrite? (Y/N)").ToUpper() -eq 'Y')) {
                    
                    $success = Decrypt-File -FilePath $file -OutputFilePath $outputFilePath
                    if ($success) { $successCount++ } else { $failureCount++ }
                }
                else {
                    Write-Host "Skipped '$file' (output file exists)" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "Skipped '$file' (not an encrypted file)" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "`nDirectory processing complete." -ForegroundColor Cyan
    Write-Host "Total files: $totalFiles" -ForegroundColor White
    Write-Host "Successfully processed: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failureCount" -ForegroundColor Red
    Write-Host "Skipped: $($totalFiles - $successCount - $failureCount)" -ForegroundColor Yellow
}

# Lists all encrypted files in a directory
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

# Main script logic
try {
    # Check if Path exists
    if (-not (Test-Path -Path $Path)) {
        Write-Host "Error: Path '$Path' does not exist." -ForegroundColor Red
        exit 1
    }
    
    # If output path is specified, ensure it exists
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $pathIsDirectory = Test-Path -Path $Path -PathType Container
        $outputPathIsDirectory = Test-Path -Path $OutputPath -PathType Container
        
        # For ListEncrypted, output path is not used
        if ($Mode -ne "ListEncrypted") {
            if (-not $pathIsDirectory -and -not (Test-Path -Path ([System.IO.Path]::GetDirectoryName($OutputPath)))) {
                Ensure-Directory -DirectoryPath ([System.IO.Path]::GetDirectoryName($OutputPath))
            }
            elseif ($pathIsDirectory -and -not $outputPathIsDirectory) {
                Ensure-Directory -DirectoryPath $OutputPath
            }
        }
    }
    
    # Process based on mode
    switch ($Mode) {
        "Encrypt" {
            if (Test-Path -Path $Path -PathType Container) {
                # Process a directory
                $outputDir = if ([string]::IsNullOrEmpty($OutputPath)) { $Path } else { $OutputPath }
                Process-Directory -DirectoryPath $Path -OutputDirectoryPath $outputDir -Operation "Encrypt" -ProcessRecursively $Recursive
            }
            else {
                # Process a single file
                $outputFilePath = Build-OutputPath -InputPath $Path -BaseOutputPath $OutputPath -Operation "Encrypt"
                
                if (($Force) -or (-not (Test-Path $outputFilePath)) -or 
                    ((Test-Path $outputFilePath) -and (Read-Host "File '$outputFilePath' already exists. Overwrite? (Y/N)").ToUpper() -eq 'Y')) {
                    
                    Encrypt-File -FilePath $Path -OutputFilePath $outputFilePath | Out-Null
                }
                else {
                    Write-Host "Operation cancelled." -ForegroundColor Yellow
                }
            }
        }
        "Decrypt" {
            if (Test-Path -Path $Path -PathType Container) {
                # Process a directory
                $outputDir = if ([string]::IsNullOrEmpty($OutputPath)) { $Path } else { $OutputPath }
                Process-Directory -DirectoryPath $Path -OutputDirectoryPath $outputDir -Operation "Decrypt" -ProcessRecursively $Recursive
            }
            else {
                # Process a single file
                $outputFilePath = Build-OutputPath -InputPath $Path -BaseOutputPath $OutputPath -Operation "Decrypt"
                
                if (($Force) -or (-not (Test-Path $outputFilePath)) -or 
                    ((Test-Path $outputFilePath) -and (Read-Host "File '$outputFilePath' already exists. Overwrite? (Y/N)").ToUpper() -eq 'Y')) {
                    
                    Decrypt-File -FilePath $Path -OutputFilePath $outputFilePath | Out-Null
                }
                else {
                    Write-Host "Operation cancelled." -ForegroundColor Yellow
                }
            }
        }
        "ListEncrypted" {
            if (Test-Path -Path $Path -PathType Container) {
                List-EncryptedFiles -DirectoryPath $Path -ProcessRecursively $Recursive
            }
            else {
                Write-Host "Error: Path must be a directory when using ListEncrypted mode." -ForegroundColor Red
                exit 1
            }
        }
    }
    
    exit 0
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    exit 1
}
