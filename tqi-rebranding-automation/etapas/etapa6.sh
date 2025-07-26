#!/bin/bash

# ================================================================
# ETAPA 6: DOCUMENTAÇÃO
# ================================================================
# 
# Esta etapa atualiza toda a documentação do projeto incluindo
# README, CHANGELOG, CONTRIBUTING, LICENSE e outros docs.
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

log_header "ETAPA 6: DOCUMENTAÇÃO"

# Função para backup de arquivo
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.etapa6"
        log_info "✅ Backup: $(basename "$file")"
    fi
}

# Função para atualizar documentação principal
update_main_readme() {
    log_header "Atualizando README principal"
    
    local readme_file="$PROJECT_ROOT/README.md"
    
    if [ -f "$readme_file" ]; then
        backup_file "$readme_file"
        
        # Usar template se disponível
        if [ -f "$AUTOMATION_DIR/templates/README-TQI.md" ]; then
            log_info "Usando template TQI README..."
            cp "$AUTOMATION_DIR/templates/README-TQI.md" "$readme_file"
            log_success "✅ README principal substituído pelo template TQI"
        else
            log_info "Atualizando README existente..."
            sed -i.bak \
                -e 's/Roo Code/TQI AI Assistant/g' \
                -e 's/RooCode/TQI AI Assistant/g' \
                -e 's/Roo-Code/TQI AI Assistant/g' \
                -e 's/roo-cline/tqi-ai-assistant/g' \
                -e 's/RooVeterinaryInc/TQI/g' \
                -e 's|RooCodeInc/Roo-Code|SeuUsuario/tqi-ai-assistant|g' \
                -e 's|https://github.com/RooCodeInc/Roo-Code|https://github.com/SeuUsuario/tqi-ai-assistant|g' \
                "$readme_file"
            
            rm -f "$readme_file.bak"
            log_success "✅ README principal atualizado"
        fi
    else
        log_warning "⚠️  README.md não encontrado - criando novo"
        if [ -f "$AUTOMATION_DIR/templates/README-TQI.md" ]; then
            cp "$AUTOMATION_DIR/templates/README-TQI.md" "$readme_file"
            log_success "✅ README principal criado a partir do template"
        fi
    fi
}

# Função para atualizar CHANGELOG
update_changelog() {
    log_header "Atualizando CHANGELOG"
    
    local changelog_file="$PROJECT_ROOT/CHANGELOG.md"
    
    if [ -f "$changelog_file" ]; then
        backup_file "$changelog_file"
        
        # Adicionar entrada de rebranding no topo
        local temp_file=$(mktemp)
        cat > "$temp_file" << EOF
# Changelog

## [1.0.0] - $(date +%Y-%m-%d)

### Added
- Rebranding completo para TQI AI Assistant
- Nova identidade visual e branding
- Documentação atualizada para TQI
- Configurações e comandos rebrandizados

### Changed
- Nome da extensão: roo-cline → tqi-ai-assistant
- Publisher: RooVeterinaryInc → TQI
- Todos os comandos agora começam com 'tqi-ai-assistant.'
- URLs do repositório atualizadas para GitHub TQI

### Removed
- Referências ao branding anterior Roo Code

---

EOF
        
        # Adicionar conteúdo existente (pular primeira linha se for "# Changelog")
        if head -1 "$changelog_file" | grep -q "# Changelog"; then
            tail -n +2 "$changelog_file" >> "$temp_file"
        else
            cat "$changelog_file" >> "$temp_file"
        fi
        
        mv "$temp_file" "$changelog_file"
        log_success "✅ CHANGELOG atualizado com entrada de rebranding"
    else
        log_warning "⚠️  CHANGELOG.md não encontrado - criando novo"
        cat > "$changelog_file" << EOF
# Changelog

## [1.0.0] - $(date +%Y-%m-%d)

### Added
- Lançamento inicial do TQI AI Assistant
- Assistente de IA inteligente para desenvolvimento
- Suporte a múltiplos provedores de IA
- Interface integrada ao VSCode
- Comandos avançados de código

### Features
- Análise e explicação de código
- Correção automática de bugs  
- Melhorias de código sugeridas
- Geração de documentação
- Suporte a múltiplas linguagens

EOF
        log_success "✅ CHANGELOG criado"
    fi
}

# Função para atualizar documentação de contribuição
update_contributing() {
    log_header "Atualizando CONTRIBUTING"
    
    local contributing_file="$PROJECT_ROOT/CONTRIBUTING.md"
    
    if [ -f "$contributing_file" ]; then
        backup_file "$contributing_file"
        
        sed -i.bak \
            -e 's/Roo Code/TQI AI Assistant/g' \
            -e 's/RooCode/TQI AI Assistant/g' \
            -e 's/Roo-Code/TQI AI Assistant/g' \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            -e 's/RooVeterinaryInc/TQI/g' \
            -e 's|RooCodeInc/Roo-Code|SeuUsuario/tqi-ai-assistant|g' \
            -e 's|dev@roocode.com|dev-ai@tqi.com.br|g' \
            "$contributing_file"
        
        rm -f "$contributing_file.bak"
        log_success "✅ CONTRIBUTING.md atualizado"
    else
        log_warning "⚠️  CONTRIBUTING.md não encontrado"
    fi
}

# Função para atualizar CODE_OF_CONDUCT
update_code_of_conduct() {
    log_header "Atualizando CODE_OF_CONDUCT"
    
    local coc_file="$PROJECT_ROOT/CODE_OF_CONDUCT.md"
    
    if [ -f "$coc_file" ]; then
        backup_file "$coc_file"
        
        sed -i.bak \
            -e 's/Roo Code/TQI AI Assistant/g' \
            -e 's/RooCode/TQI AI Assistant/g' \
            -e 's/dev@roocode.com/dev-ai@tqi.com.br/g' \
            "$coc_file"
        
        rm -f "$coc_file.bak"
        log_success "✅ CODE_OF_CONDUCT.md atualizado"
    else
        log_warning "⚠️  CODE_OF_CONDUCT.md não encontrado"
    fi
}

# Função para atualizar documentação de aplicações
update_apps_docs() {
    log_header "Atualizando documentação das aplicações"
    
    local updated=0
    
    # Atualizar READMEs das apps
    find "$PROJECT_ROOT/apps" -name "README.md" -type f | while read -r app_readme; do
        local app_name=$(basename "$(dirname "$app_readme")")
        log_info "Atualizando README da app: $app_name"
        
        backup_file "$app_readme"
        
        sed -i.bak \
            -e 's/Roo Code/TQI AI Assistant/g' \
            -e 's/RooCode/TQI AI Assistant/g' \
            -e 's/Roo-Code/TQI AI Assistant/g' \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            -e 's/@roo-code\//@tqi\//g' \
            "$app_readme"
        
        rm -f "$app_readme.bak"
        ((updated++))
        log_success "✅ README $app_name atualizado"
    done
    
    log_info "📊 READMEs de apps atualizados: $updated"
}

# Função para atualizar documentação de pacotes
update_packages_docs() {
    log_header "Atualizando documentação dos pacotes"
    
    local updated=0
    
    # Atualizar READMEs dos pacotes
    find "$PROJECT_ROOT/packages" -name "README.md" -type f | while read -r pkg_readme; do
        local pkg_name=$(basename "$(dirname "$pkg_readme")")
        log_info "Atualizando README do pacote: $pkg_name"
        
        backup_file "$pkg_readme"
        
        sed -i.bak \
            -e 's/Roo Code/TQI AI Assistant/g' \
            -e 's/RooCode/TQI AI Assistant/g' \
            -e 's/@roo-code\//@tqi\//g' \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            "$pkg_readme"
        
        rm -f "$pkg_readme.bak"
        ((updated++))
        log_success "✅ README $pkg_name atualizado"
    done
    
    log_info "📊 READMEs de pacotes atualizados: $updated"
}

# Função para atualizar documentação de desenvolvimento
update_dev_docs() {
    log_header "Atualizando documentação de desenvolvimento"
    
    local dev_docs=(
        "$PROJECT_ROOT/docs"
        "$PROJECT_ROOT/.github"
        "$PROJECT_ROOT/.vscode"
    )
    
    local updated=0
    
    for docs_dir in "${dev_docs[@]}"; do
        if [ -d "$docs_dir" ]; then
            find "$docs_dir" -name "*.md" -type f | while read -r doc_file; do
                if grep -q "Roo.*Code\|roo-cline\|@roo-code" "$doc_file" 2>/dev/null; then
                    log_info "Atualizando doc: $(realpath --relative-to="$PROJECT_ROOT" "$doc_file")"
                    backup_file "$doc_file"
                    
                    sed -i.bak \
                        -e 's/Roo Code/TQI AI Assistant/g' \
                        -e 's/RooCode/TQI AI Assistant/g' \
                        -e 's/Roo-Code/TQI AI Assistant/g' \
                        -e 's/roo-cline/tqi-ai-assistant/g' \
                        -e 's/@roo-code\//@tqi\//g' \
                        "$doc_file"
                    
                    rm -f "$doc_file.bak"
                    ((updated++))
                fi
            done
        fi
    done
    
    log_info "📊 Docs de desenvolvimento atualizados: $updated"
}

# Função para atualizar comentários em VSCode settings
update_vscode_settings() {
    log_header "Atualizando configurações VSCode"
    
    local vscode_settings="$PROJECT_ROOT/.vscode/settings.json"
    
    if [ -f "$vscode_settings" ]; then
        backup_file "$vscode_settings"
        
        if command -v jq > /dev/null 2>&1; then
            # Usar jq se disponível
            jq '
            # Atualizar configurações específicas da extensão
            if ."roo-cline.allowedCommands" then
                ."tqi-ai-assistant.allowedCommands" = ."roo-cline.allowedCommands" |
                del(."roo-cline.allowedCommands")
            else . end |
            
            if ."roo-cline.customStoragePath" then
                ."tqi-ai-assistant.customStoragePath" = ."roo-cline.customStoragePath" |
                del(."roo-cline.customStoragePath")
            else . end
            ' "$vscode_settings" > "$vscode_settings.tmp"
            
            if [ -s "$vscode_settings.tmp" ]; then
                mv "$vscode_settings.tmp" "$vscode_settings"
                log_success "✅ VSCode settings atualizado"
            else
                rm -f "$vscode_settings.tmp"
                log_warning "⚠️  Erro ao atualizar VSCode settings"
            fi
        else
            # Fallback sem jq
            sed -i.bak 's/roo-cline\./tqi-ai-assistant\./g' "$vscode_settings"
            rm -f "$vscode_settings.bak"
            log_success "✅ VSCode settings atualizado (sed)"
        fi
    else
        log_warning "⚠️  .vscode/settings.json não encontrado"
    fi
}

# Função para criar documentação adicional TQI
create_tqi_docs() {
    log_header "Criando documentação adicional TQI"
    
    # Criar diretório docs se não existir
    mkdir -p "$PROJECT_ROOT/docs"
    
    # Criar SECURITY.md se não existir
    if [ ! -f "$PROJECT_ROOT/SECURITY.md" ]; then
        cat > "$PROJECT_ROOT/SECURITY.md" << 'EOF'
# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

Se você descobrir uma vulnerabilidade de segurança no TQI AI Assistant, por favor nos ajude a resolvê-la de forma responsável.

### Como Reportar

1. **NÃO** abra uma issue pública no GitHub
2. Envie um email para: security@tqi.com.br
3. Inclua uma descrição detalhada da vulnerabilidade
4. Se possível, inclua passos para reproduzir o problema

### O que esperar

- Confirmação do recebimento em até 48 horas
- Avaliação inicial em até 7 dias
- Atualizações regulares sobre o progresso
- Reconhecimento público após a correção (se desejado)

### Escopo

Esta política se aplica a:
- Extensão principal TQI AI Assistant
- Todas as dependências incluídas
- APIs e serviços relacionados

Obrigado por ajudar a manter o TQI AI Assistant seguro!
EOF
        log_success "✅ SECURITY.md criado"
    fi
    
    # Criar docs/INSTALLATION.md
    if [ ! -f "$PROJECT_ROOT/docs/INSTALLATION.md" ]; then
        cat > "$PROJECT_ROOT/docs/INSTALLATION.md" << 'EOF'
# Guia de Instalação - TQI AI Assistant

## Instalação via VSCode Marketplace

1. Abra o VSCode
2. Vá para Extensions (Ctrl+Shift+X)
3. Busque por "TQI AI Assistant"
4. Clique em "Install"

## Instalação Manual

1. Baixe o arquivo `.vsix` da [página de releases](https://github.com/SeuUsuario/tqi-ai-assistant/releases)
2. No VSCode, abra Command Palette (Ctrl+Shift+P)
3. Digite "Extensions: Install from VSIX..."
4. Selecione o arquivo baixado

## Configuração Inicial

1. Após instalação, configure sua API key preferida
2. Abra configurações: File > Preferences > Settings
3. Busque por "TQI AI Assistant"
4. Configure suas preferências

## Resolução de Problemas

### Extensão não aparece
- Reinicie o VSCode
- Verifique se a versão do VSCode é compatível (>= 1.74.0)

### Comandos não funcionam
- Verifique se a extensão está ativada
- Abra Output panel e selecione "TQI AI Assistant"

Para mais ajuda, visite: https://docs.tqi.com.br/ai-assistant
EOF
        log_success "✅ docs/INSTALLATION.md criado"
    fi
}

# Função principal
main() {
    log_header "INICIANDO ETAPA 6"
    
    # 1. Atualizar documentação principal
    update_main_readme
    
    # 2. Atualizar CHANGELOG
    update_changelog
    
    # 3. Atualizar CONTRIBUTING
    update_contributing
    
    # 4. Atualizar CODE_OF_CONDUCT
    update_code_of_conduct
    
    # 5. Atualizar documentação das aplicações
    update_apps_docs
    
    # 6. Atualizar documentação dos pacotes
    update_packages_docs
    
    # 7. Atualizar documentação de desenvolvimento
    update_dev_docs
    
    # 8. Atualizar configurações VSCode
    update_vscode_settings
    
    # 9. Criar documentação adicional TQI
    create_tqi_docs
    
    # 10. Validar resultado
    log_header "Validando documentação"
    
    local docs_errors=0
    local total_docs=0
    
    # Contar documentos atualizados
    find "$PROJECT_ROOT" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" | while read -r doc_file; do
        ((total_docs++))
        
        # Verificar se ainda há referências antigas
        local old_refs=$(grep -c "Roo Code\|RooCode\|roo-cline\|@roo-code" "$doc_file" 2>/dev/null || echo 0)
        if [ "$old_refs" -gt 0 ]; then
            log_warning "⚠️  $old_refs referência(s) antiga(s) em: $(basename "$doc_file")"
            ((docs_errors++))
        fi
    done
    
    log_info "📊 Total de documentos: $total_docs"
    log_info "📊 Documentos com referências antigas: $docs_errors"
    
    # 11. Relatório final
    log_header "RELATÓRIO FINAL ETAPA 6"
    
    if [ "$docs_errors" -eq 0 ]; then
        log_success "🎉 ETAPA 6 CONCLUÍDA COM SUCESSO!"
        status="completed"
    else
        log_warning "⚠️  Etapa 6 concluída com alguns documentos pendentes"
        status="completed_with_warnings"
    fi
    
    # Criar relatório JSON
    mkdir -p "$AUTOMATION_DIR/logs"
    cat > "$AUTOMATION_DIR/logs/etapa6-report.json" << EOF
{
    "etapa": 6,
    "name": "documentacao",
    "status": "$status",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "changes": {
        "total_docs": $total_docs,
        "docs_with_old_refs": $docs_errors,
        "main_readme": $([ -f "$PROJECT_ROOT/README.md" ] && echo "true" || echo "false"),
        "changelog": $([ -f "$PROJECT_ROOT/CHANGELOG.md" ] && echo "true" || echo "false"),
        "contributing": $([ -f "$PROJECT_ROOT/CONTRIBUTING.md" ] && echo "true" || echo "false"),
        "security": $([ -f "$PROJECT_ROOT/SECURITY.md" ] && echo "true" || echo "false")
    },
    "documentation": {
        "readme_updated": "true",
        "changelog_updated": "true", 
        "vscode_settings": $([ -f "$PROJECT_ROOT/.vscode/settings.json" ] && echo "true" || echo "false"),
        "additional_docs_created": "true"
    }
}
EOF
    
    log_info "📊 Estatísticas:"
    log_info "   - Total de documentos: $total_docs"
    log_info "   - Documentos com problemas: $docs_errors"
    log_info "   - Status: $status"
    
    log_info "📁 Relatório salvo: logs/etapa6-report.json"
    
    if [[ "$status" == "completed"* ]]; then
        log_info "➡️  Próxima etapa: ./etapas/etapa7.sh"
    fi
}

# Função de rollback
rollback_etapa6() {
    log_header "ROLLBACK ETAPA 6"
    
    log_info "Restaurando backups de documentação..."
    
    # Restaurar todos os arquivos .backup.etapa6
    find "$PROJECT_ROOT" -name "*.backup.etapa6" | while read -r backup; do
        original="${backup%.backup.etapa6}"
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
        rollback_etapa6
        exit 0
        ;;
    "--help")
        echo "Uso: $0 [--rollback|--help]"
        echo "  --rollback  Desfaz as mudanças da etapa 6"
        echo "  --help      Mostra esta ajuda"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 