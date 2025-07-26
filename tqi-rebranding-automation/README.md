# TQI AI Assistant - Sistema de Rebranding Automatizado

Este diretório contém todos os scripts e arquivos necessários para rebrandizar a extensão Roo-Code para TQI AI Assistant de forma segura e automatizada.

## 🚀 Início Rápido

```bash
# 1. Entre na pasta de automação
cd tqi-rebranding-automation

# 2. Execute o script de configuração inicial
./setup.sh

# 3. Execute a validação do projeto base
./validate-project.sh

# 4. Inicie o rebranding automático
./start-rebranding.sh

# OU execute etapa por etapa
./etapas/etapa1.sh
./etapas/etapa2.sh
# ... continue com as demais etapas
```

## 📁 Estrutura dos Arquivos

```
tqi-rebranding-automation/
├── README.md                    # Este arquivo
├── setup.sh                     # Configuração inicial
├── validate-project.sh          # Validação do projeto base
├── start-rebranding.sh          # Início automático completo
├── scripts/                     # Scripts utilitários
│   ├── backup-system.sh         # Sistema avançado de backup
│   ├── git-management.sh        # Gerenciamento de Git/branches
│   ├── validation.sh            # Validações e testes
│   └── rollback.sh              # Sistema de rollback
├── etapas/                      # Scripts de cada etapa
│   ├── etapa1.sh               # Rebranding básico
│   ├── etapa2.sh               # Workspace e pacotes
│   ├── etapa3.sh               # Assets visuais
│   ├── etapa4.sh               # Internacionalização
│   ├── etapa5.sh               # Código e comandos
│   ├── etapa6.sh               # Documentação
│   ├── etapa7.sh               # URLs e links
│   ├── etapa8.sh               # Configurações avançadas
│   └── etapa9.sh               # Validação e testes
├── templates/                   # Templates e assets
│   ├── package-json/           # Templates de package.json
│   ├── assets/                 # Novos assets TQI
│   └── configs/                # Configurações
├── backups/                     # Sistema de backup
│   ├── etapa1/                 # Backups da etapa 1
│   ├── etapa2/                 # Backups da etapa 2
│   └── ...                     # Demais etapas
└── logs/                        # Logs de execução
    ├── execucao.log            # Log principal
    ├── validacoes.log          # Log de validações
    └── rollbacks.log           # Log de rollbacks
```

## ⚡ Funcionalidades Principais

### 🛡️ Sistema de Backup Triplo
- **Backup por cópia**: Arquivos físicos organizados por etapa
- **Git branching**: Versionamento com branches específicas
- **Manifesto de integridade**: Validação automática com MD5

### 🔄 Rollback Avançado
- **Granular**: Por arquivo específico
- **Por etapa**: Etapa completa
- **Projeto completo**: Volta ao estado original
- **Emergência**: Último estado conhecido bom

### 🧪 Validação Contínua
- **Build automático**: Após cada etapa
- **Sintaxe JSON**: Validação de todos os arquivos
- **Integridade**: Hash MD5 e verificações
- **Funcional**: Testes da extensão no VSCode

## 📋 Pré-requisitos

Antes de executar, certifique-se de ter instalado:

- **Node.js** >= 16.0.0
- **pnpm** >= 8.0.0
- **Git** >= 2.20.0
- **VSCode Extension CLI (vsce)**
- **jq** (para manipulação JSON)
- **VSCode** (para testes)

```bash
# Verificar pré-requisitos
./scripts/check-requirements.sh
```

## 🎯 Etapas do Rebranding

### Etapa 1: Rebranding Básico (CRÍTICA)
- Modificação dos `package.json` principais
- Alteração de nomes, publisher, versão
- Atualização de comandos e IDs

### Etapa 2: Workspace e Pacotes (ALTA)
- Configuração do monorepo
- Dependências internas `@roo-code/*` → `@tqi/*`
- Estrutura do workspace

### Etapa 3: Assets Visuais (ALTA)
- Substituição de ícones e logos
- Identidade visual TQI
- Otimização e validação

### Etapa 4: Internacionalização (ALTA)
- Textos da interface
- Múltiplos idiomas
- Chaves de localização

### Etapa 5: Código e Comandos (MÉDIA)
- Referências no código TypeScript
- Imports e exports
- Constantes e variáveis

### Etapa 6: Documentação (MÉDIA)
- README, CHANGELOG
- Documentação técnica
- Guias de usuário

### Etapa 7: URLs e Links (BAIXA)
- Links do GitHub
- URLs de suporte
- Referências externas

### Etapa 8: Configurações Avançadas (BAIXA)
- Configurações específicas
- Metadados avançados
- Otimizações finais

### Etapa 9: Validação e Testes (CRÍTICA)
- Testes funcionais completos
- Validação final
- Geração do VSIX

## 🚨 Comandos de Emergência

### Parar Execução
```bash
# Se algo der errado durante a execução
pkill -f "rebranding"
```

### Rollback Completo
```bash
# Voltar ao estado original
./scripts/rollback.sh --full
```

### Validação Rápida
```bash
# Verificar integridade atual
./scripts/validation.sh --quick
```

## 📞 Suporte e Troubleshooting

### Problemas Comuns

1. **Build falha**: Execute `./scripts/validation.sh --build`
2. **Git conflicts**: Execute `./scripts/git-management.sh --resolve`
3. **Dependências**: Execute `./setup.sh --check-deps`
4. **Rollback**: Execute `./scripts/rollback.sh --interactive`

### Logs

Todos os logs são salvos em `logs/`:
- `execucao.log`: Log principal de todas as operações
- `validacoes.log`: Resultados de validações e testes
- `rollbacks.log`: Histórico de rollbacks executados

### Contato

Em caso de problemas críticos:
- Verifique os logs em `logs/`
- Execute `./scripts/validation.sh --diagnose`
- Consulte a documentação completa em `mod-plan.md`

## ⚠️ Avisos Importantes

- **SEMPRE** execute em um projeto separado (backup)
- **NUNCA** execute em produção sem testes
- **SEMPRE** valide cada etapa antes de continuar
- **MANTENHA** backups em local seguro

## 🎉 Resultado Final

Após a execução completa:
- ✅ Extensão rebrandizada para TQI AI Assistant
- ✅ VSIX pronto para distribuição
- ✅ Código limpo e validado
- ✅ Documentação atualizada
- ✅ Identidade visual TQI aplicada

---

**Tempo estimado**: 2-4 horas (manual) ou 30-60 minutos (automático)
**Complexidade**: Intermediária a Avançada
**Risco**: Baixo (com sistema de backup) 