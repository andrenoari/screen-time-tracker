# Run this script in PowerShell as Administrator
# Creates a self-signed certificate for MSIX signing

# Certificate parameters - MUST match the Publisher in pubspec.yaml
$publisherName = "CN=Ariful Islam Khan, O=Freak Media, C=IN"
$certPassword = "1QAZxsw@"
$certPath = ".\certificates"
$pfxFile = "$certPath\ScreenTimeTracker.pfx"
$cerFile = "$certPath\ScreenTimeTracker.cer"

# Create certificates folder
if (!(Test-Path $certPath)) {
    New-Item -ItemType Directory -Path $certPath | Out-Null
    Write-Host "Created certificates folder" -ForegroundColor Green
}

# Create self-signed certificate
Write-Host "`nCreating self-signed certificate..." -ForegroundColor Yellow
$cert = New-SelfSignedCertificate -Type Custom `
    -Subject $publisherName `
    -KeyUsage DigitalSignature `
    -FriendlyName "Screen Time Tracker" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")

Write-Host "Certificate created with thumbprint: $($cert.Thumbprint)" -ForegroundColor Green

# Export to PFX (for signing)
Write-Host "`nExporting certificate to PFX..." -ForegroundColor Yellow
$password = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $pfxFile -Password $password | Out-Null
Write-Host "PFX exported to: $pfxFile" -ForegroundColor Green

# Export to CER (for distribution to users)
Write-Host "Exporting certificate to CER..." -ForegroundColor Yellow
Export-Certificate -Cert $cert -FilePath $cerFile | Out-Null
Write-Host "CER exported to: $cerFile" -ForegroundColor Green

# Install certificate to Trusted People store
Write-Host "`nInstalling certificate to Trusted People store..." -ForegroundColor Yellow
Import-PfxCertificate -FilePath $pfxFile -CertStoreLocation Cert:\LocalMachine\TrustedPeople -Password $password | Out-Null
Write-Host "Certificate installed successfully!" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CERTIFICATE CREATED SUCCESSFULLY!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nCertificate files:"
Write-Host "  PFX (for signing): $pfxFile"
Write-Host "  CER (for users):   $cerFile"
Write-Host "`nPassword: $certPassword"
Write-Host "`nNext steps:"
Write-Host "1. Update pubspec.yaml with certificate path and password"
Write-Host "2. Run: dart run msix:create"
Write-Host "`nFor distribution, share the .cer file with users to install."
