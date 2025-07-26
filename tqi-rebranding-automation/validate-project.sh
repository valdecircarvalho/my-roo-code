#!/bin/bash
# validate-project.sh - Validação Completa do Projeto Roo-Code
# Autor: TQI AI Assistant Automation
# Versão: 1.0.0

set -euo pipefail
IFS=$'\n\t'

# Importar configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Carregar configurações
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
fi

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configurações
LOG_FILE="$SCRIPT_DIR/logs/validation.log"
VALIDATION_REPORT="$SCRIPT_DIR/logs/validation-report.json"

# Funções de log
log_info() { echo -e "${BLUE}[VALIDATE]${NC} $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }
log_header() { echo -e "${PURPLE}[VALIDATE]${NC} $1" | tee -a "$LOG_FILE"; }

# Variáveis de resultado
declare -A VALIDATION_RESULTS
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# Banner
show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║           VALIDAÇÃO COMPLETA DO PROJETO ROO-CODE            ║"
    echo "║                                                              ║"
    echo "║  Verificação de integridade, estrutura e pré-requisitos     ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Função para registrar resultado
record_result() {
    local test_name=$1
    local status=$2
    local details=${3:-""}
    
    ((TOTAL_TESTS++))
    VALIDATION_RESULTS[$test_name]=$status
    
    case $status in
        "PASS")
            ((PASSED_TESTS++))
            log_success "$test_name: PASSOU"
            ;;
        "FAIL")
            ((FAILED_TESTS++))
            log_error "$test_name: FALHOU - $details"
            ;;
        "WARN")
            ((WARNING_TESTS++))
            log_warning "$test_name: AVISO - $details"
            ;;
    esac
}

# Validar estrutura de diretórios
validate_directory_structure() {
    log_header "Validando estrutura de diretórios..."
    
    local required_dirs=(
        "src"
        "packages"
        "webview-ui"
        "apps"
        "packages/cloud"
        "packages/ipc"
        "packages/telemetry"
        "packages/types"
        "src/assets"
        "src/assets/icons"
        "src/shared"
    )
    
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            log_info "✓ $dir/"
        else
            log_warning "✗ $dir/ (ausente)"
            missing_dirs+=("$dir")
        fi
    done
    
    if [ ${#missing_dirs[@]} -eq 0 ]; then
        record_result "Estrutura de Diretórios" "PASS"
    elif [ ${#missing_dirs[@]} -le 2 ]; then
        record_result "Estrutura de Diretórios" "WARN" "${#missing_dirs[@]} diretório(s) ausente(s)"
    else
        record_result "Estrutura de Diretórios" "FAIL" "${#missing_dirs[@]} diretórios críticos ausentes"
    fi
}

# Validar arquivos críticos
validate_critical_files() {
    log_header "Validando arquivos críticos..."
    
    local critical_files=(
        "package.json"
        "src/package.json"
        "src/shared/package.ts"
        "pnpm-workspace.yaml"
        "turbo.json"
        "src/assets/icons/icon.png"
        "src/assets/icons/icon.svg"
    )
    
    local missing_files=()
    
    for file in "${critical_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            log_info "✓ $file"
        else
            log_error "✗ $file (ausente)"
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        record_result "Arquivos Críticos" "PASS"
    else
        record_result "Arquivos Críticos" "FAIL" "${#missing_files[@]} arquivo(s) crítico(s) ausente(s)"
    fi
}

# Validar sintaxe JSON
validate_json_syntax() {
    log_header "Validando sintaxe JSON..."
    
    local json_files=(
        "package.json"
        "src/package.json"
        "turbo.json"
        "pnpm-workspace.yaml"
    )
    
    local invalid_files=()
    
    for file in "${json_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            if jq . "$PROJECT_ROOT/$file" > /dev/null 2>&1; then
                log_info "✓ $file (JSON válido)"
            else
                log_error "✗ $file (JSON inválido)"
                invalid_files+=("$file")
            fi
        fi
    done
    
    if [ ${#invalid_files[@]} -eq 0 ]; then
        record_result "Sintaxe JSON" "PASS"
    else
        record_result "Sintaxe JSON" "FAIL" "${#invalid_files[@]} arquivo(s) com JSON inválido"
    fi
}

# Validar identificadores Roo-Code
validate_roo_identifiers() {
    log_header "Validando identificadores Roo-Code..."
    
    local identifiers_found=0
    
    # Verificar package.json raiz
    if [ -f "$PROJECT_ROOT/package.json" ]; then
        if grep -q "roo-code" "$PROJECT_ROOT/package.json"; then
            log_info "✓ package.json: Contém identificador 'roo-code'"
            ((identifiers_found++))
        else
            log_warning "✗ package.json: Não contém 'roo-code'"
        fi
    fi
    
    # Verificar src/package.json
    if [ -f "$PROJECT_ROOT/src/package.json" ]; then
        if grep -q "roo-cline" "$PROJECT_ROOT/src/package.json"; then
            log_info "✓ src/package.json: Contém identificador 'roo-cline'"
            ((identifiers_found++))
        else
            log_warning "✗ src/package.json: Não contém 'roo-cline'"
        fi
        
        if grep -q "RooVeterinaryInc" "$PROJECT_ROOT/src/package.json"; then
            log_info "✓ src/package.json: Contém publisher 'RooVeterinaryInc'"
            ((identifiers_found++))
        else
            log_warning "✗ src/package.json: Não contém 'RooVeterinaryInc'"
        fi
    fi
    
    # Verificar package.ts
    if [ -f "$PROJECT_ROOT/src/shared/package.ts" ]; then
        if grep -q "Roo-Code" "$PROJECT_ROOT/src/shared/package.ts"; then
            log_info "✓ package.ts: Contém identificador 'Roo-Code'"
            ((identifiers_found++))
        else
            log_warning "✗ package.ts: Não contém 'Roo-Code'"
        fi
    fi
    
    if [ $identifiers_found -ge 3 ]; then
        record_result "Identificadores Roo-Code" "PASS"
    elif [ $identifiers_found -ge 1 ]; then
        record_result "Identificadores Roo-Code" "WARN" "Alguns identificadores podem estar ausentes"
    else
        record_result "Identificadores Roo-Code" "FAIL" "Projeto não parece ser Roo-Code original"
    fi
}

# Validar dependências do projeto
validate_project_dependencies() {
    log_header "Validando dependências do projeto..."
    
    cd "$PROJECT_ROOT"
    
    # Verificar se node_modules existe
    if [ -d "node_modules" ]; then
        log_info "✓ node_modules/ existe"
        
        # Verificar algumas dependências críticas
        local critical_deps=("typescript" "vscode" "@types/node")
        local missing_deps=()
        
        for dep in "${critical_deps[@]}"; do
            if [ -d "node_modules/$dep" ] || [ -d "node_modules/@types/$dep" ]; then
                log_info "✓ Dependência: $dep"
            else
                log_warning "✗ Dependência ausente: $dep"
                missing_deps+=("$dep")
            fi
        done
        
        if [ ${#missing_deps[@]} -eq 0 ]; then
            record_result "Dependências do Projeto" "PASS"
        else
            record_result "Dependências do Projeto" "WARN" "${#missing_deps[@]} dependência(s) ausente(s)"
        fi
    else
        log_warning "node_modules/ não existe - execute 'pnpm install'"
        record_result "Dependências do Projeto" "WARN" "Dependências não instaladas"
    fi
    
    cd "$SCRIPT_DIR"
}

# Validar workspace monorepo
validate_workspace() {
    log_header "Validando configuração do workspace..."
    
    # Verificar pnpm-workspace.yaml
    if [ -f "$PROJECT_ROOT/pnpm-workspace.yaml" ]; then
        log_info "✓ pnpm-workspace.yaml existe"
        
        # Verificar se contém os pacotes esperados
        local expected_packages=("packages/*" "apps/*" "src" "webview-ui")
        local found_packages=0
        
        for pkg in "${expected_packages[@]}"; do
            if grep -q "$pkg" "$PROJECT_ROOT/pnpm-workspace.yaml"; then
                log_info "✓ Workspace inclui: $pkg"
                ((found_packages++))
            else
                log_warning "✗ Workspace não inclui: $pkg"
            fi
        done
        
        if [ $found_packages -eq ${#expected_packages[@]} ]; then
            record_result "Configuração Workspace" "PASS"
        else
            record_result "Configuração Workspace" "WARN" "Configuração incompleta"
        fi
    else
        record_result "Configuração Workspace" "FAIL" "pnpm-workspace.yaml ausente"
    fi
}

# Testar build do projeto
test_project_build() {
    log_header "Testando build do projeto..."
    
    cd "$PROJECT_ROOT"
    
    # Verificar se pnpm está disponível
    if ! command -v pnpm > /dev/null 2>&1; then
        record_result "Build do Projeto" "FAIL" "pnpm não encontrado"
        cd "$SCRIPT_DIR"
        return
    fi
    
    # Instalar dependências se necessário
    if [ ! -d "node_modules" ]; then
        log_info "Instalando dependências..."
        if pnpm install > /dev/null 2>&1; then
            log_info "✓ Dependências instaladas"
        else
            record_result "Build do Projeto" "FAIL" "Falha na instalação de dependências"
            cd "$SCRIPT_DIR"
            return
        fi
    fi
    
    # Testar build
    log_info "Executando build..."
    if pnpm build > /dev/null 2>&1; then
        log_info "✓ Build passou"
        record_result "Build do Projeto" "PASS"
    else
        log_error "✗ Build falhou"
        record_result "Build do Projeto" "FAIL" "Erro durante build"
    fi
    
    cd "$SCRIPT_DIR"
}

# Validar Git status
validate_git_status() {
    log_header "Validando status do Git..."
    
    cd "$PROJECT_ROOT"
    
    if git rev-parse --git-dir > /dev/null 2>&1; then
        log_info "✓ É um repositório Git"
        
        # Verificar branch atual
        local current_branch=$(git branch --show-current 2>/dev/null || echo "N/A")
        log_info "Branch atual: $current_branch"
        
        # Verificar mudanças não commitadas
        local uncommitted=$(git status --porcelain | wc -l)
        if [ "$uncommitted" -eq 0 ]; then
            log_info "✓ Nenhuma mudança não commitada"
            record_result "Status Git" "PASS"
        else
            log_warning "⚠ $uncommitted arquivo(s) com mudanças não commitadas"
            record_result "Status Git" "WARN" "$uncommitted arquivo(s) modificado(s)"
        fi
        
        # Verificar histórico
        local commit_count=$(git rev-list --count HEAD 2>/dev/null || echo 0)
        log_info "Commits no histórico: $commit_count"
    else
        record_result "Status Git" "WARN" "Não é um repositório Git"
    fi
    
    cd "$SCRIPT_DIR"
}

# Validar ferramentas necessárias
validate_required_tools() {
    log_header "Validando ferramentas necessárias..."
    
    local required_tools=(
        "node:Node.js"
        "pnpm:pnpm"
        "git:Git"
        "jq:jq"
        "vsce:VSCode Extension CLI"
    )
    
    local missing_tools=()
    
    for tool_info in "${required_tools[@]}"; do
        local tool="${tool_info%%:*}"
        local name="${tool_info##*:}"
        
        if command -v "$tool" > /dev/null 2>&1; then
            local version=$($tool --version 2>/dev/null | head -1 || echo "unknown")
            log_info "✓ $name: $version"
        else
            log_error "✗ $name: Não encontrado"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -eq 0 ]; then
        record_result "Ferramentas Necessárias" "PASS"
    else
        record_result "Ferramentas Necessárias" "FAIL" "${#missing_tools[@]} ferramenta(s) ausente(s)"
    fi
}

# Validar versões das ferramentas
validate_tool_versions() {
    log_header "Validando versões das ferramentas..."
    
    local version_issues=0
    
    # Verificar Node.js
    if command -v node > /dev/null 2>&1; then
        local node_version=$(node --version | sed 's/v//')
        local major_version=$(echo $node_version | cut -d. -f1)
        
        if [ "$major_version" -ge 16 ]; then
            log_info "✓ Node.js $node_version (>= 16.0.0)"
        else
            log_error "✗ Node.js $node_version (requer >= 16.0.0)"
            ((version_issues++))
        fi
    fi
    
    # Verificar Git
    if command -v git > /dev/null 2>&1; then
        local git_version=$(git --version | awk '{print $3}')
        local git_major=$(echo $git_version | cut -d. -f1)
        local git_minor=$(echo $git_version | cut -d. -f2)
        
        if [ "$git_major" -gt 2 ] || ([ "$git_major" -eq 2 ] && [ "$git_minor" -ge 20 ]); then
            log_info "✓ Git $git_version (>= 2.20.0)"
        else
            log_warning "⚠ Git $git_version (recomenda >= 2.20.0)"
        fi
    fi
    
    if [ $version_issues -eq 0 ]; then
        record_result "Versões das Ferramentas" "PASS"
    else
        record_result "Versões das Ferramentas" "FAIL" "$version_issues problema(s) de versão"
    fi
}

# Verificar compatibilidade do sistema
validate_system_compatibility() {
    log_header "Validando compatibilidade do sistema..."
    
    local os_name=$(uname -s)
    local os_issues=0
    
    case $os_name in
        "Darwin")
            log_info "✓ Sistema: macOS"
            local os_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
            log_info "Versão: $os_version"
            ;;
        "Linux")
            log_info "✓ Sistema: Linux"
            local distro=$(lsb_release -d 2>/dev/null | cut -f2 || echo "unknown")
            log_info "Distribuição: $distro"
            ;;
        "MINGW"*|"CYGWIN"*|"MSYS"*)
            log_info "✓ Sistema: Windows"
            ;;
        *)
            log_warning "⚠ Sistema não testado: $os_name"
            ((os_issues++))
            ;;
    esac
    
    # Verificar encoding
    if [[ "${LANG:-}" == *"UTF-8"* ]] || [[ "${LC_ALL:-}" == *"UTF-8"* ]]; then
        log_info "✓ Encoding: UTF-8"
    else
        log_warning "⚠ Encoding pode não ser UTF-8"
        ((os_issues++))
    fi
    
    if [ $os_issues -eq 0 ]; then
        record_result "Compatibilidade Sistema" "PASS"
    else
        record_result "Compatibilidade Sistema" "WARN" "$os_issues possível(is) problema(s)"
    fi
}

# Gerar relatório final
generate_report() {
    log_header "Gerando relatório de validação..."
    
    # Criar relatório JSON
    cat > "$VALIDATION_REPORT" << EOF
{
    "validation": {
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "project_root": "$PROJECT_ROOT",
        "automation_dir": "$SCRIPT_DIR"
    },
    "summary": {
        "total_tests": $TOTAL_TESTS,
        "passed": $PASSED_TESTS,
        "failed": $FAILED_TESTS,
        "warnings": $WARNING_TESTS,
        "success_rate": $(( PASSED_TESTS * 100 / TOTAL_TESTS ))
    },
    "results": {
EOF
    
    # Adicionar resultados individuais
    local first=true
    for test in "${!VALIDATION_RESULTS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$VALIDATION_REPORT"
        fi
        echo "        \"$test\": \"${VALIDATION_RESULTS[$test]}\"" >> "$VALIDATION_REPORT"
    done
    
    cat >> "$VALIDATION_REPORT" << EOF
    },
    "recommendations": [
EOF
    
    # Adicionar recomendações baseadas nos resultados
    local recommendations=()
    
    if [ "${VALIDATION_RESULTS[Ferramentas Necessárias]:-}" = "FAIL" ]; then
        recommendations+=("\"Instale as ferramentas necessárias antes de continuar\"")
    fi
    
    if [ "${VALIDATION_RESULTS[Build do Projeto]:-}" = "FAIL" ]; then
        recommendations+=("\"Corrija os problemas de build antes do rebranding\"")
    fi
    
    if [ "${VALIDATION_RESULTS[Arquivos Críticos]:-}" = "FAIL" ]; then
        recommendations+=("\"Verifique se está executando no projeto Roo-Code correto\"")
    fi
    
    if [ "${VALIDATION_RESULTS[Status Git]:-}" = "WARN" ]; then
        recommendations+=("\"Considere commitar as mudanças antes do rebranding\"")
    fi
    
    if [ ${#recommendations[@]} -eq 0 ]; then
        recommendations+=("\"Projeto validado com sucesso - pronto para rebranding\"")
    fi
    
    # Escrever recomendações
    for i in "${!recommendations[@]}"; do
        if [ $i -gt 0 ]; then
            echo "," >> "$VALIDATION_REPORT"
        fi
        echo "        ${recommendations[$i]}" >> "$VALIDATION_REPORT"
    done
    
    cat >> "$VALIDATION_REPORT" << EOF
    ]
}
EOF
    
    log_success "Relatório gerado: $VALIDATION_REPORT"
}

# Mostrar sumário final
show_summary() {
    local success_rate=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
    
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    RELATÓRIO DE VALIDAÇÃO                    ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo "📊 ESTATÍSTICAS:"
    echo "   Total de testes: $TOTAL_TESTS"
    echo "   Passaram: $PASSED_TESTS"
    echo "   Falharam: $FAILED_TESTS"
    echo "   Avisos: $WARNING_TESTS"
    echo "   Taxa de sucesso: $success_rate%"
    echo ""
    
    # Status geral
    if [ $FAILED_TESTS -eq 0 ]; then
        if [ $WARNING_TESTS -eq 0 ]; then
            echo -e "${GREEN}✅ VALIDAÇÃO COMPLETA - Projeto pronto para rebranding${NC}"
            echo ""
            echo "🚀 PRÓXIMOS PASSOS:"
            echo "   1. Execute: ./start-rebranding.sh"
            echo "   2. Ou: ./start-rebranding.sh --auto (modo automático)"
        else
            echo -e "${YELLOW}⚠️  VALIDAÇÃO COM AVISOS - Projeto pode ser usado com cuidado${NC}"
            echo ""
            echo "💡 RECOMENDAÇÕES:"
            echo "   1. Revise os avisos acima"
            echo "   2. Considere resolver problemas não críticos"
            echo "   3. Execute: ./start-rebranding.sh (modo interativo recomendado)"
        fi
    else
        echo -e "${RED}❌ VALIDAÇÃO FALHOU - Problemas críticos encontrados${NC}"
        echo ""
        echo "🔧 AÇÕES NECESSÁRIAS:"
        echo "   1. Resolva os problemas marcados como FALHOU"
        echo "   2. Execute ./validate-project.sh novamente"
        echo "   3. NÃO prossiga com o rebranding até resolver tudo"
    fi
    
    echo ""
    echo "📄 Relatório detalhado: $VALIDATION_REPORT"
    echo "📝 Log completo: $LOG_FILE"
    echo ""
}

# Função principal
main() {
    # Criar diretório de logs se não existir
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Mostrar banner
    show_banner
    
    log_header "Iniciando validação completa do projeto..."
    
    # Executar todas as validações
    validate_directory_structure
    validate_critical_files
    validate_json_syntax
    validate_roo_identifiers
    validate_required_tools
    validate_tool_versions
    validate_system_compatibility
    validate_workspace
    validate_project_dependencies
    validate_git_status
    test_project_build
    
    # Gerar relatório e mostrar sumário
    generate_report
    show_summary
    
    # Exit code baseado nos resultados
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "Validação concluída com sucesso"
        exit 0
    else
        log_error "Validação falhou com $FAILED_TESTS problema(s) crítico(s)"
        exit 1
    fi
}

# Executar função principal
main "$@" 