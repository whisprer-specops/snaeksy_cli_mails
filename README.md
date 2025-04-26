📄 README.md
StealthMailer: Covert PowerShell Email System with Tor Routing, Credential Encryption, and Script Obfuscation

Overview
StealthMailer is a fully modular, security-focused PowerShell email system designed for covert communications, anonymous email dispatch, and maximum operational stealth.

It combines Tor routing, SMTP authentication through encrypted credentials, script obfuscation, registry stealthing, and dynamic environment configuration to create a hardened communication channel with minimal forensic footprint.

Designed for advanced privacy-conscious users, StealthMailer ensures no plaintext credentials, no unprotected scripts, and no obvious traces left behind.

Features
✅ Encrypted SMTP Password Handling
✅ Tor Proxy Email Routing (SOCKS5 127.0.0.1:9050)
✅ Dynamic Environment Variable Injection
✅ Script Obfuscation and Secure Storage
✅ Registry Hiding Techniques
✅ USB Activity Obfuscation Demo
✅ Operational Stealth Mode (History Cleanup + Anti-Forensics)
✅ IPv6 Proxy Support for Additional Cloaking
✅ Modular Utilities for Profile Management and System Prep

Project Structure

Folder	Description
/scripts/	Core functionality: email scripts, encryption scripts, Tor setup, obfuscators
/docs/	Guides and explainers (e.g., SMTP password encryption instructions)
/tools/	Optional helper scripts (e.g., environment injection, profile revealers)
Quickstart Guide
Set Up SMTP Credentials Securely

Encrypt your SMTP app password using provided utilities (2_enc_app_pwd.ps1).

Store it securely in mail_ic_enc.xml or longmail_dynamic_enc.xml.

Prepare Environment Variables

Use scripts like 4_gi_set_env_var_enc.ps1 to safely load environment variables without exposing credentials.

Verify Tor Connectivity

Launch Tor (tor.exe) separately or auto-verify using 4_tor_verify.ps1 or 6_tor_verify.ps1.

Send Stealth Emails

Use longmail_dynamic.ps1 (Tor routed, dynamic) or longmail_static_tor.ps1 (static Tor) to dispatch encrypted, routed emails.

Maintain Stealth

Obfuscate scripts (5_obfuscate.ps1).

Wipe PowerShell console history (9_clear_history.ps1).

Hide sensitive registry changes (7_hide_regedits.ps1).

USB Activity Obfuscation (Optional Bonus)

Test covert downloads via 8_obfuscate_usb_usage.ps1 (e.g., hidden image pull).

Main Scripts Explained

Script	Purpose
1_decrypt_profile_script.ps1	Decrypts your SMTP profile credentials
2_encrypt_smtp_pwd_only.ps1	Encrypts SMTP password securely
3_decrypt_&_run.ps1	Decrypt and immediately run an email operation
4_tor_verify.ps1	Confirm Tor proxy is operational
5_obfuscate.ps1	Obfuscates target script for stealth
6_encrypt_profile_script.ps1	Encrypts full profile (not just password)
7_hide_regedits.ps1	Applies hidden registry changes
8_obfuscate_usb_usage.ps1	Covert USB download obfuscation example
9_clear_history.ps1	Wipe local PowerShell command history
longmail_dynamic.ps1	Fully dynamic, stealthy email sender (Tor)
longmail_static_tor.ps1	Static profile stealth email sender (Tor)
clean_sweep.ps1	Clean operation tracks (defense grade wipe)
Utilities (Helpers)

Script	Purpose
1_gi_get_env_var.ps1	Safely retrieve environment variables
2_enc_app_pwd.ps1	Encrypt app-specific password
3_enc_env_var_pwd.ps1	Encrypt a password from env var
4_gi_set_env_var_enc.ps1	Securely set environment variable from an encrypted file
5_obfuscate_set_env_vars.ps1	Obfuscate environment setup
reveal_set_env_var.ps1	Reveal stored environment variables (for debugging)
temp_disable_defender_line.ps1	Temporarily disable Windows Defender (optional, caution advised)
whole_set.ps1	Orchestrates the full environment setup
Security Layers
SecureString Encryption: All sensitive passwords encrypted to the user's machine/account.

Tor Routing: SMTP traffic routed through anonymized proxy.

Script Obfuscation: Scripts transformed and optionally hidden inside encrypted XML blobs.

Registry Hiding: Sensitive registry modifications hidden from casual inspection.

No Plaintext Logging: PowerShell history cleaned after major actions.

Requirements
Windows 10/11

PowerShell 5.0+

Tor Browser installed (or tor.exe available separately)

A valid Gmail (or compatible SMTP server) account with App Passwords enabled

Administrative privileges for some stealth operations (registry, Defender changes)

Notes and Warnings
Secure Strings are user/machine-bound. Re-encrypt passwords if moving to a different machine.

Tor must be active before sending emails or the proxy will fail.

Some scripts (e.g., Defender disable) are advanced ops. Only use if you fully understand the security implications.

StealthMailer is for ethical and educational uses only. Respect all local laws.

Credits
Built with relentless obsession for stealth, security, and operational perfection by fren.
With some wagging huskly paws of support from your forever assistant 🖤

