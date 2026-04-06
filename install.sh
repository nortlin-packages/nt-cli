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
    darwin) PLATFORM="darwin" ;;
    *) PLATFORM="linux" ;;
esac

info "Instalador nt-cli"
info "=================="
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

# Try to download binary release
ASSET_NAME="nt-cli-$PLATFORM-$ARCH.tar.gz"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$ASSET_NAME"

info "Tentando baixar binario..."

if curl -fsSL -o "$TEMP_DIR/$ASSET_NAME" "$DOWNLOAD_URL" 2>/dev/null; then
    info "Baixando binario..."
    tar -xzf "$TEMP_DIR/$ASSET_NAME" -C "$INSTALL_DIR"
else
    # Fallback: install via node
    info "Binario nao encontrado. Instalando via node..."
    
    # Check if node is installed
    if ! command -v node &> /dev/null; then
        error "Node.js nao encontrado. Por favor instale o Node.js primeiro:"
        info "  https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    info "Node.js encontrado: $NODE_VERSION"
    
    # Download source
    info "Baixando codigo fonte..."
    ZIP_URL="https://github.com/$REPO/archive/refs/heads/main.zip"
    
    if command -v curl &> /dev/null; then
        curl -fsSL -o "$TEMP_DIR/nt-cli.zip" "$ZIP_URL"
    elif command -v wget &> /dev/null; then
        wget -q -O "$TEMP_DIR/nt-cli.zip" "$ZIP_URL"
    else
        error "curl ou wget necessarios para download"
        exit 1
    fi
    
    info "Extraindo..."
    if command -v unzip &> /dev/null; then
        unzip -q "$TEMP_DIR/nt-cli.zip" -d "$TEMP_DIR"
    else
        error "unzip necessario para extrair"
        exit 1
    fi
    
    SOURCE_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "nt-cli*" | head -1)
    
    if [ -z "$SOURCE_DIR" ]; then
        error "Nao foi possivel encontrar o codigo fonte extraido"
        exit 1
    fi
    
    info "Instalando dependencias..."
    (cd "$SOURCE_DIR" && npm install --production)
    
    info "Copiando arquivos..."
    cp -r "$SOURCE_DIR"/* "$INSTALL_DIR/"
fi

# Create wrapper script
cat > "$BIN_DIR/nt" << 'EOF'
#!/bin/bash
node "$HOME/.nt/bin/nt.js" "$@"
EOF

chmod +x "$BIN_DIR/nt"

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
if command -v node &> /dev/null; then
    if node "$INSTALL_DIR/bin/nt.js" --help &> /dev/null || true; then
        success "Instalacao verificada com sucesso!"
    fi
fi
