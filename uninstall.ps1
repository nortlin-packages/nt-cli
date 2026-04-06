#!/usr/bin/env pwsh
# Uninstall script for nt-cli
# Usage: irm https://raw.githubusercontent.com/nortlin-packages/nt-cli/main/uninstall.ps1 | iex

$ErrorActionPreference = "Stop"

$InstallDir = "$env:USERPROFILE\.nt"
$BinDir = "$InstallDir\bin"

function Write-Info($msg) {
    Write-Host $msg
}

function Write-Error($msg) {
    Write-Host "ERRO: $msg" -ForegroundColor Red
}

function Write-Success($msg) {
    Write-Host $msg
}

Write-Info "Desinstalador nt-cli"
Write-Info "===================="
Write-Info ""

# Check if installed
if (-not (Test-Path $InstallDir)) {
    Write-Error "nt-cli nao esta instalado"
    exit 1
}

# Remove from PATH
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($CurrentPath -like "*$BinDir*") {
    Write-Info "Removendo do PATH..."
    $NewPath = ($CurrentPath -split ';' | Where-Object { $_ -ne $BinDir }) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    Write-Info "PATH atualizado"
}

# Remove installation directory
Write-Info "Removendo arquivos..."
if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
}

Write-Info ""
Write-Success "nt-cli desinstalado com sucesso!"
Write-Info ""
Write-Info "Reinicie o terminal para completar a desinstalação"
