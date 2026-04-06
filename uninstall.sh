#!/bin/bash
# Uninstall script for nt-cli
# Usage: curl -fsSL https://raw.githubusercontent.com/nortlin-packages/nt-cli/main/uninstall.sh | bash

set -e

INSTALL_DIR="$HOME/.nt"
BIN_DIR="$INSTALL_DIR/bin"

info() {
    echo "$1"
}

error() {
    echo "ERRO: $1" >&2
}

success() {
    echo "$1"
}

info "Desinstalador nt-cli"
info "===================="
info ""

# Check if installed
if [ ! -d "$INSTALL_DIR" ]; then
    error "nt-cli nao esta instalado"
    exit 1
fi

# Remove from PATH
if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
    info "Removendo do PATH..."
    
    # Detect shell
    if [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.profile"
    fi
    
    # Remove PATH line from shell rc
    if [ -f "$SHELL_RC" ]; then
        sed -i '/\.nt\/bin/d' "$SHELL_RC" 2>/dev/null || true
        info "PATH removido de $SHELL_RC"
    fi
fi

# Remove installation directory
info "Removendo arquivos..."
rm -rf "$INSTALL_DIR"

info ""
success "nt-cli desinstalado com sucesso!"
info ""
info "Execute 'source $SHELL_RC' ou reinicie o terminal para completar"
