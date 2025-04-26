# Set error action preference to stop on non-terminating errors
$ErrorActionPreference = "Stop"

$scripts = @(
    "000_spoof_mac",
    "00_wget_proxy",
    "0_reveal",
    "1_decrypt_profile_script",
    "2_encrypt_smtp_pwd_only",
    "3_decrypt_&_run",
    "4_tor_verify",
    "5_obfuscate",
    "6_encrypt_profile_script",
    "7_hide_regedits",
    "8_obfuscate_usb_usage",
    "9_clear_history"
)

foreach ($script in $scripts) {
    try {
        Write-Host "Running $script..."
        & ".\$script"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "$script failed with exit code $LASTEXITCODE."
        } else {
            Write-Host "$script completed successfully."
        }
    } catch {
        Write-Host "Error running $script : $_"
        # Optionally exit the entire script if a critical script fails
        # exit 1
    }
}