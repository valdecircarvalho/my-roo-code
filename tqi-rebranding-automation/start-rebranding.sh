#!/bin/bash
# start-rebranding.sh - Script Principal de Automação de Rebranding
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
CYAN='\033[0;36m'
NC='\033[0m'

# Configurações
LOG_FILE="$SCRIPT_DIR/logs/rebranding.log"
STATUS_FILE="$SCRIPT_DIR/status.json"
START_TIME=$(date +%s)

# Funções de log
log_info() { echo -e "${BLUE}[REBRANDING]${NC} $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }
log_header() { echo -e "${PURPLE}[MAIN]${NC} $1" | tee -a "$LOG_FILE"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1" | tee -a "$LOG_FILE"; }

# Banner principal
show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║           TQI AI ASSISTANT - REBRANDING AUTOMÁTICO          ║"
    echo "║                                                              ║"
    echo "║  Transformando Roo-Code em TQI AI Assistant                 ║"
    echo "║  Sistema completo de automação com backup e validação       ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Configurações padrão
DEFAULT_MODE="interactive"
SKIP_CONFIRMATIONS=false
FORCE_MODE=false
AUTO_FIX=false
STOP_ON_ERROR=true
DRY_RUN=false

# Status das etapas
declare -A ETAPA_STATUS
declare -A ETAPA_NAMES
declare -A ETAPA_PRIORITY

# Inicializar informações das etapas
init_etapas_info() {
    ETAPA_NAMES[1]="Rebranding Básico"
    ETAPA_NAMES[2]="Workspace e Pacotes"
    ETAPA_NAMES[3]="Assets Visuais"
    ETAPA_NAMES[4]="Internacionalização"
    ETAPA_NAMES[5]="Código e Comandos"
    ETAPA_NAMES[6]="Documentação"
    ETAPA_NAMES[7]="URLs e Links"
    ETAPA_NAMES[8]="Configurações Avançadas"
    ETAPA_NAMES[9]="Validação e Testes"
    
    ETAPA_PRIORITY[1]="CRÍTICA"
    ETAPA_PRIORITY[2]="ALTA"
    ETAPA_PRIORITY[3]="ALTA"
    ETAPA_PRIORITY[4]="ALTA"
    ETAPA_PRIORITY[5]="MÉDIA"
    ETAPA_PRIORITY[6]="MÉDIA"
    ETAPA_PRIORITY[7]="BAIXA"
    ETAPA_PRIORITY[8]="BAIXA"
    ETAPA_PRIORITY[9]="CRÍTICA"
    
    # Inicializar todos como pendentes
    for i in {1..9}; do
        ETAPA_STATUS[$i]="pending"
    done
}

# Verificar dependências e pré-requisitos
check_dependencies() {
    log_header "Verificando dependências e pré-requisitos..."
    
    local errors=0
    
    # Verificar se setup foi executado
    if [ ! -f "$STATUS_FILE" ]; then
        log_error "Setup não foi executado. Execute ./setup.sh primeiro"
        ((errors++))
    fi
    
    # Verificar ferramentas obrigatórias
    local tools=("node" "pnpm" "git" "jq" "vsce")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" > /dev/null 2>&1; then
            log_error "$tool não encontrado"
            ((errors++))
        else
            local version=$($tool --version 2>/dev/null | head -1 || echo "unknown")
            log_info "$tool: $version"
        fi
    done
    
    # Verificar projeto Roo-Code
    if [ ! -f "$PROJECT_ROOT/src/package.json" ]; then
        log_error "Projeto Roo-Code não encontrado"
        ((errors++))
    elif ! grep -q "roo-cline" "$PROJECT_ROOT/src/package.json"; then
        log_warning "Projeto pode já ter sido modificado"
    fi
    
    # Verificar Git status
    cd "$PROJECT_ROOT"
    if git status > /dev/null 2>&1; then
        local uncommitted=$(git status --porcelain | wc -l)
        if [ "$uncommitted" -gt 0 ]; then
            log_warning "$uncommitted arquivo(s) com mudanças não commitadas"
        fi
    fi
    cd "$SCRIPT_DIR"
    
    if [ $errors -gt 0 ]; then
        log_error "$errors erro(s) crítico(s) encontrado(s)"
        return 1
    fi
    
    log_success "Todos os pré-requisitos atendidos"
    return 0
}

# Atualizar status das etapas
update_etapa_status() {
    local etapa=$1
    local status=$2
    
    ETAPA_STATUS[$etapa]=$status
    
    # Atualizar arquivo de status
    local temp_file=$(mktemp)
    
    cat > "$temp_file" << EOF
{
    "rebranding": {
        "status": "in_progress",
        "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "current_etapa": $etapa
    },
    "etapas": {
EOF
    
    for i in {1..9}; do
        echo "        \"$i\": {" >> "$temp_file"
        echo "            \"name\": \"${ETAPA_NAMES[$i]}\"," >> "$temp_file"
        echo "            \"priority\": \"${ETAPA_PRIORITY[$i]}\"," >> "$temp_file"
        echo "            \"status\": \"${ETAPA_STATUS[$i]}\"" >> "$temp_file"
        if [ $i -eq 9 ]; then
            echo "        }" >> "$temp_file"
        else
            echo "        }," >> "$temp_file"
        fi
    done
    
    echo "    }" >> "$temp_file"
    echo "}" >> "$temp_file"
    
    mv "$temp_file" "$STATUS_FILE"
}

# Mostrar progresso
show_progress() {
    local current_etapa=${1:-0}
    
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      PROGRESSO GERAL                         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    for i in {1..9}; do
        local status="${ETAPA_STATUS[$i]}"
        local name="${ETAPA_NAMES[$i]}"
        local priority="${ETAPA_PRIORITY[$i]}"
        
        # Indicador visual
        local indicator
        local color
        case $status in
            "completed")
                indicator="✅"
                color="$GREEN"
                ;;
            "in_progress")
                indicator="🔄"
                color="$YELLOW"
                ;;
            "failed")
                indicator="❌"
                color="$RED"
                ;;
            "skipped")
                indicator="⏭️"
                color="$YELLOW"
                ;;
            *)
                if [ $i -eq $current_etapa ]; then
                    indicator="▶️"
                    color="$CYAN"
                else
                    indicator="⚪"
                    color="$NC"
                fi
                ;;
        esac
        
        echo -e "${color}${indicator} Etapa $i: $name ($priority)${NC}"
    done
    
    echo ""
    
    # Estatísticas
    local completed=$(printf '%s\n' "${ETAPA_STATUS[@]}" | grep -c "completed" || echo 0)
    local failed=$(printf '%s\n' "${ETAPA_STATUS[@]}" | grep -c "failed" || echo 0)
    local progress=$((completed * 100 / 9))
    
    echo "📊 Progresso: $completed/9 etapas concluídas ($progress%)"
    if [ $failed -gt 0 ]; then
        echo "⚠️  Falhas: $failed etapa(s)"
    fi
    echo ""
}

# Executar uma etapa específica
execute_etapa() {
    local etapa=$1
    local etapa_name="${ETAPA_NAMES[$etapa]}"
    local script_path="$SCRIPT_DIR/etapas/etapa${etapa}.sh"
    
    log_step "Iniciando Etapa $etapa: $etapa_name"
    
    # Verificar se o script existe
    if [ ! -f "$script_path" ]; then
        log_error "Script da etapa não encontrado: $script_path"
        update_etapa_status $etapa "failed"
        return 1
    fi
    
    # Atualizar status
    update_etapa_status $etapa "in_progress"
    show_progress $etapa
    
    # Criar backup antes da etapa
    if [ -f "$SCRIPT_DIR/scripts/backup-system.sh" ]; then
        log_info "Criando backup antes da Etapa $etapa..."
        "$SCRIPT_DIR/scripts/backup-system.sh" backup $etapa "pre-execution" || {
            log_warning "Falha ao criar backup - continuando..."
        }
    fi
    
    # Executar o script da etapa
    local start_time=$(date +%s)
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "DRY RUN: Simulando execução da Etapa $etapa"
        sleep 2
        update_etapa_status $etapa "completed"
        return 0
    fi
    
    # Executar com timeout se configurado
    local timeout_cmd=""
    if command -v timeout > /dev/null 2>&1; then
        timeout_cmd="timeout 1800"  # 30 minutos
    fi
    
    if $timeout_cmd "$script_path" ${FORCE_MODE:+--force} ${SKIP_CONFIRMATIONS:+--skip-tests}; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_success "Etapa $etapa concluída em ${duration}s"
        update_etapa_status $etapa "completed"
        
        # Backup pós-execução
        if [ -f "$SCRIPT_DIR/scripts/backup-system.sh" ]; then
            "$SCRIPT_DIR/scripts/backup-system.sh" backup $etapa "completed" || {
                log_warning "Falha ao criar backup pós-execução"
            }
        fi
        
        return 0
    else
        local exit_code=$?
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_error "Etapa $etapa falhou após ${duration}s (exit code: $exit_code)"
        update_etapa_status $etapa "failed"
        
        return $exit_code
    fi
}

# Modo interativo
interactive_mode() {
    log_header "Iniciando modo interativo..."
    
    while true; do
        show_progress
        
        echo "🎛️  MODO INTERATIVO - Escolha uma opção:"
        echo ""
        echo "📋 ETAPAS:"
        echo "  1-9) Executar etapa específica"
        echo "  A)   Executar todas as etapas pendentes"
        echo "  S)   Pular etapa atual"
        echo ""
        echo "🔧 UTILITÁRIOS:"
        echo "  B)   Sistema de backup"
        echo "  V)   Validar estado atual"
        echo "  R)   Rollback"
        echo "  L)   Ver logs"
        echo ""
        echo "  Q)   Sair"
        echo ""
        
        read -p "Sua escolha: " choice
        
        case $choice in
            [1-9])
                if [ "${ETAPA_STATUS[$choice]}" = "completed" ]; then
                    echo "Etapa $choice já foi concluída. Executar novamente? (s/N)"
                    read -p "> " confirm
                    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
                        continue
                    fi
                fi
                
                execute_etapa $choice
                
                if [ "${ETAPA_STATUS[$choice]}" = "failed" ] && [ "$STOP_ON_ERROR" = "true" ]; then
                    echo ""
                    echo "❌ Etapa falhou. Opções:"
                    echo "1) Tentar novamente"
                    echo "2) Pular esta etapa"
                    echo "3) Sair"
                    read -p "Escolha: " error_choice
                    
                    case $error_choice in
                        1) execute_etapa $choice ;;
                        2) update_etapa_status $choice "skipped" ;;
                        3) exit 1 ;;
                    esac
                fi
                ;;
            [Aa])
                execute_all_pending
                ;;
            [Ss])
                read -p "Qual etapa pular? (1-9): " skip_etapa
                if [[ "$skip_etapa" =~ ^[1-9]$ ]]; then
                    update_etapa_status $skip_etapa "skipped"
                    log_warning "Etapa $skip_etapa marcada como pulada"
                fi
                ;;
            [Bb])
                if [ -f "$SCRIPT_DIR/scripts/backup-system.sh" ]; then
                    "$SCRIPT_DIR/scripts/backup-system.sh"
                else
                    log_error "Sistema de backup não disponível"
                fi
                ;;
            [Vv])
                validate_current_state
                ;;
            [Rr])
                show_rollback_menu
                ;;
            [Ll])
                show_logs_menu
                ;;
            [Qq])
                echo "Saindo do modo interativo..."
                break
                ;;
            *)
                log_error "Opção inválida: $choice"
                ;;
        esac
        
        echo ""
        read -p "Pressione ENTER para continuar..."
    done
}

# Executar todas as etapas pendentes
execute_all_pending() {
    log_header "Executando todas as etapas pendentes..."
    
    local total_errors=0
    
    for i in {1..9}; do
        if [ "${ETAPA_STATUS[$i]}" = "pending" ]; then
            echo ""
            log_step "=== EXECUTANDO ETAPA $i: ${ETAPA_NAMES[$i]} ==="
            
            if execute_etapa $i; then
                log_success "Etapa $i concluída"
            else
                log_error "Etapa $i falhou"
                ((total_errors++))
                
                if [ "$STOP_ON_ERROR" = "true" ]; then
                    log_error "Parando execução devido a erro na Etapa $i"
                    break
                fi
            fi
            
            # Pausa entre etapas (exceto se em modo força)
            if [ "$FORCE_MODE" != "true" ] && [ $i -lt 9 ]; then
                echo ""
                echo "⏱️  Pausa de 3 segundos antes da próxima etapa..."
                sleep 3
            fi
        fi
    done
    
    # Relatório final
    echo ""
    log_header "EXECUÇÃO AUTOMÁTICA CONCLUÍDA"
    
    local completed=$(printf '%s\n' "${ETAPA_STATUS[@]}" | grep -c "completed" || echo 0)
    local failed=$(printf '%s\n' "${ETAPA_STATUS[@]}" | grep -c "failed" || echo 0)
    local skipped=$(printf '%s\n' "${ETAPA_STATUS[@]}" | grep -c "skipped" || echo 0)
    
    echo ""
    echo "📊 RELATÓRIO FINAL:"
    echo "   ✅ Concluídas: $completed/9"
    echo "   ❌ Falharam: $failed/9"
    echo "   ⏭️  Puladas: $skipped/9"
    echo ""
    
    if [ $failed -eq 0 ] && [ $completed -eq 9 ]; then
        log_success "🎉 REBRANDING COMPLETO! Todas as etapas foram executadas com sucesso!"
        finalize_rebranding
    elif [ $total_errors -eq 0 ]; then
        log_success "Execução concluída com $skipped etapa(s) pulada(s)"
    else
        log_warning "Execução concluída com $total_errors erro(s)"
    fi
}

# Validar estado atual
validate_current_state() {
    log_header "Validando estado atual do projeto..."
    
    cd "$PROJECT_ROOT"
    
    # Verificar sintaxe JSON
    local json_files=("package.json" "src/package.json")
    for file in "${json_files[@]}"; do
        if [ -f "$file" ]; then
            if jq . "$file" > /dev/null 2>&1; then
                log_success "$file: Sintaxe válida"
            else
                log_error "$file: Sintaxe inválida"
            fi
        fi
    done
    
    # Verificar build
    log_info "Testando build..."
    if pnpm build > /dev/null 2>&1; then
        log_success "Build: OK"
    else
        log_error "Build: FALHA"
    fi
    
    # Verificar VSIX
    log_info "Testando geração VSIX..."
    if pnpm vsix > /dev/null 2>&1; then
        log_success "VSIX: OK"
    else
        log_warning "VSIX: FALHA"
    fi
    
    cd "$SCRIPT_DIR"
}

# Menu de rollback
show_rollback_menu() {
    echo ""
    echo "🔄 SISTEMA DE ROLLBACK"
    echo ""
    echo "1) Rollback da última etapa"
    echo "2) Rollback para etapa específica"
    echo "3) Rollback completo (estado original)"
    echo "4) Voltar"
    echo ""
    
    read -p "Escolha: " rollback_choice
    
    case $rollback_choice in
        1)
            # Encontrar última etapa executada
            local last_etapa=0
            for i in {9..1}; do
                if [ "${ETAPA_STATUS[$i]}" = "completed" ]; then
                    last_etapa=$i
                    break
                fi
            done
            
            if [ $last_etapa -gt 0 ]; then
                log_warning "Fazendo rollback da Etapa $last_etapa..."
                if [ -f "$SCRIPT_DIR/scripts/backup-system.sh" ]; then
                    "$SCRIPT_DIR/scripts/backup-system.sh" restore-copy "latest-etapa$((last_etapa-1))"
                fi
            else
                log_warning "Nenhuma etapa concluída para rollback"
            fi
            ;;
        2)
            read -p "Rollback para qual etapa? (1-9): " target_etapa
            if [[ "$target_etapa" =~ ^[1-9]$ ]]; then
                log_warning "Fazendo rollback para Etapa $target_etapa..."
                if [ -f "$SCRIPT_DIR/scripts/backup-system.sh" ]; then
                    "$SCRIPT_DIR/scripts/backup-system.sh" restore-copy "latest-etapa$target_etapa"
                fi
            fi
            ;;
        3)
            echo "⚠️  ATENÇÃO: Isso reverterá TODAS as modificações!"
            read -p "Confirma rollback completo? (s/N): " confirm
            if [[ "$confirm" =~ ^[Ss]$ ]]; then
                log_warning "Fazendo rollback completo..."
                if [ -f "$SCRIPT_DIR/scripts/backup-system.sh" ]; then
                    "$SCRIPT_DIR/scripts/backup-system.sh" restore-copy "original-latest"
                fi
            fi
            ;;
        4)
            return
            ;;
    esac
}

# Menu de logs
show_logs_menu() {
    echo ""
    echo "📋 VISUALIZAR LOGS"
    echo ""
    echo "1) Log principal (últimas 50 linhas)"
    echo "2) Log de uma etapa específica"
    echo "3) Todos os logs disponíveis"
    echo "4) Voltar"
    echo ""
    
    read -p "Escolha: " log_choice
    
    case $log_choice in
        1)
            echo ""
            echo "=== LOG PRINCIPAL (últimas 50 linhas) ==="
            tail -50 "$LOG_FILE" 2>/dev/null || echo "Log não encontrado"
            ;;
        2)
            read -p "Qual etapa? (1-9): " etapa_log
            if [[ "$etapa_log" =~ ^[1-9]$ ]]; then
                local etapa_log_file="$SCRIPT_DIR/logs/etapa${etapa_log}.log"
                if [ -f "$etapa_log_file" ]; then
                    echo ""
                    echo "=== LOG ETAPA $etapa_log ==="
                    cat "$etapa_log_file"
                else
                    log_warning "Log da etapa $etapa_log não encontrado"
                fi
            fi
            ;;
        3)
            echo ""
            echo "=== LOGS DISPONÍVEIS ==="
            find "$SCRIPT_DIR/logs" -name "*.log" -exec echo "📄 {}" \; -exec tail -5 {} \; -exec echo "" \;
            ;;
        4)
            return
            ;;
    esac
}

# Finalizar rebranding
finalize_rebranding() {
    log_header "Finalizando processo de rebranding..."
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))
    local hours=$((total_duration / 3600))
    local minutes=$(((total_duration % 3600) / 60))
    local seconds=$((total_duration % 60))
    
    # Criar relatório final
    cat > "$SCRIPT_DIR/logs/rebranding-final.json" << EOF
{
    "rebranding": {
        "status": "completed",
        "started_at": "$(date -d @$START_TIME -u +%Y-%m-%dT%H:%M:%SZ)",
        "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "duration_seconds": $total_duration,
        "duration_human": "${hours}h ${minutes}m ${seconds}s"
    },
    "summary": {
        "total_etapas": 9,
        "completed": $(printf '%s\n' "${ETAPA_STATUS[@]}" | grep -c "completed" || echo 0),
        "failed": $(printf '%s\n' "${ETAPA_STATUS[@]}" | grep -c "failed" || echo 0),
        "skipped": $(printf '%s\n' "${ETAPA_STATUS[@]}" | grep -c "skipped" || echo 0)
    },
    "final_build": {
        "test_performed": true,
        "build_success": $(cd "$PROJECT_ROOT" && pnpm build > /dev/null 2>&1 && echo "true" || echo "false"),
        "vsix_generated": $(cd "$PROJECT_ROOT" && pnpm vsix > /dev/null 2>&1 && echo "true" || echo "false")
    }
}
EOF
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║                  REBRANDING CONCLUÍDO!                      ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║   Roo-Code foi transformado em TQI AI Assistant             ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_success "🎉 TRANSFORMAÇÃO COMPLETA!"
    echo ""
    echo "⏱️  Tempo total: ${hours}h ${minutes}m ${seconds}s"
    echo ""
    echo "📋 PRÓXIMOS PASSOS:"
    echo ""
    echo "1. 🧪 Testar a extensão:"
    echo "   cd $PROJECT_ROOT"
    echo "   code --install-extension bin/tqi-ai-assistant-*.vsix"
    echo ""
    echo "2. 🚀 Publicar (se desejado):"
    echo "   vsce publish"
    echo ""
    echo "3. 📊 Ver relatório completo:"
    echo "   cat $SCRIPT_DIR/logs/rebranding-final.json"
    echo ""
    echo "4. 💾 Fazer backup final:"
    echo "   $SCRIPT_DIR/scripts/backup-system.sh backup final completed"
    echo ""
}

# Processar argumentos da linha de comando
process_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto|--automatic)
                DEFAULT_MODE="automatic"
                SKIP_CONFIRMATIONS=true
                shift
                ;;
            --force)
                FORCE_MODE=true
                shift
                ;;
            --no-stop-on-error)
                STOP_ON_ERROR=false
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --etapa)
                if [ -n "$2" ] && [[ "$2" =~ ^[1-9]$ ]]; then
                    execute_etapa "$2"
                    exit $?
                else
                    log_error "Etapa inválida: $2"
                    exit 1
                fi
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Mostrar ajuda
show_help() {
    echo "TQI AI Assistant - Sistema de Rebranding Automatizado"
    echo ""
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  --auto, --automatic     Modo automático (sem interação)"
    echo "  --force                 Modo força (sem confirmações)"
    echo "  --no-stop-on-error     Continuar mesmo com erros"
    echo "  --dry-run              Simular execução sem modificar arquivos"
    echo "  --etapa N              Executar apenas a etapa N (1-9)"
    echo "  --help                 Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                     # Modo interativo"
    echo "  $0 --auto             # Execução automática completa"
    echo "  $0 --etapa 1          # Executar apenas Etapa 1"
    echo "  $0 --dry-run --auto   # Simular execução automática"
    echo ""
}

# Função principal
main() {
    # Criar diretório de logs se não existir
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Processar argumentos
    process_arguments "$@"
    
    # Mostrar banner
    show_banner
    
    # Inicializar informações das etapas
    init_etapas_info
    
    # Verificar dependências
    if ! check_dependencies; then
        log_error "Pré-requisitos não atendidos"
        exit 1
    fi
    
    # Mostrar configurações
    log_info "Configuração:"
    log_info "  Modo: $DEFAULT_MODE"
    log_info "  Pular confirmações: $SKIP_CONFIRMATIONS"
    log_info "  Modo força: $FORCE_MODE"
    log_info "  Parar em erro: $STOP_ON_ERROR"
    log_info "  Dry run: $DRY_RUN"
    echo ""
    
    # Executar conforme modo
    case $DEFAULT_MODE in
        "automatic")
            log_header "Iniciando execução automática..."
            execute_all_pending
            ;;
        "interactive")
            interactive_mode
            ;;
        *)
            log_error "Modo inválido: $DEFAULT_MODE"
            exit 1
            ;;
    esac
    
    log_success "Script principal executado com sucesso em $(date)"
}

# Executar função principal
main "$@" 