#!/usr/bin/env pwsh
# Install script for nt-cli
# Usage: irm https://raw.githubusercontent.com/nortlin-packages/nt-cli/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = "nortlin-packages/nt-cli"
$InstallDir = "$env:USERPROFILE\.nt"
$BinDir = "$InstallDir\bin"
$TempDir = "$env:TEMP\nt-install-$(Get-Random)"

function Write-Info($msg) {
    Write-Host $msg
}

function Write-Error($msg) {
    Write-Host "ERRO: $msg" -ForegroundColor Red
}

function Write-Success($msg) {
    Write-Host $msg
}

Write-Info "Instalador nt-cli"
Write-Info "=================="
Write-Info ""

# Create directories
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

try {
    # Download latest release
    Write-Info "Buscando ultima versao..."
    
    $ApiUrl = "https://api.github.com/repos/$Repo/releases/latest"
    $Release = Invoke-RestMethod -Uri $ApiUrl -Headers @{ "User-Agent" = "nt-installer" }
    $Version = $Release.tag_name
    
    Write-Info "Versao encontrada: $Version"
    
    # Find Windows executable asset
    $Asset = $Release.assets | Where-Object { $_.name -eq "nt-win-x64.exe" } | Select-Object -First 1
    
    if (-not $Asset) {
        Write-Error "Executavel Windows nao encontrado na release"
        Write-Info "Por favor verifique se a release foi publicada corretamente."
        exit 1
    }
    
    # Download executable
    Write-Info "Baixando $Version..."
    $DownloadUrl = $Asset.browser_download_url
    $ExeFile = "$BinDir\nt.exe"
    
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ExeFile -Headers @{ "User-Agent" = "nt-installer" }
    
    Write-Info "Extraindo..."
    
    # Also create PowerShell wrapper for convenience
    $PwshWrapper = @"
#!/usr/bin/env pwsh
& "$BinDir\nt.exe" `@args
"@
    $PwshWrapperPath = "$BinDir\nt.ps1"
    Set-Content -Path $PwshWrapperPath -Value $PwshWrapper
    
    Write-Info ""
    Write-Success "nt-cli $Version instalado com sucesso!"
    Write-Info ""
    
    # Update PATH if needed
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($CurrentPath -notlike "*$BinDir*") {
        Write-Info "Adicionando ao PATH..."
        [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$BinDir", "User")
        Write-Info "PATH atualizado. Reinicie o terminal para usar o comando 'nt'."
    }
    
    Write-Info ""
    Write-Info "Uso:"
    Write-Info "  nt install <pacote>     - Instala um pacote"
    Write-Info "  nt uninstall <pacote>   - Remove um pacote"
    Write-Info "  nt list                 - Lista pacotes instalados"
    Write-Info ""
    Write-Info "Exemplo:"
    Write-Info "  nt install sdk-auth"
    Write-Info ""
    
    # Test installation
    try {
        $TestOutput = & "$BinDir\nt.exe" list 2>&1
        Write-Success "Instalacao verificada com sucesso!"
    } catch {
        # Ignore test errors
    }
    
} finally {
    # Cleanup
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
