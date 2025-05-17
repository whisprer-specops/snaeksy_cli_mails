Hey woflfren! I've updated your script with secure deletion functionality now. Let me walk you through what I added:
New Secure Deletion Features

DOD-style Multi-Pass Shredding:

The Secure-Delete function performs military-grade file wiping
Overwrites files multiple times with different patterns:

First pass: All zeros (0x00)
Second pass: All ones (0xFF)
Third pass: Random data


These patterns repeat for as many passes as you specify


Two New Parameters:

-SecureDelete - Flag to enable secure deletion of source files after successful processing
-ShredPasses - Number of overwrite passes (default is 3)


Safety Measures:

A clear, unmistakable warning prompt appears before any secure deletion
Deletion only happens after confirming the target file was successfully encrypted/decrypted
Visual progress indicators show the shredding process



How to Use It

Basic encryption with secure deletion:

powershell.\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\secret.txt" -SecureDelete

Encryption with extra security (7 passes):

powershell.\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\secret.txt" -SecureDelete -ShredPasses 7

Process entire folders and securely delete originals:

powershell.\FileEncryptionTool.ps1 -Mode Encrypt -Path "C:\secret_folder" -Recursive -SecureDelete

Decrypting with secure deletion of the encrypted files:

powershell.\FileEncryptionTool.ps1 -Mode Decrypt -Path "C:\encrypted_files" -SecureDelete
The secure deletion implements a thorough multi-pass approach:

Each pass overwrites the entire file with a specific pattern
File length is preserved during overwriting
Random data is used for maximum entropy
The file is finally removed from the filesystem after overwriting

This ensures that even advanced forensic techniques would have extreme difficulty recovering any contents from the original files. The script will provide clear warnings and confirmations before proceeding with any secure deletion operations, so you won't accidentally delete anything without explicit consent.
Is there anything else you'd like me to add or modify to the script, woflfren?