#!/bin/bash

# ================================================================
# ETAPA 7: URLs E LINKS (VERIFICAÇÃO)
# ================================================================
# 
# Esta etapa verifica se todas as URLs foram atualizadas corretamente
# nas etapas anteriores. Não faz modificações, apenas validação.
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

log_header "ETAPA 7: VERIFICAÇÃO DE URLs E LINKS"

# URLs antigas que não devem mais existir
OLD_URLS=(
    "github.com/RooCodeInc/Roo-Code"
    "RooCodeInc/Roo-Code"
    "marketplace.visualstudio.com/publishers/RooVeterinaryInc"
    "dev@roocode.com"
    "roocode.com"
)

# URLs novas esperadas
NEW_URLS=(
    "github.com/SeuUsuario/tqi-ai-assistant"
    "SeuUsuario/tqi-ai-assistant"
    "marketplace.visualstudio.com/publishers/TQI"
    "dev-ai@tqi.com.br"
    "tqi.com.br"
)

# Função para verificar URLs em arquivo
check_urls_in_file() {
    local file=$1
    local file_type=$2
    
    log_info "Verificando URLs em $file_type: $(basename "$file")"
    
    local errors=0
    local warnings=0
    
    # Verificar URLs antigas
    for old_url in "${OLD_URLS[@]}"; do
        local count=$(grep -c "$old_url" "$file" 2>/dev/null || echo 0)
        if [ "$count" -gt 0 ]; then
            log_error "❌ $count ocorrência(s) de URL antiga: $old_url"
            ((errors++))
        fi
    done
    
    # Verificar se URLs novas estão presentes (quando aplicável)
    if [[ "$file" == *"package.json" ]] || [[ "$file" == *"README.md" ]]; then
        for new_url in "${NEW_URLS[@]}"; do
            if grep -q "$new_url" "$file" 2>/dev/null; then
                log_success "✅ URL nova encontrada: $new_url"
            else
                log_warning "⚠️  URL nova não encontrada: $new_url"
                ((warnings++))
            fi
        done
    fi
    
    return $((errors + warnings))
}

# Função para verificar package.json files
verify_package_json_urls() {
    log_header "Verificando URLs em package.json files"
    
    local total_errors=0
    
    # Arquivos package.json principais
    local package_files=(
        "$PROJECT_ROOT/package.json"
        "$PROJECT_ROOT/src/package.json"
        "$PROJECT_ROOT/webview-ui/package.json"
    )
    
    for pkg_file in "${package_files[@]}"; do
        if [ -f "$pkg_file" ]; then
            check_urls_in_file "$pkg_file" "package.json"
            ((total_errors += $?))
        fi
    done
    
    # Verificar todos os package.json do monorepo
    find "$PROJECT_ROOT" -name "package.json" -not -path "*/node_modules/*" | while read -r pkg_file; do
        # Pular se já verificamos acima
        local skip=false
        for main_pkg in "${package_files[@]}"; do
            if [ "$pkg_file" = "$main_pkg" ]; then
                skip=true
                break
            fi
        done
        
        if [ "$skip" = false ]; then
            check_urls_in_file "$pkg_file" "package.json"
            ((total_errors += $?))
        fi
    done
    
    log_info "📊 Total de problemas em package.json: $total_errors"
    return $total_errors
}

# Função para verificar documentação
verify_documentation_urls() {
    log_header "Verificando URLs na documentação"
    
    local total_errors=0
    
    # Arquivos de documentação principais
    local doc_files=(
        "$PROJECT_ROOT/README.md"
        "$PROJECT_ROOT/CHANGELOG.md"
        "$PROJECT_ROOT/CONTRIBUTING.md"
        "$PROJECT_ROOT/CODE_OF_CONDUCT.md"
        "$PROJECT_ROOT/SECURITY.md"
    )
    
    for doc_file in "${doc_files[@]}"; do
        if [ -f "$doc_file" ]; then
            check_urls_in_file "$doc_file" "documentação"
            ((total_errors += $?))
        fi
    done
    
    # Verificar documentação em subdiretórios
    find "$PROJECT_ROOT" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" | while read -r md_file; do
        # Pular se já verificamos acima
        local skip=false
        for main_doc in "${doc_files[@]}"; do
            if [ "$md_file" = "$main_doc" ]; then
                skip=true
                break
            fi
        done
        
        if [ "$skip" = false ]; then
            check_urls_in_file "$md_file" "documentação"
            ((total_errors += $?))
        fi
    done
    
    log_info "📊 Total de problemas na documentação: $total_errors"
    return $total_errors
}

# Função para verificar arquivos de configuração
verify_config_urls() {
    log_header "Verificando URLs em configurações"
    
    local total_errors=0
    
    # Arquivos de configuração
    local config_files=(
        "$PROJECT_ROOT/.vscode/settings.json"
        "$PROJECT_ROOT/.github/workflows/"
        "$PROJECT_ROOT/ellipsis.yaml"
        "$PROJECT_ROOT/turbo.json"
    )
    
    for config_item in "${config_files[@]}"; do
        if [ -f "$config_item" ]; then
            check_urls_in_file "$config_item" "configuração"
            ((total_errors += $?))
        elif [ -d "$config_item" ]; then
            find "$config_item" -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.json" \) | while read -r config_file; do
                check_urls_in_file "$config_file" "configuração"
                ((total_errors += $?))
            done
        fi
    done
    
    log_info "📊 Total de problemas em configurações: $total_errors"
    return $total_errors
}

# Função para verificar código fonte
verify_source_code_urls() {
    log_header "Verificando URLs no código fonte"
    
    local total_errors=0
    
    # Verificar arquivos TypeScript/JavaScript
    find "$PROJECT_ROOT/src" "$PROJECT_ROOT/webview-ui/src" -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | while read -r src_file; do
        local errors=0
        
        # Verificar apenas URLs antigas (problemáticas)
        for old_url in "${OLD_URLS[@]}"; do
            local count=$(grep -c "$old_url" "$src_file" 2>/dev/null || echo 0)
            if [ "$count" -gt 0 ]; then
                log_error "❌ $count ocorrência(s) de URL antiga em código: $(basename "$src_file") -> $old_url"
                ((errors++))
            fi
        done
        
        ((total_errors += errors))
    done
    
    log_info "📊 Total de problemas no código fonte: $total_errors"
    return $total_errors
}

# Função para gerar relatório de URLs
generate_url_report() {
    log_header "Gerando relatório de URLs"
    
    local report_file="$AUTOMATION_DIR/logs/etapa7-url-report.txt"
    
    cat > "$report_file" << EOF
RELATÓRIO DE VERIFICAÇÃO DE URLs - TQI AI ASSISTANT
Gerado em: $(date)

=== URLs ANTIGAS QUE NÃO DEVEM EXISTIR ===
EOF
    
    for old_url in "${OLD_URLS[@]}"; do
        echo "- $old_url" >> "$report_file"
        local total_occurrences=$(find "$PROJECT_ROOT" -type f \( -name "*.json" -o -name "*.md" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -exec grep -l "$old_url" {} \; 2>/dev/null | wc -l)
        echo "  Encontrado em $total_occurrences arquivo(s)" >> "$report_file"
        
        if [ "$total_occurrences" -gt 0 ]; then
            echo "  Arquivos afetados:" >> "$report_file"
            find "$PROJECT_ROOT" -type f \( -name "*.json" -o -name "*.md" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -exec grep -l "$old_url" {} \; 2>/dev/null | while read -r file; do
                echo "    - $(realpath --relative-to="$PROJECT_ROOT" "$file")" >> "$report_file"
            done
        fi
        echo "" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

=== URLs NOVAS ESPERADAS ===
EOF
    
    for new_url in "${NEW_URLS[@]}"; do
        echo "- $new_url" >> "$report_file"
        local total_occurrences=$(find "$PROJECT_ROOT" -type f \( -name "*.json" -o -name "*.md" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -exec grep -l "$new_url" {} \; 2>/dev/null | wc -l)
        echo "  Encontrado em $total_occurrences arquivo(s)" >> "$report_file"
        echo "" >> "$report_file"
    done
    
    log_success "✅ Relatório de URLs salvo: logs/etapa7-url-report.txt"
}

# Função para verificar conectividade (opcional)
test_url_connectivity() {
    log_header "Testando conectividade das URLs (opcional)"
    
    if ! command -v curl > /dev/null 2>&1; then
        log_warning "⚠️  curl não disponível - pulando teste de conectividade"
        return 0
    fi
    
    # URLs TQI para testar (ajustar conforme necessário)
    local urls_to_test=(
        "https://www.tqi.com.br"
        "https://github.com/SeuUsuario/tqi-ai-assistant"
    )
    
    local connectivity_ok=0
    
    for url in "${urls_to_test[@]}"; do
        log_info "🌐 Testando: $url"
        
        if curl -s --head --max-time 10 "$url" > /dev/null 2>&1; then
            log_success "✅ Conectividade OK: $url"
            ((connectivity_ok++))
        else
            log_warning "⚠️  Sem conectividade ou URL não existe: $url"
        fi
    done
    
    log_info "📊 URLs com conectividade: $connectivity_ok/${#urls_to_test[@]}"
}

# Função principal
main() {
    log_header "INICIANDO ETAPA 7"
    
    log_info "ℹ️  Esta etapa apenas VERIFICA URLs - não faz modificações"
    log_info "ℹ️  URLs devem ter sido atualizadas nas etapas anteriores"
    
    local total_errors=0
    
    # 1. Verificar package.json files
    verify_package_json_urls
    ((total_errors += $?))
    
    # 2. Verificar documentação
    verify_documentation_urls
    ((total_errors += $?))
    
    # 3. Verificar configurações
    verify_config_urls
    ((total_errors += $?))
    
    # 4. Verificar código fonte
    verify_source_code_urls
    ((total_errors += $?))
    
    # 5. Gerar relatório detalhado
    generate_url_report
    
    # 6. Testar conectividade (opcional)
    test_url_connectivity
    
    # 7. Relatório final
    log_header "RELATÓRIO FINAL ETAPA 7"
    
    if [ "$total_errors" -eq 0 ]; then
        log_success "🎉 ETAPA 7 CONCLUÍDA COM SUCESSO!"
        log_success "✅ Todas as URLs estão atualizadas corretamente"
        status="completed"
    elif [ "$total_errors" -le 3 ]; then
        log_warning "⚠️  Etapa 7 concluída com avisos menores"
        log_warning "📋 $total_errors problema(s) encontrado(s) - verificar relatório"
        status="completed_with_warnings"
    else
        log_error "❌ ETAPA 7 FALHOU"
        log_error "📋 $total_errors problema(s) crítico(s) encontrado(s)"
        status="failed"
    fi
    
    # Criar relatório JSON
    mkdir -p "$AUTOMATION_DIR/logs"
    cat > "$AUTOMATION_DIR/logs/etapa7-report.json" << EOF
{
    "etapa": 7,
    "name": "urls-links",
    "status": "$status",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "validation": {
        "total_errors": $total_errors,
        "old_urls_found": $(find "$PROJECT_ROOT" -type f \( -name "*.json" -o -name "*.md" -o -name "*.ts" -o -name "*.tsx" \) -not -path "*/node_modules/*" -exec grep -l "github.com/RooCodeInc/Roo-Code\|RooVeterinaryInc" {} \; 2>/dev/null | wc -l),
        "new_urls_found": $(find "$PROJECT_ROOT" -type f \( -name "*.json" -o -name "*.md" \) -not -path "*/node_modules/*" -exec grep -l "SeuUsuario/tqi-ai-assistant\|TQI" {} \; 2>/dev/null | wc -l)
    },
    "checks": {
        "package_json": "completed",
        "documentation": "completed",
        "config_files": "completed",
        "source_code": "completed",
        "connectivity_test": "optional"
    },
    "files_checked": {
        "total_files": $(find "$PROJECT_ROOT" -type f \( -name "*.json" -o -name "*.md" -o -name "*.ts" -o -name "*.tsx" \) -not -path "*/node_modules/*" | wc -l),
        "json_files": $(find "$PROJECT_ROOT" -name "*.json" -not -path "*/node_modules/*" | wc -l),
        "md_files": $(find "$PROJECT_ROOT" -name "*.md" -not -path "*/node_modules/*" | wc -l),
        "source_files": $(find "$PROJECT_ROOT" -name "*.ts" -o -name "*.tsx" -not -path "*/node_modules/*" | wc -l)
    }
}
EOF
    
    log_info "📊 Estatísticas:"
    log_info "   - Total de problemas: $total_errors"
    log_info "   - Status: $status"
    log_info "   - Arquivos verificados: $(find "$PROJECT_ROOT" -type f \( -name "*.json" -o -name "*.md" -o -name "*.ts" -o -name "*.tsx" \) -not -path "*/node_modules/*" | wc -l)"
    
    log_info "📁 Relatórios salvos:"
    log_info "   - logs/etapa7-report.json"
    log_info "   - logs/etapa7-url-report.txt"
    
    if [[ "$status" == "completed"* ]]; then
        log_info "➡️  Próxima etapa: ./etapas/etapa8.sh"
    else
        log_warning "⚠️  Corrija os problemas antes de prosseguir"
        log_info "💡 Verifique o relatório detalhado: logs/etapa7-url-report.txt"
    fi
}

# Esta etapa é apenas de verificação - não há rollback
case "${1:-}" in
    "--help")
        echo "Uso: $0 [--help]"
        echo "  --help      Mostra esta ajuda"
        echo ""
        echo "Esta etapa apenas VERIFICA URLs - não faz modificações."
        echo "Não há função de rollback porque nenhum arquivo é alterado."
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 