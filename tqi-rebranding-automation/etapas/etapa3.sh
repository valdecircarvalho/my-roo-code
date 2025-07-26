#!/bin/bash

# ================================================================
# ETAPA 3: ASSETS E RECURSOS VISUAIS
# ================================================================
# 
# Esta etapa substitui todos os assets visuais (ícones, logos,
# imagens) do projeto original pelos assets TQI.
#
# IMPORTANTE: Esta etapa requer intervenção manual para fornecer
# os assets TQI específicos.
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

# Verificar se Etapa 2 foi concluída
if [ ! -f "$AUTOMATION_DIR/logs/etapa2-report.json" ]; then
    log_warning "Etapa 2 não parece ter sido concluída. Continuando..."
fi

log_header "ETAPA 3: ASSETS E RECURSOS VISUAIS"

# Caminhos dos assets
ASSETS_DIR="$PROJECT_ROOT/src/assets"
ICONS_DIR="$ASSETS_DIR/icons"
IMAGES_DIR="$ASSETS_DIR/images"
WEBVIEW_PUBLIC="$PROJECT_ROOT/webview-ui/public"
APPS_PUBLIC="$PROJECT_ROOT/apps/web-roo-code/public"

# Templates de assets TQI
TEMPLATES_ASSETS="$AUTOMATION_DIR/templates/assets"

# Função para backup de diretório
backup_directory() {
    local dir=$1
    local backup_name=$2
    
    if [ -d "$dir" ]; then
        local backup_dir="${dir}.backup.etapa3.${backup_name}"
        cp -r "$dir" "$backup_dir"
        log_info "✅ Backup criado: $backup_dir"
    fi
}

# Função para verificar se image magick está disponível
check_imagemagick() {
    if command -v magick > /dev/null 2>&1; then
        log_success "✅ ImageMagick encontrado"
        return 0
    elif command -v convert > /dev/null 2>&1; then
        log_success "✅ ImageMagick (convert) encontrado"
        return 0
    else
        log_warning "⚠️  ImageMagick não encontrado - redimensionamento automático desabilitado"
        return 1
    fi
}

# Função para otimizar imagem PNG
optimize_png() {
    local file=$1
    local target_size=${2:-""}
    
    if ! check_imagemagick; then
        return 0
    fi
    
    log_info "Otimizando $file..."
    
    # Backup original
    cp "$file" "${file}.original"
    
    # Redimensionar se tamanho especificado
    if [ -n "$target_size" ]; then
        if command -v magick > /dev/null 2>&1; then
            magick "$file" -resize "${target_size}x${target_size}" "$file"
        else
            convert "$file" -resize "${target_size}x${target_size}" "$file"
        fi
    fi
    
    # Otimizar PNG (se disponível)
    if command -v optipng > /dev/null 2>&1; then
        optipng -quiet "$file" 2>/dev/null || true
    fi
    
    log_success "✅ Otimizado: $(basename "$file")"
}

# Função para criar templates de assets se não existirem
create_asset_templates() {
    log_header "Criando templates de assets"
    
    mkdir -p "$TEMPLATES_ASSETS"
    
    # Criar ícone placeholder SVG
    if [ ! -f "$TEMPLATES_ASSETS/icon.svg" ]; then
        cat > "$TEMPLATES_ASSETS/icon.svg" << 'EOF'
<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="tqiGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0066CC;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#004499;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="128" height="128" rx="16" fill="url(#tqiGradient)"/>
  <text x="64" y="72" font-family="Arial, sans-serif" font-size="36" font-weight="bold" 
        text-anchor="middle" fill="white">TQI</text>
  <text x="64" y="96" font-family="Arial, sans-serif" font-size="12" 
        text-anchor="middle" fill="#E6F3FF">AI Assistant</text>
</svg>
EOF
        log_success "✅ Criado template: icon.svg"
    fi
    
    # Converter SVG para PNG se possível
    if [ -f "$TEMPLATES_ASSETS/icon.svg" ] && check_imagemagick; then
        for size in 16 32 48 64 128 256; do
            local png_file="$TEMPLATES_ASSETS/icon-${size}.png"
            if [ ! -f "$png_file" ]; then
                if command -v magick > /dev/null 2>&1; then
                    magick -background transparent "$TEMPLATES_ASSETS/icon.svg" -resize "${size}x${size}" "$png_file"
                else
                    convert -background transparent "$TEMPLATES_ASSETS/icon.svg" -resize "${size}x${size}" "$png_file"
                fi
                log_success "✅ Gerado: icon-${size}.png"
            fi
        done
    fi
    
    # Criar favicon
    if [ ! -f "$TEMPLATES_ASSETS/favicon.ico" ] && [ -f "$TEMPLATES_ASSETS/icon-32.png" ]; then
        if check_imagemagick; then
            if command -v magick > /dev/null 2>&1; then
                magick "$TEMPLATES_ASSETS/icon-32.png" "$TEMPLATES_ASSETS/favicon.ico"
            else
                convert "$TEMPLATES_ASSETS/icon-32.png" "$TEMPLATES_ASSETS/favicon.ico"
            fi
            log_success "✅ Gerado: favicon.ico"
        fi
    fi
    
    # Criar banner do marketplace (1376x400)
    if [ ! -f "$TEMPLATES_ASSETS/marketplace-banner.png" ]; then
        if check_imagemagick; then
            if command -v magick > /dev/null 2>&1; then
                magick -size 1376x400 gradient:"#0066CC-#004499" \
                       -gravity center -pointsize 72 -fill white \
                       -annotate +0-20 "TQI AI Assistant" \
                       -gravity center -pointsize 32 -fill "#E6F3FF" \
                       -annotate +0+40 "Intelligent Coding Assistant" \
                       "$TEMPLATES_ASSETS/marketplace-banner.png"
            else
                convert -size 1376x400 gradient:"#0066CC-#004499" \
                        -gravity center -pointsize 72 -fill white \
                        -annotate +0-20 "TQI AI Assistant" \
                        -gravity center -pointsize 32 -fill "#E6F3FF" \
                        -annotate +0+40 "Intelligent Coding Assistant" \
                        "$TEMPLATES_ASSETS/marketplace-banner.png"
            fi
            log_success "✅ Gerado: marketplace-banner.png"
        fi
    fi
}

# Função para listar assets que precisam ser substituídos
list_required_assets() {
    log_header "Assets que precisam ser substituídos"
    
    local assets_found=()
    
    # Procurar por assets existentes
    if [ -d "$ICONS_DIR" ]; then
        while IFS= read -r -d '' file; do
            assets_found+=("$(realpath --relative-to="$PROJECT_ROOT" "$file")")
        done < <(find "$ICONS_DIR" -type f \( -name "*.png" -o -name "*.svg" -o -name "*.ico" \) -print0)
    fi
    
    if [ -d "$IMAGES_DIR" ]; then
        while IFS= read -r -d '' file; do
            assets_found+=("$(realpath --relative-to="$PROJECT_ROOT" "$file")")
        done < <(find "$IMAGES_DIR" -type f \( -name "*.png" -o -name "*.svg" -o -name "*.jpg" -o -name "*.jpeg" \) -print0)
    fi
    
    if [ -d "$WEBVIEW_PUBLIC" ]; then
        while IFS= read -r -d '' file; do
            assets_found+=("$(realpath --relative-to="$PROJECT_ROOT" "$file")")
        done < <(find "$WEBVIEW_PUBLIC" -type f \( -name "*.png" -o -name "*.svg" -o -name "*.ico" \) -print0)
    fi
    
    if [ -d "$APPS_PUBLIC" ]; then
        while IFS= read -r -d '' file; do
            assets_found+=("$(realpath --relative-to="$PROJECT_ROOT" "$file")")
        done < <(find "$APPS_PUBLIC" -type f \( -name "*.png" -o -name "*.svg" -o -name "*.ico" \) -print0)
    fi
    
    log_info "📊 Assets encontrados: ${#assets_found[@]}"
    
    if [ ${#assets_found[@]} -gt 0 ]; then
        log_info "📁 Localizações:"
        printf '%s\n' "${assets_found[@]}" | sort
    else
        log_warning "⚠️  Nenhum asset visual encontrado"
    fi
    
    return ${#assets_found[@]}
}

# Função para substituir assets automaticamente
replace_assets_auto() {
    log_header "Substituindo assets automaticamente"
    
    local replacements=0
    
    # Substituir ícone principal da extensão
    if [ -f "$TEMPLATES_ASSETS/icon.svg" ] && [ -d "$ICONS_DIR" ]; then
        local icon_files=("$ICONS_DIR/icon.svg" "$ICONS_DIR/icon.png")
        for icon_file in "${icon_files[@]}"; do
            if [ -f "$icon_file" ]; then
                backup_file "$icon_file"
                
                if [[ "$icon_file" == *.svg ]]; then
                    cp "$TEMPLATES_ASSETS/icon.svg" "$icon_file"
                elif [[ "$icon_file" == *.png ]]; then
                    if [ -f "$TEMPLATES_ASSETS/icon-128.png" ]; then
                        cp "$TEMPLATES_ASSETS/icon-128.png" "$icon_file"
                    else
                        log_warning "⚠️  Template PNG não encontrado para: $icon_file"
                        continue
                    fi
                fi
                
                log_success "✅ Substituído: $(basename "$icon_file")"
                ((replacements++))
            fi
        done
    fi
    
    # Substituir favicons
    if [ -f "$TEMPLATES_ASSETS/favicon.ico" ]; then
        local favicon_paths=(
            "$WEBVIEW_PUBLIC/favicon.ico"
            "$APPS_PUBLIC/favicon.ico"
            "$PROJECT_ROOT/public/favicon.ico"
        )
        
        for favicon_path in "${favicon_paths[@]}"; do
            if [ -f "$favicon_path" ]; then
                backup_file "$favicon_path"
                cp "$TEMPLATES_ASSETS/favicon.ico" "$favicon_path"
                log_success "✅ Substituído: $(realpath --relative-to="$PROJECT_ROOT" "$favicon_path")"
                ((replacements++))
            fi
        done
    fi
    
    # Substituir ícones de diferentes tamanhos
    for size in 16 32 48 64 128 192 256 512; do
        local template_file="$TEMPLATES_ASSETS/icon-${size}.png"
        if [ ! -f "$template_file" ]; then
            continue
        fi
        
        # Procurar arquivos que possam corresponder a este tamanho
        local pattern_files=(
            "*${size}x${size}*"
            "*${size}*"
            "icon-${size}*"
            "android-chrome-${size}x${size}*"
            "apple-touch-icon*"
        )
        
        for pattern in "${pattern_files[@]}"; do
            while IFS= read -r -d '' file; do
                if [[ "$file" == *.png ]] || [[ "$file" == *.jpg ]]; then
                    backup_file "$file"
                    cp "$template_file" "$file"
                    optimize_png "$file" "$size"
                    log_success "✅ Substituído: $(realpath --relative-to="$PROJECT_ROOT" "$file")"
                    ((replacements++))
                fi
            done < <(find "$PROJECT_ROOT" -name "$pattern" -type f -print0 2>/dev/null || true)
        done
    done
    
    log_info "📊 Total de assets substituídos automaticamente: $replacements"
    return $replacements
}

# Função para backup de arquivo específico
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.etapa3"
        log_info "✅ Backup criado: $(basename "$file").backup.etapa3"
    fi
}

# Função para guia manual de substituição
manual_replacement_guide() {
    log_header "GUIA DE SUBSTITUIÇÃO MANUAL"
    
    echo ""
    echo "🎨 ASSETS TQI NECESSÁRIOS:"
    echo "=========================="
    echo ""
    echo "📁 Ícones principais (obrigatórios):"
    echo "   - icon.svg (vetorial, 128x128)"
    echo "   - icon.png (raster, 128x128)"
    echo ""
    echo "📁 Favicons (recomendados):"
    echo "   - favicon.ico (16x16, 32x32)"
    echo "   - icon-16.png, icon-32.png, icon-48.png"
    echo ""
    echo "📁 Marketplace (publicação):"
    echo "   - marketplace-banner.png (1376x400)"
    echo "   - icon-128.png (ícone principal)"
    echo ""
    echo "📁 Aplicativo móvel (opcional):"
    echo "   - android-chrome-192x192.png"
    echo "   - android-chrome-512x512.png"
    echo "   - apple-touch-icon.png (180x180)"
    echo ""
    echo "🎨 ESPECIFICAÇÕES TÉCNICAS:"
    echo "=========================="
    echo "   - Formato: PNG (transparente) ou SVG"
    echo "   - Cores: Azul TQI (#0066CC, #004499)"
    echo "   - Estilo: Moderno, minimalista"
    echo "   - Logo: 'TQI' ou símbolo corporativo"
    echo ""
    echo "📂 LOCALIZAÇÃO DOS TEMPLATES:"
    echo "=========================="
    echo "   $TEMPLATES_ASSETS/"
    echo ""
    echo "💡 INSTRUÇÃO:"
    echo "============"
    echo "1. Adicione seus assets TQI na pasta templates/assets/"
    echo "2. Execute novamente este script"
    echo "3. Ou substitua manualmente os arquivos nas pastas:"
    echo "   - $ICONS_DIR/"
    echo "   - $WEBVIEW_PUBLIC/"
    echo "   - $APPS_PUBLIC/"
    echo ""
}

# Função para verificar se assets TQI foram fornecidos
check_tqi_assets() {
    log_header "Verificando assets TQI fornecidos"
    
    local required_assets=(
        "icon.svg"
        "icon-128.png"
        "favicon.ico"
    )
    
    local missing_assets=()
    local found_assets=()
    
    for asset in "${required_assets[@]}"; do
        if [ -f "$TEMPLATES_ASSETS/$asset" ]; then
            found_assets+=("$asset")
        else
            missing_assets+=("$asset")
        fi
    done
    
    log_info "📊 Assets encontrados: ${#found_assets[@]}/${#required_assets[@]}"
    
    if [ ${#found_assets[@]} -gt 0 ]; then
        log_success "✅ Assets disponíveis:"
        printf '   - %s\n' "${found_assets[@]}"
    fi
    
    if [ ${#missing_assets[@]} -gt 0 ]; then
        log_warning "⚠️  Assets ausentes:"
        printf '   - %s\n' "${missing_assets[@]}"
        return 1
    fi
    
    return 0
}

# Função para modo interativo
interactive_mode() {
    log_header "MODO INTERATIVO - SUBSTITUIÇÃO DE ASSETS"
    
    echo ""
    echo "Escolha uma opção:"
    echo "1) Usar templates gerados automaticamente (placeholders)"
    echo "2) Aguardar fornecimento manual dos assets TQI"
    echo "3) Pular esta etapa (manter assets originais)"
    echo ""
    read -p "Opção (1-3): " choice
    
    case $choice in
        1)
            log_info "Usando templates gerados automaticamente..."
            create_asset_templates
            replace_assets_auto
            ;;
        2)
            manual_replacement_guide
            echo ""
            read -p "Assets TQI foram adicionados? (s/N): " assets_ready
            if [[ "$assets_ready" =~ ^[Ss]$ ]]; then
                if check_tqi_assets; then
                    replace_assets_auto
                else
                    log_error "Assets ainda estão faltando"
                    return 1
                fi
            else
                log_warning "Etapa 3 marcada como pendente"
                return 2
            fi
            ;;
        3)
            log_warning "Assets originais mantidos - rebranding visual incompleto"
            return 3
            ;;
        *)
            log_error "Opção inválida"
            return 1
            ;;
    esac
}

# Função para validar integridade dos assets
validate_assets() {
    log_header "Validando integridade dos assets"
    
    local errors=0
    
    # Verificar se ícone principal existe
    local main_icons=("$ICONS_DIR/icon.svg" "$ICONS_DIR/icon.png")
    local main_icon_found=false
    
    for icon in "${main_icons[@]}"; do
        if [ -f "$icon" ]; then
            main_icon_found=true
            log_success "✅ Ícone principal encontrado: $(basename "$icon")"
            
            # Verificar tamanho se for PNG
            if [[ "$icon" == *.png ]] && check_imagemagick; then
                local dimensions
                if command -v magick > /dev/null 2>&1; then
                    dimensions=$(magick identify -format "%wx%h" "$icon" 2>/dev/null || echo "unknown")
                else
                    dimensions=$(identify -format "%wx%h" "$icon" 2>/dev/null || echo "unknown")
                fi
                log_info "   Dimensões: $dimensions"
            fi
        fi
    done
    
    if [ "$main_icon_found" = false ]; then
        log_error "❌ Nenhum ícone principal encontrado"
        ((errors++))
    fi
    
    # Verificar favicons
    local favicon_found=false
    local favicon_paths=(
        "$WEBVIEW_PUBLIC/favicon.ico"
        "$APPS_PUBLIC/favicon.ico"
    )
    
    for favicon in "${favicon_paths[@]}"; do
        if [ -f "$favicon" ]; then
            favicon_found=true
            log_success "✅ Favicon encontrado: $(realpath --relative-to="$PROJECT_ROOT" "$favicon")"
        fi
    done
    
    if [ "$favicon_found" = false ]; then
        log_warning "⚠️  Nenhum favicon encontrado"
    fi
    
    return $errors
}

# Função principal
main() {
    log_header "INICIANDO ETAPA 3"
    
    log_info "📊 Status inicial:"
    log_info "   - Projeto: $(basename "$PROJECT_ROOT")"
    log_info "   - Assets dir: $ASSETS_DIR"
    log_info "   - Templates: $TEMPLATES_ASSETS"
    
    # Verificar ferramentas opcionais
    check_imagemagick
    
    # Criar backup dos diretórios de assets
    backup_directory "$ASSETS_DIR" "assets"
    backup_directory "$WEBVIEW_PUBLIC" "webview-public"
    if [ -d "$APPS_PUBLIC" ]; then
        backup_directory "$APPS_PUBLIC" "apps-public"
    fi
    
    # Listar assets existentes
    local asset_count
    asset_count=$(list_required_assets)
    
    # Criar templates se não existirem
    create_asset_templates
    
    # Verificar se modo não-interativo foi solicitado
    if [[ "${1:-}" == "--auto" ]]; then
        log_info "Modo automático: usando templates gerados"
        replace_assets_auto
        validation_result=0
    else
        # Modo interativo
        interactive_mode
        local interaction_result=$?
        
        case $interaction_result in
            0) validation_result=0 ;;
            2) validation_result=2 ;; # Pendente
            3) validation_result=3 ;; # Pulado
            *) validation_result=1 ;; # Erro
        esac
    fi
    
    # Validar resultado
    if [ "$validation_result" -eq 0 ]; then
        validate_assets
        local validation_errors=$?
        
        if [ "$validation_errors" -eq 0 ]; then
            log_success "🎉 ETAPA 3 CONCLUÍDA COM SUCESSO!"
            status="completed"
        else
            log_warning "⚠️  Etapa 3 concluída com avisos"
            status="completed_with_warnings"
        fi
    elif [ "$validation_result" -eq 2 ]; then
        log_warning "⚠️  Etapa 3 pendente - aguardando assets TQI"
        status="pending"
    elif [ "$validation_result" -eq 3 ]; then
        log_warning "⚠️  Etapa 3 pulada - assets originais mantidos"
        status="skipped"
    else
        log_error "❌ ETAPA 3 FALHOU"
        status="failed"
        exit 1
    fi
    
    # Criar relatório JSON
    mkdir -p "$AUTOMATION_DIR/logs"
    cat > "$AUTOMATION_DIR/logs/etapa3-report.json" << EOF
{
    "etapa": 3,
    "name": "assets-visuais",
    "status": "$status",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "changes": {
        "assets_found": $asset_count,
        "templates_created": $(ls -1 "$TEMPLATES_ASSETS" 2>/dev/null | wc -l),
        "replacements_made": "automated",
        "validation_errors": ${validation_errors:-0}
    },
    "tools": {
        "imagemagick": $(check_imagemagick && echo "true" || echo "false"),
        "optipng": $(command -v optipng > /dev/null && echo "true" || echo "false")
    }
}
EOF
    
    log_info "📁 Relatório salvo: logs/etapa3-report.json"
    
    if [[ "$status" == "completed"* ]]; then
        log_info "➡️  Próxima etapa: ./etapas/etapa4.sh"
    else
        log_info "🔄 Para repetir esta etapa: ./etapas/etapa3.sh"
    fi
}

# Função de rollback
rollback_etapa3() {
    log_header "ROLLBACK ETAPA 3"
    
    log_info "Restaurando backups de assets..."
    
    # Restaurar diretórios
    local backup_dirs=(
        "$ASSETS_DIR.backup.etapa3.assets"
        "$WEBVIEW_PUBLIC.backup.etapa3.webview-public"
        "$APPS_PUBLIC.backup.etapa3.apps-public"
    )
    
    for backup_dir in "${backup_dirs[@]}"; do
        if [ -d "$backup_dir" ]; then
            local original_dir="${backup_dir%.backup.etapa3.*}"
            rm -rf "$original_dir"
            mv "$backup_dir" "$original_dir"
            log_info "✅ Restaurado: $(basename "$original_dir")"
        fi
    done
    
    # Restaurar arquivos individuais
    find "$PROJECT_ROOT" -name "*.backup.etapa3" | while read -r backup; do
        original="${backup%.backup.etapa3}"
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
        rollback_etapa3
        exit 0
        ;;
    "--help")
        echo "Uso: $0 [--auto|--rollback|--help]"
        echo "  --auto      Modo automático (usar templates gerados)"
        echo "  --rollback  Desfaz as mudanças da etapa 3"
        echo "  --help      Mostra esta ajuda"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 