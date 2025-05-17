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
    
.PARAMETER SecureDelete
    Securely delete original files after successful encryption/decryption.
    Uses DOD-compliant multi-pass overwrite before deletion.
    
.PARAMETER ShredPasses
    Number of overwrite passes to use when securely deleting files.
    Default is 3 passes (zeros, ones, and random data).
    
.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\path\to\file.txt"
    
.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\path\to\folder" -Recursive -OutputPath "C:\encrypted"
    
.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode Decrypt -Path "C:\path\to\file.enc
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
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SecureDelete = $false,
    
    [Parameter(Mandatory=$false)]
    [int]$ShredPasses = 3,
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanEmptyFolders = $false
)

# Function to create directory if it doesn't exist
function Ensure-Directory {
    param ([string]$DirectoryPath)
    
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        New-Item -Path $DirectoryPath -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $DirectoryPath"
    }
}

# Function to securely delete a file
function Secure-Delete {
    param (
        [string]$FilePath,
        [int]$Passes = 3
    )
    
    try {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Host "Warning: File '$FilePath' not found for secure deletion." -ForegroundColor Yellow
            return $false
        }
        
        $fileInfo = New-Object System.IO.FileInfo($FilePath)
        $fileLength = $fileInfo.Length
        
        if ($fileLength -eq 0) {
            # For empty files, just delete them
            Remove-Item -Path $FilePath -Force
            Write-Host "Securely deleted empty file '$FilePath'" -ForegroundColor Green
            return $true
        }
        
        Write-Host "Securely deleting file '$FilePath' with $Passes passes..." -ForegroundColor Yellow
        
        # Open the file with write access
        $fileStream = New-Object System.IO.FileStream($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write)
        $buffer = New-Object byte[] 8192  # 8KB buffer for efficiency
        
        # Generate a random number generator
        $random = New-Object System.Random
        
        for ($pass = 1; $pass -le $Passes; $pass++) {
            Write-Progress -Activity "Secure File Deletion" -Status "Pass $pass of $Passes" -PercentComplete (($pass - 1) / $Passes * 100)
            
            # Move to the beginning of the file
            $fileStream.Position = 0
            
            # Calculate how many full buffers we need
            $fullBuffers = [Math]::Floor($fileLength / $buffer.Length)
            $remainder = $fileLength % $buffer.Length
            
            # Write pattern based on the pass number
            $pattern = switch ($pass % 3) {
                0 { 0x00 }  # Zeros
                1 { 0xFF }  # Ones
                2 { $null } # Random - will be filled in the loop
            }
            
            if ($pattern -ne $null) {
                # Fill the buffer with the pattern
                for ($i = 0; $i -lt $buffer.Length; $i++) {
                    $buffer[$i] = $pattern
                }
            }
            
            # Write full buffers
            for ($i = 0; $i -lt $fullBuffers; $i++) {
                if ($pattern -eq $null) {
                    # For random pattern, regenerate the buffer each time
                    $random.NextBytes($buffer)
                }
                
                $fileStream.Write($buffer, 0, $buffer.Length)
                
                if ($i % 100 -eq 0) {  # Update progress less frequently for performance
                    $percentComplete = ($pass - 1) / $Passes * 100 + ($i / $fullBuffers) / $Passes * 100
                    Write-Progress -Activity "Secure File Deletion" -Status "Pass $pass of $Passes" -PercentComplete $percentComplete
                }
            }
            
            # Write the remainder
            if ($remainder -gt 0) {
                if ($pattern -eq $null) {
                    $random.NextBytes($buffer)
                }
                
                $fileStream.Write($buffer, 0, $remainder)
            }
            
            # Flush changes to disk
            $fileStream.Flush()
        }
        
        # Close the file
        $fileStream.Close()
        $fileStream.Dispose()
        
        # Finally, delete the file
        Remove-Item -Path $FilePath -Force
        
        Write-Host "Successfully securely deleted '$FilePath'" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to securely delete file '$FilePath': $_" -ForegroundColor Red
        return $false
    }
    finally {
        Write-Progress -Activity "Secure File Deletion" -Completed
    }
}

# Function to clean up empty directories after processing
function Clean-EmptyDirectories {
    param (
        [string]$DirectoryPath,
        [bool]$Recursive = $true
    )
    
    try {
        if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
            Write-Host "Warning: Directory '$DirectoryPath' not found for cleanup." -ForegroundColor Yellow
            return 0
        }
        
        $deletedFolders = 0
        
        # If recursive, process subdirectories first (bottom-up deletion)
        if ($Recursive) {
            $subDirectories = Get-ChildItem -Path $DirectoryPath -Directory -Recurse | Sort-Object -Property FullName -Descending
            foreach ($dir in $subDirectories) {
                $isEmpty = (-not (Get-ChildItem -Path $dir.FullName -File)) -and (-not (Get-ChildItem -Path $dir.FullName -Directory))
                
                if ($isEmpty) {
                    Write-Host "Removing empty directory: $($dir.FullName)" -ForegroundColor Yellow
                    Remove-Item -Path $dir.FullName -Force
                    $deletedFolders++
                }
            }
        }
        
        # Check if the root directory is now empty and should be deleted
        $isEmpty = (-not (Get-ChildItem -Path $DirectoryPath -File)) -and (-not (Get-ChildItem -Path $DirectoryPath -Directory))
        
        if ($isEmpty) {
            Write-Host "Removing empty root directory: $DirectoryPath" -ForegroundColor Yellow
            Remove-Item -Path $DirectoryPath -Force
            $deletedFolders++
        }
        
        return $deletedFolders
    }
    catch {
        Write-Host "Error cleaning up empty directories: $_" -ForegroundColor Red
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
        Write-Host "Encrypted '$FilePath' to '$OutputFilePath'" -ForegroundColor Green
        
        # If secure delete is requested, perform it after successful encryption
        if ($PerformSecureDelete) {
            if (Secure-Delete -FilePath $FilePath -Passes $ShredPasses) {
                Write-Host "Original file securely deleted after encryption." -ForegroundColor Green
            }
            else {
                Write-Host "Warning: Failed to securely delete original file after encryption." -ForegroundColor Yellow
            }
        }
        
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
        Write-Host "Decrypted '$FilePath' to '$OutputFilePath'" -ForegroundColor Green
        
        # If secure delete is requested, perform it after successful decryption
        if ($PerformSecureDelete) {
            if (Secure-Delete -FilePath $FilePath -Passes $ShredPasses) {
                Write-Host "Encrypted file securely deleted after decryption." -ForegroundColor Green
            }
            else {
                Write-Host "Warning: Failed to securely delete encrypted file after decryption." -ForegroundColor Yellow
            }
        }
        
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
        [bool]$ProcessRecursively,
        [bool]$PerformSecureDelete = $false,
        [int]$ShredPasses = 3,
        [bool]$CleanEmptyFolders = $false
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
                    
                    $success = Encrypt-File -FilePath $file -OutputFilePath $outputFilePath -PerformSecureDelete $PerformSecureDelete -ShredPasses $ShredPasses
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
                    
                    $success = Decrypt-File -FilePath $file -OutputFilePath $outputFilePath -PerformSecureDelete $PerformSecureDelete -ShredPasses $ShredPasses
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
    
    # Clean up empty directories if requested
    if ($CleanEmptyFolders -and $PerformSecureDelete) {
        Write-Host "`nCleaning up empty directories..." -ForegroundColor Cyan
        $deletedFolders = Clean-EmptyDirectories -DirectoryPath $DirectoryPath -Recursive $ProcessRecursively
        Write-Host "Removed $deletedFolders empty directories." -ForegroundColor Green
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

# Function to confirm secure deletion
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
    
    # If secure delete was requested, confirm with the user
    $performSecureDelete = $false
    if ($SecureDelete -and ($Mode -eq "Encrypt" -or $Mode -eq "Decrypt")) {
        $isDirectory = Test-Path -Path $Path -PathType Container
        $performSecureDelete = Confirm-SecureDeletion -Path $Path -IsDirectory $isDirectory -IncludeEmptyFolders $CleanEmptyFolders
        
        if (-not $performSecureDelete) {
            Write-Host "Secure deletion cancelled. Continuing without deleting original files." -ForegroundColor Yellow
            $CleanEmptyFolders = $false  # Disable folder cleanup if secure delete was cancelled
        }
        else {
            Write-Host "Secure deletion confirmed. Original files will be securely deleted after processing." -ForegroundColor Red
            # Display information about the shredding process
            Write-Host "Files will be overwritten with $ShredPasses passes using zeros, ones, and random data." -ForegroundColor Yellow
            
            if ($CleanEmptyFolders) {
                Write-Host "Empty folders will be removed after processing." -ForegroundColor Yellow
            }
        }
    }
    
    # Process based on mode
    switch ($Mode) {
        "Encrypt" {
            if (Test-Path -Path $Path -PathType Container) {
                # Process a directory
                $outputDir = if ([string]::IsNullOrEmpty($OutputPath)) { $Path } else { $OutputPath }
                Process-Directory -DirectoryPath $Path -OutputDirectoryPath $outputDir -Operation "Encrypt" -ProcessRecursively $Recursive -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses -CleanEmptyFolders $CleanEmptyFolders
            }
            else {
                # Process a single file
                $outputFilePath = Build-OutputPath -InputPath $Path -BaseOutputPath $OutputPath -Operation "Encrypt"
                
                if (($Force) -or (-not (Test-Path $outputFilePath)) -or 
                    ((Test-Path $outputFilePath) -and (Read-Host "File '$outputFilePath' already exists. Overwrite? (Y/N)").ToUpper() -eq 'Y')) {
                    
                    Encrypt-File -FilePath $Path -OutputFilePath $outputFilePath -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses | Out-Null
                    
                    # Clean up parent directory if it's now empty and cleaning was requested
                    if ($CleanEmptyFolders -and $performSecureDelete) {
                        $parentDir = [System.IO.Path]::GetDirectoryName($Path)
                        $isEmpty = (-not (Get-ChildItem -Path $parentDir -File)) -and (-not (Get-ChildItem -Path $parentDir -Directory))
                        
                        if ($isEmpty) {
                            Write-Host "Removing empty parent directory: $parentDir" -ForegroundColor Yellow
                            Remove-Item -Path $parentDir -Force
                        }
                    }
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
                Process-Directory -DirectoryPath $Path -OutputDirectoryPath $outputDir -Operation "Decrypt" -ProcessRecursively $Recursive -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses -CleanEmptyFolders $CleanEmptyFolders
            }
            else {
                # Process a single file
                $outputFilePath = Build-OutputPath -InputPath $Path -BaseOutputPath $OutputPath -Operation "Decrypt"
                
                if (($Force) -or (-not (Test-Path $outputFilePath)) -or 
                    ((Test-Path $outputFilePath) -and (Read-Host "File '$outputFilePath' already exists. Overwrite? (Y/N)").ToUpper() -eq 'Y')) {
                    
                    Decrypt-File -FilePath $Path -OutputFilePath $outputFilePath -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses | Out-Null
                    
                    # Clean up parent directory if it's now empty and cleaning was requested
                    if ($CleanEmptyFolders -and $performSecureDelete) {
                        $parentDir = [System.IO.Path]::GetDirectoryName($Path)
                        $isEmpty = (-not (Get-ChildItem -Path $parentDir -File)) -and (-not (Get-ChildItem -Path $parentDir -Directory))
                        
                        if ($isEmpty) {
                            Write-Host "Removing empty parent directory: $parentDir" -ForegroundColor Yellow
                            Remove-Item -Path $parentDir -Force
                        }
                    }
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
}GetDirectoryName($OutputPath))
            }
            elseif ($pathIsDirectory -and -not $outputPathIsDirectory) {
                Ensure-Directory -DirectoryPath $OutputPath
            }
        }
    }
    
    # If secure delete was requested, confirm with the user
    $performSecureDelete = $false
    if ($SecureDelete -and ($Mode -eq "Encrypt" -or $Mode -eq "Decrypt")) {
        $isDirectory = Test-Path -Path $Path -PathType Container
        $performSecureDelete = Confirm-SecureDeletion -Path $Path -IsDirectory $isDirectory
        
        if (-not $performSecureDelete) {
            Write-Host "Secure deletion cancelled. Continuing without deleting original files." -ForegroundColor Yellow
        }
        else {
            Write-Host "Secure deletion confirmed. Original files will be securely deleted after processing." -ForegroundColor Red
            # Display information about the shredding process
            Write-Host "Files will be overwritten with $ShredPasses passes using zeros, ones, and random data." -ForegroundColor Yellow
        }
    }
    
    # Process based on mode
    switch ($Mode) {
        "Encrypt" {
            if (Test-Path -Path $Path -PathType Container) {
                # Process a directory
                $outputDir = if ([string]::IsNullOrEmpty($OutputPath)) { $Path } else { $OutputPath }
                Process-Directory -DirectoryPath $Path -OutputDirectoryPath $outputDir -Operation "Encrypt" -ProcessRecursively $Recursive -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses
            }
            else {
                # Process a single file
                $outputFilePath = Build-OutputPath -InputPath $Path -BaseOutputPath $OutputPath -Operation "Encrypt"
                
                if (($Force) -or (-not (Test-Path $outputFilePath)) -or 
                    ((Test-Path $outputFilePath) -and (Read-Host "File '$outputFilePath' already exists. Overwrite? (Y/N)").ToUpper() -eq 'Y')) {
                    
                    Encrypt-File -FilePath $Path -OutputFilePath $outputFilePath -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses | Out-Null
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
                Process-Directory -DirectoryPath $Path -OutputDirectoryPath $outputDir -Operation "Decrypt" -ProcessRecursively $Recursive -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses
            }
            else {
                # Process a single file
                $outputFilePath = Build-OutputPath -InputPath $Path -BaseOutputPath $OutputPath -Operation "Decrypt"
                
                if (($Force) -or (-not (Test-Path $outputFilePath)) -or 
                    ((Test-Path $outputFilePath) -and (Read-Host "File '$outputFilePath' already exists. Overwrite? (Y/N)").ToUpper() -eq 'Y')) {
                    
                    Decrypt-File -FilePath $Path -OutputFilePath $outputFilePath -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses | Out-Null
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

Ensure-Directory -DirectoryPath ([System.IO.Path]::GetDirectoryName($OutputPath))
            }
            elseif ($pathIsDirectory -and -not $outputPathIsDirectory) {
                Ensure-Directory -DirectoryPath $OutputPath
            }
        }
    }
    
    # If secure delete was requested, confirm with the user
    $performSecureDelete = $false
    if ($SecureDelete -and ($Mode -eq "Encrypt" -or $Mode -eq "Decrypt")) {
        $isDirectory = Test-Path -Path $Path -PathType Container
        $performSecureDelete = Confirm-SecureDeletion -Path $Path -IsDirectory $isDirectory -IncludeEmptyFolders $CleanEmptyFolders
        
        if (-not $performSecureDelete) {
            Write-Host "Secure deletion cancelled. Continuing without deleting original files." -ForegroundColor Yellow
            $CleanEmptyFolders = $false  # Disable folder cleanup if secure delete was cancelled
        }
        else {
            Write-Host "Secure deletion confirmed. Original files will be securely deleted after processing." -ForegroundColor Red
            # Display information about the shredding process
            Write-Host "Files will be overwritten with $ShredPasses passes using zeros, ones, and random data." -ForegroundColor Yellow
            
            if ($CleanEmptyFolders) {
                Write-Host "Empty folders will be removed after processing." -ForegroundColor Yellow
            }
        }
    }
    
    # Process based on mode
    switch ($Mode) {
        "Encrypt" {
            if (Test-Path -Path $Path -PathType Container) {
                # Process a directory
                $outputDir = if ([string]::IsNullOrEmpty($OutputPath)) { $Path } else { $OutputPath }
                Process-Directory -DirectoryPath $Path -OutputDirectoryPath $outputDir -Operation "Encrypt" -ProcessRecursively $Recursive -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses -CleanEmptyFolders $CleanEmptyFolders
            }
            else {
                # Process a single file
                $outputFilePath = Build-OutputPath -InputPath $Path -BaseOutputPath $OutputPath -Operation "Encrypt"
                
                if (($Force) -or (-not (Test-Path $outputFilePath)) -or 
                    ((Test-Path $outputFilePath) -and (Read-Host "File '$outputFilePath' already exists. Overwrite? (Y/N)").ToUpper() -eq 'Y')) {
                    
                    Encrypt-File -FilePath $Path -OutputFilePath $outputFilePath -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses | Out-Null
                    
                    # Clean up parent directory if it's now empty and cleaning was requested
                    if ($CleanEmptyFolders -and $performSecureDelete) {
                        $parentDir = [System.IO.Path]::GetDirectoryName($Path)
                        $isEmpty = (-not (Get-ChildItem -Path $parentDir -File)) -and (-not (Get-ChildItem -Path $parentDir -Directory))
                        
                        if ($isEmpty) {
                            Write-Host "Removing empty parent directory: $parentDir" -ForegroundColor Yellow
                            Remove-Item -Path $parentDir -Force
                        }
                    }
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
                Process-Directory -DirectoryPath $Path -OutputDirectoryPath $outputDir -Operation "Decrypt" -ProcessRecursively $Recursive -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses -CleanEmptyFolders $CleanEmptyFolders
            }
            else {
                # Process a single file
                $outputFilePath = Build-OutputPath -InputPath $Path -BaseOutputPath $OutputPath -Operation "Decrypt"
                
                if (($Force) -or (-not (Test-Path $outputFilePath)) -or 
                    ((Test-Path $outputFilePath) -and (Read-Host "File '$outputFilePath' already exists. Overwrite? (Y/N)").ToUpper() -eq 'Y')) {
                    
                    Decrypt-File -FilePath $Path -OutputFilePath $outputFilePath -PerformSecureDelete $performSecureDelete -ShredPasses $ShredPasses | Out-Null
                    
                    # Clean up parent directory if it's now empty and cleaning was requested
                    if ($CleanEmptyFolders -and $performSecureDelete) {
                        $parentDir = [System.IO.Path]::GetDirectoryName($Path)
                        $isEmpty = (-not (Get-ChildItem -Path $parentDir -File)) -and (-not (Get-ChildItem -Path $parentDir -Directory))
                        
                        if ($isEmpty) {
                            Write-Host "Removing empty parent directory: $parentDir" -ForegroundColor Yellow
                            Remove-Item -Path $parentDir -Force
                        }
                    }
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
