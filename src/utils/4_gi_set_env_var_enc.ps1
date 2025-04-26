$envVars = @{
    "SENDER_EMAIL"  = "got.girl.camera"
    "SMTP_PORT"     = "587"
    "SMTP_SERVER"   = "smtp.gmail.com"
    "SMTP_USER"     = "got.girl.camera"
    "TO_EMAIL"      = "troymetro@hotmail.com"
}
foreach ($key in $envVars.Keys) {
    [Environment]::SetEnvironmentVariable($key, $envVars[$key], "User")
}