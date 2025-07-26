#!/bin/bash

# ================================================================
# ETAPA 9: VALIDAÇÃO E TESTES FINAIS
# ================================================================
# 
# Esta etapa final executa uma validação completa do rebranding,
# testes funcionais, verificações de integridade e gera relatórios.
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

log_header "ETAPA 9: VALIDAÇÃO E TESTES FINAIS"

# Contadores globais
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Função para registrar resultado de check
register_check() {
    local status=$1
    local description=$2
    
    ((TOTAL_CHECKS++))
    
    case $status in
        "pass")
            log_success "✅ $description"
            ((PASSED_CHECKS++))
            ;;
        "fail")
            log_error "❌ $description"
            ((FAILED_CHECKS++))
            ;;
        "warn")
            log_warning "⚠️  $description"
            ((WARNING_CHECKS++))
            ;;
    esac
}

# Função para validar estrutura do projeto
validate_project_structure() {
    log_header "Validando estrutura do projeto"
    
    # Verificar arquivos essenciais
    local essential_files=(
        "package.json"
        "src/package.json"
        "README.md"
        "CHANGELOG.md"
    )
    
    for file in "${essential_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            register_check "pass" "Arquivo essencial existe: $file"
        else
            register_check "fail" "Arquivo essencial ausente: $file"
        fi
    done
    
    # Verificar diretórios principais
    local essential_dirs=(
        "src"
        "packages"
        "webview-ui"
        "apps"
    )
    
    for dir in "${essential_dirs[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            register_check "pass" "Diretório principal existe: $dir"
        else
            register_check "warn" "Diretório principal ausente: $dir"
        fi
    done
}

# Função para validar JSON files
validate_json_files() {
    log_header "Validando arquivos JSON"
    
    if ! command -v jq > /dev/null 2>&1; then
        register_check "warn" "jq não disponível - validação JSON limitada"
        return 0
    fi
    
    local json_errors=0
    
    find "$PROJECT_ROOT" -name "*.json" -not -path "*/node_modules/*" -not -path "*/.git/*" | while read -r json_file; do
        if jq . "$json_file" > /dev/null 2>&1; then
            register_check "pass" "JSON válido: $(basename "$json_file")"
        else
            register_check "fail" "JSON inválido: $(basename "$json_file")"
            ((json_errors++))
        fi
    done
    
    if [ "$json_errors" -eq 0 ]; then
        register_check "pass" "Todos os arquivos JSON são válidos"
    else
        register_check "fail" "$json_errors arquivo(s) JSON com erros"
    fi
}

# Função para verificar rebranding completo
verify_rebranding_completeness() {
    log_header "Verificando completude do rebranding"
    
    # Patterns antigas que não devem existir
    local old_patterns=(
        "roo-cline"
        "Roo Code"
        "RooCode"
        "Roo-Code"
        "RooVeterinaryInc"
        "@roo-code/"
        "github.com/RooCodeInc/Roo-Code"
    )
    
    # Patterns novas que devem existir
    local new_patterns=(
        "tqi-ai-assistant"
        "TQI AI Assistant"
        "@tqi/"
        "github.com/SeuUsuario/tqi-ai-assistant"
    )
    
    # Verificar padrões antigos
    for pattern in "${old_patterns[@]}"; do
        local count=$(find "$PROJECT_ROOT" -type f \( -name "*.json" -o -name "*.md" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -exec grep -l "$pattern" {} \; 2>/dev/null | wc -l)
        
        if [ "$count" -eq 0 ]; then
            register_check "pass" "Nenhuma referência antiga encontrada: $pattern"
        else
            register_check "fail" "$count arquivo(s) ainda contém: $pattern"
        fi
    done
    
    # Verificar padrões novos (essenciais)
    for pattern in "${new_patterns[@]}"; do
        local count=$(find "$PROJECT_ROOT" -type f \( -name "*.json" -o -name "*.md" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -exec grep -l "$pattern" {} \; 2>/dev/null | wc -l)
        
        if [ "$count" -gt 0 ]; then
            register_check "pass" "$count arquivo(s) contém padrão novo: $pattern"
        else
            register_check "warn" "Padrão novo não encontrado: $pattern"
        fi
    done
}

# Função para verificar package.json principal
verify_main_package_json() {
    log_header "Verificando package.json principal da extensão"
    
    local pkg_file="$PROJECT_ROOT/src/package.json"
    
    if [ ! -f "$pkg_file" ]; then
        register_check "fail" "src/package.json não encontrado"
        return 1
    fi
    
    # Verificar campos críticos
    if command -v jq > /dev/null 2>&1; then
        local name=$(jq -r '.name // empty' "$pkg_file")
        local publisher=$(jq -r '.publisher // empty' "$pkg_file")
        local displayName=$(jq -r '.displayName // empty' "$pkg_file")
        
        if [ "$name" = "tqi-ai-assistant" ]; then
            register_check "pass" "Nome da extensão correto: $name"
        else
            register_check "fail" "Nome da extensão incorreto: $name (esperado: tqi-ai-assistant)"
        fi
        
        if [ "$publisher" = "TQI" ]; then
            register_check "pass" "Publisher correto: $publisher"
        else
            register_check "fail" "Publisher incorreto: $publisher (esperado: TQI)"
        fi
        
        if [ -n "$displayName" ]; then
            register_check "pass" "DisplayName definido: $displayName"
        else
            register_check "warn" "DisplayName não definido"
        fi
        
        # Verificar comandos
        local commands_count=$(jq '.contributes.commands | length' "$pkg_file" 2>/dev/null || echo 0)
        if [ "$commands_count" -gt 0 ]; then
            register_check "pass" "$commands_count comando(s) definido(s)"
            
            # Verificar se comandos usam prefixo correto
            local old_commands=$(jq -r '.contributes.commands[]?.command // empty' "$pkg_file" 2>/dev/null | grep -c "roo-cline" || echo 0)
            local new_commands=$(jq -r '.contributes.commands[]?.command // empty' "$pkg_file" 2>/dev/null | grep -c "tqi-ai-assistant" || echo 0)
            
            if [ "$old_commands" -eq 0 ]; then
                register_check "pass" "Nenhum comando com prefixo antigo"
            else
                register_check "fail" "$old_commands comando(s) ainda com prefixo antigo"
            fi
            
            if [ "$new_commands" -gt 0 ]; then
                register_check "pass" "$new_commands comando(s) com prefixo novo"
            else
                register_check "warn" "Nenhum comando com prefixo novo encontrado"
            fi
        else
            register_check "warn" "Nenhum comando definido"
        fi
    else
        register_check "warn" "jq não disponível - verificação limitada do package.json"
    fi
}

# Função para executar testes de build
run_build_tests() {
    log_header "Executando testes de build"
    
    cd "$PROJECT_ROOT"
    
    # Verificar se pnpm está disponível
    if ! command -v pnpm > /dev/null 2>&1; then
        register_check "warn" "pnpm não disponível - pulando testes de build"
        return 0
    fi
    
    # Limpar e instalar dependências
    log_info "Limpando e instalando dependências..."
    if pnpm clean > /dev/null 2>&1; then
        register_check "pass" "Limpeza realizada com sucesso"
    else
        register_check "warn" "Comando de limpeza falhou ou não existe"
    fi
    
    if pnpm install --frozen-lockfile > /dev/null 2>&1; then
        register_check "pass" "Instalação de dependências bem-sucedida"
    else
        register_check "fail" "Falha na instalação de dependências"
        return 1
    fi
    
    # Verificar TypeScript
    if pnpm check-types > /dev/null 2>&1; then
        register_check "pass" "Verificação de tipos TypeScript passou"
    else
        register_check "fail" "Verificação de tipos TypeScript falhou"
    fi
    
    # Build principal
    if pnpm build > /dev/null 2>&1; then
        register_check "pass" "Build principal bem-sucedido"
    else
        register_check "fail" "Build principal falhou"
        return 1
    fi
    
    # Verificar se arquivos de output foram gerados
    local output_dirs=("dist" "out" "build")
    local output_found=false
    
    for dir in "${output_dirs[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ] && [ "$(ls -A "$PROJECT_ROOT/$dir" 2>/dev/null)" ]; then
            register_check "pass" "Arquivos de output gerados em: $dir"
            output_found=true
            break
        fi
    done
    
    if [ "$output_found" = false ]; then
        register_check "warn" "Nenhum diretório de output encontrado"
    fi
}

# Função para testar geração VSIX
test_vsix_generation() {
    log_header "Testando geração de VSIX"
    
    cd "$PROJECT_ROOT"
    
    if ! command -v vsce > /dev/null 2>&1; then
        register_check "warn" "vsce não disponível - pulando teste VSIX"
        return 0
    fi
    
    # Gerar VSIX
    log_info "Gerando arquivo VSIX..."
    
    if pnpm vsix > /dev/null 2>&1; then
        register_check "pass" "Comando 'pnpm vsix' executou com sucesso"
    elif vsce package --no-dependencies > /dev/null 2>&1; then
        register_check "pass" "Geração VSIX com vsce bem-sucedida"
    else
        register_check "fail" "Falha na geração do VSIX"
        return 1
    fi
    
    # Verificar se arquivo VSIX foi criado
    local vsix_files=($(find "$PROJECT_ROOT" -name "*.vsix" -newer "$PROJECT_ROOT/src/package.json" 2>/dev/null))
    
    if [ ${#vsix_files[@]} -gt 0 ]; then
        local vsix_file="${vsix_files[0]}"
        local vsix_name=$(basename "$vsix_file")
        
        register_check "pass" "Arquivo VSIX gerado: $vsix_name"
        
        # Verificar nome do arquivo
        if [[ "$vsix_name" =~ ^tqi-ai-assistant.*\.vsix$ ]]; then
            register_check "pass" "Nome do VSIX está correto"
        else
            register_check "warn" "Nome do VSIX pode estar incorreto: $vsix_name"
        fi
        
        # Verificar tamanho do arquivo
        local size=$(stat -c%s "$vsix_file" 2>/dev/null || stat -f%z "$vsix_file" 2>/dev/null || echo 0)
        if [ "$size" -gt 100000 ]; then  # > 100KB
            register_check "pass" "Tamanho do VSIX parece adequado: $(($size / 1024))KB"
        else
            register_check "warn" "Tamanho do VSIX parece muito pequeno: $(($size / 1024))KB"
        fi
    else
        register_check "fail" "Nenhum arquivo VSIX encontrado"
    fi
}

# Função para verificar assets
verify_assets() {
    log_header "Verificando assets visuais"
    
    local assets_dir="$PROJECT_ROOT/src/assets"
    local required_assets=(
        "icons/icon.svg"
        "icons/icon.png"
    )
    
    for asset in "${required_assets[@]}"; do
        if [ -f "$assets_dir/$asset" ]; then
            register_check "pass" "Asset encontrado: $asset"
            
            # Verificar tamanho do arquivo
            local size=$(stat -c%s "$assets_dir/$asset" 2>/dev/null || stat -f%z "$assets_dir/$asset" 2>/dev/null || echo 0)
            if [ "$size" -gt 1000 ]; then  # > 1KB
                register_check "pass" "Tamanho do asset adequado: $asset"
            else
                register_check "warn" "Asset muito pequeno: $asset"
            fi
        else
            register_check "warn" "Asset ausente: $asset"
        fi
    done
    
    # Verificar favicons
    local favicon_paths=(
        "$PROJECT_ROOT/webview-ui/public/favicon.ico"
        "$PROJECT_ROOT/apps/web-roo-code/public/favicon.ico"
    )
    
    for favicon in "${favicon_paths[@]}"; do
        if [ -f "$favicon" ]; then
            register_check "pass" "Favicon encontrado: $(basename "$(dirname "$favicon")")/favicon.ico"
        else
            register_check "warn" "Favicon ausente: $(basename "$(dirname "$favicon")")/favicon.ico"
        fi
    done
}

# Função para verificar traduções
verify_translations() {
    log_header "Verificando traduções"
    
    local i18n_dirs=(
        "$PROJECT_ROOT/src/i18n/locales"
        "$PROJECT_ROOT/webview-ui/src/i18n/locales"
        "$PROJECT_ROOT/locales"
    )
    
    local total_translations=0
    
    for i18n_dir in "${i18n_dirs[@]}"; do
        if [ -d "$i18n_dir" ]; then
            local lang_count=$(find "$i18n_dir" -type d -mindepth 1 -maxdepth 1 | wc -l)
            if [ "$lang_count" -gt 0 ]; then
                register_check "pass" "$lang_count idioma(s) encontrado(s) em: $(basename "$i18n_dir")"
                ((total_translations += lang_count))
            else
                register_check "warn" "Nenhum idioma encontrado em: $(basename "$i18n_dir")"
            fi
        fi
    done
    
    if [ "$total_translations" -gt 0 ]; then
        register_check "pass" "Total de $total_translations configuração(ões) de idioma"
    else
        register_check "warn" "Nenhuma configuração de idioma encontrada"
    fi
}

# Função para gerar relatório final
generate_final_report() {
    log_header "Gerando relatório final"
    
    local report_file="$AUTOMATION_DIR/logs/etapa9-final-report.json"
    local summary_file="$AUTOMATION_DIR/logs/rebranding-summary.txt"
    
    # Relatório JSON detalhado
    cat > "$report_file" << EOF
{
    "etapa": 9,
    "name": "validacao-testes-finais",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "validation_summary": {
        "total_checks": $TOTAL_CHECKS,
        "passed_checks": $PASSED_CHECKS,
        "failed_checks": $FAILED_CHECKS,
        "warning_checks": $WARNING_CHECKS,
        "success_rate": $(echo "scale=2; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc -l 2>/dev/null || echo "0")
    },
    "project_status": {
        "rebranding_complete": $([ $FAILED_CHECKS -eq 0 ] && echo "true" || echo "false"),
        "build_functional": $([ -d "$PROJECT_ROOT/dist" ] || [ -d "$PROJECT_ROOT/out" ] && echo "true" || echo "false"),
        "vsix_generated": $(find "$PROJECT_ROOT" -name "*.vsix" -newer "$PROJECT_ROOT/src/package.json" 2>/dev/null | wc -l | xargs test 0 -lt && echo "true" || echo "false")
    },
    "etapas_completed": {
        "etapa1": $([ -f "$AUTOMATION_DIR/logs/etapa1-report.json" ] && echo "true" || echo "false"),
        "etapa2": $([ -f "$AUTOMATION_DIR/logs/etapa2-report.json" ] && echo "true" || echo "false"),
        "etapa3": $([ -f "$AUTOMATION_DIR/logs/etapa3-report.json" ] && echo "true" || echo "false"),
        "etapa4": $([ -f "$AUTOMATION_DIR/logs/etapa4-report.json" ] && echo "true" || echo "false"),
        "etapa5": $([ -f "$AUTOMATION_DIR/logs/etapa5-report.json" ] && echo "true" || echo "false"),
        "etapa6": $([ -f "$AUTOMATION_DIR/logs/etapa6-report.json" ] && echo "true" || echo "false"),
        "etapa7": $([ -f "$AUTOMATION_DIR/logs/etapa7-report.json" ] && echo "true" || echo "false"),
        "etapa8": $([ -f "$AUTOMATION_DIR/logs/etapa8-report.json" ] && echo "true" || echo "false"),
        "etapa9": true
    }
}
EOF
    
    # Relatório de texto resumido
    cat > "$summary_file" << EOF
============================================================
RELATÓRIO FINAL - REBRANDING TQI AI ASSISTANT
============================================================
Gerado em: $(date)

RESUMO DA VALIDAÇÃO:
- Total de verificações: $TOTAL_CHECKS
- Verificações passou: $PASSED_CHECKS
- Verificações falharam: $FAILED_CHECKS  
- Verificações com aviso: $WARNING_CHECKS
- Taxa de sucesso: $(echo "scale=1; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc -l 2>/dev/null || echo "N/A")%

STATUS DO PROJETO:
EOF
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo "✅ REBRANDING COMPLETO COM SUCESSO!" >> "$summary_file"
    elif [ $FAILED_CHECKS -le 3 ]; then
        echo "⚠️  REBRANDING COMPLETO COM AVISOS MENORES" >> "$summary_file"
    else
        echo "❌ REBRANDING INCOMPLETO - $FAILED_CHECKS PROBLEMAS CRÍTICOS" >> "$summary_file"
    fi
    
    cat >> "$summary_file" << EOF

PRÓXIMOS PASSOS:
EOF
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        cat >> "$summary_file" << EOF
1. ✅ Extensão pronta para publicação
2. 📦 Arquivo VSIX gerado e testado
3. 🚀 Publicar no VSCode Marketplace
4. 📢 Comunicar mudança de branding
5. 📚 Atualizar documentação externa
EOF
    else
        cat >> "$summary_file" << EOF
1. ❌ Corrigir os $FAILED_CHECKS problema(s) crítico(s)
2. 🔄 Re-executar validação: ./etapas/etapa9.sh
3. 📋 Verificar logs detalhados para correções
EOF
    fi
    
    cat >> "$summary_file" << EOF

ETAPAS EXECUTADAS:
EOF
    
    for i in {1..9}; do
        if [ -f "$AUTOMATION_DIR/logs/etapa${i}-report.json" ]; then
            echo "✅ Etapa $i: Concluída" >> "$summary_file"
        else
            echo "❌ Etapa $i: Não executada" >> "$summary_file"
        fi
    done
    
    cat >> "$summary_file" << EOF

ARQUIVOS GERADOS:
- $(find "$PROJECT_ROOT" -name "*.vsix" 2>/dev/null | wc -l) arquivo(s) VSIX
- $(find "$AUTOMATION_DIR/logs" -name "*.json" 2>/dev/null | wc -l) relatório(s) JSON
- $(find "$AUTOMATION_DIR/logs" -name "*.txt" 2>/dev/null | wc -l) relatório(s) de texto

Para mais detalhes, consulte:
- $report_file
- $AUTOMATION_DIR/logs/
============================================================
EOF
    
    log_success "✅ Relatório final salvo: logs/etapa9-final-report.json"
    log_success "✅ Resumo salvo: logs/rebranding-summary.txt"
}

# Função principal
main() {
    log_header "INICIANDO ETAPA 9 - VALIDAÇÃO FINAL"
    
    log_info "Esta é a última etapa do rebranding TQI AI Assistant"
    log_info "Executando validação completa..."
    
    # Resetar contadores
    TOTAL_CHECKS=0
    PASSED_CHECKS=0
    FAILED_CHECKS=0
    WARNING_CHECKS=0
    
    # Executar todas as validações
    validate_project_structure
    validate_json_files
    verify_rebranding_completeness
    verify_main_package_json
    run_build_tests
    test_vsix_generation
    verify_assets
    verify_translations
    
    # Gerar relatório final
    generate_final_report
    
    # Resultado final
    log_header "RESULTADO FINAL"
    
    local success_rate=0
    if [ $TOTAL_CHECKS -gt 0 ]; then
        success_rate=$(echo "scale=1; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc -l 2>/dev/null || echo "0")
    fi
    
    log_info "📊 Estatísticas finais:"
    log_info "   - Total de verificações: $TOTAL_CHECKS"
    log_info "   - Passou: $PASSED_CHECKS"
    log_info "   - Falhou: $FAILED_CHECKS"
    log_info "   - Avisos: $WARNING_CHECKS"
    log_info "   - Taxa de sucesso: ${success_rate}%"
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        log_success "🎉 REBRANDING TQI AI ASSISTANT CONCLUÍDO COM SUCESSO!"
        log_success "✅ Projeto pronto para publicação"
        
        # Mostrar arquivos importantes gerados
        local vsix_files=($(find "$PROJECT_ROOT" -name "*.vsix" 2>/dev/null))
        if [ ${#vsix_files[@]} -gt 0 ]; then
            log_success "📦 VSIX gerado: $(basename "${vsix_files[0]}")"
        fi
        
        status="completed"
    elif [ $FAILED_CHECKS -le 3 ]; then
        log_warning "⚠️  REBRANDING CONCLUÍDO COM AVISOS MENORES"
        log_warning "📋 $FAILED_CHECKS problema(s) menor(es) detectado(s)"
        log_info "💡 Verifique os logs para correções opcionais"
        status="completed_with_warnings"
    else
        log_error "❌ REBRANDING INCOMPLETO"
        log_error "📋 $FAILED_CHECKS problema(s) crítico(s) encontrado(s)"
        log_error "🔧 Corrija os problemas antes de prosseguir"
        status="failed"
    fi
    
    # Salvar status final
    cat > "$AUTOMATION_DIR/logs/etapa9-report.json" << EOF
{
    "etapa": 9,
    "name": "validacao-testes-finais",
    "status": "$status",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "final_validation": {
        "total_checks": $TOTAL_CHECKS,
        "passed_checks": $PASSED_CHECKS,
        "failed_checks": $FAILED_CHECKS,
        "warning_checks": $WARNING_CHECKS,
        "success_rate": $success_rate
    }
}
EOF
    
    log_info "📁 Relatórios finais:"
    log_info "   - logs/etapa9-report.json"
    log_info "   - logs/etapa9-final-report.json"
    log_info "   - logs/rebranding-summary.txt"
    
    if [[ "$status" == "completed"* ]]; then
        log_info "🎊 PARABÉNS! Rebranding TQI AI Assistant finalizado!"
    fi
}

# Esta etapa é de validação final - não tem rollback
case "${1:-}" in
    "--help")
        echo "Uso: $0 [--help]"
        echo "  --help      Mostra esta ajuda"
        echo ""
        echo "Esta etapa executa validação final e gera relatórios."
        echo "Não há função de rollback - é apenas validação."
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 