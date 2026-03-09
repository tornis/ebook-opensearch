#!/bin/bash

# EXEMPLO 2: Apache Log Parsing com Grok
# Descrição: Parse de logs Apache em formato Common Log Format
# Pipeline: apache-logs-pipeline
# Endpoint: POST http://localhost:21001/apache/logs

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EXEMPLO 2: Apache Log Parsing com Grok${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Verificações iniciais
echo -e "${YELLOW}1. Verificando serviços...${NC}"
curl -s http://localhost:21000/health > /dev/null 2>&1 || {
    echo "❌ Data Prepper não disponível"; exit 1
}
echo -e "${GREEN}✅ Data Prepper OK${NC}"

curl -s -u admin:admin https://localhost:9200/_cluster/health -k > /dev/null 2>&1 || {
    echo "❌ OpenSearch não disponível"; exit 1
}
echo -e "${GREEN}✅ OpenSearch OK${NC}\n"

# Logs Apache em Common Log Format
# 192.168.1.1 - - [01/Jan/2025:12:00:00 +0000] "GET /index.html HTTP/1.1" 200 1234

echo -e "${YELLOW}2. Enviando logs Apache (Common Log Format)...${NC}"

# Array de logs Apache para teste
APACHE_LOGS='[
  {
    "message": "192.168.1.10 - frank [01/Jan/2025:12:00:00 +0000] \"GET /apache.html HTTP/1.0\" 200 2326"
  },
  {
    "message": "192.168.1.4 - - [01/Jan/2025:12:00:01 +0000] \"GET / HTTP/1.0\" 304 0"
  },
  {
    "message": "192.168.1.43 - - [01/Jan/2025:12:00:02 +0000] \"GET /icons/blank.gif HTTP/1.0\" 404 497"
  },
  {
    "message": "192.168.100.228 - - [01/Jan/2025:12:00:03 +0000] \"GET /cgi-bin/test.pl HTTP/1.0\" 200 3395"
  },
  {
    "message": "192.168.1.1 - - [01/Jan/2025:12:00:04 +0000] \"GET /style.css HTTP/1.1\" 200 1567"
  },
  {
    "message": "192.168.1.1 - user1 [01/Jan/2025:12:00:05 +0000] \"POST /api/login HTTP/1.1\" 401 256"
  },
  {
    "message": "203.0.113.45 - alice [01/Jan/2025:12:00:06 +0000] \"DELETE /api/users/123 HTTP/1.1\" 403 189"
  },
  {
    "message": "10.0.0.5 - - [01/Jan/2025:12:00:07 +0000] \"GET /download/file.zip HTTP/1.1\" 200 5242880"
  }
]'

# Enviar para Data Prepper na porta 21001
RESPONSE=$(curl -s -X POST http://localhost:21001/apache/logs \
  -H "Content-Type: application/json" \
  -d "$APACHE_LOGS" \
  -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
    echo -e "${GREEN}✅ 8 logs Apache enviados (HTTP $HTTP_CODE)${NC}\n"
else
    echo -e "${YELLOW}⚠️ HTTP $HTTP_CODE${NC}\n"
fi

# Aguardar processamento
echo -e "${YELLOW}3. Aguardando processamento...${NC}"
sleep 4
echo -e "${GREEN}✅ Processamento concluído${NC}\n"

# Consultar dados
echo -e "${YELLOW}4. Buscando dados processados no OpenSearch...${NC}"

INDEX_PATTERN="apache-logs-*"
COUNT=$(curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_count" -k 2>/dev/null | jq '.count' 2>/dev/null || echo "0")

echo -e "${GREEN}✅ Encontrados $COUNT documentos${NC}\n"

if [ "$COUNT" -gt "0" ]; then
    echo -e "${YELLOW}Documentos parseados (mostrando 3):${NC}"
    curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_search?size=3" \
      -H "Content-Type: application/json" -k | jq '.hits.hits[] | {
        "_id": ._id,
        "clientip": ._source.clientip,
        "auth": ._source.auth,
        "timestamp": ._source.timestamp,
        "verb": ._source.verb,
        "request": ._source.request,
        "httpversion": ._source.httpversion,
        "response": ._source.response,
        "bytes": ._source.bytes,
        "response_category": ._source.response_category,
        "@timestamp": ._source."@timestamp"
      }' | head -60
fi

# Estatísticas
echo -e "\n${YELLOW}5. Estatísticas dos logs (Agregação)${NC}"

# Contar por código de resposta
echo -e "${YELLOW}Distribuição por código HTTP:${NC}"
curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_search?size=0" \
  -H "Content-Type: application/json" \
  -d '{
    "aggs": {
      "by_status": {
        "terms": {
          "field": "response",
          "size": 10
        }
      }
    }
  }' -k | jq '.aggregations.by_status.buckets[] | {
    "http_code": .key,
    "count": .doc_count
  }'

# Contar por categoria
echo -e "\n${YELLOW}Distribuição por categoria de resposta:${NC}"
curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_search?size=0" \
  -H "Content-Type: application/json" \
  -d '{
    "aggs": {
      "by_category": {
        "terms": {
          "field": "response_category.keyword",
          "size": 10
        }
      }
    }
  }' -k | jq '.aggregations.by_category.buckets[] | {
    "category": .key,
    "count": .doc_count
  }'

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Exemplo 2 Completo!${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Executar Exemplo 3: bash exemplo/cap07/03-enriched-logs.sh"
echo "2. Analisar campos: curl -s -u admin:admin https://localhost:9200/$INDEX_PATTERN/_mapping -k | jq"
