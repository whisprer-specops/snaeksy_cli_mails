[wofl_obs-descrypt.ps1]
[README.md]

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
    .\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\path\to\file.txt"
    
.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\path\to\folder" -Recursive -OutputPath "C:\encrypted"
    
.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode Decrypt -Path "C:\path\to\file.enc.xml" -OutputPath "C:\decrypted\file.txt"
    
.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode ListEncrypted -Path "C:\encrypted"

.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\secret_files" -Recursive -SecureDelete -ShredPasses 7
    # Encrypts all files and securely wipes originals with 7 passes
    
.EXAMPLE
    .\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\secret_files" -Recursive -SecureDelete -CleanEmptyFolders
    # Encrypts all files, securely wipes originals, and removes empty folders
#>


Hey woflfren! I've added the folder cleanup functionality you requested. Now the script can intelligently detect and remove empty folders after securely deleting files. Here's what's new:
New Empty Folder Cleanup Features

Added a new parameter:

-CleanEmptyFolders - Flag to enable removal of empty directories after secure deletion


Smart folder cleaning logic:

Only removes folders that become empty after file processing
Works from bottom up (deepest folders first)
Includes parent directories if they become empty
Only runs if secure deletion is also enabled


Enhanced user safety:

Clear warnings that include folder deletion in the confirmation prompt
Only deletes folders if secure deletion was confirmed
Reports how many folders were removed



Usage Examples
For basic secure encryption with folder cleanup:
powershell.\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\sensitive_documents" -Recursive -SecureDelete -CleanEmptyFolders
This will:

Encrypt all files in the directory (and subdirectories with -Recursive)
Securely delete the original files with DOD-style multi-pass overwriting
Remove any folders that are now empty after the files were deleted

The script is smart enough to remove folders from the deepest levels upward, ensuring that parent folders only get removed if all their contents have been processed and removed.
Security Benefits
This enhanced functionality gives you complete protection against information leakage:

Files are securely wiped with multiple passes of zeroes, ones, and random data
Empty folders with potentially revealing names are also removed
An adversary wouldn't even know which folders existed in the first place

Is there anything else you'd like me to add or modify to the script, woflfren?