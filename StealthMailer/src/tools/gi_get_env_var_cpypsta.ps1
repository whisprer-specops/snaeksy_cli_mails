gi -Path Env:SENDER_EMAIL, Env:SMTP_PORT, Env:SMTP_SERVER, Env:SMTP_USER, Env:TO_EMAIL, Env:SMTP_PASSWORD | Select-
Object -ExpandProperty Value