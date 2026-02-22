#!/bin/bash
# Setup script para Cap 05 - Fluent Bit + OpenSearch

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Diretório: $SCRIPT_DIR"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Iniciando setup do Capítulo 5...${NC}"

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker não encontrado. Instale Docker Desktop.${NC}"
    exit 1
fi

# Verificar Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose não encontrado.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker instalado${NC}"

# Criar diretório de logs
mkdir -p "$SCRIPT_DIR/logs"
echo -e "${GREEN}✓ Diretório de logs criado${NC}"

# Pull das imagens
echo -e "${YELLOW}📦 Baixando imagens Docker...${NC}"
docker pull opensearchproject/opensearch:3.5.0
docker pull cr.fluentbit.io/fluent/fluent-bit:4.2.2

echo -e "${GREEN}✓ Imagens baixadas${NC}"

# Iniciar serviços
echo -e "${YELLOW}🔄 Iniciando services...${NC}"
cd "$SCRIPT_DIR"
docker-compose up -d

# Aguardar OpenSearch ficar healthy
echo -e "${YELLOW}⏳ Aguardando OpenSearch ficar pronto...${NC}"
sleep 10

# Verificar conectividade
if curl -sk -u admin:M1nhavid@ https://localhost:9200/_cluster/health &> /dev/null; then
    echo -e "${GREEN}✓ OpenSearch está pronto${NC}"
else
    echo -e "${RED}❌ Falha ao conectar ao OpenSearch${NC}"
    exit 1
fi

# Verificar Fluent Bit
if curl -s http://localhost:2020/api/v1/metrics &> /dev/null; then
    echo -e "${GREEN}✓ Fluent Bit está pronto${NC}"
else
    echo -e "${RED}❌ Fluent Bit ainda não respondendo${NC}"
fi

echo ""
echo -e "${GREEN}✅ Setup completo!${NC}"
echo ""
echo "Próximos passos:"
echo "1. Verificar indices: curl -sk -u admin:M1nhavid@ https://localhost:9200/_cat/indices"
echo "2. Ver logs: docker compose logs -f fluent-bit"
echo "3. Parar: docker compose down"
