#!/bin/bash

# ================================================================
# ETAPA 8: CONFIGURAÇÕES AVANÇADAS
# ================================================================
# 
# Esta etapa atualiza configurações específicas do projeto como
# ellipsis.yaml, .vscode/settings.json, GitHub Actions e outros.
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

log_header "ETAPA 8: CONFIGURAÇÕES AVANÇADAS"

# Função para backup de arquivo
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.etapa8"
        log_info "✅ Backup: $(basename "$file")"
    fi
}

# Função para atualizar ellipsis.yaml
update_ellipsis_config() {
    log_header "Atualizando ellipsis.yaml"
    
    local ellipsis_file="$PROJECT_ROOT/ellipsis.yaml"
    
    if [ -f "$ellipsis_file" ]; then
        backup_file "$ellipsis_file"
        
        # Atualizar configurações do Ellipsis
        sed -i.bak \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            -e 's/Roo Code/TQI AI Assistant/g' \
            -e 's/RooCode/TQI AI Assistant/g' \
            -e 's/@roo-code\//@tqi\//g' \
            -e 's/RooVeterinaryInc/TQI/g' \
            "$ellipsis_file"
        
        rm -f "$ellipsis_file.bak"
        log_success "✅ ellipsis.yaml atualizado"
    else
        log_warning "⚠️  ellipsis.yaml não encontrado"
        
        # Criar ellipsis.yaml básico se não existir
        cat > "$ellipsis_file" << 'EOF'
# Ellipsis Configuration for TQI AI Assistant
version: 1.0

# Project information
project:
  name: tqi-ai-assistant
  description: TQI AI Assistant - Intelligent coding assistant
  version: "1.0.0"

# AI assistant configuration
assistant:
  name: TQI AI Assistant
  provider: tqi
  
# File patterns to ignore
ignore:
  - node_modules/
  - .git/
  - dist/
  - out/
  - "*.log"

# Custom rules for TQI
rules:
  - name: tqi-branding
    description: Ensure TQI branding consistency
    pattern: "Roo Code|RooCode|roo-cline"
    replacement: "TQI AI Assistant"
EOF
        log_success "✅ ellipsis.yaml criado"
    fi
}

# Função para atualizar configurações VSCode avançadas
update_vscode_advanced() {
    log_header "Atualizando configurações avançadas do VSCode"
    
    local vscode_dir="$PROJECT_ROOT/.vscode"
    mkdir -p "$vscode_dir"
    
    # Atualizar settings.json
    local settings_file="$vscode_dir/settings.json"
    if [ -f "$settings_file" ]; then
        backup_file "$settings_file"
        
        if command -v jq > /dev/null 2>&1; then
            # Usar jq para atualizações precisas
            jq '
            # Remover configurações antigas roo-cline
            del(."roo-cline.allowedCommands") |
            del(."roo-cline.customStoragePath") |
            del(."roo-cline.commandExecutionTimeout") |
            
            # Adicionar configurações TQI
            ."tqi-ai-assistant.allowedCommands" = ["echo", "ls", "cat", "grep", "find"] |
            ."tqi-ai-assistant.customStoragePath" = "" |
            ."tqi-ai-assistant.commandExecutionTimeout" = 30000 |
            
            # Configurações do editor para o projeto
            ."typescript.preferences.includePackageJsonAutoImports" = "on" |
            ."typescript.suggest.autoImports" = true |
            ."editor.codeActionsOnSave" = {
                "source.fixAll.eslint": true,
                "source.organizeImports": true
            }
            ' "$settings_file" > "$settings_file.tmp"
            
            if [ -s "$settings_file.tmp" ]; then
                mv "$settings_file.tmp" "$settings_file"
                log_success "✅ .vscode/settings.json atualizado"
            else
                rm -f "$settings_file.tmp"
                log_warning "⚠️  Erro ao atualizar settings.json"
            fi
        else
            # Fallback sem jq
            sed -i.bak 's/roo-cline\./tqi-ai-assistant\./g' "$settings_file"
            rm -f "$settings_file.bak"
            log_success "✅ .vscode/settings.json atualizado (sed)"
        fi
    else
        # Criar settings.json básico
        cat > "$settings_file" << 'EOF'
{
    "tqi-ai-assistant.allowedCommands": [
        "echo",
        "ls", 
        "cat",
        "grep",
        "find",
        "npm",
        "pnpm",
        "git"
    ],
    "tqi-ai-assistant.customStoragePath": "",
    "tqi-ai-assistant.commandExecutionTimeout": 30000,
    "typescript.preferences.includePackageJsonAutoImports": "on",
    "typescript.suggest.autoImports": true,
    "editor.codeActionsOnSave": {
        "source.fixAll.eslint": true,
        "source.organizeImports": true
    }
}
EOF
        log_success "✅ .vscode/settings.json criado"
    fi
    
    # Atualizar launch.json se existir
    local launch_file="$vscode_dir/launch.json"
    if [ -f "$launch_file" ]; then
        backup_file "$launch_file"
        
        sed -i.bak \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            -e 's/Roo Code/TQI AI Assistant/g' \
            "$launch_file"
        
        rm -f "$launch_file.bak"
        log_success "✅ .vscode/launch.json atualizado"
    fi
    
    # Atualizar tasks.json se existir
    local tasks_file="$vscode_dir/tasks.json"
    if [ -f "$tasks_file" ]; then
        backup_file "$tasks_file"
        
        sed -i.bak \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            -e 's/Roo Code/TQI AI Assistant/g' \
            "$tasks_file"
        
        rm -f "$tasks_file.bak"
        log_success "✅ .vscode/tasks.json atualizado"
    fi
}

# Função para atualizar GitHub Actions
update_github_actions() {
    log_header "Atualizando GitHub Actions"
    
    local github_dir="$PROJECT_ROOT/.github"
    
    if [ -d "$github_dir" ]; then
        # Atualizar workflows
        find "$github_dir/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | while read -r workflow_file; do
            log_info "Atualizando workflow: $(basename "$workflow_file")"
            backup_file "$workflow_file"
            
            sed -i.bak \
                -e 's/roo-cline/tqi-ai-assistant/g' \
                -e 's/Roo Code/TQI AI Assistant/g' \
                -e 's/RooCode/TQI AI Assistant/g' \
                -e 's/@roo-code\//@tqi\//g' \
                -e 's/RooVeterinaryInc/TQI/g' \
                "$workflow_file"
            
            rm -f "$workflow_file.bak"
            log_success "✅ $(basename "$workflow_file") atualizado"
        done
        
        # Atualizar issue templates
        find "$github_dir/ISSUE_TEMPLATE" -name "*.md" -o -name "*.yml" 2>/dev/null | while read -r template_file; do
            log_info "Atualizando template: $(basename "$template_file")"
            backup_file "$template_file"
            
            sed -i.bak \
                -e 's/Roo Code/TQI AI Assistant/g' \
                -e 's/RooCode/TQI AI Assistant/g' \
                -e 's/roo-cline/tqi-ai-assistant/g' \
                "$template_file"
            
            rm -f "$template_file.bak"
            log_success "✅ $(basename "$template_file") atualizado"
        done
        
        # Atualizar pull request template
        if [ -f "$github_dir/PULL_REQUEST_TEMPLATE.md" ]; then
            backup_file "$github_dir/PULL_REQUEST_TEMPLATE.md"
            
            sed -i.bak \
                -e 's/Roo Code/TQI AI Assistant/g' \
                -e 's/RooCode/TQI AI Assistant/g' \
                -e 's/roo-cline/tqi-ai-assistant/g' \
                "$github_dir/PULL_REQUEST_TEMPLATE.md"
            
            rm -f "$github_dir/PULL_REQUEST_TEMPLATE.md.bak"
            log_success "✅ PULL_REQUEST_TEMPLATE.md atualizado"
        fi
    else
        log_warning "⚠️  Diretório .github não encontrado"
    fi
}

# Função para atualizar configurações de build
update_build_configs() {
    log_header "Atualizando configurações de build"
    
    # Atualizar esbuild.mjs se existir
    local esbuild_file="$PROJECT_ROOT/src/esbuild.mjs"
    if [ -f "$esbuild_file" ]; then
        backup_file "$esbuild_file"
        
        sed -i.bak \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            -e 's/@roo-code\//@tqi\//g' \
            "$esbuild_file"
        
        rm -f "$esbuild_file.bak"
        log_success "✅ esbuild.mjs atualizado"
    fi
    
    # Atualizar webpack configs se existirem
    find "$PROJECT_ROOT" -name "webpack*.js" -o -name "webpack*.ts" -not -path "*/node_modules/*" | while read -r webpack_file; do
        log_info "Atualizando webpack config: $(basename "$webpack_file")"
        backup_file "$webpack_file"
        
        sed -i.bak \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            -e 's/@roo-code\//@tqi\//g' \
            "$webpack_file"
        
        rm -f "$webpack_file.bak"
        log_success "✅ $(basename "$webpack_file") atualizado"
    done
    
    # Atualizar vite configs se existirem
    find "$PROJECT_ROOT" -name "vite*.js" -o -name "vite*.ts" -not -path "*/node_modules/*" | while read -r vite_file; do
        log_info "Atualizando vite config: $(basename "$vite_file")"
        backup_file "$vite_file"
        
        sed -i.bak \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            -e 's/@roo-code\//@tqi\//g' \
            "$vite_file"
        
        rm -f "$vite_file.bak"
        log_success "✅ $(basename "$vite_file") atualizado"
    done
}

# Função para atualizar configurações de linting
update_lint_configs() {
    log_header "Atualizando configurações de linting"
    
    # Atualizar .eslintrc.* files
    find "$PROJECT_ROOT" -name ".eslintrc*" -not -path "*/node_modules/*" | while read -r eslint_file; do
        log_info "Atualizando ESLint config: $(basename "$eslint_file")"
        backup_file "$eslint_file"
        
        sed -i.bak \
            -e 's/@roo-code\//@tqi\//g' \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            "$eslint_file"
        
        rm -f "$eslint_file.bak"
        log_success "✅ $(basename "$eslint_file") atualizado"
    done
    
    # Atualizar eslint.config.* files
    find "$PROJECT_ROOT" -name "eslint.config.*" -not -path "*/node_modules/*" | while read -r eslint_file; do
        log_info "Atualizando ESLint config: $(basename "$eslint_file")"
        backup_file "$eslint_file"
        
        sed -i.bak \
            -e 's/@roo-code\//@tqi\//g' \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            "$eslint_file"
        
        rm -f "$eslint_file.bak"
        log_success "✅ $(basename "$eslint_file") atualizado"
    done
    
    # Atualizar .prettierrc se existir
    local prettier_file="$PROJECT_ROOT/.prettierrc"
    if [ -f "$prettier_file" ]; then
        backup_file "$prettier_file"
        
        # Prettier config geralmente não tem referências específicas, mas verificamos
        if grep -q "roo-code\|Roo.*Code" "$prettier_file" 2>/dev/null; then
            sed -i.bak \
                -e 's/@roo-code\//@tqi\//g' \
                -e 's/roo-cline/tqi-ai-assistant/g' \
                "$prettier_file"
            
            rm -f "$prettier_file.bak"
            log_success "✅ .prettierrc atualizado"
        else
            log_info "   .prettierrc não precisa de atualizações"
        fi
    fi
}

# Função para atualizar configurações de teste
update_test_configs() {
    log_header "Atualizando configurações de teste"
    
    # Atualizar jest.config.* files
    find "$PROJECT_ROOT" -name "jest.config.*" -not -path "*/node_modules/*" | while read -r jest_file; do
        log_info "Atualizando Jest config: $(basename "$jest_file")"
        backup_file "$jest_file"
        
        sed -i.bak \
            -e 's/@roo-code\//@tqi\//g' \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            "$jest_file"
        
        rm -f "$jest_file.bak"
        log_success "✅ $(basename "$jest_file") atualizado"
    done
    
    # Atualizar vitest.config.* files
    find "$PROJECT_ROOT" -name "vitest.config.*" -not -path "*/node_modules/*" | while read -r vitest_file; do
        log_info "Atualizando Vitest config: $(basename "$vitest_file")"
        backup_file "$vitest_file"
        
        sed -i.bak \
            -e 's/@roo-code\//@tqi\//g' \
            -e 's/roo-cline/tqi-ai-assistant/g' \
            "$vitest_file"
        
        rm -f "$vitest_file.bak"
        log_success "✅ $(basename "$vitest_file") atualizado"
    done
}

# Função para criar configurações TQI específicas
create_tqi_configs() {
    log_header "Criando configurações específicas TQI"
    
    # Criar .tqirc se não existir (configuração personalizada TQI)
    local tqi_config="$PROJECT_ROOT/.tqirc"
    if [ ! -f "$tqi_config" ]; then
        cat > "$tqi_config" << 'EOF'
{
  "project": {
    "name": "tqi-ai-assistant",
    "version": "1.0.0",
    "description": "TQI AI Assistant - Intelligent coding assistant"
  },
  "branding": {
    "name": "TQI AI Assistant",
    "company": "TQI",
    "website": "https://www.tqi.com.br",
    "support": "https://suporte.tqi.com.br"
  },
  "development": {
    "repository": "https://github.com/SeuUsuario/tqi-ai-assistant",
    "issues": "https://github.com/SeuUsuario/tqi-ai-assistant/issues",
    "documentation": "https://docs.tqi.com.br/ai-assistant"
  },
  "settings": {
    "allowedCommands": ["echo", "ls", "cat", "grep", "find", "npm", "pnpm", "git"],
    "commandTimeout": 30000,
    "enableCodeActions": true,
    "autoImportSettings": true
  }
}
EOF
        log_success "✅ .tqirc criado"
    fi
    
    # Criar .vscode/extensions.json recomendado
    local extensions_file="$PROJECT_ROOT/.vscode/extensions.json"
    if [ ! -f "$extensions_file" ]; then
        cat > "$extensions_file" << 'EOF'
{
    "recommendations": [
        "ms-vscode.vscode-typescript-next",
        "bradlc.vscode-tailwindcss",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "ms-vscode.vscode-json",
        "redhat.vscode-yaml"
    ]
}
EOF
        log_success "✅ .vscode/extensions.json criado"
    fi
}

# Função principal
main() {
    log_header "INICIANDO ETAPA 8"
    
    local configs_updated=0
    
    # 1. Atualizar ellipsis.yaml
    update_ellipsis_config
    ((configs_updated++))
    
    # 2. Atualizar configurações VSCode avançadas
    update_vscode_advanced
    ((configs_updated++))
    
    # 3. Atualizar GitHub Actions
    update_github_actions
    ((configs_updated++))
    
    # 4. Atualizar configurações de build
    update_build_configs
    ((configs_updated++))
    
    # 5. Atualizar configurações de linting
    update_lint_configs
    ((configs_updated++))
    
    # 6. Atualizar configurações de teste
    update_test_configs
    ((configs_updated++))
    
    # 7. Criar configurações TQI específicas
    create_tqi_configs
    ((configs_updated++))
    
    # 8. Validação final
    log_header "Validando configurações"
    
    local validation_errors=0
    
    # Verificar se arquivos de configuração são válidos
    find "$PROJECT_ROOT" -name "*.json" -not -path "*/node_modules/*" | while read -r json_file; do
        if ! command -v jq > /dev/null 2>&1; then
            break
        fi
        
        if ! jq . "$json_file" > /dev/null 2>&1; then
            log_error "❌ JSON inválido: $(basename "$json_file")"
            ((validation_errors++))
        fi
    done
    
    # Verificar se ainda há referências antigas em configs
    local old_refs=$(find "$PROJECT_ROOT" \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.mjs" -o -name "*.js" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -exec grep -l "roo-cline\|@roo-code\|RooVeterinaryInc" {} \; 2>/dev/null | wc -l)
    
    if [ "$old_refs" -gt 0 ]; then
        log_warning "⚠️  $old_refs arquivo(s) de configuração ainda contém referências antigas"
        ((validation_errors++))
    fi
    
    # 9. Relatório final
    log_header "RELATÓRIO FINAL ETAPA 8"
    
    if [ "$validation_errors" -eq 0 ]; then
        log_success "🎉 ETAPA 8 CONCLUÍDA COM SUCESSO!"
        status="completed"
    else
        log_warning "⚠️  Etapa 8 concluída com avisos"
        status="completed_with_warnings"
    fi
    
    # Criar relatório JSON
    mkdir -p "$AUTOMATION_DIR/logs"
    cat > "$AUTOMATION_DIR/logs/etapa8-report.json" << EOF
{
    "etapa": 8,
    "name": "configuracoes-avancadas",
    "status": "$status",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "changes": {
        "configs_updated": $configs_updated,
        "validation_errors": $validation_errors,
        "old_references_remaining": $old_refs
    },
    "configurations": {
        "ellipsis_yaml": $([ -f "$PROJECT_ROOT/ellipsis.yaml" ] && echo "true" || echo "false"),
        "vscode_settings": $([ -f "$PROJECT_ROOT/.vscode/settings.json" ] && echo "true" || echo "false"),
        "github_actions": $([ -d "$PROJECT_ROOT/.github" ] && echo "true" || echo "false"),
        "tqi_config": $([ -f "$PROJECT_ROOT/.tqirc" ] && echo "true" || echo "false")
    },
    "file_counts": {
        "json_files": $(find "$PROJECT_ROOT" -name "*.json" -not -path "*/node_modules/*" | wc -l),
        "yaml_files": $(find "$PROJECT_ROOT" -name "*.yml" -o -name "*.yaml" -not -path "*/node_modules/*" | wc -l),
        "config_files": $(find "$PROJECT_ROOT" \( -name "*.config.*" -o -name ".*rc*" \) -not -path "*/node_modules/*" | wc -l)
    }
}
EOF
    
    log_info "📊 Estatísticas:"
    log_info "   - Configurações atualizadas: $configs_updated"
    log_info "   - Erros de validação: $validation_errors"
    log_info "   - Referências antigas restantes: $old_refs"
    log_info "   - Status: $status"
    
    log_info "📁 Relatório salvo: logs/etapa8-report.json"
    
    if [[ "$status" == "completed"* ]]; then
        log_info "➡️  Próxima etapa: ./etapas/etapa9.sh"
    fi
}

# Função de rollback
rollback_etapa8() {
    log_header "ROLLBACK ETAPA 8"
    
    log_info "Restaurando backups de configurações..."
    
    # Restaurar todos os arquivos .backup.etapa8
    find "$PROJECT_ROOT" -name "*.backup.etapa8" | while read -r backup; do
        original="${backup%.backup.etapa8}"
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
        rollback_etapa8
        exit 0
        ;;
    "--help")
        echo "Uso: $0 [--rollback|--help]"
        echo "  --rollback  Desfaz as mudanças da etapa 8"
        echo "  --help      Mostra esta ajuda"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 