#!/bin/bash
# setup.sh - Configuração inicial do sistema de rebranding TQI
# Autor: TQI AI Assistant Automation
# Versão: 1.0.0

set -euo pipefail
IFS=$'\n\t'

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AUTOMATION_DIR="$SCRIPT_DIR"

# Arquivos de log
LOG_DIR="$AUTOMATION_DIR/logs"
SETUP_LOG="$LOG_DIR/setup.log"

# Funções de log
log_info() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$SETUP_LOG"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$SETUP_LOG"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$SETUP_LOG"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$SETUP_LOG"; }
log_header() { echo -e "${PURPLE}[SETUP]${NC} $1" | tee -a "$SETUP_LOG"; }

# Banner de início
show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              TQI AI ASSISTANT - REBRANDING SETUP            ║"
    echo "║                                                              ║"
    echo "║  Sistema de automação para rebrandizar Roo-Code → TQI       ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Verificar se está no diretório correto
check_directory() {
    log_header "Verificando diretório de execução..."
    
    if [ ! -f "$PROJECT_ROOT/package.json" ]; then
        log_error "Projeto Roo-Code não encontrado no diretório pai"
        log_error "Execute este script dentro da pasta tqi-rebranding-automation"
        log_error "que deve estar na raiz do projeto Roo-Code"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_ROOT/src/package.json" ]; then
        log_error "Estrutura do projeto Roo-Code não encontrada"
        log_error "Certifique-se de que está na raiz do projeto correto"
        exit 1
    fi
    
    log_success "Diretório correto confirmado"
}

# Criar estrutura de diretórios
create_directories() {
    log_header "Criando estrutura de diretórios..."
    
    local dirs=(
        "scripts"
        "etapas" 
        "templates/package-json"
        "templates/assets" 
        "templates/configs"
        "backups"
        "logs"
        "temp"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$AUTOMATION_DIR/$dir"
        log_info "Criado: $dir/"
    done
    
    # Criar subdiretórios de backup para cada etapa
    for i in {1..9}; do
        mkdir -p "$AUTOMATION_DIR/backups/etapa$i"
        log_info "Criado: backups/etapa$i/"
    done
    
    mkdir -p "$AUTOMATION_DIR/backups/emergency"
    log_success "Estrutura de diretórios criada"
}

# Verificar pré-requisitos
check_prerequisites() {
    log_header "Verificando pré-requisitos..."
    
    local missing_tools=0
    local tools=(
        "node:Node.js"
        "pnpm:pnpm"
        "git:Git"
        "jq:jq"
        "vsce:VSCode Extension CLI"
    )
    
    for tool_info in "${tools[@]}"; do
        local tool="${tool_info%%:*}"
        local name="${tool_info##*:}"
        
        if command -v "$tool" > /dev/null 2>&1; then
            local version=$($tool --version 2>/dev/null | head -1 || echo "unknown")
            log_success "$name: $version"
        else
            log_error "$name não encontrado"
            ((missing_tools++))
        fi
    done
    
    # Verificações específicas de versão
    if command -v node > /dev/null 2>&1; then
        local node_version=$(node --version | sed 's/v//')
        local major_version=$(echo $node_version | cut -d. -f1)
        
        if [ "$major_version" -ge 16 ]; then
            log_success "Node.js versão OK ($node_version >= 16.0.0)"
        else
            log_error "Node.js versão muito antiga ($node_version < 16.0.0)"
            ((missing_tools++))
        fi
    fi
    
    if [ $missing_tools -gt 0 ]; then
        log_error "$missing_tools ferramenta(s) ausente(s)"
        show_installation_help
        exit 1
    else
        log_success "Todos os pré-requisitos atendidos"
    fi
}

# Mostrar ajuda de instalação
show_installation_help() {
    echo ""
    log_info "Comandos de instalação:"
    echo ""
    echo "Node.js:"
    echo "  - macOS: brew install node"
    echo "  - Linux: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs"
    echo "  - Windows: https://nodejs.org/"
    echo ""
    echo "pnpm:"
    echo "  npm install -g pnpm"
    echo ""
    echo "jq:"
    echo "  - macOS: brew install jq"
    echo "  - Linux: sudo apt-get install jq"
    echo "  - Windows: https://stedolan.github.io/jq/download/"
    echo ""
    echo "VSCode Extension CLI:"
    echo "  npm install -g @vscode/vsce"
    echo ""
}

# Copiar arquivos de configuração
copy_config_files() {
    log_header "Copiando arquivos de configuração..."
    
    # Copiar .gitignore específico para automação
    cat > "$AUTOMATION_DIR/.gitignore" << 'EOF'
# Logs
logs/*.log
temp/
*.tmp

# Backups temporários
backups/temp-*
*.backup.*

# Arquivos sensíveis
config/secrets.*
.env

# Node modules (se houver)
node_modules/
EOF
    
    log_success "Arquivo .gitignore criado"
    
    # Arquivo de configuração principal
    cat > "$AUTOMATION_DIR/config.sh" << 'EOF'
#!/bin/bash
# config.sh - Configurações do sistema de rebranding

# Informações TQI
TQI_NAME="tqi-ai-assistant"
TQI_DISPLAY_NAME="TQI AI Assistant"
TQI_PUBLISHER="TQI"
TQI_VERSION="1.0.0"
TQI_EMAIL="dev-ai@tqi.com.br"
TQI_WEBSITE="https://www.tqi.com.br"
TQI_GITHUB_USER="SeuUsuario"  # ALTERE AQUI
TQI_GITHUB_REPO="tqi-ai-assistant"

# URLs
TQI_REPOSITORY_URL="https://github.com/${TQI_GITHUB_USER}/${TQI_GITHUB_REPO}"
TQI_ISSUES_URL="https://github.com/${TQI_GITHUB_USER}/${TQI_GITHUB_REPO}/issues"
TQI_HOMEPAGE_URL="https://github.com/${TQI_GITHUB_USER}/${TQI_GITHUB_REPO}"

# Configurações de backup
BACKUP_ENABLED=true
BACKUP_COMPRESSION=false
BACKUP_RETENTION_DAYS=30

# Configurações de validação
VALIDATION_STRICT=true
BUILD_AFTER_EACH_STEP=true
TEST_INSTALLATION=true

# Configurações de Git
GIT_AUTO_COMMIT=true
GIT_CREATE_TAGS=true
GIT_CREATE_BRANCHES=true

export TQI_NAME TQI_DISPLAY_NAME TQI_PUBLISHER TQI_VERSION
export TQI_EMAIL TQI_WEBSITE TQI_GITHUB_USER TQI_GITHUB_REPO
export TQI_REPOSITORY_URL TQI_ISSUES_URL TQI_HOMEPAGE_URL
export BACKUP_ENABLED BACKUP_COMPRESSION BACKUP_RETENTION_DAYS
export VALIDATION_STRICT BUILD_AFTER_EACH_STEP TEST_INSTALLATION
export GIT_AUTO_COMMIT GIT_CREATE_TAGS GIT_CREATE_BRANCHES
EOF
    
    chmod +x "$AUTOMATION_DIR/config.sh"
    log_success "Arquivo de configuração criado"
}

# Verificar projeto Roo-Code
validate_roo_project() {
    log_header "Validando projeto Roo-Code..."
    
    local validation_errors=0
    
    # Verificar package.json raiz
    if [ -f "$PROJECT_ROOT/package.json" ]; then
        if grep -q "roo-code" "$PROJECT_ROOT/package.json"; then
            log_success "package.json raiz identificado como Roo-Code"
        else
            log_warning "package.json raiz não contém 'roo-code'"
        fi
    else
        log_error "package.json não encontrado na raiz"
        ((validation_errors++))
    fi
    
    # Verificar src/package.json
    if [ -f "$PROJECT_ROOT/src/package.json" ]; then
        if grep -q "roo-cline" "$PROJECT_ROOT/src/package.json"; then
            log_success "src/package.json identificado como Roo-Code"
        else
            log_warning "src/package.json não contém 'roo-cline'"
        fi
    else
        log_error "src/package.json não encontrado"
        ((validation_errors++))
    fi
    
    # Verificar estrutura de diretórios
    local required_dirs=("src" "packages" "webview-ui")
    for dir in "${required_dirs[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            log_success "Diretório encontrado: $dir/"
        else
            log_error "Diretório ausente: $dir/"
            ((validation_errors++))
        fi
    done
    
    if [ $validation_errors -gt 0 ]; then
        log_error "$validation_errors erro(s) de validação encontrado(s)"
        log_error "Certifique-se de que está executando no projeto Roo-Code correto"
        exit 1
    else
        log_success "Projeto Roo-Code validado com sucesso"
    fi
}

# Criar backup inicial
create_initial_backup() {
    log_header "Criando backup inicial do projeto..."
    
    local backup_dir="$AUTOMATION_DIR/backups/original-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Copiar arquivos principais
    cp -r "$PROJECT_ROOT/src" "$backup_dir/" 2>/dev/null || true
    cp -r "$PROJECT_ROOT/packages" "$backup_dir/" 2>/dev/null || true
    cp -r "$PROJECT_ROOT/webview-ui" "$backup_dir/" 2>/dev/null || true
    cp -r "$PROJECT_ROOT/apps" "$backup_dir/" 2>/dev/null || true
    cp "$PROJECT_ROOT/package.json" "$backup_dir/" 2>/dev/null || true
    cp "$PROJECT_ROOT/README.md" "$backup_dir/" 2>/dev/null || true
    cp "$PROJECT_ROOT/turbo.json" "$backup_dir/" 2>/dev/null || true
    cp "$PROJECT_ROOT/pnpm-workspace.yaml" "$backup_dir/" 2>/dev/null || true
    
    # Criar manifesto do backup
    cat > "$backup_dir/backup-manifest.json" << EOF
{
    "backup_info": {
        "type": "original",
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "created_by": "setup.sh",
        "version": "1.0.0"
    },
    "project_info": {
        "original_name": "roo-code",
        "target_name": "tqi-ai-assistant",
        "backup_reason": "Pre-rebranding safety backup"
    },
    "environment": {
        "hostname": "$(hostname)",
        "user": "$(whoami)",
        "pwd": "$(pwd)",
        "git_branch": "$(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null || echo 'N/A')",
        "git_commit": "$(cd "$PROJECT_ROOT" && git rev-parse HEAD 2>/dev/null || echo 'N/A')"
    }
}
EOF
    
    # Link para último backup
    ln -sfn "$backup_dir" "$AUTOMATION_DIR/backups/original-latest"
    
    log_success "Backup inicial criado: $backup_dir"
}

# Teste de funcionalidade básica
test_basic_functionality() {
    log_header "Testando funcionalidade básica..."
    
    # Testar se consegue fazer build do projeto
    cd "$PROJECT_ROOT"
    
    log_info "Testando instalação de dependências..."
    if pnpm install > /dev/null 2>&1; then
        log_success "pnpm install passou"
    else
        log_warning "pnpm install falhou - pode afetar build"
    fi
    
    log_info "Testando build do projeto..."
    if pnpm build > /dev/null 2>&1; then
        log_success "Build passou - projeto está funcionando"
    else
        log_warning "Build falhou - projeto pode ter problemas"
        log_warning "Isso pode afetar o rebranding"
    fi
    
    cd "$AUTOMATION_DIR"
}

# Finalizar setup
finalize_setup() {
    log_header "Finalizando configuração..."
    
    # Criar arquivo de status
    cat > "$AUTOMATION_DIR/status.json" << EOF
{
    "setup": {
        "completed": true,
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "version": "1.0.0"
    },
    "project": {
        "validated": true,
        "backed_up": true,
        "build_tested": true
    },
    "next_steps": [
        "Execute ./validate-project.sh para validação detalhada",
        "Execute ./start-rebranding.sh para início automático",
        "Ou execute etapas individuais em ./etapas/"
    ]
}
EOF
    
    # Tornar scripts executáveis quando criados
    find "$AUTOMATION_DIR" -name "*.sh" -exec chmod +x {} \;
    
    log_success "Setup concluído com sucesso!"
}

# Mostrar próximos passos
show_next_steps() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    SETUP CONCLUÍDO                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    log_info "🎉 Sistema de rebranding configurado com sucesso!"
    echo ""
    log_info "📋 PRÓXIMOS PASSOS:"
    echo ""
    echo "  1. 🔍 Validação detalhada:"
    echo "     ./validate-project.sh"
    echo ""
    echo "  2. 🚀 Início automático (recomendado):"
    echo "     ./start-rebranding.sh"
    echo ""
    echo "  3. 📝 Execução manual por etapas:"
    echo "     ./etapas/etapa1.sh"
    echo "     ./etapas/etapa2.sh"
    echo "     # ... continue com as demais"
    echo ""
    echo "  4. 📊 Verificar status a qualquer momento:"
    echo "     cat status.json"
    echo ""
    log_info "📁 Logs disponíveis em: logs/"
    log_info "🔧 Configurações em: config.sh"
    log_info "💾 Backup inicial em: backups/original-latest/"
    echo ""
    log_warning "⚠️  IMPORTANTE: Edite config.sh para ajustar TQI_GITHUB_USER"
    echo ""
}

# Função principal
main() {
    show_banner
    
    # Criar diretório de logs primeiro
    mkdir -p "$LOG_DIR"
    
    log_header "Iniciando setup do sistema de rebranding TQI..."
    
    check_directory
    create_directories
    check_prerequisites
    copy_config_files
    validate_roo_project
    create_initial_backup
    test_basic_functionality
    finalize_setup
    show_next_steps
    
    log_success "Setup executado com sucesso em $(date)"
}

# Executar função principal
main "$@" 