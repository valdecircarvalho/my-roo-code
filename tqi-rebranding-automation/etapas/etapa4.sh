#!/bin/bash

# ================================================================
# ETAPA 4: INTERNACIONALIZAÇÃO (i18n)
# ================================================================
# 
# Esta etapa atualiza todas as strings de internacionalização
# para refletir o novo branding TQI AI Assistant.
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

log_header "ETAPA 4: INTERNACIONALIZAÇÃO (i18n)"

# Diretórios de localização
I18N_MAIN="$PROJECT_ROOT/src/i18n/locales"
I18N_WEBVIEW="$PROJECT_ROOT/webview-ui/src/i18n/locales"
I18N_ROOT="$PROJECT_ROOT/locales"

# Função para backup de arquivo
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.etapa4"
        log_info "✅ Backup: $(basename "$file")"
    fi
}

# Função para validar JSON
validate_json() {
    local file=$1
    if command -v jq > /dev/null 2>&1; then
        if ! jq . "$file" > /dev/null 2>&1; then
            log_error "JSON inválido: $file"
            return 1
        fi
    fi
    return 0
}

# Função para atualizar arquivo de localização JSON
update_locale_json() {
    local file=$1
    local lang=$2
    
    log_info "Atualizando $lang: $(basename "$file")"
    backup_file "$file"
    
    if command -v jq > /dev/null 2>&1; then
        # Usar jq para substituições precisas
        jq '
        # Atualizar nome da extensão
        if .extension then
            .extension.displayName = "TQI AI Assistant" |
            .extension.description = "Assistente de IA inteligente para desenvolvimento de código"
        else . end |
        
        # Atualizar nomes de comandos
        if .commands then
            .commands = (.commands | with_entries(
                if (.value | test("Roo.*[Cc]ode|Cline")) then
                    .value = (.value | 
                        gsub("Roo Code|RooCode|Roo-Code"; "TQI AI Assistant") |
                        gsub("Cline"; "TQI AI Assistant")
                    )
                else . end
            ))
        else . end |
        
        # Atualizar views
        if .views then
            .views.activitybar.title = "TQI AI Assistant" |
            .views.sidebar.name = "TQI AI Assistant"
        else . end |
        
        # Atualizar menus de contexto
        if .contextMenu then
            .contextMenu.label = "TQI AI Assistant"
        else . end |
        
        # Atualizar menu terminal
        if .terminalMenu then
            .terminalMenu.label = "TQI AI Assistant"
        else . end
        ' "$file" > "$file.tmp"
        
        if validate_json "$file.tmp"; then
            mv "$file.tmp" "$file"
            log_success "✅ $lang atualizado"
        else
            log_error "❌ Erro ao atualizar $file"
            rm -f "$file.tmp"
            return 1
        fi
    else
        # Fallback usando sed se jq não estiver disponível
        sed -i.bak \
            -e 's/"Roo Code"/"TQI AI Assistant"/g' \
            -e 's/"RooCode"/"TQI AI Assistant"/g' \
            -e 's/"Roo-Code"/"TQI AI Assistant"/g' \
            -e 's/"Cline"/"TQI AI Assistant"/g' \
            -e 's/Roo Code/TQI AI Assistant/g' \
            -e 's/RooCode/TQI AI Assistant/g' \
            -e 's/Roo-Code/TQI AI Assistant/g' \
            "$file"
        
        if validate_json "$file"; then
            rm -f "$file.bak"
            log_success "✅ $lang atualizado (sed)"
        else
            log_error "❌ Erro no JSON - restaurando backup"
            mv "$file.bak" "$file"
            return 1
        fi
    fi
}

# Função para atualizar localização em português brasileiro
update_pt_br_specific() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    log_info "Aplicando traduções específicas PT-BR..."
    
    if command -v jq > /dev/null 2>&1; then
        jq '
        # Traduções específicas para PT-BR
        if .extension then
            .extension.displayName = "TQI Assistente de IA" |
            .extension.description = "Assistente inteligente de IA para desenvolvimento de código"
        else . end |
        
        if .views then
            .views.activitybar.title = "TQI Assistente de IA" |
            .views.sidebar.name = "TQI Assistente de IA"
        else . end
        ' "$file" > "$file.tmp"
        
        if validate_json "$file.tmp"; then
            mv "$file.tmp" "$file"
            log_success "✅ PT-BR específico aplicado"
        else
            rm -f "$file.tmp"
        fi
    fi
}

# Função para processar diretório de locales
process_locales_directory() {
    local locales_dir=$1
    local description=$2
    
    if [ ! -d "$locales_dir" ]; then
        log_warning "⚠️  Diretório não encontrado: $locales_dir"
        return 0
    fi
    
    log_header "Processando $description"
    log_info "📁 Diretório: $locales_dir"
    
    local updated_count=0
    
    # Processar cada idioma
    for lang_dir in "$locales_dir"/*; do
        if [ ! -d "$lang_dir" ]; then
            continue
        fi
        
        local lang=$(basename "$lang_dir")
        log_info "🌐 Processando idioma: $lang"
        
        # Procurar arquivos JSON de tradução
        find "$lang_dir" -name "*.json" -type f | while read -r json_file; do
            update_locale_json "$json_file" "$lang"
            ((updated_count++))
        done
        
        # Aplicar traduções específicas para PT-BR
        if [[ "$lang" =~ ^(pt|pt-BR|pt_BR)$ ]]; then
            find "$lang_dir" -name "*.json" -type f | while read -r json_file; do
                update_pt_br_specific "$json_file"
            done
        fi
    done
    
    log_info "📊 Arquivos processados: $updated_count"
    return $updated_count
}

# Função para criar arquivos de tradução se não existirem
create_missing_translations() {
    log_header "Verificando traduções obrigatórias"
    
    # Verificar se existe tradução em inglês (base)
    local en_file="$I18N_MAIN/en/extension.json"
    if [ ! -f "$en_file" ]; then
        log_warning "⚠️  Criando tradução base (EN)..."
        mkdir -p "$(dirname "$en_file")"
        cat > "$en_file" << 'EOF'
{
    "extension": {
        "displayName": "TQI AI Assistant",
        "description": "Intelligent AI assistant for code development"
    },
    "commands": {
        "newTask": "TQI AI Assistant: New Task",
        "openInNewTab": "TQI AI Assistant: Open in New Tab",
        "explainCode": "TQI AI Assistant: Explain Code",
        "fixCode": "TQI AI Assistant: Fix Code",
        "improveCode": "TQI AI Assistant: Improve Code"
    },
    "views": {
        "activitybar": {
            "title": "TQI AI Assistant"
        },
        "sidebar": {
            "name": "TQI AI Assistant"
        }
    },
    "contextMenu": {
        "label": "TQI AI Assistant"
    },
    "terminalMenu": {
        "label": "TQI AI Assistant"
    }
}
EOF
        log_success "✅ Tradução EN criada"
    fi
    
    # Verificar se existe tradução em português
    local pt_file="$I18N_MAIN/pt-BR/extension.json"
    if [ ! -f "$pt_file" ]; then
        log_warning "⚠️  Criando tradução PT-BR..."
        mkdir -p "$(dirname "$pt_file")"
        cat > "$pt_file" << 'EOF'
{
    "extension": {
        "displayName": "TQI Assistente de IA",
        "description": "Assistente inteligente de IA para desenvolvimento de código"
    },
    "commands": {
        "newTask": "TQI Assistente de IA: Nova Tarefa",
        "openInNewTab": "TQI Assistente de IA: Abrir em Nova Aba",
        "explainCode": "TQI Assistente de IA: Explicar Código",
        "fixCode": "TQI Assistente de IA: Corrigir Código",
        "improveCode": "TQI Assistente de IA: Melhorar Código"
    },
    "views": {
        "activitybar": {
            "title": "TQI Assistente de IA"
        },
        "sidebar": {
            "name": "TQI Assistente de IA"
        }
    },
    "contextMenu": {
        "label": "TQI Assistente de IA"
    },
    "terminalMenu": {
        "label": "TQI Assistente de IA"
    }
}
EOF
        log_success "✅ Tradução PT-BR criada"
    fi
}

# Função para atualizar documentação multilíngue
update_multilingual_docs() {
    log_header "Atualizando documentação multilíngue"
    
    if [ ! -d "$I18N_ROOT" ]; then
        log_warning "⚠️  Diretório de docs multilíngue não encontrado"
        return 0
    fi
    
    local updated_docs=0
    
    # Procurar por arquivos README.md e outros docs
    find "$I18N_ROOT" -name "README.md" -type f | while read -r readme_file; do
        local lang_dir=$(dirname "$readme_file")
        local lang=$(basename "$lang_dir")
        
        log_info "📝 Atualizando README $lang: $readme_file"
        backup_file "$readme_file"
        
        # Substituir referências ao nome antigo
        sed -i.bak \
            -e 's/Roo Code/TQI AI Assistant/g' \
            -e 's/RooCode/TQI AI Assistant/g' \
            -e 's/Roo-Code/TQI AI Assistant/g' \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            -e 's/RooVeterinaryInc/TQI/g' \
            -e 's|RooCodeInc/Roo-Code|SeuUsuario/tqi-ai-assistant|g' \
            "$readme_file"
        
        rm -f "$readme_file.bak"
        log_success "✅ README $lang atualizado"
        ((updated_docs++))
    done
    
    log_info "📊 Documentos atualizados: $updated_docs"
}

# Função para validar traduções
validate_translations() {
    log_header "Validando traduções"
    
    local errors=0
    local files_checked=0
    
    # Validar arquivos JSON de tradução
    find "$PROJECT_ROOT" -path "*/i18n/*" -name "*.json" -type f | while read -r json_file; do
        ((files_checked++))
        
        if ! validate_json "$json_file"; then
            log_error "❌ JSON inválido: $json_file"
            ((errors++))
        fi
        
        # Verificar se ainda há referências antigas
        local old_refs=$(grep -c "Roo.*Code\|Cline" "$json_file" 2>/dev/null || echo 0)
        if [ "$old_refs" -gt 0 ]; then
            log_warning "⚠️  $old_refs referência(s) antiga(s) em: $(basename "$json_file")"
        fi
    done
    
    log_info "📊 Arquivos verificados: $files_checked"
    
    if [ "$errors" -eq 0 ]; then
        log_success "✅ Todas as traduções são válidas"
    else
        log_error "❌ $errors erro(s) de validação encontrado(s)"
    fi
    
    return $errors
}

# Função principal
main() {
    log_header "INICIANDO ETAPA 4"
    
    local total_updated=0
    
    # 1. Criar traduções obrigatórias se não existirem
    create_missing_translations
    
    # 2. Processar locales da extensão principal
    if process_locales_directory "$I18N_MAIN" "Locales da extensão principal"; then
        local count=$?
        ((total_updated += count))
    fi
    
    # 3. Processar locales da webview
    if process_locales_directory "$I18N_WEBVIEW" "Locales da webview"; then
        local count=$?
        ((total_updated += count))
    fi
    
    # 4. Atualizar documentação multilíngue
    update_multilingual_docs
    
    # 5. Validar resultado
    validate_translations
    local validation_errors=$?
    
    # 6. Teste de integração com i18n
    log_header "Teste de integração i18n"
    
    if [ -f "$PROJECT_ROOT/src/i18n/index.ts" ]; then
        log_info "Verificando sistema i18n..."
        
        # Verificar se o sistema i18n carrega sem erros
        cd "$PROJECT_ROOT"
        if command -v pnpm > /dev/null 2>&1; then
            if pnpm check-types > /dev/null 2>&1; then
                log_success "✅ Sistema i18n integrado com sucesso"
            else
                log_warning "⚠️  Sistema i18n pode ter problemas de tipo"
            fi
        fi
    else
        log_warning "⚠️  Sistema i18n não encontrado"
    fi
    
    # 7. Relatório final
    log_header "RELATÓRIO FINAL ETAPA 4"
    
    if [ "$validation_errors" -eq 0 ]; then
        log_success "🎉 ETAPA 4 CONCLUÍDA COM SUCESSO!"
        status="completed"
    else
        log_warning "⚠️  Etapa 4 concluída com avisos"
        status="completed_with_warnings"
    fi
    
    # Criar relatório JSON
    mkdir -p "$AUTOMATION_DIR/logs"
    cat > "$AUTOMATION_DIR/logs/etapa4-report.json" << EOF
{
    "etapa": 4,
    "name": "internacionalizacao",
    "status": "$status",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "changes": {
        "translations_updated": $total_updated,
        "validation_errors": $validation_errors,
        "languages_found": $(find "$PROJECT_ROOT" -path "*/i18n/*" -type d -name "en*" -o -name "pt*" -o -name "es*" -o -name "fr*" | wc -l),
        "json_files_processed": $(find "$PROJECT_ROOT" -path "*/i18n/*" -name "*.json" | wc -l)
    },
    "locales": {
        "main_extension": $([ -d "$I18N_MAIN" ] && echo "true" || echo "false"),
        "webview": $([ -d "$I18N_WEBVIEW" ] && echo "true" || echo "false"),
        "docs": $([ -d "$I18N_ROOT" ] && echo "true" || echo "false")
    }
}
EOF
    
    log_info "📊 Estatísticas:"
    log_info "   - Traduções atualizadas: $total_updated"
    log_info "   - Erros de validação: $validation_errors"
    log_info "   - Status: $status"
    
    log_info "📁 Relatório salvo: logs/etapa4-report.json"
    
    if [[ "$status" == "completed"* ]]; then
        log_info "➡️  Próxima etapa: ./etapas/etapa5.sh"
    fi
}

# Função de rollback
rollback_etapa4() {
    log_header "ROLLBACK ETAPA 4"
    
    log_info "Restaurando backups de traduções..."
    
    # Restaurar todos os arquivos .backup.etapa4
    find "$PROJECT_ROOT" -name "*.backup.etapa4" | while read -r backup; do
        original="${backup%.backup.etapa4}"
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
        rollback_etapa4
        exit 0
        ;;
    "--help")
        echo "Uso: $0 [--rollback|--help]"
        echo "  --rollback  Desfaz as mudanças da etapa 4"
        echo "  --help      Mostra esta ajuda"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 