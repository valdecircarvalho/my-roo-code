# Como Usar o Sistema de Rebranding TQI AI Assistant

Este guia detalha como usar o sistema de automação para transformar o Roo-Code em TQI AI Assistant.

## 🚀 Início Rápido (5 minutos)

```bash
# 1. Clone o projeto Roo-Code
git clone https://github.com/RooCodeInc/Roo-Code.git
cd Roo-Code

# 2. Extraia a automação na raiz do projeto
# (cole a pasta tqi-rebranding-automation aqui)

# 3. Configure o sistema
cd tqi-rebranding-automation
./setup.sh

# 4. Edite as configurações TQI
nano config.sh
# Altere TQI_GITHUB_USER="SeuUsuario" para seu usuário do GitHub

# 5. Execute o rebranding automático
./start-rebranding.sh --auto
```

## 📋 Pré-requisitos

### Ferramentas Necessárias

Antes de começar, instale:

```bash
# Node.js (>= 16.0.0)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# pnpm
npm install -g pnpm

# jq (para manipulação JSON)
sudo apt-get install jq

# VSCode Extension CLI
npm install -g @vscode/vsce

# Git (>= 2.20.0)
sudo apt-get install git
```

### Verificar Instalação

```bash
cd tqi-rebranding-automation
./scripts/check-requirements.sh
```

## 🛠️ Configuração Detalhada

### 1. Setup Inicial

```bash
./setup.sh
```

**O que o setup faz:**
- ✅ Verifica se está no projeto Roo-Code correto
- ✅ Cria estrutura de diretórios
- ✅ Configura sistema de backup
- ✅ Valida pré-requisitos
- ✅ Cria backup inicial do projeto

### 2. Configurar Informações TQI

Edite o arquivo `config.sh`:

```bash
nano config.sh
```

**Configurações obrigatórias:**
```bash
TQI_GITHUB_USER="SeuUsuario"        # ⚠️ ALTERE AQUI
TQI_GITHUB_REPO="tqi-ai-assistant"
TQI_EMAIL="dev-ai@tqi.com.br"
TQI_WEBSITE="https://www.tqi.com.br"
```

### 3. Validar Projeto

```bash
./validate-project.sh
```

**O que é validado:**
- 📁 Estrutura de diretórios
- 📄 Arquivos críticos
- 🔧 Ferramentas instaladas
- 💻 Build do projeto
- 🌿 Status do Git

## 🎯 Métodos de Execução

### Método 1: Automático (Recomendado)

**Para primeira execução:**
```bash
./start-rebranding.sh --auto
```

**Execução com opções:**
```bash
# Modo força (sem confirmações)
./start-rebranding.sh --auto --force

# Simular execução (não modifica arquivos)
./start-rebranding.sh --auto --dry-run

# Continuar mesmo com erros
./start-rebranding.sh --auto --no-stop-on-error
```

### Método 2: Interativo

```bash
./start-rebranding.sh
```

**Menu interativo oferece:**
- 🎯 Executar etapas específicas
- 📊 Ver progresso em tempo real
- 💾 Sistema de backup/rollback
- 📋 Visualizar logs
- ⚙️ Utilitários avançados

### Método 3: Etapa por Etapa

```bash
# Executar apenas uma etapa específica
./start-rebranding.sh --etapa 1

# Ou usar scripts individuais
./etapas/etapa1.sh
./etapas/etapa2.sh
# ... continue
```

## 📊 Entendendo as Etapas

### Etapa 1: Rebranding Básico (CRÍTICA)
- 🎯 **O que faz**: Modifica package.json, nomes, publisher, comandos
- ⏱️ **Tempo**: 2-5 minutos
- 🔄 **Backup**: Automático antes da execução
- ⚠️ **Atenção**: Mais crítica - falha aqui para tudo

### Etapa 2: Workspace e Pacotes (ALTA)
- 🎯 **O que faz**: Atualiza dependências internas @roo-code → @tqi
- ⏱️ **Tempo**: 3-7 minutos
- 🧪 **Testes**: Build completo após modificações

### Etapa 3: Assets Visuais (ALTA)
- 🎯 **O que faz**: Substitui ícones e logos TQI
- ⏱️ **Tempo**: 1-3 minutos + tempo manual
- 👤 **Manual**: Requer substituição manual dos assets

### Etapa 4-9: Outras Configurações
- 📝 Internacionalização, documentação, URLs
- ⏱️ **Tempo total**: 10-20 minutos

## 💾 Sistema de Backup

### Tipos de Backup

1. **Backup por Cópia**: Arquivos físicos
2. **Backup Git**: Branches e tags
3. **Manifesto**: Metadados e integridade

### Comandos de Backup

```bash
# Sistema interativo de backup
./scripts/backup-system.sh

# Backup manual de uma etapa
./scripts/backup-system.sh backup 1 "meu-checkpoint"

# Listar backups disponíveis
./scripts/backup-system.sh list

# Validar integridade
./scripts/backup-system.sh validate backups/etapa1/20241201_143022
```

### Rollback

```bash
# Rollback da última etapa
./scripts/backup-system.sh restore-copy latest-etapa1

# Rollback completo (volta ao Roo-Code original)
./scripts/backup-system.sh restore-copy original-latest

# Rollback por Git
./scripts/backup-system.sh restore-git main
```

## 🧪 Validação e Testes

### Durante a Execução

Cada etapa automaticamente:
- ✅ Valida sintaxe JSON
- ✅ Testa build
- ✅ Verifica integridade
- ✅ Cria backups

### Testes Manuais

```bash
# Testar build
cd .. && pnpm build

# Gerar VSIX
pnpm vsix

# Instalar para teste
code --install-extension bin/tqi-ai-assistant-1.0.0.vsix

# Verificar funcionamento
code .
```

## 📋 Checklist de Validação

### ✅ Antes da Execução
- [ ] Projeto Roo-Code original confirmado
- [ ] Todas as ferramentas instaladas
- [ ] Git status limpo (recomendado)
- [ ] config.sh editado com informações TQI
- [ ] Backup inicial criado

### ✅ Durante a Execução
- [ ] Cada etapa passa nos testes
- [ ] Builds são bem-sucedidos
- [ ] Nenhum erro crítico reportado
- [ ] Backups criados automaticamente

### ✅ Após a Execução
- [ ] VSIX gerado com sucesso
- [ ] Extensão instala no VSCode
- [ ] Interface mostra "TQI AI Assistant"
- [ ] Comandos funcionam corretamente
- [ ] Nenhuma referência ao Roo-Code na UI

## 🚨 Resolução de Problemas

### Problema: Setup falha

```bash
# Verificar dependências
./scripts/check-requirements.sh

# Verificar se está no projeto correto
ls -la ../src/package.json
grep "roo-cline" ../src/package.json
```

### Problema: Build falha após modificações

```bash
# Rollback para estado anterior
./scripts/backup-system.sh restore-copy latest-etapa1

# Verificar logs
cat logs/etapa1.log

# Executar novamente com mais verbosidade
./etapas/etapa1.sh --force
```

### Problema: JSON inválido

```bash
# Identificar arquivo problemático
find .. -name "*.json" -not -path "*/node_modules/*" -exec jq . {} \;

# Restaurar backup específico
cp backups/etapa1/20241201_143022/src/package.json ../src/package.json
```

### Problema: Git conflicts

```bash
# Resolver conflicts
./scripts/git-management.sh --resolve

# Ou resetar para estado limpo
cd .. && git reset --hard HEAD && git clean -fd
```

## 📊 Monitoramento e Logs

### Logs Disponíveis

```bash
# Log principal
tail -f logs/rebranding.log

# Log de uma etapa específica
cat logs/etapa1.log

# Relatórios JSON
cat logs/validation-report.json
cat logs/rebranding-final.json
```

### Status em Tempo Real

```bash
# Ver status atual
cat status.json

# Progresso em tempo real (durante execução)
watch -n 2 'cat status.json | jq .rebranding.current_etapa'
```

## 🎉 Finalização

### Após Sucesso Completo

1. **Testar a extensão**:
   ```bash
   cd ..
   code --install-extension bin/tqi-ai-assistant-1.0.0.vsix
   ```

2. **Criar repositório TQI**:
   ```bash
   # No GitHub, criar novo repositório: tqi-ai-assistant
   git remote add tqi https://github.com/SeuUsuario/tqi-ai-assistant.git
   git push tqi main --tags
   ```

3. **Publicar no Marketplace** (opcional):
   ```bash
   vsce publish
   ```

### Limpeza (Opcional)

```bash
# Remover pasta de automação
rm -rf tqi-rebranding-automation

# Manter apenas backups essenciais
mkdir tqi-backups
cp -r tqi-rebranding-automation/backups/original-latest tqi-backups/
```

## 🆘 Suporte

### Comandos de Emergência

```bash
# Parar execução
pkill -f "rebranding"

# Rollback completo de emergência
./scripts/backup-system.sh restore-copy original-latest

# Diagnóstico completo
./scripts/validation.sh --diagnose
```

### Contatos

- 📧 Email: dev-ai@tqi.com.br
- 🐛 Issues: [GitHub Issues](https://github.com/SeuUsuario/tqi-ai-assistant/issues)
- 📚 Docs: Arquivo `mod-plan.md` (documentação completa)

## 🏆 Dicas de Boas Práticas

1. **Sempre execute validação antes**: `./validate-project.sh`
2. **Use modo interativo na primeira vez**: Mais controle
3. **Monitore logs em tempo real**: `tail -f logs/rebranding.log`
4. **Mantenha backups**: Sistema cria automaticamente, mas preserve manualmente
5. **Teste cada etapa**: Não pule validações
6. **Documente problemas**: Para melhorar o processo

---

**Tempo total estimado**: 30-60 minutos (automático) ou 2-4 horas (manual)

**Taxa de sucesso**: >95% quando pré-requisitos são atendidos

**Suporte**: Sistema completo de rollback garante que nada será perdido 