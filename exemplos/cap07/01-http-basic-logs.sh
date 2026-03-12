#!/bin/bash

# EXEMPLO 1: HTTP Básico - Ingestão simples de logs JSON
# Descrição: Enviar logs JSON simples via HTTP para Data Prepper
# Pipeline: log-ingestion-pipeline
# Endpoint: POST http://localhost:21000/log/ingest

set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EXEMPLO 1: HTTP Básico - Logs JSON${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 1. Verificar se Data Prepper está rodando
echo -e "${YELLOW}1. Verificando saúde do Data Prepper...${NC}"
if ! curl -s http://localhost:21000/health > /dev/null 2>&1; then
    echo "❌ Data Prepper não está respondendo em http://localhost:21000"
    echo "Inicie com: docker-compose -f docker-compose-data-prepper.yml up -d"
    exit 1
fi
echo -e "${GREEN}✅ Data Prepper está rodando${NC}\n"

# 2. Verificar OpenSearch
echo -e "${YELLOW}2. Verificando OpenSearch...${NC}"
if ! curl -s -u admin:Admin#123456 https://localhost:9200/_cluster/health -k > /dev/null 2>&1; then
    echo "❌ OpenSearch não está respondendo"
    exit 1
fi
echo -e "${GREEN}✅ OpenSearch está rodando${NC}\n"

# 3. Enviar logs HTTP
echo -e "${YELLOW}3. Enviando logs JSON via HTTP...${NC}"

LOGS_JSON='[
  {
    "message": "Application started successfully",
    "level": "INFO",
    "service": "api-server",
    "component": "bootstrap"
  },
  {
    "message": "Database connection established",
    "level": "INFO",
    "service": "api-server",
    "component": "db-init"
  },
  {
    "message": "Cache warmed up",
    "level": "INFO",
    "service": "api-server",
    "component": "cache"
  },
  {
    "message": "Server listening on port 8080",
    "level": "INFO",
    "service": "api-server",
    "component": "network"
  }
]'

# Enviar para Data Prepper
RESPONSE=$(curl -s -X POST http://localhost:21000/log/ingest \
  -H "Content-Type: application/json" \
  -d "$LOGS_JSON" \
  -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
    echo -e "${GREEN}✅ Logs enviados com sucesso (HTTP $HTTP_CODE)${NC}\n"
else
    echo -e "${YELLOW}⚠️ Response HTTP: $HTTP_CODE${NC}"
fi

# 4. Aguardar processamento
echo -e "${YELLOW}4. Aguardando processamento (3 segundos)...${NC}"
sleep 3
echo -e "${GREEN}✅ Processamento completo${NC}\n"

# 5. Verificar dados no OpenSearch
echo -e "${YELLOW}5. Consultando dados no OpenSearch...${NC}"

INDEX_PATTERN="logs-app-*"

# Verificar se índice existe
INDEX_COUNT=$(curl -s -u admin:Admin#123456 https://localhost:9200/$INDEX_PATTERN/_count -k 2>/dev/null | jq '.count' 2>/dev/null || echo "0")

if [ "$INDEX_COUNT" = "0" ] || [ "$INDEX_COUNT" = "" ]; then
    echo -e "${YELLOW}⚠️ Nenhum documento encontrado ainda.${NC}"
    echo "   Aguarde um pouco mais ou verifique:"
    echo "   - Logs do Data Prepper: docker logs data-prepper"
    echo "   - Logs do OpenSearch: docker logs opensearch"
else
    echo -e "${GREEN}✅ Encontrados $INDEX_COUNT documentos em $INDEX_PATTERN${NC}\n"

    echo -e "${YELLOW}Primeiros 2 documentos:${NC}"
    curl -s -u admin:Admin#123456 "https://localhost:9200/$INDEX_PATTERN/_search?size=2" \
      -H "Content-Type: application/json" -k | jq '.hits.hits[] | {
        "_id": ._id,
        "_source": ._source
      }' | head -50
fi

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Exemplo 1 Completo!${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Dicas finais
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Executar Exemplo 2: bash exemplo/cap07/02-apache-logs.sh"
echo "2. Verificar índices: curl -s -u admin:admin https://localhost:9200/_cat/indices -k"
echo "3. Buscar todos dados: curl -s -u admin:admin https://localhost:9200/logs-app-*/_search -k | jq"
