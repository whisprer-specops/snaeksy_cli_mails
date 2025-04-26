# Analysis of the clean_sweep.ps1 Output
Overall Script Execution Summary


## Successful Scripts:

00_wget_proxy.ps1: Succeeded, downloaded a file over Tor (1256 bytes).
text
`100  1256  100  1256    0     0   1070      0  0:00:01  0:00:01 --:--:--  1070`

0_reveal.ps1: Succeeded, decrypted content (wpsdjdrtfhdcyvph).
1_decrypt_profile_script.ps1: Succeeded, decrypted and executed script.
2_encrypt_smtp_pwd_only.ps1: Succeeded, encrypted SMTP password.
3_decrypt_&_run.ps1: Succeeded, decrypted and executed script.
4_tor_verify.ps1: Succeeded, verified Tor on 127.0.0.1:9050.
5_obfuscate.ps1: Succeeded, obfuscated script to longmail_dynamic_enc.xml.
6_encrypt_profile_script.ps1: Succeeded (new script in the sequence—nice!).
7_hide_regedits.ps1: Succeeded, encoded registry file to hidden_sam_encoded.txt.
8_obfuscate_usb_usage.ps1: Succeeded!
9_clear_history.ps1: Succeeded, cleared PowerShell history.
