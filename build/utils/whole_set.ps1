# List of scripts to run in order
$scripts = @(
    "1_gi_get_env_vars.ps1",
    "2_enc_app_pwd.ps1",
    "3_enc_env_var_pwd.ps1",
    "4_gi_set_env_var_enc.ps1",
    "5_obfuscate_set_env_vars.ps1",
    "6_tor_verify.ps1"
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