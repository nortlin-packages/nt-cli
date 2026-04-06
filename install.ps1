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

# Detect architecture
$Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

# Detect platform
$Platform = "win32"

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
    
    # Find asset
    $Asset = $Release.assets | Where-Object { $_.name -eq "nt-cli-win32-$Arch.tar.gz" -or $_.name -eq "nt-cli.tar.gz" } | Select-Object -First 1
    
    if (-not $Asset) {
        # Fallback: download source and install via node
        Write-Info "Asset nao encontrado. Instalando via node..."
        
        # Check if node is installed
        try {
            $NodeVersion = node --version 2>$null
            Write-Info "Node.js encontrado: $NodeVersion"
        } catch {
            Write-Error "Node.js nao encontrado. Por favor instale o Node.js primeiro:"
            Write-Info "  https://nodejs.org/"
            exit 1
        }
        
        # Clone and install
        Write-Info "Baixando codigo fonte..."
        $ZipUrl = "https://github.com/$Repo/archive/refs/heads/main.zip"
        $ZipFile = "$TempDir\nt-cli.zip"
        
        Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile -Headers @{ "User-Agent" = "nt-installer" }
        
        Write-Info "Extraindo..."
        Expand-Archive -Path $ZipFile -DestinationPath $TempDir -Force
        
        $SourceDir = Get-ChildItem -Path $TempDir -Directory | Where-Object { $_.Name -like "nt-cli*" } | Select-Object -First 1
        
        if (-not $SourceDir) {
            Write-Error "Nao foi possivel encontrar o codigo fonte extraido"
            exit 1
        }
        
        Write-Info "Instalando dependencias..."
        Push-Location $SourceDir.FullName
        try {
            npm install --production 2>&1 | ForEach-Object { Write-Info $_ }
        } finally {
            Pop-Location
        }
        
        Write-Info "Copiando arquivos..."
        Copy-Item -Path "$($SourceDir.FullName)\*" -Destination $InstallDir -Recurse -Force
        
    } else {
        # Download binary release
        Write-Info "Baixando $Version..."
        $DownloadUrl = $Asset.browser_download_url
        $TarFile = "$TempDir\$($Asset.name)"
        
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $TarFile -Headers @{ "User-Agent" = "nt-installer" }
        
        Write-Info "Extraindo..."
        # Use tar if available (Windows 10+), otherwise use alternative
        try {
            tar -xzf $TarFile -C $InstallDir 2>&1 | Out-Null
        } catch {
            # Fallback: use PowerShell Expand-Archive if it's a zip
            if ($TarFile -match '\.zip$') {
                Expand-Archive -Path $TarFile -DestinationPath $InstallDir -Force
            } else {
                Write-Error "Nao foi possivel extrair o arquivo. Instale o tar ou use npm install -g nt-cli"
                exit 1
            }
        }
    }
    
    # Create wrapper script
    $WrapperScript = @"
@echo off
node "$InstallDir\bin\nt.js" %*
"@
    $WrapperPath = "$BinDir\nt.cmd"
    Set-Content -Path $WrapperPath -Value $WrapperScript
    
    # Also create PowerShell wrapper
    $PwshWrapper = @"
#!/usr/bin/env pwsh
node '$InstallDir\bin\nt.js' `@args
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
        $TestOutput = node "$InstallDir\bin\nt.js" --help 2>&1
        if ($LASTEXITCODE -eq 0 -or $TestOutput -match "nt") {
            Write-Success "Instalacao verificada com sucesso!"
        }
    } catch {
        # Ignore test errors
    }
    
} finally {
    # Cleanup
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
