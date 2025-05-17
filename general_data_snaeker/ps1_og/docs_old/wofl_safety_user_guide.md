This versatile tool expands on your original scripts significantly, woflfren! Let me walk you through how to use it:
Features

Multiple operation modes:

Encrypt - Securely encrypts files
Decrypt - Restores encrypted files
ListEncrypted - Shows all encrypted files in a directory


Handles both files and folders:

Process individual files
Process entire directories with -Recursive flag


Smart output path handling:

Defaults to the same directory if not specified
Creates necessary directories automatically
Preserves folder structure when encrypting/decrypting multiple files


Safety and control:

-Force parameter to overwrite existing files without prompting
Confirmation before overwriting files by default
Skips already encrypted/decrypted files to avoid duplicates



Usage Examples

Encrypt a single file:

powershell.\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\path\to\secret.txt"

Encrypt an entire folder recursively:

powershell.\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\path\to\secrets" -Recursive -OutputPath "C:\encrypted"

Decrypt a file:

powershell.\FileEncryptionTool.ps1 -Mode Decrypt -Path "C:\path\to\secret.txt.enc.xml"

List all encrypted files:

powershell.\FileEncryptionTool.ps1 -Mode ListEncrypted -Path "C:\encrypted" -Recursive
This tool uses the same security approach as your original scripts - PowerShell's SecureString and XML export/import functions - but now applies them to any file type and provides much more flexibility.
Would you like me to explain any specific part of the script in more detail, or would you prefer any modifications to better suit your needs, woflfren?