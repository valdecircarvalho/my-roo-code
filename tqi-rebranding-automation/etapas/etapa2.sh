#!/bin/bash

# ================================================================
# ETAPA 2: CONFIGURAÇÃO DO WORKSPACE E PACOTES INTERNOS
# ================================================================
# 
# Esta etapa atualiza todos os pacotes internos do monorepo,
# configurações do workspace e dependências internas.
#
# VERIFICAÇÃO: Se a Etapa 1 foi bem executada, algumas mudanças
# já foram aplicadas. Esta etapa valida e completa o que falta.
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

# Verificar se estamos no diretório correto
if [ ! -f "$PROJECT_ROOT/package.json" ] || [ ! -f "$PROJECT_ROOT/src/package.json" ]; then
    log_error "Execute este script na raiz do projeto Roo-Code"
    exit 1
fi

# Verificar se Etapa 1 foi concluída
if ! grep -q "tqi-ai-assistant" "$PROJECT_ROOT/src/package.json" 2>/dev/null; then
    log_error "Etapa 1 não foi concluída! Execute primeiro ./etapas/etapa1.sh"
    exit 1
fi

log_header "ETAPA 2: CONFIGURAÇÃO DO WORKSPACE E PACOTES INTERNOS"

# Função para verificar se jq está disponível
check_jq() {
    if ! command -v jq > /dev/null 2>&1; then
        log_error "jq não está instalado. Instale com:"
        log_error "  macOS: brew install jq"
        log_error "  Ubuntu/Debian: sudo apt-get install jq"
        exit 1
    fi
}

# Função para backup de arquivo específico
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.etapa2"
        log_info "✅ Backup criado: $file.backup.etapa2"
    fi
}

# Função para validar JSON
validate_json() {
    local file=$1
    if ! jq . "$file" > /dev/null 2>&1; then
        log_error "JSON inválido: $file"
        return 1
    fi
    return 0
}

# Função para substituir @roo-code por @tqi em package.json
update_package_deps() {
    local file=$1
    local description=$2
    
    log_info "Atualizando $description: $file"
    
    if [ ! -f "$file" ]; then
        log_warning "Arquivo não encontrado: $file"
        return 0
    fi
    
    backup_file "$file"
    
    # Usar jq para substituições precisas
    local temp_file="${file}.tmp"
    
    jq '
    # Atualizar name se for pacote @roo-code
    if .name and (.name | startswith("@roo-code/")) then
        .name = (.name | sub("@roo-code/"; "@tqi/"))
    else . end |
    
    # Atualizar dependencies
    if .dependencies then
        .dependencies = (
            .dependencies | 
            with_entries(
                if (.key | startswith("@roo-code/")) then
                    .key = (.key | sub("@roo-code/"; "@tqi/"))
                else . end
            )
        )
    else . end |
    
    # Atualizar devDependencies  
    if .devDependencies then
        .devDependencies = (
            .devDependencies |
            with_entries(
                if (.key | startswith("@roo-code/")) then
                    .key = (.key | sub("@roo-code/"; "@tqi/"))
                else . end
            )
        )
    else . end |
    
    # Atualizar peerDependencies
    if .peerDependencies then
        .peerDependencies = (
            .peerDependencies |
            with_entries(
                if (.key | startswith("@roo-code/")) then
                    .key = (.key | sub("@roo-code/"; "@tqi/"))
                else . end
            )
        )
    else . end |
    
    # Atualizar repository URLs
    if .repository and .repository.url then
        .repository.url = (.repository.url | sub("RooCodeInc/Roo-Code"; "SeuUsuario/tqi-ai-assistant"))
    else . end |
    
    # Atualizar homepage
    if .homepage then
        .homepage = (.homepage | sub("RooCodeInc/Roo-Code"; "SeuUsuario/tqi-ai-assistant"))
    else . end |
    
    # Atualizar bugs URL
    if .bugs and .bugs.url then
        .bugs.url = (.bugs.url | sub("RooCodeInc/Roo-Code"; "SeuUsuario/tqi-ai-assistant"))
    else . end |
    
    # Atualizar keywords
    if .keywords then
        .keywords = [.keywords[] | if . == "roo-code" then "tqi-ai-assistant" else . end]
    else . end
    ' "$file" > "$temp_file"
    
    if validate_json "$temp_file"; then
        mv "$temp_file" "$file"
        log_success "✅ Atualizado: $description"
    else
        log_error "❌ Erro ao atualizar: $file"
        rm -f "$temp_file"
        return 1
    fi
}

# Função para atualizar turbo.json
update_turbo_json() {
    local file="$PROJECT_ROOT/turbo.json"
    log_header "Atualizando turbo.json"
    
    if [ ! -f "$file" ]; then
        log_warning "turbo.json não encontrado - criando versão básica"
        cat > "$file" << EOF
{
  "pipeline": {
    "build": {
      "dependsOn": ["@tqi/types#build"]
    },
    "dev": {
      "cache": false
    },
    "test": {
      "dependsOn": ["build"]
    }
  }
}
EOF
        log_success "✅ turbo.json criado"
        return 0
    fi
    
    backup_file "$file"
    
    # Substituir dependências
    sed -i.bak 's/@roo-code\//@tqi\//g' "$file"
    
    if validate_json "$file"; then
        log_success "✅ turbo.json atualizado"
        rm -f "$file.bak"
    else
        log_error "❌ Erro no turbo.json - restaurando backup"
        mv "$file.bak" "$file"
        return 1
    fi
}

# Função para verificar workspace
verify_workspace() {
    local file="$PROJECT_ROOT/pnpm-workspace.yaml"
    log_header "Verificando pnpm-workspace.yaml"
    
    if [ ! -f "$file" ]; then
        log_warning "pnpm-workspace.yaml não encontrado - criando"
        cat > "$file" << EOF
packages:
  - "packages/*"
  - "apps/*"
  - "src"
  - "webview-ui"
EOF
        log_success "✅ pnpm-workspace.yaml criado"
    else
        log_info "✅ pnpm-workspace.yaml existe - verificando estrutura..."
        
        if grep -q "packages/\*" "$file" && grep -q "apps/\*" "$file"; then
            log_success "✅ Estrutura do workspace está correta"
        else
            log_warning "⚠️  Estrutura do workspace pode estar incompleta"
        fi
    fi
}

# Função principal
main() {
    log_header "INICIANDO ETAPA 2"
    
    # Verificações iniciais
    check_jq
    
    log_info "📊 Status inicial:"
    log_info "   - Projeto: $(basename "$PROJECT_ROOT")"
    log_info "   - Diretório: $PROJECT_ROOT"
    
    # 1. Verificar e atualizar workspace
    verify_workspace
    
    # 2. Atualizar turbo.json
    update_turbo_json
    
    # 3. Atualizar pacotes internos
    log_header "Atualizando pacotes internos"
    
    # packages/*
    for pkg_dir in "$PROJECT_ROOT/packages"/*; do
        if [ -d "$pkg_dir" ] && [ -f "$pkg_dir/package.json" ]; then
            update_package_deps "$pkg_dir/package.json" "Pacote $(basename "$pkg_dir")"
        fi
    done
    
    # packages/types/npm/package.json (especial)
    if [ -f "$PROJECT_ROOT/packages/types/npm/package.json" ]; then
        update_package_deps "$PROJECT_ROOT/packages/types/npm/package.json" "Types NPM package"
    fi
    
    # 4. Atualizar apps
    log_header "Atualizando aplicações auxiliares"
    
    for app_dir in "$PROJECT_ROOT/apps"/*; do
        if [ -d "$app_dir" ] && [ -f "$app_dir/package.json" ]; then
            update_package_deps "$app_dir/package.json" "App $(basename "$app_dir")"
        fi
    done
    
    # 5. Atualizar webview-ui
    if [ -f "$PROJECT_ROOT/webview-ui/package.json" ]; then
        update_package_deps "$PROJECT_ROOT/webview-ui/package.json" "WebView UI"
    fi
    
    # 6. Verificar se src/package.json está correto (deve estar da Etapa 1)
    log_header "Verificando src/package.json (deve estar correto da Etapa 1)"
    
    if grep -q "@roo-code/" "$PROJECT_ROOT/src/package.json" 2>/dev/null; then
        log_warning "⚠️  src/package.json ainda tem referências @roo-code - atualizando..."
        update_package_deps "$PROJECT_ROOT/src/package.json" "Extension main package"
    else
        log_success "✅ src/package.json já está correto da Etapa 1"
    fi
    
    # 7. Validações finais
    log_header "Validações finais"
    
    local errors=0
    
    # Verificar se não há mais referências @roo-code
    local roo_count=$(find "$PROJECT_ROOT" -name "package.json" -not -path "*/node_modules/*" -exec grep -l "@roo-code/" {} \; | wc -l)
    if [ "$roo_count" -gt 0 ]; then
        log_error "❌ Ainda há $roo_count arquivo(s) com referências @roo-code"
        find "$PROJECT_ROOT" -name "package.json" -not -path "*/node_modules/*" -exec grep -l "@roo-code/" {} \;
        ((errors++))
    else
        log_success "✅ Nenhuma referência @roo-code encontrada"
    fi
    
    # Verificar se há referências @tqi
    local tqi_count=$(find "$PROJECT_ROOT" -name "package.json" -not -path "*/node_modules/*" -exec grep -l "@tqi/" {} \; | wc -l)
    if [ "$tqi_count" -gt 0 ]; then
        log_success "✅ $tqi_count arquivo(s) com referências @tqi encontrados"
    else
        log_warning "⚠️  Nenhuma referência @tqi encontrada - pode haver problema"
    fi
    
    # Validar sintaxe JSON de todos os package.json
    log_info "Validando sintaxe JSON..."
    find "$PROJECT_ROOT" -name "package.json" -not -path "*/node_modules/*" | while read -r file; do
        if ! validate_json "$file"; then
            log_error "❌ JSON inválido: $file"
            ((errors++))
        fi
    done
    
    # 8. Teste de build básico
    log_header "Teste de build básico"
    
    cd "$PROJECT_ROOT"
    
    if command -v pnpm > /dev/null 2>&1; then
        log_info "Executando pnpm install..."
        if pnpm install --frozen-lockfile > /dev/null 2>&1; then
            log_success "✅ pnpm install passou"
        else
            log_warning "⚠️  pnpm install teve problemas - pode ser normal"
        fi
        
        log_info "Testando TypeScript compilation..."
        if pnpm check-types > /dev/null 2>&1; then
            log_success "✅ TypeScript compilation passou"
        else
            log_warning "⚠️  TypeScript compilation teve problemas"
        fi
    else
        log_warning "⚠️  pnpm não encontrado - pulando testes de build"
    fi
    
    # 9. Relatório final
    log_header "RELATÓRIO FINAL ETAPA 2"
    
    if [ "$errors" -eq 0 ]; then
        log_success "🎉 ETAPA 2 CONCLUÍDA COM SUCESSO!"
        
        # Criar relatório JSON
        cat > "$AUTOMATION_DIR/logs/etapa2-report.json" << EOF
{
    "etapa": 2,
    "name": "workspace-pacotes",
    "status": "completed",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "changes": {
        "turbo_json": "updated",
        "workspace_yaml": "verified",
        "packages_updated": $(find "$PROJECT_ROOT/packages" -name "package.json" | wc -l),
        "apps_updated": $(find "$PROJECT_ROOT/apps" -name "package.json" | wc -l),
        "webview_updated": $([ -f "$PROJECT_ROOT/webview-ui/package.json" ] && echo "true" || echo "false")
    },
    "validation": {
        "roo_references": $roo_count,
        "tqi_references": $tqi_count,
        "json_valid": true,
        "build_test": "attempted"
    }
}
EOF
        
        log_info "📊 Estatísticas:"
        log_info "   - Pacotes atualizados: $(find "$PROJECT_ROOT/packages" -name "package.json" | wc -l)"
        log_info "   - Apps atualizadas: $(find "$PROJECT_ROOT/apps" -name "package.json" | wc -l)"
        log_info "   - Referências @roo-code: $roo_count"
        log_info "   - Referências @tqi: $tqi_count"
        
        log_info "📁 Relatório salvo: logs/etapa2-report.json"
        
        log_info "➡️  Próxima etapa: ./etapas/etapa3.sh"
        
    else
        log_error "❌ ETAPA 2 FALHOU COM $errors ERRO(S)"
        log_error "Corrija os problemas antes de prosseguir"
        exit 1
    fi
}

# Função de rollback
rollback_etapa2() {
    log_header "ROLLBACK ETAPA 2"
    
    log_info "Restaurando backups..."
    
    # Restaurar todos os arquivos .backup.etapa2
    find "$PROJECT_ROOT" -name "*.backup.etapa2" | while read -r backup; do
        original="${backup%.backup.etapa2}"
        if [ -f "$backup" ]; then
            mv "$backup" "$original"
            log_info "✅ Restaurado: $original"
        fi
    done
    
    log_success "✅ Rollback concluído"
}

# Processar argumentos
case "${1:-}" in
    "--rollback")
        rollback_etapa2
        exit 0
        ;;
    "--help")
        echo "Uso: $0 [--rollback|--help]"
        echo "  --rollback  Desfaz as mudanças da etapa 2"
        echo "  --help      Mostra esta ajuda"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 