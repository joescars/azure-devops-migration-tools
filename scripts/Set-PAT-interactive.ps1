# Set-PAT-Simple.ps1
# Simple script to set PAT environment variables

param(
    [string]$SourcePAT,
    [string]$TargetPAT,
    [switch]$SessionOnly,
    [switch]$Help
)

if ($Help) {
    Write-Host "Set-PAT-Simple.ps1 - Sets MigrationTools__Endpoints__Source__Authentication__AccessToken and MigrationTools__Endpoints__TARGET__Authentication__AccessToken environment variables"
    Write-Host "Usage: .\Set-PAT-Simple.ps1 [-SessionOnly] [-Help]"
    exit 0
}

Write-Host ""
Write-Host "=== ADO Migration - PAT Setup ===" -ForegroundColor Cyan

if ($SessionOnly) {
    Write-Host "Mode: Session Only" -ForegroundColor Yellow
} else {
    Write-Host "Mode: Persistent (User Profile)" -ForegroundColor Green
}

# Get source PAT
if (-not $SourcePAT) {
    Write-Host ""
    Write-Host "Enter SOURCE AccessToken: " -NoNewline -ForegroundColor Yellow
    $secureSource = Read-Host -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureSource)
    $SourcePAT = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

# Get target PAT  
if (-not $TargetPAT) {
    Write-Host "Enter TARGET AccessToken: " -NoNewline -ForegroundColor Yellow
    $secureTarget = Read-Host -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureTarget)
    $TargetPAT = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

# Validate
if (-not $SourcePAT -or -not $TargetPAT -or $SourcePAT.Length -eq 0 -or $TargetPAT.Length -eq 0) {
    Write-Host ""
    Write-Host "ERROR: Both tokens are required and cannot be empty." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Setting environment variables..." -ForegroundColor White

# Set session variables
$env:MigrationTools__Endpoints__Source__Authentication__AccessToken = $SourcePAT
$env:MigrationTools__Endpoints__TARGET__Authentication__AccessToken = $TargetPAT
Write-Host "OK: Set session variables" -ForegroundColor Green

# Set persistent variables (unless session-only)
if (-not $SessionOnly) {
    [Environment]::SetEnvironmentVariable("MigrationTools__Endpoints__Source__Authentication__AccessToken", $SourcePAT, [EnvironmentVariableTarget]::User)
    [Environment]::SetEnvironmentVariable("MigrationTools__Endpoints__TARGET__Authentication__AccessToken", $TargetPAT, [EnvironmentVariableTarget]::User)
    Write-Host "OK: Set persistent variables" -ForegroundColor Green
}

# Verification
Write-Host ""
Write-Host "Verification:" -ForegroundColor White

if ($env:MigrationTools__Endpoints__Source__Authentication__AccessToken) {
    Write-Host "MigrationTools__Endpoints__Source__Authentication__AccessToken (session): OK - Length $($env:MigrationTools__Endpoints__Source__Authentication__AccessToken.Length)" -ForegroundColor Green
} else {
    Write-Host "MigrationTools__Endpoints__Source__Authentication__AccessToken (session): FAIL" -ForegroundColor Red
}

if ($env:MigrationTools__Endpoints__TARGET__Authentication__AccessToken) {
    Write-Host "MigrationTools__Endpoints__TARGET__Authentication__AccessToken (session): OK - Length $($env:MigrationTools__Endpoints__TARGET__Authentication__AccessToken.Length)" -ForegroundColor Green  
} else {
    Write-Host "MigrationTools__Endpoints__TARGET__Authentication__AccessToken (session): FAIL" -ForegroundColor Red
}

if (-not $SessionOnly) {
    $persistSource = [Environment]::GetEnvironmentVariable("MigrationTools__Endpoints__Source__Authentication__AccessToken", "User")
    $persistTarget = [Environment]::GetEnvironmentVariable("MigrationTools__Endpoints__TARGET__Authentication__AccessToken", "User")
    
    if ($persistSource) {
        Write-Host "MigrationTools__Endpoints__Source__Authentication__AccessToken (persistent): OK - Length $($persistSource.Length)" -ForegroundColor Green
    } else {
        Write-Host "MigrationTools__Endpoints__Source__Authentication__AccessToken (persistent): FAIL" -ForegroundColor Red
    }
    
    if ($persistTarget) {
        Write-Host "MigrationTools__Endpoints__TARGET__Authentication__AccessToken (persistent): OK - Length $($persistTarget.Length)" -ForegroundColor Green
    } else {
        Write-Host "MigrationTools__Endpoints__TARGET__Authentication__AccessToken (persistent): FAIL" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "SUCCESS: Environment variables have been set!" -ForegroundColor Green

if (-not $SessionOnly) {
    Write-Host "Note: You may need to restart applications to see the changes." -ForegroundColor Yellow
}