#!/bin/bash

# ================================================================
# ETAPA 5: CÓDIGO E COMANDOS
# ================================================================
# 
# Esta etapa atualiza referências no código fonte, comentários,
# strings hardcoded e registros de comandos.
# ================================================================

set -euo pipefail
IFS=$'\n\t'

# Carregar configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$AUTOMATION_DIR")"

if [ -f "$AUTOMATION_DIR/config.sh" ]; then
    source "$AUTOMATION_DIR/config.sh"
else
    echo "❌ Arquivo config.sh não encontrado!"
    exit 1
fi

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções de log
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Verificar pré-requisitos
if [ ! -f "$PROJECT_ROOT/package.json" ] || [ ! -f "$PROJECT_ROOT/src/package.json" ]; then
    log_error "Execute este script na raiz do projeto Roo-Code"
    exit 1
fi

log_header "ETAPA 5: CÓDIGO E COMANDOS"

# Função para backup de arquivo
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.etapa5"
        log_info "✅ Backup: $(basename "$file")"
    fi
}

# Função para processar arquivo de código
process_code_file() {
    local file=$1
    local file_type=$2
    
    log_info "Processando $file_type: $(basename "$file")"
    backup_file "$file"
    
    local changes=0
    
    # Substituições em strings e comentários
    if sed -i.tmp \
        -e 's/roo-cline/tqi-ai-assistant/g' \
        -e 's/Roo Code/TQI AI Assistant/g' \
        -e 's/RooCode/TQI AI Assistant/g' \
        -e 's/Roo-Code/TQI AI Assistant/g' \
        -e 's/RooVeterinaryInc/TQI/g' \
        -e 's/@roo-code\//@tqi\//g' \
        -e 's/roocode/tqi-ai-assistant/g' \
        -e 's/ROOCODE/TQI_AI_ASSISTANT/g' \
        -e 's/Cline/TQI AI Assistant/g' \
        "$file"; then
        
        # Verificar se houve mudanças
        if ! cmp -s "$file" "$file.tmp"; then
            mv "$file.tmp" "$file"
            changes=1
            log_success "✅ Atualizado: $(basename "$file")"
        else
            mv "$file.tmp" "$file"
            log_info "   Nenhuma mudança necessária"
        fi
    else
        log_error "❌ Erro ao processar: $file"
        rm -f "$file.tmp"
    fi
    
    return $changes
}

# Função para atualizar registros de comandos TypeScript
update_command_registrations() {
    log_header "Atualizando registros de comandos"
    
    local updated_files=0
    
    # Procurar por arquivos que registram comandos
    find "$PROJECT_ROOT/src" -name "*.ts" -type f | while read -r ts_file; do
        if grep -q "registerCommand\|commands\.register" "$ts_file" 2>/dev/null; then
            if process_code_file "$ts_file" "TypeScript Command"; then
                ((updated_files++))
            fi
        fi
    done
    
    log_info "📊 Arquivos de comando atualizados: $updated_files"
}

# Função para atualizar arquivos de extensão principal
update_extension_files() {
    log_header "Atualizando arquivos principais da extensão"
    
    local key_files=(
        "$PROJECT_ROOT/src/extension.ts"
        "$PROJECT_ROOT/src/activate/registerCommands.ts"
        "$PROJECT_ROOT/src/activate/handleTask.ts"
        "$PROJECT_ROOT/src/activate/handleUri.ts"
    )
    
    local updated=0
    
    for file in "${key_files[@]}"; do
        if [ -f "$file" ]; then
            if process_code_file "$file" "Extension File"; then
                ((updated++))
            fi
        fi
    done
    
    log_info "📊 Arquivos principais atualizados: $updated"
}

# Função para atualizar providers e serviços
update_providers_services() {
    log_header "Atualizando providers e serviços"
    
    local updated=0
    
    # Atualizar todos os arquivos em src/
    find "$PROJECT_ROOT/src" -name "*.ts" -type f | while read -r ts_file; do
        # Pular arquivos já processados
        if [[ "$ts_file" == *"/activate/"* ]]; then
            continue
        fi
        
        # Verificar se arquivo contém referências relevantes
        if grep -q "roo-cline\|Roo.*Code\|RooVeterinaryInc\|@roo-code" "$ts_file" 2>/dev/null; then
            if process_code_file "$ts_file" "Service/Provider"; then
                ((updated++))
            fi
        fi
    done
    
    log_info "📊 Providers/serviços atualizados: $updated"
}

# Função para atualizar webview
update_webview_code() {
    log_header "Atualizando código da webview"
    
    local updated=0
    
    # Atualizar arquivos TypeScript/React da webview
    find "$PROJECT_ROOT/webview-ui/src" -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | while read -r web_file; do
        if grep -q "roo-cline\|Roo.*Code\|@roo-code" "$web_file" 2>/dev/null; then
            if process_code_file "$web_file" "WebView"; then
                ((updated++))
            fi
        fi
    done
    
    log_info "📊 Arquivos webview atualizados: $updated"
}

# Função para atualizar aplicações auxiliares
update_apps_code() {
    log_header "Atualizando código das aplicações auxiliares"
    
    local updated=0
    
    # Atualizar arquivos das apps
    find "$PROJECT_ROOT/apps" -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | while read -r app_file; do
        if grep -q "roo-cline\|Roo.*Code\|@roo-code" "$app_file" 2>/dev/null; then
            if process_code_file "$app_file" "App"; then
                ((updated++))
            fi
        fi
    done
    
    log_info "📊 Arquivos de apps atualizados: $updated"
}

# Função para atualizar configurações ESLint e TypeScript
update_config_files() {
    log_header "Atualizando arquivos de configuração"
    
    local config_files=(
        "$PROJECT_ROOT/eslint.config.mjs"
        "$PROJECT_ROOT/src/eslint.config.mjs"
        "$PROJECT_ROOT/webview-ui/eslint.config.mjs"
        "$PROJECT_ROOT/tsconfig.json"
        "$PROJECT_ROOT/src/tsconfig.json"
        "$PROJECT_ROOT/webview-ui/tsconfig.json"
    )
    
    local updated=0
    
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            if grep -q "@roo-code\|roo-cline" "$config_file" 2>/dev/null; then
                if process_code_file "$config_file" "Config"; then
                    ((updated++))
                fi
            fi
        fi
    done
    
    log_info "📊 Arquivos de config atualizados: $updated"
}

# Função para atualizar comentários e logs
update_comments_logs() {
    log_header "Atualizando comentários e logs"
    
    local updated=0
    
    # Procurar por arquivos com comentários relevantes
    find "$PROJECT_ROOT/src" "$PROJECT_ROOT/webview-ui/src" -name "*.ts" -o -name "*.tsx" | while read -r file; do
        if grep -q "// .*[Rr]oo.*[Cc]ode\|/\* .*[Rr]oo.*[Cc]ode\|console.*[Rr]oo.*[Cc]ode" "$file" 2>/dev/null; then
            log_info "Atualizando comentários: $(basename "$file")"
            backup_file "$file"
            
            # Atualizar comentários específicos
            sed -i.tmp \
                -e 's|// Roo Code|// TQI AI Assistant|g' \
                -e 's|/\* Roo Code|/* TQI AI Assistant|g' \
                -e 's|console\.log.*".*[Rr]oo.*[Cc]ode"|console.log("TQI AI Assistant")|g' \
                "$file"
            
            if ! cmp -s "$file" "$file.tmp"; then
                mv "$file.tmp" "$file"
                ((updated++))
                log_success "✅ Comentários atualizados: $(basename "$file")"
            else
                mv "$file.tmp" "$file"
            fi
        fi
    done
    
    log_info "📊 Arquivos com comentários atualizados: $updated"
}

# Função para verificar e corrigir imports
fix_imports() {
    log_header "Verificando e corrigindo imports"
    
    local errors=0
    
    # Procurar por imports que podem estar quebrados
    find "$PROJECT_ROOT/src" "$PROJECT_ROOT/webview-ui/src" -name "*.ts" -o -name "*.tsx" | while read -r file; do
        # Verificar imports @roo-code que devem ser @tqi
        local bad_imports=$(grep -c "from ['\"]@roo-code/" "$file" 2>/dev/null || echo 0)
        if [ "$bad_imports" -gt 0 ]; then
            log_warning "⚠️  $bad_imports import(s) @roo-code em: $(basename "$file")"
            backup_file "$file"
            
            sed -i.tmp 's|from ["'"'"']@roo-code/|from "@tqi/|g' "$file"
            mv "$file.tmp" "$file"
            log_success "✅ Imports corrigidos: $(basename "$file")"
        fi
    done
    
    return $errors
}

# Função para validar TypeScript
validate_typescript() {
    log_header "Validando TypeScript"
    
    cd "$PROJECT_ROOT"
    
    if command -v pnpm > /dev/null 2>&1; then
        log_info "Executando verificação de tipos..."
        if pnpm check-types > /dev/null 2>&1; then
            log_success "✅ TypeScript compilation OK"
            return 0
        else
            log_warning "⚠️  TypeScript compilation tem avisos"
            return 1
        fi
    else
        log_warning "⚠️  pnpm não encontrado - pulando validação TS"
        return 0
    fi
}

# Função para buscar strings hardcoded restantes
find_remaining_references() {
    log_header "Procurando referências restantes"
    
    local patterns=(
        "roo-cline"
        "Roo Code"
        "RooCode"
        "Roo-Code"
        "RooVeterinaryInc"
        "@roo-code"
        "cline"
    )
    
    local total_refs=0
    
    for pattern in "${patterns[@]}"; do
        log_info "🔍 Procurando: $pattern"
        
        local count=$(find "$PROJECT_ROOT/src" "$PROJECT_ROOT/webview-ui/src" "$PROJECT_ROOT/apps" \
                     -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | \
                     xargs grep -l "$pattern" 2>/dev/null | wc -l)
        
        if [ "$count" -gt 0 ]; then
            log_warning "⚠️  $count arquivo(s) ainda contém '$pattern'"
            ((total_refs += count))
            
            # Mostrar arquivos específicos
            find "$PROJECT_ROOT/src" "$PROJECT_ROOT/webview-ui/src" "$PROJECT_ROOT/apps" \
                 -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | \
                 xargs grep -l "$pattern" 2>/dev/null | head -5 | while read -r file; do
                log_info "   - $(realpath --relative-to="$PROJECT_ROOT" "$file")"
            done
        else
            log_success "✅ Nenhuma referência '$pattern' encontrada"
        fi
    done
    
    log_info "📊 Total de referências restantes: $total_refs"
    return $total_refs
}

# Função principal
main() {
    log_header "INICIANDO ETAPA 5"
    
    local total_files_updated=0
    
    # 1. Atualizar registros de comandos
    update_command_registrations
    
    # 2. Atualizar arquivos principais da extensão
    update_extension_files
    
    # 3. Atualizar providers e serviços
    update_providers_services
    
    # 4. Atualizar código da webview
    update_webview_code
    
    # 5. Atualizar aplicações auxiliares
    update_apps_code
    
    # 6. Atualizar arquivos de configuração
    update_config_files
    
    # 7. Atualizar comentários e logs
    update_comments_logs
    
    # 8. Corrigir imports
    fix_imports
    
    # 9. Validar TypeScript
    local ts_valid=0
    if validate_typescript; then
        ts_valid=1
    fi
    
    # 10. Procurar referências restantes
    find_remaining_references
    local remaining_refs=$?
    
    # 11. Teste de build
    log_header "Teste de build"
    
    local build_success=0
    if command -v pnpm > /dev/null 2>&1; then
        log_info "Executando build..."
        if pnpm build > /dev/null 2>&1; then
            log_success "✅ Build passou"
            build_success=1
        else
            log_warning "⚠️  Build falhou - verificar erros"
        fi
    fi
    
    # 12. Relatório final
    log_header "RELATÓRIO FINAL ETAPA 5"
    
    if [ "$ts_valid" -eq 1 ] && [ "$build_success" -eq 1 ] && [ "$remaining_refs" -eq 0 ]; then
        log_success "🎉 ETAPA 5 CONCLUÍDA COM SUCESSO!"
        status="completed"
    elif [ "$remaining_refs" -gt 0 ]; then
        log_warning "⚠️  Etapa 5 concluída com referências restantes"
        status="completed_with_warnings"
    else
        log_warning "⚠️  Etapa 5 concluída com avisos"
        status="completed_with_warnings"
    fi
    
    # Criar relatório JSON
    mkdir -p "$AUTOMATION_DIR/logs"
    cat > "$AUTOMATION_DIR/logs/etapa5-report.json" << EOF
{
    "etapa": 5,
    "name": "codigo-comandos",
    "status": "$status",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "validation": {
        "typescript_valid": $ts_valid,
        "build_success": $build_success,
        "remaining_references": $remaining_refs
    },
    "statistics": {
        "total_ts_files": $(find "$PROJECT_ROOT/src" "$PROJECT_ROOT/webview-ui/src" "$PROJECT_ROOT/apps" -name "*.ts" -o -name "*.tsx" | wc -l),
        "total_js_files": $(find "$PROJECT_ROOT/src" "$PROJECT_ROOT/webview-ui/src" "$PROJECT_ROOT/apps" -name "*.js" -o -name "*.jsx" | wc -l),
        "config_files_checked": 6
    }
}
EOF
    
    log_info "📊 Estatísticas:"
    log_info "   - TypeScript válido: $([ $ts_valid -eq 1 ] && echo "Sim" || echo "Não")"
    log_info "   - Build bem-sucedido: $([ $build_success -eq 1 ] && echo "Sim" || echo "Não")"
    log_info "   - Referências restantes: $remaining_refs"
    log_info "   - Status: $status"
    
    log_info "📁 Relatório salvo: logs/etapa5-report.json"
    
    if [[ "$status" == "completed"* ]]; then
        log_info "➡️  Próxima etapa: ./etapas/etapa6.sh"
    fi
}

# Função de rollback
rollback_etapa5() {
    log_header "ROLLBACK ETAPA 5"
    
    log_info "Restaurando backups de código..."
    
    # Restaurar todos os arquivos .backup.etapa5
    find "$PROJECT_ROOT" -name "*.backup.etapa5" | while read -r backup; do
        original="${backup%.backup.etapa5}"
        if [ -f "$backup" ]; then
            mv "$backup" "$original"
            log_info "✅ Restaurado: $(realpath --relative-to="$PROJECT_ROOT" "$original")"
        fi
    done
    
    log_success "✅ Rollback concluído"
}

# Processar argumentos
case "${1:-}" in
    "--rollback")
        rollback_etapa5
        exit 0
        ;;
    "--help")
        echo "Uso: $0 [--rollback|--help]"
        echo "  --rollback  Desfaz as mudanças da etapa 5"
        echo "  --help      Mostra esta ajuda"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 