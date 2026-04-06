#!/bin/bash
# Install script for nt-cli
# Usage: curl -fsSL https://raw.githubusercontent.com/nortlin-packages/nt-cli/main/install.sh | bash

set -e

REPO="nortlin-packages/nt-cli"
INSTALL_DIR="$HOME/.nt"
BIN_DIR="$INSTALL_DIR/bin"
TEMP_DIR="/tmp/nt-install-$$"

info() {
    echo "$1"
}

error() {
    echo "ERRO: $1" >&2
}

success() {
    echo "$1"
}

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="x64" ;;
    amd64) ARCH="x64" ;;
    arm64) ARCH="arm64" ;;
    aarch64) ARCH="arm64" ;;
    *) ARCH="x64" ;;
esac

# Detect platform
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
case $PLATFORM in
    linux) PLATFORM="linux" ;;
    darwin) PLATFORM="macos" ;;
    *) PLATFORM="linux" ;;
esac

info "Instalador nt-cli"
info "=================="
info ""
info "Plataforma detectada: $PLATFORM"
info ""

# Create directories
mkdir -p "$BIN_DIR"
mkdir -p "$TEMP_DIR"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Download latest release
info "Buscando ultima versao..."

API_URL="https://api.github.com/repos/$REPO/releases/latest"
VERSION=$(curl -fsSL -H "User-Agent: nt-installer" "$API_URL" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    error "Nao foi possivel determinar a versao"
    exit 1
fi

info "Versao encontrada: $VERSION"

# Download executable
info "Baixando $VERSION..."
ASSET_NAME="nt-$PLATFORM-x64"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$ASSET_NAME"

if command -v curl &> /dev/null; then
    curl -fsSL -o "$BIN_DIR/nt" "$DOWNLOAD_URL"
elif command -v wget &> /dev/null; then
    wget -q -O "$BIN_DIR/nt" "$DOWNLOAD_URL"
else
    error "curl ou wget necessarios para download"
    exit 1
fi

# Make executable
chmod +x "$BIN_DIR/nt"

info "Extraindo..."

info ""
success "nt-cli $VERSION instalado com sucesso!"
info ""

# Update PATH if needed
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    info "Adicionando ao PATH..."
    
    # Detect shell
    if [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.profile"
    fi
    
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
    info "PATH atualizado em $SHELL_RC"
    info "Execute 'source $SHELL_RC' ou reinicie o terminal para usar o comando 'nt'."
fi

info ""
info "Uso:"
info "  nt install <pacote>     - Instala um pacote"
info "  nt uninstall <pacote>   - Remove um pacote"
info "  nt list                 - Lista pacotes instalados"
info ""
info "Exemplo:"
info "  nt install sdk-auth"
info ""

# Test installation
if "$BIN_DIR/nt" list &> /dev/null; then
    success "Instalacao verificada com sucesso!"
fi
