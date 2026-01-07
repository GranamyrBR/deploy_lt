# PowerShell Environment Setup Script - English Language Configuration
# This script configures PowerShell and development tools to use English language

Write-Host "Configuring PowerShell environment for English language..." -ForegroundColor Green

# Set locale and language environment variables
$env:LANG = 'en_US.UTF-8'
$env:LC_ALL = 'en_US.UTF-8'
$env:POWERSHELL_TELEMETRY_OPTOUT = '1'
$env:DOTNET_CLI_UI_LANGUAGE = 'en'
$env:FLUTTER_LOCALE = 'en'

# Set permanent user environment variables
[Environment]::SetEnvironmentVariable('LANG', 'en_US.UTF-8', 'User')
[Environment]::SetEnvironmentVariable('LC_ALL', 'en_US.UTF-8', 'User')
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'User')
[Environment]::SetEnvironmentVariable('DOTNET_CLI_UI_LANGUAGE', 'en', 'User')
[Environment]::SetEnvironmentVariable('FLUTTER_LOCALE', 'en', 'User')

Write-Host "Environment variables configured:" -ForegroundColor Yellow
Write-Host "  LANG: $env:LANG" -ForegroundColor Cyan
Write-Host "  LC_ALL: $env:LC_ALL" -ForegroundColor Cyan
Write-Host "  DOTNET_CLI_UI_LANGUAGE: $env:DOTNET_CLI_UI_LANGUAGE" -ForegroundColor Cyan
Write-Host "  FLUTTER_LOCALE: $env:FLUTTER_LOCALE" -ForegroundColor Cyan
Write-Host "  POWERSHELL_TELEMETRY_OPTOUT: $env:POWERSHELL_TELEMETRY_OPTOUT" -ForegroundColor Cyan

# Test Flutter configuration
Write-Host "\nTesting Flutter configuration..." -ForegroundColor Green
flutter --version

Write-Host "\nEnvironment setup completed successfully!" -ForegroundColor Green
Write-Host "All development tools are now configured to use English language." -ForegroundColor Yellow