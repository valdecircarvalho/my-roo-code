#!/bin/bash
# backup-system.sh - Sistema Avançado de Backup e Restore
# Autor: TQI AI Assistant Automation
# Versão: 2.0.0

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

# Configurações globais
BACKUP_ROOT="$AUTOMATION_DIR/backups"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="$AUTOMATION_DIR/logs/backup.log"

# Funções de log
log_info() { echo -e "${BLUE}[BACKUP]${NC} $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }

# Função para calcular hash MD5 de diretórios
calculate_dir_hash() {
    local dir=$1
    if [ -d "$dir" ]; then
        find "$dir" -type f -exec md5sum {} \; 2>/dev/null | sort -k 2 | md5sum | cut -d' ' -f1
    else
        echo "N/A"
    fi
}

# Função para criar manifesto de backup
create_backup_manifest() {
    local backup_dir=$1
    local etapa=$2
    local operation=$3
    
    mkdir -p "$backup_dir"
    
    cat > "$backup_dir/backup-manifest.json" << EOF
{
    "backup_info": {
        "etapa": "$etapa",
        "operation": "$operation",
        "timestamp": "$TIMESTAMP",
        "backup_type": "hybrid_advanced",
        "script_version": "2.0.0"
    },
    "environment": {
        "hostname": "$(hostname)",
        "user": "$(whoami)",
        "pwd": "$(pwd)",
        "automation_dir": "$AUTOMATION_DIR",
        "project_root": "$PROJECT_ROOT",
        "git_branch": "$(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null || echo 'N/A')",
        "git_commit": "$(cd "$PROJECT_ROOT" && git rev-parse HEAD 2>/dev/null || echo 'N/A')"
    },
    "file_counts": {
        "total_files": $(find "$PROJECT_ROOT" -type f -not -path "*/node_modules/*" -not -path "*/.git/*" | wc -l || echo 0),
        "js_files": $(find "$PROJECT_ROOT" -name "*.js" -not -path "*/node_modules/*" | wc -l || echo 0),
        "ts_files": $(find "$PROJECT_ROOT" -name "*.ts" -not -path "*/node_modules/*" | wc -l || echo 0),
        "json_files": $(find "$PROJECT_ROOT" -name "*.json" -not -path "*/node_modules/*" | wc -l || echo 0)
    },
    "integrity": {
        "src_hash": "$(calculate_dir_hash "$PROJECT_ROOT/src")",
        "packages_hash": "$(calculate_dir_hash "$PROJECT_ROOT/packages")",
        "webview_hash": "$(calculate_dir_hash "$PROJECT_ROOT/webview-ui")",
        "apps_hash": "$(calculate_dir_hash "$PROJECT_ROOT/apps")"
    },
    "backup_contents": {
        "includes_src": $([ -d "$backup_dir/src" ] && echo "true" || echo "false"),
        "includes_packages": $([ -d "$backup_dir/packages" ] && echo "true" || echo "false"),
        "includes_webview": $([ -d "$backup_dir/webview-ui" ] && echo "true" || echo "false"),
        "includes_apps": $([ -d "$backup_dir/apps" ] && echo "true" || echo "false")
    }
}
EOF
}

# Função para validar integridade do backup
validate_backup_integrity() {
    local backup_dir=$1
    local manifest_file="$backup_dir/backup-manifest.json"
    
    if [ ! -f "$manifest_file" ]; then
        log_error "Manifesto não encontrado: $manifest_file"
        return 1
    fi
    
    log_info "Validando integridade do backup..."
    
    # Verificar se jq está disponível para análise JSON
    if command -v jq > /dev/null 2>&1; then
        # Verificar estrutura básica do manifesto
        if ! jq -e '.backup_info.etapa' "$manifest_file" > /dev/null 2>&1; then
            log_error "Manifesto corrompido ou inválido"
            return 1
        fi
        
        # Verificar diretórios obrigatórios se indicados no manifesto
        local includes_src=$(jq -r '.backup_contents.includes_src' "$manifest_file" 2>/dev/null || echo "false")
        local includes_packages=$(jq -r '.backup_contents.includes_packages' "$manifest_file" 2>/dev/null || echo "false")
        
        if [ "$includes_src" == "true" ] && [ ! -d "$backup_dir/src" ]; then
            log_error "Diretório src ausente no backup mas indicado no manifesto"
            return 1
        fi
        
        if [ "$includes_packages" == "true" ] && [ ! -d "$backup_dir/packages" ]; then
            log_error "Diretório packages ausente no backup mas indicado no manifesto"
            return 1
        fi
        
        log_success "Validação de integridade passou"
        return 0
    else
        log_warning "jq não disponível - validação limitada"
        
        # Validação básica sem jq
        if [ -d "$backup_dir/src" ] || [ -d "$backup_dir/packages" ]; then
            log_success "Backup contém diretórios principais"
            return 0
        else
            log_error "Backup não contém diretórios principais"
            return 1
        fi
    fi
}

# Função principal de backup
create_advanced_backup() {
    local etapa=$1
    local operation=${2:-"manual"}
    local checkpoint=${3:-""}
    
    # Determinar nome do backup
    local backup_name="etapa${etapa}"
    if [ -n "$checkpoint" ]; then
        backup_name="${backup_name}-${checkpoint}"
    fi
    
    local backup_dir="$BACKUP_ROOT/$backup_name/$TIMESTAMP"
    
    log_info "Criando backup avançado: $backup_name"
    log_info "Destino: $backup_dir"
    
    # === BACKUP POR CÓPIA ===
    log_info "📁 Iniciando backup por cópia..."
    
    # Criar estrutura de diretórios
    mkdir -p "$backup_dir"
    
    # Copiar diretórios principais
    local dirs_to_backup=("src" "packages" "webview-ui" "apps")
    for dir in "${dirs_to_backup[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            log_info "   📂 Copiando $dir/..."
            cp -r "$PROJECT_ROOT/$dir" "$backup_dir/" 2>/dev/null || {
                log_warning "Falha ao copiar $dir - continuando..."
            }
        else
            log_warning "   ⚠️  Diretório não encontrado: $dir"
        fi
    done
    
    # Copiar arquivos raiz importantes
    local files_to_backup=("package.json" "README.md" "turbo.json" "pnpm-workspace.yaml" ".gitignore")
    for file in "${files_to_backup[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            log_info "   📄 Copiando $file"
            cp "$PROJECT_ROOT/$file" "$backup_dir/" 2>/dev/null || {
                log_warning "Falha ao copiar $file - continuando..."
            }
        fi
    done
    
    # === BACKUP GIT ===
    log_info "🌿 Iniciando backup Git..."
    
    cd "$PROJECT_ROOT"
    
    # Verificar se é repositório Git
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Criar branch de backup se não existir
        local backup_branch="backup/etapa${etapa}-${TIMESTAMP}"
        
        # Commit estado atual se houver mudanças
        if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
            log_info "   💾 Commitando mudanças pendentes..."
            git add -A 2>/dev/null || true
            git commit -m "backup: estado antes de $operation - etapa $etapa" 2>/dev/null || {
                log_warning "Falha ao commitar - continuando sem commit Git"
            }
        fi
        
        # Criar branch de backup
        log_info "   🌿 Criando branch: $backup_branch"
        git branch "$backup_branch" 2>/dev/null || {
            log_warning "Falha ao criar branch - pode já existir"
        }
        
        # Criar tag
        local tag_name="backup-etapa${etapa}-$(echo $operation | tr ' ' '-')-$TIMESTAMP"
        log_info "   🏷️  Criando tag: $tag_name"
        git tag "$tag_name" -m "Backup automático - Etapa $etapa - $operation" 2>/dev/null || {
            log_warning "Falha ao criar tag - pode já existir"
        }
    else
        log_warning "Não é um repositório Git - backup Git desabilitado"
    fi
    
    cd "$AUTOMATION_DIR"
    
    # === MANIFESTO E VALIDAÇÃO ===
    log_info "📋 Criando manifesto..."
    create_backup_manifest "$backup_dir" "$etapa" "$operation"
    
    # Validar backup imediatamente
    if validate_backup_integrity "$backup_dir"; then
        log_success "✅ Backup criado e validado com sucesso!"
        log_info "📍 Localização: $backup_dir"
    else
        log_error "❌ Falha na validação do backup!"
        return 1
    fi
    
    # Atualizar link para último backup
    local latest_link="$BACKUP_ROOT/latest-etapa${etapa}"
    ln -sfn "$backup_dir" "$latest_link" 2>/dev/null || true
    
    # Atualizar backup de emergência
    local emergency_backup="$BACKUP_ROOT/emergency/last-known-good"
    rm -rf "$emergency_backup" 2>/dev/null || true
    mkdir -p "$(dirname "$emergency_backup")"
    cp -r "$backup_dir" "$emergency_backup" 2>/dev/null || true
    
    return 0
}

# Função de restore por cópia
restore_from_copy() {
    local backup_path=$1
    local target_dir=${2:-"$PROJECT_ROOT"}
    local force=${3:-false}
    
    log_info "🔄 Iniciando restore por cópia..."
    log_info "Origem: $backup_path"
    log_info "Destino: $target_dir"
    
    # Validar backup antes de restore
    if ! validate_backup_integrity "$backup_path"; then
        log_error "Backup inválido - cancelando restore"
        return 1
    fi
    
    # Confirmar ação se não estiver em modo força
    if [ "$force" != "true" ]; then
        echo -e "${YELLOW}ATENÇÃO: Esta operação sobrescreverá arquivos existentes!${NC}"
        echo "Backup será feito antes do restore."
        read -p "Continuar? (s/N): " confirm
        if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
            log_info "Restore cancelado pelo usuário"
            return 0
        fi
    fi
    
    # Backup do estado atual antes do restore
    log_info "📁 Criando backup do estado atual..."
    local emergency_backup="$BACKUP_ROOT/emergency/before-restore-$TIMESTAMP"
    mkdir -p "$emergency_backup"
    
    local dirs_to_backup=("src" "packages" "webview-ui" "apps")
    for dir in "${dirs_to_backup[@]}"; do
        if [ -d "$target_dir/$dir" ]; then
            cp -r "$target_dir/$dir" "$emergency_backup/" 2>/dev/null || true
        fi
    done
    
    local files_to_backup=("package.json" "README.md" "turbo.json" "pnpm-workspace.yaml")
    for file in "${files_to_backup[@]}"; do
        if [ -f "$target_dir/$file" ]; then
            cp "$target_dir/$file" "$emergency_backup/" 2>/dev/null || true
        fi
    done
    
    # Executar restore
    log_info "🔄 Restaurando arquivos..."
    
    for dir in "${dirs_to_backup[@]}"; do
        if [ -d "$backup_path/$dir" ]; then
            log_info "   📂 Restaurando $dir/"
            rm -rf "$target_dir/$dir" 2>/dev/null || true
            cp -r "$backup_path/$dir" "$target_dir/" 2>/dev/null || {
                log_error "Falha ao restaurar $dir"
                return 1
            }
        fi
    done
    
    # Restaurar arquivos raiz
    for file in "${files_to_backup[@]}"; do
        if [ -f "$backup_path/$file" ]; then
            log_info "   📄 Restaurando $file"
            cp "$backup_path/$file" "$target_dir/" 2>/dev/null || {
                log_warning "Falha ao restaurar $file"
            }
        fi
    done
    
    log_success "✅ Restore por cópia concluído!"
    log_info "💾 Backup de emergência salvo em: $emergency_backup"
    
    return 0
}

# Função de restore por Git
restore_from_git() {
    local git_ref=$1
    local force=${2:-false}
    
    log_info "🌿 Iniciando restore por Git..."
    log_info "Referência: $git_ref"
    
    cd "$PROJECT_ROOT"
    
    # Verificar se a referência existe
    if ! git rev-parse --verify "$git_ref" > /dev/null 2>&1; then
        log_error "Referência Git não encontrada: $git_ref"
        return 1
    fi
    
    # Verificar se há mudanças não commitadas
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        log_warning "Há mudanças não commitadas!"
        
        if [ "$force" != "true" ]; then
            echo -e "${YELLOW}Opções:${NC}"
            echo "1) Commitar mudanças antes do restore"
            echo "2) Descartar mudanças (PERIGOSO)"
            echo "3) Cancelar"
            read -p "Escolha (1-3): " choice
            
            case $choice in
                1)
                    log_info "💾 Commitando mudanças..."
                    git add -A
                    git commit -m "emergency commit before restore to $git_ref"
                    ;;
                2)
                    log_warning "⚠️  Descartando mudanças..."
                    git reset --hard HEAD
                    git clean -fd
                    ;;
                3)
                    log_info "Restore cancelado"
                    return 0
                    ;;
                *)
                    log_error "Opção inválida"
                    return 1
                    ;;
            esac
        else
            log_info "Modo força ativado - commitando mudanças automaticamente"
            git add -A 2>/dev/null || true
            git commit -m "auto commit before restore to $git_ref" 2>/dev/null || true
        fi
    fi
    
    # Executar restore
    log_info "🔄 Fazendo checkout para $git_ref..."
    if git checkout "$git_ref" 2>/dev/null; then
        log_success "✅ Restore por Git concluído!"
        log_info "📍 Branch/Tag atual: $(git branch --show-current 2>/dev/null || git describe --tags 2>/dev/null || git rev-parse --short HEAD)"
    else
        log_error "Falha no checkout para $git_ref"
        return 1
    fi
    
    cd "$AUTOMATION_DIR"
    return 0
}

# Listar backups disponíveis
list_backups() {
    log_info "📋 Listando backups disponíveis..."
    
    if [ ! -d "$BACKUP_ROOT" ]; then
        log_warning "Diretório de backups não encontrado"
        return 1
    fi
    
    echo ""
    echo "=== BACKUPS DISPONÍVEIS ==="
    
    find "$BACKUP_ROOT" -name "backup-manifest.json" -print0 | while IFS= read -r -d '' manifest; do
        local backup_dir=$(dirname "$manifest")
        local relative_path=${backup_dir#$BACKUP_ROOT/}
        
        echo ""
        echo "📁 $relative_path"
        
        if command -v jq > /dev/null 2>&1; then
            echo "   Etapa: $(jq -r '.backup_info.etapa' "$manifest" 2>/dev/null || echo 'N/A')"
            echo "   Operação: $(jq -r '.backup_info.operation' "$manifest" 2>/dev/null || echo 'N/A')"
            echo "   Data: $(jq -r '.backup_info.timestamp' "$manifest" 2>/dev/null || echo 'N/A')"
            echo "   Git Branch: $(jq -r '.environment.git_branch' "$manifest" 2>/dev/null || echo 'N/A')"
        else
            echo "   Manifesto: $manifest"
        fi
        
        echo "   Tamanho: $(du -sh "$backup_dir" 2>/dev/null | cut -f1 || echo 'N/A')"
    done
    
    echo ""
    echo "=== ATALHOS ==="
    ls -la "$BACKUP_ROOT"/latest-* 2>/dev/null || echo "Nenhum atalho disponível"
    echo ""
}

# Limpar backups antigos
cleanup_old_backups() {
    local retention_days=${1:-${BACKUP_RETENTION_DAYS:-30}}
    
    log_info "🧹 Limpando backups com mais de $retention_days dias..."
    
    local deleted_count=0
    
    find "$BACKUP_ROOT" -type d -name "*-[0-9]*_[0-9]*" -mtime +$retention_days | while read -r backup_dir; do
        if [ -f "$backup_dir/backup-manifest.json" ]; then
            log_info "Removendo backup antigo: $(basename "$backup_dir")"
            rm -rf "$backup_dir"
            ((deleted_count++))
        fi
    done
    
    log_success "Limpeza concluída. $deleted_count backup(s) removido(s)"
}

# Menu interativo
show_interactive_menu() {
    while true; do
        echo ""
        echo -e "${BLUE}=== SISTEMA AVANÇADO DE BACKUP E RESTORE ===${NC}"
        echo ""
        echo "📁 OPERAÇÕES DE BACKUP:"
        echo "  1) Criar backup completo de etapa"
        echo "  2) Criar checkpoint durante etapa"
        echo "  3) Backup de emergência (estado atual)"
        echo ""
        echo "🔄 OPERAÇÕES DE RESTORE:"
        echo "  4) Restore por cópia (selecionar backup)"
        echo "  5) Restore por Git (branch/tag/commit)"
        echo "  6) Restore de emergência (último estado bom)"
        echo ""
        echo "📊 UTILITÁRIOS:"
        echo "  7) Listar backups disponíveis"
        echo "  8) Validar integridade de backup"
        echo "  9) Limpar backups antigos"
        echo ""
        echo "  0) Sair"
        echo ""
        
        read -p "Escolha uma opção: " option
        
        case $option in
            1)
                read -p "Número da etapa (1-9): " etapa
                if [[ "$etapa" =~ ^[1-9]$ ]]; then
                    create_advanced_backup "$etapa" "manual"
                else
                    log_error "Etapa inválida"
                fi
                ;;
            2)
                read -p "Número da etapa (1-9): " etapa
                read -p "Nome do checkpoint: " checkpoint
                if [[ "$etapa" =~ ^[1-9]$ ]] && [ -n "$checkpoint" ]; then
                    create_advanced_backup "$etapa" "checkpoint" "$checkpoint"
                else
                    log_error "Dados inválidos"
                fi
                ;;
            3)
                create_advanced_backup "emergency" "panic-backup"
                ;;
            4)
                list_backups
                echo ""
                read -p "Caminho do backup (relativo a backups/): " backup_path
                if [ -d "$BACKUP_ROOT/$backup_path" ]; then
                    restore_from_copy "$BACKUP_ROOT/$backup_path"
                else
                    log_error "Backup não encontrado"
                fi
                ;;
            5)
                cd "$PROJECT_ROOT"
                echo "Branches disponíveis:"
                git branch -a 2>/dev/null || echo "Git não disponível"
                echo ""
                echo "Tags disponíveis:"
                git tag -l 2>/dev/null | tail -10 || echo "Nenhuma tag"
                echo ""
                read -p "Branch/Tag/Commit para restore: " git_ref
                if [ -n "$git_ref" ]; then
                    restore_from_git "$git_ref"
                fi
                cd "$AUTOMATION_DIR"
                ;;
            6)
                local last_good="$BACKUP_ROOT/emergency/last-known-good"
                if [ -d "$last_good" ]; then
                    restore_from_copy "$last_good"
                else
                    log_error "Backup de emergência não encontrado"
                fi
                ;;
            7)
                list_backups
                ;;
            8)
                read -p "Caminho do backup para validar: " backup_path
                if [ -d "$backup_path" ]; then
                    validate_backup_integrity "$backup_path"
                else
                    log_error "Backup não encontrado"
                fi
                ;;
            9)
                read -p "Dias de retenção (padrão: $BACKUP_RETENTION_DAYS): " retention
                retention=${retention:-$BACKUP_RETENTION_DAYS}
                cleanup_old_backups "$retention"
                ;;
            0)
                log_info "Saindo..."
                break
                ;;
            *)
                log_error "Opção inválida"
                ;;
        esac
        
        echo ""
        read -p "Pressione ENTER para continuar..."
    done
}

# Função principal
main() {
    # Criar diretório de logs se não existir
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Verificar se foi chamado com argumentos ou modo interativo
    if [ $# -eq 0 ]; then
        show_interactive_menu
    else
        # Modo linha de comando
        local operation=$1
        shift
        
        case $operation in
            "backup")
                if [ $# -ge 1 ]; then
                    create_advanced_backup "$@"
                else
                    log_error "Uso: $0 backup <etapa> [operacao] [checkpoint]"
                    exit 1
                fi
                ;;
            "restore-copy")
                if [ $# -ge 1 ]; then
                    restore_from_copy "$@"
                else
                    log_error "Uso: $0 restore-copy <caminho_backup> [destino] [force]"
                    exit 1
                fi
                ;;
            "restore-git")
                if [ $# -ge 1 ]; then
                    restore_from_git "$@"
                else
                    log_error "Uso: $0 restore-git <branch_tag_commit> [force]"
                    exit 1
                fi
                ;;
            "list")
                list_backups
                ;;
            "validate")
                if [ $# -ge 1 ]; then
                    validate_backup_integrity "$1"
                else
                    log_error "Uso: $0 validate <caminho_backup>"
                    exit 1
                fi
                ;;
            "cleanup")
                cleanup_old_backups "${1:-$BACKUP_RETENTION_DAYS}"
                ;;
            *)
                log_error "Operação inválida: $operation"
                echo "Operações disponíveis: backup, restore-copy, restore-git, list, validate, cleanup"
                exit 1
                ;;
        esac
    fi
}

# Executar função principal
main "$@" 