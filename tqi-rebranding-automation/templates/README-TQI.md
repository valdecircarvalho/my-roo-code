# TQI AI Assistant

> 🤖 Assistente de IA Avançado para Desenvolvimento - Powered by TQI

## 🚀 Visão Geral

O TQI AI Assistant é uma extensão VSCode poderosa que traz inteligência artificial avançada para o seu fluxo de desenvolvimento. Com suporte a múltiplos provedores de IA e recursos avançados de automação, acelere sua produtividade como nunca antes.

### ✨ Principais Recursos

- 🧠 **IA Conversacional**: Chat interativo com múltiplos modelos de IA
- 💻 **Geração de Código**: Criação automática de código inteligente
- 🔧 **Refatoração Assistida**: Melhoria e otimização automática de código
- 🐛 **Debug Inteligente**: Análise e correção de bugs com IA
- 📝 **Documentação Automática**: Geração de documentação contextual
- 🔍 **Análise de Código**: Revisão e sugestões de qualidade
- 🛡️ **Segurança**: Detecção de vulnerabilidades e boas práticas

### 🎯 Provedores Suportados

- **OpenAI**: GPT-4, GPT-3.5-turbo
- **Anthropic**: Claude 3 (Opus, Sonnet, Haiku)
- **OpenRouter**: Acesso a 150+ modelos
- **Vertex AI**: Modelos do Google Cloud
- **Ollama**: Modelos locais
- **Azure OpenAI**: Integração empresarial

## 📦 Instalação

### Via VSCode Marketplace

1. Abra o VSCode
2. Vá para Extensions (Ctrl+Shift+X)
3. Busque por "TQI AI Assistant"
4. Clique em "Install"

### Via VSIX

```bash
# Download do VSIX
curl -L -o tqi-ai-assistant.vsix https://github.com/[SEU_USUARIO]/tqi-ai-assistant/releases/latest/download/tqi-ai-assistant.vsix

# Instalar
code --install-extension tqi-ai-assistant.vsix
```

## 🛠️ Configuração

### 1. Configuração Inicial

Após a instalação, configure sua chave de API:

1. Abra Command Palette (Ctrl+Shift+P)
2. Execute: `TQI AI Assistant: Configure API Keys`
3. Selecione seu provedor preferido
4. Insira sua chave de API

### 2. Configurações Avançadas

```json
{
  "tqi-ai-assistant.defaultProvider": "openai",
  "tqi-ai-assistant.model": "gpt-4",
  "tqi-ai-assistant.maxTokens": 4000,
  "tqi-ai-assistant.temperature": 0.7,
  "tqi-ai-assistant.enableCodeActions": true,
  "tqi-ai-assistant.autoSuggestions": true
}
```

## 🎮 Como Usar

### Chat Interativo

1. Abra a barra lateral do TQI AI Assistant
2. Digite sua pergunta ou solicitação
3. Receba respostas contextuais e acionáveis

### Ações de Código

- **Explicar Código**: Selecione código → Right-click → TQI AI Assistant → Explain Code
- **Gerar Testes**: Selecione função → Right-click → TQI AI Assistant → Generate Tests
- **Refatorar**: Selecione código → Right-click → TQI AI Assistant → Refactor
- **Corrigir Bug**: Selecione código com erro → Right-click → TQI AI Assistant → Fix Bug

### Comandos Principais

| Comando | Atalho | Descrição |
|---------|--------|-----------|
| `TQI AI Assistant: New Chat` | `Ctrl+Shift+A` | Iniciar nova conversa |
| `TQI AI Assistant: Explain Code` | `Ctrl+Shift+E` | Explicar código selecionado |
| `TQI AI Assistant: Generate Tests` | `Ctrl+Shift+T` | Gerar testes unitários |
| `TQI AI Assistant: Fix Code` | `Ctrl+Shift+F` | Corrigir código selecionado |

## 🏢 Sobre a TQI

A TQI é uma empresa líder em transformação digital e desenvolvimento de software, oferecendo soluções inovadoras que impulsionam o crescimento dos negócios através da tecnologia.

### 🔗 Links Úteis

- **Website**: [https://www.tqi.com.br](https://www.tqi.com.br)
- **Documentação**: [https://docs.tqi.com.br/ai-assistant](https://docs.tqi.com.br/ai-assistant)
- **Suporte**: [suporte.ai@tqi.com.br](mailto:suporte.ai@tqi.com.br)
- **GitHub**: [https://github.com/[SEU_USUARIO]/tqi-ai-assistant](https://github.com/[SEU_USUARIO]/tqi-ai-assistant)

## 🆘 Suporte e FAQ

### Problemas Comuns

**Q: A extensão não responde**
A: Verifique se sua API key está configurada corretamente e se você tem conexão com a internet.

**Q: Como alterar o modelo de IA?**
A: Vá em Settings → Extensions → TQI AI Assistant → Model e selecione o modelo desejado.

**Q: A extensão consome muitos tokens?**
A: Configure o `maxTokens` nas configurações para limitar o uso por solicitação.

### Reportar Problemas

Encontrou um bug? [Abra uma issue](https://github.com/[SEU_USUARIO]/tqi-ai-assistant/issues/new) no GitHub.

## 🤝 Contribuindo

Contribuições são bem-vindas! Veja nosso [guia de contribuição](CONTRIBUTING.md) para começar.

### Desenvolvimento Local

```bash
# Clone o repositório
git clone https://github.com/[SEU_USUARIO]/tqi-ai-assistant.git
cd tqi-ai-assistant

# Instalar dependências
pnpm install

# Executar em modo desenvolvimento
pnpm dev

# Build para produção
pnpm build

# Gerar VSIX
pnpm package
```

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

## 🏷️ Versão

**Versão Atual**: 1.0.0  
**Última Atualização**: [DATA_ATUAL]

---

**Desenvolvido com ❤️ pela equipe TQI**

*Acelere seu desenvolvimento com inteligência artificial de ponta* 