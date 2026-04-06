# nt-cli

CLI oficial do ecossistema Nortlin para gerenciamento de pacotes.

## Instalação Rápida (One-Liner)

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/nortlin-packages/nt-cli/main/install.ps1 | iex
```

### Linux / macOS
```bash
curl -fsSL https://raw.githubusercontent.com/nortlin-packages/nt-cli/main/install.sh | bash
```

## Desinstalação

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/nortlin-packages/nt-cli/main/uninstall.ps1 | iex
```

### Linux / macOS
```bash
curl -fsSL https://raw.githubusercontent.com/nortlin-packages/nt-cli/main/uninstall.sh | bash
```

## Instalação Manual

### Via npm

```bash
npm install -g nt-cli
```

### Via GitHub

```bash
npm install -g github:nortlin-packages/nt-cli
```

### Desenvolvimento local

```bash
git clone https://github.com/nortlin-packages/nt-cli.git
cd nt-cli
npm install
npm link
```

## Comandos

### `nt install <pacote>[@versao]`

Instala um pacote do GitHub Releases da organização `nortlin-packages`.

```bash
# Instalar versão mais recente
nt install sdk-auth

# Instalar versão específica
nt install sdk-auth@1.0.0
```

### `nt uninstall <pacote>`

Remove um pacote instalado.

```bash
nt uninstall sdk-auth
```

### `nt list`

Lista todos os pacotes instalados com suas versões.

```bash
nt list
```

## Estrutura do Projeto

```
nt-cli/
├── bin/
│   └── nt.js          # Entry point da CLI
├── src/
│   ├── install.js     # Lógica de instalação com progress bar
│   ├── uninstall.js    # Lógica de remoção
│   ├── list.js         # Listagem de pacotes
│   └── utils.js        # Funções utilitárias
└── package.json
```

## Como funciona

1. A CLI busca releases na API do GitHub
2. Baixa o arquivo `.tar.gz` da release
3. Extrai para `node_modules/<pacote>/`
4. Verifica e exibe dependências pendentes

## Requisitos para pacotes

Os pacotes na org `nortlin-packages` devem:

1. Ter releases no formato `vX.Y.Z` (ex: `v1.0.0`)
2. Incluir um asset `.tar.gz` na release
3. Conter `package.json` com `name`, `version` e `dependencies`

## Exemplo de pacote

Estrutura do `.tar.gz`:
```
sdk-auth/
├── package.json
└── dist/
    └── index.js
```

## Progress Bar

A CLI exibe uma única barra de progresso para toda a operação:
- 0-70%: Download do pacote
- 70-100%: Extração do arquivo

## Dependências

- `axios`: HTTP client para downloads
- `cli-progress`: Barra de progresso
- `tar`: Extração de arquivos
