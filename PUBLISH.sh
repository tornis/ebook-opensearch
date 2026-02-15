#!/bin/bash

# ============================================================================
# Script de Publicação - OpenSearch Ebook no GitHub
# ============================================================================
# Este script automatiza a publicação do repositório local no GitHub
# 
# Pré-requisitos:
#   1. Git instalado
#   2. Conta GitHub criada (https://github.com/signup)
#   3. Token de acesso pessoal GitHub gerado
#
# Como gerar Token GitHub:
#   1. Ir para https://github.com/settings/tokens/new
#   2. Selecionar "repo" scope
#   3. Copiar o token gerado
# ============================================================================

set -e  # Exit on error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Script de Publicação - OpenSearch Ebook GitHub        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# ============================================================================
# 1. Solicitar informações do usuário
# ============================================================================

echo -e "${YELLOW}📋 PASSO 1: Informações do GitHub${NC}\n"

# Verificar se git está instalado
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git não está instalado${NC}"
    echo "   Baixe em: https://git-scm.com/download"
    exit 1
fi

echo "✅ Git encontrado: $(git --version)"
echo ""

# Solicitar username GitHub
read -p "📧 Digite seu username GitHub (ex: seu-usuario): " GITHUB_USER
if [ -z "$GITHUB_USER" ]; then
    echo -e "${RED}❌ Username não pode estar vazio${NC}"
    exit 1
fi

# Solicitar nome do repositório
read -p "📁 Nome do repositório [opensearch-ebook]: " REPO_NAME
REPO_NAME=${REPO_NAME:-opensearch-ebook}

# Solicitar token (com verificação de visibilidade)
echo ""
echo -e "${YELLOW}🔐 Token de Acesso GitHub${NC}"
echo "   Como obter:"
echo "   1. Ir para: https://github.com/settings/tokens/new"
echo "   2. Selecionar escopo: 'repo' (full control of private repositories)"
echo "   3. Gerar token e copiar"
echo ""
read -sp "🔑 Cole seu token GitHub (será oculto): " GITHUB_TOKEN
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ Token não pode estar vazio${NC}"
    exit 1
fi

# ============================================================================
# 2. Confirmar configuração
# ============================================================================

echo ""
echo -e "${YELLOW}📝 Resumo da Configuração${NC}"
echo "   Username: $GITHUB_USER"
echo "   Repositório: $REPO_NAME"
echo "   URL: https://github.com/$GITHUB_USER/$REPO_NAME.git"
echo ""

read -p "✅ Confirma as configurações? (s/n): " CONFIRM
if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo -e "${RED}❌ Operação cancelada${NC}"
    exit 1
fi

# ============================================================================
# 3. Preparar repositório local
# ============================================================================

echo ""
echo -e "${YELLOW}🔧 PASSO 2: Preparando Repositório Local${NC}\n"

cd /home/claude/opensearch-ebook

# Verificar se está em repositório Git
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Não está em repositório Git${NC}"
    exit 1
fi

echo "✅ Repositório Git encontrado"
echo "   Status atual:"
git status --short | head -5

# Verificar se existem mudanças não commitadas
if [ -n "$(git status --porcelain)" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Existem mudanças não commitadas${NC}"
    echo ""
    read -p "Deseja fazer commit dessas mudanças? (s/n): " COMMIT_CHANGES
    if [ "$COMMIT_CHANGES" = "s" ] || [ "$COMMIT_CHANGES" = "S" ]; then
        read -p "📝 Mensagem do commit: " COMMIT_MSG
        git add -A
        git commit -m "$COMMIT_MSG"
        echo -e "${GREEN}✅ Commit realizado${NC}"
    fi
fi

# ============================================================================
# 4. Configurar remote do GitHub
# ============================================================================

echo ""
echo -e "${YELLOW}🌐 PASSO 3: Configurando Repositório Remoto${NC}\n"

# URL do repositório
REPO_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"

# Verificar se remote já existe
if git remote | grep -q "^origin$"; then
    echo "⚠️  Remote 'origin' já existe"
    echo "   URL atual: $(git remote get-url origin)"
    read -p "   Deseja atualizar? (s/n): " UPDATE_REMOTE
    if [ "$UPDATE_REMOTE" = "s" ] || [ "$UPDATE_REMOTE" = "S" ]; then
        git remote remove origin
        echo "   ✅ Remote removido"
    else
        echo "   ℹ️  Usando remote existente"
    fi
fi

# Adicionar remote
if ! git remote | grep -q "^origin$"; then
    git remote add origin "$REPO_URL"
    echo "✅ Remote 'origin' adicionado"
fi

# ============================================================================
# 5. Criar repositório no GitHub (automático via API)
# ============================================================================

echo ""
echo -e "${YELLOW}📦 PASSO 4: Criando Repositório no GitHub${NC}\n"

# Verificar se repositório já existe
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}")

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${YELLOW}⚠️  Repositório já existe no GitHub${NC}"
    echo "   URL: https://github.com/$GITHUB_USER/$REPO_NAME"
    read -p "   Deseja fazer push mesmo assim? (s/n): " FORCE_PUSH
    if [ "$FORCE_PUSH" != "s" ] && [ "$FORCE_PUSH" != "S" ]; then
        echo -e "${RED}❌ Operação cancelada${NC}"
        exit 1
    fi
elif [ "$HTTP_STATUS" = "404" ]; then
    echo "ℹ️  Criando novo repositório no GitHub..."
    
    # Criar repositório via GitHub API
    RESPONSE=$(curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      https://api.github.com/user/repos \
      -d "{
        \"name\": \"${REPO_NAME}\",
        \"description\": \"Ebook Técnico - OpenSearch 3.5\",
        \"homepage\": \"https://docs.opensearch.org\",
        \"private\": false,
        \"auto_init\": false,
        \"topics\": [\"opensearch\", \"ebook\", \"tutorial\", \"distributed-search\"]
      }")
    
    # Verificar se criação foi bem-sucedida
    if echo "$RESPONSE" | grep -q "\"id\""; then
        echo -e "${GREEN}✅ Repositório criado no GitHub${NC}"
    else
        echo -e "${RED}❌ Erro ao criar repositório${NC}"
        echo "$RESPONSE"
        exit 1
    fi
else
    echo -e "${RED}❌ Erro ao verificar repositório (HTTP $HTTP_STATUS)${NC}"
    exit 1
fi

# ============================================================================
# 6. Push para GitHub
# ============================================================================

echo ""
echo -e "${YELLOW}📤 PASSO 5: Enviando Código para GitHub${NC}\n"

# Renomear branch para 'main' se necessário
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "master" ]; then
    echo "ℹ️  Renomeando branch 'master' para 'main'..."
    git branch -M main
    echo "✅ Branch renomeado"
fi

# Push para GitHub
echo "📤 Enviando código para GitHub..."
git push -u origin main --force

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Push concluído com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao fazer push${NC}"
    exit 1
fi

# ============================================================================
# 7. Configurar GitHub Pages (opcional)
# ============================================================================

echo ""
echo -e "${YELLOW}🌐 PASSO 6: Configuração Opcional - GitHub Pages${NC}\n"

read -p "Deseja ativar GitHub Pages para este repositório? (s/n): " ENABLE_PAGES

if [ "$ENABLE_PAGES" = "s" ] || [ "$ENABLE_PAGES" = "S" ]; then
    echo "ℹ️  Você pode ativar GitHub Pages em:"
    echo "   https://github.com/$GITHUB_USER/$REPO_NAME/settings/pages"
    echo ""
    echo "   Instruções:"
    echo "   1. Ir para Settings → Pages"
    echo "   2. Source: main branch"
    echo "   3. Folder: / (root)"
    echo "   4. Save"
fi

# ============================================================================
# 8. Resumo Final
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              🎉 PUBLICAÇÃO CONCLUÍDA COM SUCESSO 🎉      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}✅ Status${NC}"
echo "   Repositório: $REPO_NAME"
echo "   URL: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "   Branch: main"
echo ""

echo -e "${GREEN}📂 Arquivos Publicados${NC}"
git ls-files | sed 's/^/   /'
echo ""

echo -e "${GREEN}📊 Estatísticas${NC}"
echo "   Total de commits: $(git rev-list --all --count)"
echo "   Tamanho do repositório: $(du -sh . | cut -f1)"
echo ""

echo -e "${GREEN}🚀 Próximos Passos${NC}"
echo "   1. Acessar: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "   2. Copiar link para amigos/comunidade"
echo "   3. Configurar Actions (CI/CD) se necessário"
echo "   4. Adicionar badges ao README"
echo "   5. Criar releases (Tags) para versões"
echo ""

echo -e "${YELLOW}💡 Dicas${NC}"
echo "   • Clone em outra máquina:"
echo "     git clone https://github.com/$GITHUB_USER/$REPO_NAME.git"
echo ""
echo "   • Ver histórico de commits:"
echo "     git log --oneline --graph --all"
echo ""
echo "   • Fazer novo commit:"
echo "     git add ."
echo "     git commit -m \"descrição das mudanças\""
echo "     git push origin main"
echo ""

echo -e "${GREEN}✨ Obrigado por usar este script!${NC}\n"
