# Set-EnvironmentVariables-FromEnvFile.ps1
# Script to load any environment variables from a .env file

param(
    [string]$EnvFilePath = ".\.env",
    [switch]$SessionOnly,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Set-EnvironmentVariables-FromEnvFile.ps1

DESCRIPTION:
    Loads any environment variables from a .env file and sets them in PowerShell.

PARAMETERS:
    -EnvFilePath     : Path to the .env file (default: .\.env)
    -SessionOnly     : Set variables for current session only (default: sets persistently)
    -Help           : Show this help information

USAGE:
    .\Set-EnvironmentVariables-FromEnvFile.ps1                    # Load from .\.env file
    .\Set-EnvironmentVariables-FromEnvFile.ps1 -SessionOnly       # Session only mode
    .\Set-EnvironmentVariables-FromEnvFile.ps1 -EnvFilePath "custom\.env"  # Custom file path

.ENV FILE FORMAT:
    VARIABLE_NAME=value
    # Comments start with #
    PAT_SOURCE=your_token_here
    PAT_TARGET=another_token_here
    API_KEY=your_api_key
    DATABASE_CONNECTION=server=localhost;database=mydb

"@ -ForegroundColor Cyan
    exit 0
}

function Set-EnvironmentVariableFromFile {
    param(
        [string]$Name,
        [string]$Value,
        [bool]$SessionOnly
    )
    
    try {
        # Set session variable
        Set-Item -Path "Env:$Name" -Value $Value
        
        # Set persistent variable (unless session-only)
        if (-not $SessionOnly) {
            [Environment]::SetEnvironmentVariable($Name, $Value, [EnvironmentVariableTarget]::User)
            Write-Host "  $Name = $(if ($Value.Length -gt 20) { $Value.Substring(0,16) + '...' } else { $Value }) (persistent)" -ForegroundColor Green
        } else {
            Write-Host "  $Name = $(if ($Value.Length -gt 20) { $Value.Substring(0,16) + '...' } else { $Value }) (session only)" -ForegroundColor Yellow
        }
        
        return $true
    } catch {
        Write-Host "  ERROR setting $Name`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Read-EnvFile {
    param(
        [string]$FilePath,
        [bool]$SessionOnly
    )
    
    if (-not (Test-Path $FilePath)) {
        throw "Environment file not found: $FilePath"
    }
    
    Write-Host "Reading environment file: $FilePath" -ForegroundColor White
    
    # Read file with explicit UTF-8 encoding to handle Unicode characters properly
    try {
        $content = Get-Content -Path $FilePath -Encoding UTF8 -ErrorAction Stop
    } catch {
        # Fallback to default encoding if UTF-8 fails
        Write-Host "  Warning: UTF-8 encoding failed, trying default encoding..." -ForegroundColor Yellow
        $content = Get-Content -Path $FilePath -ErrorAction Stop
    }
    
    $variablesSet = 0
    $errors = 0
    $variableNames = @()
    
    foreach ($line in $content) {
        # Skip empty lines and comments
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
            continue
        }
        
        # Parse VARIABLE=VALUE format
        if ($line -match "^([^=]+)=(.*)$") {
            $variableName = $matches[1].Trim()
            $variableValue = $matches[2].Trim()
            
            # Remove quotes if present
            if (($variableValue.StartsWith('"') -and $variableValue.EndsWith('"')) -or
                ($variableValue.StartsWith("'") -and $variableValue.EndsWith("'"))) {
                $variableValue = $variableValue.Substring(1, $variableValue.Length - 2)
            }
            
            if (Set-EnvironmentVariableFromFile -Name $variableName -Value $variableValue -SessionOnly $SessionOnly) {
                $variablesSet++
                $variableNames += $variableName
            } else {
                $errors++
            }
        } else {
            Write-Host "  WARNING: Skipping invalid line format: $line" -ForegroundColor Yellow
        }
    }
    
    return @{
        VariablesSet = $variablesSet
        Errors = $errors
        VariableNames = $variableNames
    }
}

# Main script execution
try {
    Write-Host "`n=== Environment Variables from .env File ===" -ForegroundColor Cyan
    
    if ($SessionOnly) {
        Write-Host "Mode: Session Only (variables will be lost when PowerShell session ends)" -ForegroundColor Yellow
    } else {
        Write-Host "Mode: Persistent (variables will be saved to user profile)" -ForegroundColor Green
    }
    Write-Host ""
    
    # Read and set environment variables
    $result = Read-EnvFile -FilePath $EnvFilePath -SessionOnly $SessionOnly
    
    Write-Host "`nSummary:" -ForegroundColor White
    Write-Host "  Variables set: $($result.VariablesSet)" -ForegroundColor Green
    if ($result.Errors -gt 0) {
        Write-Host "  Errors: $($result.Errors)" -ForegroundColor Red
    }
    
    # Verify all loaded variables
    if ($result.VariableNames.Count -gt 0) {
        Write-Host "`nSession Variables Verification:" -ForegroundColor White
        
        foreach ($varName in $result.VariableNames) {
            $sessionValue = [Environment]::GetEnvironmentVariable($varName)
            if ($sessionValue) {
                Write-Host "  $varName`: OK (Length: $($sessionValue.Length) chars)" -ForegroundColor Green
            } else {
                Write-Host "  $varName`: NOT SET" -ForegroundColor Red
            }
        }
        
        # Check persistent variables (if not session-only)
        if (-not $SessionOnly) {
            Write-Host "`nPersistent Variables Verification:" -ForegroundColor White
            
            foreach ($varName in $result.VariableNames) {
                $persistentValue = [Environment]::GetEnvironmentVariable($varName, "User")
                if ($persistentValue) {
                    Write-Host "  $varName (persistent): OK (Length: $($persistentValue.Length) chars)" -ForegroundColor Green
                } else {
                    Write-Host "  $varName (persistent): NOT SET" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host "`n✅ Environment variables loaded successfully!" -ForegroundColor Green
    
    if (-not $SessionOnly) {
        Write-Host "Note: You may need to restart applications to see persistent changes." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "`n❌ Error loading environment variables: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure the .env file exists and has the correct format." -ForegroundColor Yellow
    exit 1
}