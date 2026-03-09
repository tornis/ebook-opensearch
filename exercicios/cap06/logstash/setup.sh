#!/bin/bash

# Setup Script para Logstash + OpenSearch
# Automatiza download de drivers, datasets e inicialização de containers

set -e  # Exit on error

echo "========================================="
echo "  Logstash + OpenSearch Setup Script"
echo "========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Verificar pré-requisitos
echo -e "${YELLOW}[1/6]${NC} Verificando pré-requisitos..."

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker não está instalado${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose não está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker e Docker Compose encontrados${NC}"

# 2. Criar estrutura de diretórios
echo ""
echo -e "${YELLOW}[2/6]${NC} Criando estrutura de diretórios..."

mkdir -p logstash/config
mkdir -p logstash/pipelines
mkdir -p logstash/drivers
mkdir -p logstash/logs
mkdir -p datasets

echo -e "${GREEN}✓ Diretórios criados${NC}"

# 3. Criar/verificar network Docker
echo ""
echo -e "${YELLOW}[3/6]${NC} Verificando Docker network 'opensearch-net'..."

if docker network ls | grep -q "opensearch-net"; then
    echo -e "${GREEN}✓ Network 'opensearch-net' já existe${NC}"
else
    echo "   Criando network..."
    docker network create opensearch-net
    echo -e "${GREEN}✓ Network criada${NC}"
fi

# 4. Download do JDBC Driver
echo ""
echo -e "${YELLOW}[4/6]${NC} Verificando JDBC Driver para SQLite..."

DRIVER_FILE="logstash/drivers/sqlite-jdbc-3.48.0.0.jar"

if [ -f "$DRIVER_FILE" ]; then
    echo -e "${GREEN}✓ Driver JDBC já existe${NC}"
else
    echo "   Baixando sqlite-jdbc 3.48.0.0..."
    cd logstash/drivers

    if command -v wget &> /dev/null; then
        wget -q https://github.com/xerial/sqlite-jdbc/releases/download/3.48.0.0/sqlite-jdbc-3.48.0.0.jar
    elif command -v curl &> /dev/null; then
        curl -L -o sqlite-jdbc-3.48.0.0.jar \
            https://github.com/xerial/sqlite-jdbc/releases/download/3.48.0.0/sqlite-jdbc-3.48.0.0.jar
    else
        echo -e "${RED}✗ wget ou curl não encontrados. Download manual necessário.${NC}"
        echo "   Baixe de: https://github.com/xerial/sqlite-jdbc/releases/download/3.48.0.0/sqlite-jdbc-3.48.0.0.jar"
        exit 1
    fi

    cd ../..
    echo -e "${GREEN}✓ Driver JDBC baixado${NC}"
fi

# 5. Download do Dataset Chinook
echo ""
echo -e "${YELLOW}[5/6]${NC} Verificando Dataset Chinook..."

if [ -f "datasets/chinook.db" ]; then
    echo -e "${GREEN}✓ Dataset chinook.db já existe${NC}"
else
    echo "   Baixando chinook.db (~600KB)..."

    if command -v wget &> /dev/null; then
        wget -q -O datasets/chinook.db \
            https://raw.githubusercontent.com/tornis/esstackenterprise/master/datasets/chinook.db
    elif command -v curl &> /dev/null; then
        curl -L -o datasets/chinook.db \
            https://raw.githubusercontent.com/tornis/esstackenterprise/master/datasets/chinook.db
    else
        echo -e "${RED}✗ wget ou curl não encontrados${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Dataset Chinook baixado${NC}"
fi

# 6. Iniciar Logstash
echo ""
echo -e "${YELLOW}[6/6]${NC} Iniciando Logstash..."

# Verificar se OpenSearch está rodando
if ! curl -s -k -u admin:Admin@123456 https://localhost:9200 &> /dev/null; then
    echo -e "${YELLOW}   ⚠ OpenSearch não está acessível em https://localhost:9200${NC}"
    echo "   Certifique-se de que OpenSearch está rodando antes de iniciar Logstash"
    echo ""
    echo "   Para iniciar OpenSearch, execute:"
    echo "   $ docker-compose up -d opensearch"
    echo ""
fi

# Voltar para diretório raiz do projeto
cd - &> /dev/null || true

docker-compose -f docker-compose-logstash.yml up -d

# Aguardar Logstash iniciar
echo "   Aguardando Logstash iniciar..."
sleep 5

# Verificar se Logstash iniciou
if docker ps | grep -q "logstash"; then
    echo -e "${GREEN}✓ Logstash iniciado com sucesso${NC}"
else
    echo -e "${RED}✗ Erro ao iniciar Logstash${NC}"
    docker logs logstash | tail -20
    exit 1
fi

# Verificar API de monitoramento
if curl -s http://localhost:9600 &> /dev/null; then
    echo -e "${GREEN}✓ API de monitoramento acessível em http://localhost:9600${NC}"
fi

echo ""
echo "========================================="
echo -e "${GREEN}✓ Setup concluído com sucesso!${NC}"
echo "========================================="
echo ""
echo "Próximos passos:"
echo "  1. Ver status: docker logs -f logstash"
echo "  2. Testar pipeline: ./logstash/test-pipelines.sh"
echo "  3. Validar ingestão JDBC: curl -k -u admin:Admin@123456 \\
              https://localhost:9200/chinook-customers/_count"
echo ""
echo "Para mais detalhes, veja: logstash/README-SETUP.md"
echo ""
