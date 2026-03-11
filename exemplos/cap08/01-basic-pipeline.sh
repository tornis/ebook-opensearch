#!/bin/bash

# Script: 01-basic-pipeline.sh
# Descrição: Demonstra um pipeline básico com transformações simples
# Conceitos: set, convert, templating

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Exemplo 1: Pipeline Básico com Transformação${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"

# Verificar OpenSearch
echo -e "${YELLOW}1. Verificando OpenSearch...${NC}"
if ! curl -sk -u admin:Admin@123456 https://localhost:9200/_cluster/health > /dev/null 2>&1; then
    echo -e "${RED}❌ OpenSearch não está respondendo${NC}"
    exit 1
fi
echo -e "${GREEN}✅ OpenSearch operacional${NC}\n"

# Criar pipeline
echo -e "${YELLOW}2. Criando pipeline 'transformacao-basica'...${NC}"
curl -sk -X PUT -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/transformacao-basica \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Pipeline básico que adiciona campos e converte tipos",
    "processors": [
      {
        "set": {
          "field": "data_ingestao",
          "value": "{{ _ingest.timestamp }}"
        }
      },
      {
        "convert": {
          "field": "duracao_ms",
          "type": "integer",
          "on_failure": [
            {
              "set": {
                "field": "duracao_ms",
                "value": 0
              }
            }
          ]
        }
      },
      {
        "set": {
          "field": "processado",
          "value": true
        }
      }
    ]
  }' | jq .
echo -e "${GREEN}✅ Pipeline criado${NC}\n"

# Indexar documento com pipeline
echo -e "${YELLOW}3. Indexando documento com pipeline...${NC}"

RESPONSE=$(curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/pipelines-demo/_doc?pipeline=transformacao-basica \
  -H "Content-Type: application/json" \
  -d '{
    "tipo": "requisicao",
    "duracao_ms": "2500",
    "usuario": "alice",
    "endpoint": "/api/users"
  }' | jq .)

echo -e "${GREEN}✅ Documento indexado${NC}"
echo "$RESPONSE" | jq .
echo ""

# Aguardar indexação
sleep 1

# Recuperar documento
echo -e "${YELLOW}4. Recuperando documento indexado...${NC}"
DOCUMENTO=$(curl -sk -u admin:Admin@123456 \
  https://localhost:9200/pipelines-demo/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": { "match_all": {} },
    "size": 1
  }' | jq '.hits.hits[0]._source')

echo -e "${GREEN}✅ Documento recuperado${NC}"
echo "$DOCUMENTO" | jq .
echo ""

# Análise
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Análise:${NC}"
echo ""
echo "1. Campo 'duracao_ms' foi convertido de string para integer"
echo "2. Campo 'data_ingestao' foi adicionado com timestamp"
echo "3. Campo 'processado' foi marcado como true"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "- Executar: bash 02-parsing-apache.sh"
echo "- Ou consultar o índice: curl -s https://localhost:9200/pipelines-demo/_search | jq"
echo ""
