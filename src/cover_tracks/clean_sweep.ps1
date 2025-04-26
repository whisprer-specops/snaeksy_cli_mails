# List of scripts to run in order
$scripts = @(
    "decrypt_profile_script",
    "spoof_mac",
    "wget_proxy",
    "",
    "",
    "",
    ""
)

# Run each script sequentially with error handling
foreach ($script in $scripts) {
    try {
        Write-Host "Running $script..."
        & ".\$script"
        Write-Host "$script completed successfully."
    } catch {
        Write-Host "Error running $script : $_"
    }
}