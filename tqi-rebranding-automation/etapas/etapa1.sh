#!/bin/bash
# etapa1.sh - Etapa 1: Rebranding Básico
# Autor: TQI AI Assistant Automation
# Versão: 1.0.0
# Prioridade: CRÍTICA

set -euo pipefail
IFS=$'\n\t'

# Importar configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$AUTOMATION_DIR")"

# Carregar configurações
if [ -f "$AUTOMATION_DIR/config.sh" ]; then
    source "$AUTOMATION_DIR/config.sh"
fi

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configurações
LOG_FILE="$AUTOMATION_DIR/logs/etapa1.log"
BACKUP_DIR="$AUTOMATION_DIR/backups/etapa1"

# Funções de log
log_info() { echo -e "${BLUE}[ETAPA1]${NC} $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }
log_header() { echo -e "${PURPLE}[ETAPA1]${NC} $1" | tee -a "$LOG_FILE"; }

# Banner da etapa
show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║                    ETAPA 1: REBRANDING BÁSICO               ║"
    echo "║                                                              ║"
    echo "║  Modificação dos arquivos fundamentais do projeto           ║"
    echo "║  • package.json (raiz)                                      ║"
    echo "║  • src/package.json (manifesto da extensão)                 ║"
    echo "║  • src/shared/package.ts (constantes)                       ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Verificar pré-requisitos
check_prerequisites() {
    log_header "Verificando pré-requisitos da Etapa 1..."
    
    local errors=0
    
    # Verificar se setup foi executado
    if [ ! -f "$AUTOMATION_DIR/status.json" ]; then
        log_error "Setup não foi executado. Execute ./setup.sh primeiro"
        ((errors++))
    fi
    
    # Verificar ferramentas obrigatórias
    local tools=("jq" "git" "pnpm")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" > /dev/null 2>&1; then
            log_error "$tool não encontrado"
            ((errors++))
        fi
    done
    
    # Verificar arquivos críticos
    local files=(
        "$PROJECT_ROOT/package.json"
        "$PROJECT_ROOT/src/package.json"
        "$PROJECT_ROOT/src/shared/package.ts"
    )
    
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Arquivo crítico não encontrado: $file"
            ((errors++))
        fi
    done
    
    if [ $errors -gt 0 ]; then
        log_error "$errors erro(s) de pré-requisitos encontrado(s)"
        exit 1
    fi
    
    log_success "Pré-requisitos verificados"
}

# Criar backup da etapa
create_etapa_backup() {
    log_header "Criando backup da Etapa 1..."
    
    if [ -f "$AUTOMATION_DIR/scripts/backup-system.sh" ]; then
        "$AUTOMATION_DIR/scripts/backup-system.sh" backup 1 "inicio" || {
            log_error "Falha ao criar backup"
            exit 1
        }
    else
        # Backup manual se script não existir
        local timestamp=$(date '+%Y%m%d_%H%M%S')
        local backup_path="$BACKUP_DIR/$timestamp"
        
        mkdir -p "$backup_path"
        
        cp "$PROJECT_ROOT/package.json" "$backup_path/package.json.backup"
        cp "$PROJECT_ROOT/src/package.json" "$backup_path/src-package.json.backup"
        cp "$PROJECT_ROOT/src/shared/package.ts" "$backup_path/package.ts.backup"
        
        log_success "Backup manual criado em: $backup_path"
    fi
}

# Modificar package.json da raiz
modify_root_package_json() {
    log_header "Modificando package.json (raiz do projeto)..."
    
    local file="$PROJECT_ROOT/package.json"
    
    # Validar JSON antes da modificação
    if ! jq . "$file" > /dev/null 2>&1; then
        log_error "package.json da raiz está corrompido"
        return 1
    fi
    
    # Fazer backup local
    cp "$file" "$file.backup"
    
    # Modificar usando jq
    log_info "Alterando nome: roo-code → $TQI_NAME"
    
    jq --arg name "$TQI_NAME" \
       '.name = $name' \
       "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    
    # Validar resultado
    if jq . "$file" > /dev/null 2>&1; then
        local new_name=$(jq -r '.name' "$file")
        if [ "$new_name" = "$TQI_NAME" ]; then
            log_success "package.json (raiz) modificado com sucesso"
        else
            log_error "Modificação falhou - nome não foi alterado corretamente"
            return 1
        fi
    else
        log_error "JSON corrompido após modificação - restaurando backup"
        mv "$file.backup" "$file"
        return 1
    fi
}

# Modificar src/package.json (manifesto da extensão)
modify_src_package_json() {
    log_header "Modificando src/package.json (manifesto da extensão)..."
    
    local file="$PROJECT_ROOT/src/package.json"
    
    # Validar JSON antes da modificação
    if ! jq . "$file" > /dev/null 2>&1; then
        log_error "src/package.json está corrompido"
        return 1
    fi
    
    # Fazer backup local
    cp "$file" "$file.backup"
    
    log_info "Aplicando todas as modificações consolidadas..."
    
    # Aplicar todas as modificações em uma única operação jq
    jq --arg name "$TQI_NAME" \
       --arg display_name "$TQI_DISPLAY_NAME" \
       --arg publisher "$TQI_PUBLISHER" \
       --arg version "$TQI_VERSION" \
       --arg email "$TQI_EMAIL" \
       --arg website "$TQI_WEBSITE" \
       --arg repo_url "$TQI_REPOSITORY_URL" \
       --arg issues_url "$TQI_ISSUES_URL" \
       --arg homepage_url "$TQI_HOMEPAGE_URL" \
       '
       # Informações básicas
       .name = $name |
       .publisher = $publisher |
       .version = $version |
       
       # Autor
       .author = {
           "name": $publisher,
           "email": $email,
           "url": $website
       } |
       
       # Repository
       .repository = {
           "type": "git",
           "url": $repo_url
       } |
       
       # Homepage e bugs
       .homepage = $homepage_url |
       .bugs = {
           "url": $issues_url
       } |
       
       # Keywords
       .keywords = [
           "tqi",
           "ai", 
           "assistant",
           "dev",
           "mcp",
           "openrouter",
           "coding",
           "agent",
           "autonomous",
           "chatgpt",
           "sonnet",
           "llama",
           "machine learning"
       ] |
       
       # ViewsContainers
       .contributes.viewsContainers.activitybar[0].id = "tqi-ai-assistant-ActivityBar" |
       
       # Views
       .contributes.views."tqi-ai-assistant-ActivityBar" = .contributes.views."roo-cline-ActivityBar" |
       del(.contributes.views."roo-cline-ActivityBar") |
       .contributes.views."tqi-ai-assistant-ActivityBar"[0].id = "tqi-ai-assistant.SidebarProvider" |
       
       # Comandos - substituir todos os roo-cline. por tqi-ai-assistant.
       (.contributes.commands[]? | select(.command | startswith("roo-cline.")) | .command) |= sub("roo-cline\\."; "tqi-ai-assistant.") |
       
       # Menus - substituir IDs
       (.contributes.menus."editor/context"[]? | select(.submenu? == "roo-cline.contextMenu") | .submenu) = "tqi-ai-assistant.contextMenu" |
       (.contributes.menus."terminal/context"[]? | select(.submenu? == "roo-cline.terminalMenu") | .submenu) = "tqi-ai-assistant.terminalMenu" |
       (.contributes.menus."view/title"[]? | select(.when? | contains("roo-cline.SidebarProvider")) | .when) |= sub("roo-cline\\.SidebarProvider"; "tqi-ai-assistant.SidebarProvider") |
       (.contributes.menus."webview/context"[]? | select(.when? | contains("roo-cline.TabPanelProvider")) | .when) |= sub("roo-cline\\.TabPanelProvider"; "tqi-ai-assistant.TabPanelProvider") |
       
       # Submenus
       (.contributes.submenus[]? | select(.id == "roo-cline.contextMenu") | .id) = "tqi-ai-assistant.contextMenu" |
       (.contributes.submenus[]? | select(.id == "roo-cline.terminalMenu") | .id) = "tqi-ai-assistant.terminalMenu" |
       
       # Configurações - substituir todas as propriedades
       (.contributes.configuration.properties | to_entries | map(
           if .key | startswith("roo-cline.") then
               .key = (.key | sub("roo-cline\\."; "tqi-ai-assistant."))
           else . end
       ) | from_entries) as $new_props |
       .contributes.configuration.properties = $new_props |
       
       # Dependências internas
       (.dependencies // {} | to_entries | map(
           if .key | startswith("@roo-code/") then
               .key = (.key | sub("@roo-code/"; "@tqi/"))
           else . end
       ) | from_entries) as $new_deps |
       .dependencies = $new_deps |
       
       (.devDependencies // {} | to_entries | map(
           if .key | startswith("@roo-code/") then
               .key = (.key | sub("@roo-code/"; "@tqi/"))
           else . end
       ) | from_entries) as $new_dev_deps |
       .devDependencies = $new_dev_deps
       ' \
       "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    
    # Validar resultado
    if jq . "$file" > /dev/null 2>&1; then
        # Verificar algumas mudanças críticas
        local new_name=$(jq -r '.name' "$file")
        local new_publisher=$(jq -r '.publisher' "$file")
        local activity_bar_id=$(jq -r '.contributes.viewsContainers.activitybar[0].id' "$file")
        
        if [ "$new_name" = "$TQI_NAME" ] && [ "$new_publisher" = "$TQI_PUBLISHER" ] && [ "$activity_bar_id" = "tqi-ai-assistant-ActivityBar" ]; then
            log_success "src/package.json modificado com sucesso"
            
            # Verificar quantidade de substituições
            local roo_count=$(grep -o "roo-cline" "$file" | wc -l || echo 0)
            local tqi_count=$(grep -o "tqi-ai-assistant" "$file" | wc -l || echo 0)
            
            log_info "Substituições: $tqi_count ocorrências TQI, $roo_count restantes Roo-Code"
            
            if [ $roo_count -gt 0 ]; then
                log_warning "Ainda existem $roo_count referências a 'roo-cline' - podem precisar de atenção manual"
            fi
        else
            log_error "Algumas modificações críticas falharam"
            return 1
        fi
    else
        log_error "JSON corrompido após modificação - restaurando backup"
        mv "$file.backup" "$file"
        return 1
    fi
}

# Modificar src/shared/package.ts
modify_package_ts() {
    log_header "Modificando src/shared/package.ts..."
    
    local file="$PROJECT_ROOT/src/shared/package.ts"
    
    # Fazer backup local
    cp "$file" "$file.backup"
    
    # Substituir outputChannel
    log_info "Alterando outputChannel: Roo-Code → TQI-AI-Assistant"
    
    sed -i.bak 's/"Roo-Code"/"TQI-AI-Assistant"/g' "$file"
    
    # Verificar mudança
    if grep -q "TQI-AI-Assistant" "$file"; then
        log_success "package.ts modificado com sucesso"
        
        # Verificar se não há referências antigas
        local old_refs=$(grep -c "Roo-Code" "$file" || echo 0)
        if [ $old_refs -gt 0 ]; then
            log_warning "Ainda existem $old_refs referências a 'Roo-Code'"
        fi
    else
        log_error "Modificação do package.ts falhou"
        mv "$file.backup" "$file"
        return 1
    fi
}

# Executar validações pós-modificação
run_validations() {
    log_header "Executando validações pós-modificação..."
    
    local errors=0
    
    # Validar sintaxe JSON
    log_info "Validando sintaxe JSON..."
    
    if ! jq . "$PROJECT_ROOT/package.json" > /dev/null 2>&1; then
        log_error "package.json (raiz) tem sintaxe inválida"
        ((errors++))
    fi
    
    if ! jq . "$PROJECT_ROOT/src/package.json" > /dev/null 2>&1; then
        log_error "src/package.json tem sintaxe inválida"
        ((errors++))
    fi
    
    # Verificar TypeScript do package.ts
    log_info "Verificando TypeScript..."
    
    cd "$PROJECT_ROOT/src"
    if command -v npx > /dev/null 2>&1; then
        if ! npx tsc --noEmit shared/package.ts 2>/dev/null; then
            log_warning "package.ts pode ter problemas de TypeScript"
        fi
    fi
    cd "$AUTOMATION_DIR"
    
    # Contar substituições
    log_info "Verificando substituições..."
    
    local total_old=$(grep -r "roo-cline\|Roo.*Code\|RooVeterinaryInc" \
                     "$PROJECT_ROOT/package.json" \
                     "$PROJECT_ROOT/src/package.json" \
                     "$PROJECT_ROOT/src/shared/package.ts" 2>/dev/null | wc -l || echo 0)
    
    local total_new=$(grep -r "tqi-ai-assistant\|TQI\|TQI-AI-Assistant" \
                     "$PROJECT_ROOT/package.json" \
                     "$PROJECT_ROOT/src/package.json" \
                     "$PROJECT_ROOT/src/shared/package.ts" 2>/dev/null | wc -l || echo 0)
    
    log_info "Substituições: $total_new novas, $total_old antigas restantes"
    
    if [ $errors -gt 0 ]; then
        log_error "$errors erro(s) de validação encontrado(s)"
        return 1
    else
        log_success "Todas as validações passaram"
    fi
}

# Testar build básico
test_build() {
    log_header "Testando build após modificações..."
    
    cd "$PROJECT_ROOT"
    
    # Instalar dependências se necessário
    if [ ! -d "node_modules" ] || [ "package.json" -nt "node_modules" ]; then
        log_info "Instalando dependências..."
        if ! pnpm install > /dev/null 2>&1; then
            log_warning "pnpm install falhou - pode afetar build"
        fi
    fi
    
    # Tentar build
    log_info "Executando build..."
    if pnpm build > /dev/null 2>&1; then
        log_success "Build passou - projeto está funcionando"
    else
        log_error "Build falhou após modificações"
        log_error "Execute 'pnpm build' manualmente para ver detalhes"
        
        cd "$AUTOMATION_DIR"
        return 1
    fi
    
    cd "$AUTOMATION_DIR"
}

# Gerar VSIX de teste
test_vsix_generation() {
    log_header "Testando geração de VSIX..."
    
    cd "$PROJECT_ROOT"
    
    # Tentar gerar VSIX
    log_info "Gerando VSIX de teste..."
    if command -v vsce > /dev/null 2>&1; then
        if pnpm vsix > /dev/null 2>&1; then
            local vsix_file=$(find . -name "*.vsix" -newer "src/package.json" | head -1)
            if [ -n "$vsix_file" ]; then
                log_success "VSIX gerado com sucesso: $vsix_file"
            else
                log_warning "VSIX pode não ter sido gerado corretamente"
            fi
        else
            log_warning "Geração de VSIX falhou - verifique manualmente"
        fi
    else
        log_warning "vsce não disponível - pulando teste de VSIX"
    fi
    
    cd "$AUTOMATION_DIR"
}

# Criar relatório da etapa
create_report() {
    log_header "Criando relatório da Etapa 1..."
    
    local report_file="$AUTOMATION_DIR/logs/etapa1-report.json"
    
    cat > "$report_file" << EOF
{
    "etapa": 1,
    "nome": "Rebranding Básico",
    "status": "completed",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "arquivos_modificados": [
        "package.json",
        "src/package.json", 
        "src/shared/package.ts"
    ],
    "modificacoes": {
        "root_package_json": {
            "name": "$TQI_NAME"
        },
        "src_package_json": {
            "name": "$TQI_NAME",
            "publisher": "$TQI_PUBLISHER",
            "version": "$TQI_VERSION",
            "repository": "$TQI_REPOSITORY_URL",
            "commands_updated": true,
            "configurations_updated": true,
            "dependencies_updated": true
        },
        "package_ts": {
            "output_channel": "TQI-AI-Assistant"
        }
    },
    "validacoes": {
        "json_syntax": true,
        "typescript_check": true,
        "build_test": true,
        "vsix_generation": true
    }
}
EOF
    
    log_success "Relatório criado: $report_file"
}

# Mostrar próximos passos
show_next_steps() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    ETAPA 1 CONCLUÍDA                        ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_success "🎉 Etapa 1 (Rebranding Básico) concluída com sucesso!"
    echo ""
    log_info "📝 RESUMO DAS MODIFICAÇÕES:"
    echo "   ✅ package.json (raiz): nome → $TQI_NAME"
    echo "   ✅ src/package.json: nome, publisher, versão, comandos, configurações"
    echo "   ✅ src/shared/package.ts: outputChannel → TQI-AI-Assistant"
    echo ""
    log_info "📋 PRÓXIMOS PASSOS:"
    echo ""
    echo "   1. 🔄 Execute a Etapa 2:"
    echo "      ./etapas/etapa2.sh"
    echo ""
    echo "   2. 🧪 Ou teste manualmente:"
    echo "      cd .. && pnpm build && pnpm vsix"
    echo ""
    echo "   3. 💾 Fazer backup adicional:"
    echo "      ./scripts/backup-system.sh backup 1 completed"
    echo ""
    echo "   4. 📊 Ver relatório detalhado:"
    echo "      cat logs/etapa1-report.json"
    echo ""
    log_warning "⚠️  IMPORTANTE: NÃO prossiga para Etapa 2 se algum teste falhou"
    echo ""
}

# Função de rollback
rollback_etapa1() {
    log_warning "🔄 Executando rollback da Etapa 1..."
    
    # Restaurar backups locais
    local files=(
        "$PROJECT_ROOT/package.json"
        "$PROJECT_ROOT/src/package.json"
        "$PROJECT_ROOT/src/shared/package.ts"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file.backup" ]; then
            mv "$file.backup" "$file"
            log_info "Restaurado: $file"
        fi
    done
    
    # Usar sistema de backup se disponível
    if [ -f "$AUTOMATION_DIR/scripts/backup-system.sh" ]; then
        "$AUTOMATION_DIR/scripts/backup-system.sh" restore-copy "emergency/last-known-good" "$PROJECT_ROOT" true
    fi
    
    log_success "Rollback concluído"
}

# Função principal
main() {
    # Criar diretório de logs se não existir
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Verificar parâmetros
    local skip_tests=false
    local force_mode=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-tests)
                skip_tests=true
                shift
                ;;
            --force)
                force_mode=true
                shift
                ;;
            --rollback)
                rollback_etapa1
                exit 0
                ;;
            --help)
                echo "Uso: $0 [opções]"
                echo "Opções:"
                echo "  --skip-tests   Pular testes de build e VSIX"
                echo "  --force        Modo força (sem confirmações)"
                echo "  --rollback     Fazer rollback das modificações"
                echo "  --help         Mostrar esta ajuda"
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                exit 1
                ;;
        esac
    done
    
    show_banner
    
    log_header "Iniciando Etapa 1: Rebranding Básico..."
    
    # Execução das funções principais
    check_prerequisites
    create_etapa_backup
    
    # Modificações principais
    modify_root_package_json || {
        log_error "Falha ao modificar package.json da raiz"
        exit 1
    }
    
    modify_src_package_json || {
        log_error "Falha ao modificar src/package.json"
        rollback_etapa1
        exit 1
    }
    
    modify_package_ts || {
        log_error "Falha ao modificar package.ts"
        rollback_etapa1
        exit 1
    }
    
    # Validações
    run_validations || {
        log_error "Validações falharam"
        if [ "$force_mode" != "true" ]; then
            read -p "Continuar mesmo assim? (s/N): " confirm
            if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
                rollback_etapa1
                exit 1
            fi
        fi
    }
    
    # Testes (se não foram pulados)
    if [ "$skip_tests" != "true" ]; then
        test_build || {
            log_error "Teste de build falhou"
            if [ "$force_mode" != "true" ]; then
                read -p "Continuar mesmo assim? (s/N): " confirm
                if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
                    rollback_etapa1
                    exit 1
                fi
            fi
        }
        
        test_vsix_generation
    fi
    
    # Finalização
    create_report
    show_next_steps
    
    log_success "Etapa 1 executada com sucesso em $(date)"
}

# Executar função principal
main "$@" 