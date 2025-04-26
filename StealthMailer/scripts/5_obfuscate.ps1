try {
    $scriptPath = ".\longmail_static_tor.ps1"
    $outputPath = ".\longmail_dynamic_enc.xml"
    if (-not (Test-Path $scriptPath)) {
        Write-Host "Script not found at $scriptPath."
        exit 1
    }
    $scriptContent = Get-Content $scriptPath | Out-String
    ConvertTo-SecureString -String $scriptContent -AsPlainText -Force | Export-Clixml $outputPath
    $message = "Script obfuscated to $outputPath."
    Write-Host $message
    exit 0
} catch {
    Write-Host "Failed to obfuscate script: $_"
    exit 1
}