#!/bin/bash

# EXEMPLO 3: Logs Estruturados com Enriquecimento
# Descrição: Parse com normalização de severidade e campos derivados
# Pipeline: enriched-logs-pipeline
# Endpoint: POST http://localhost:21002/enriched/logs

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EXEMPLO 3: Logs Estruturados Enriquecidos${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Verificações
echo -e "${YELLOW}1. Verificando serviços...${NC}"
curl -s http://localhost:21000/health > /dev/null 2>&1 || { echo "❌ Data Prepper"; exit 1; }
echo -e "${GREEN}✅ Data Prepper OK${NC}"

curl -s -u admin:admin https://localhost:9200/_cluster/health -k > /dev/null 2>&1 || { echo "❌ OpenSearch"; exit 1; }
echo -e "${GREEN}✅ OpenSearch OK${NC}\n"

# Logs estruturados ISO8601
# Formato: "2025-01-15T10:30:45.123Z [LEVEL] [logger] - message"

echo -e "${YELLOW}2. Enviando logs estruturados enriquecidos...${NC}"

ENRICHED_LOGS='[
  {
    "message": "2025-01-15T10:30:45.123Z [INFO] [com.app.api.controller] - Request received from client 192.168.1.100",
    "request_id": "req-001",
    "user_id": "user-123"
  },
  {
    "message": "2025-01-15T10:30:46.456Z [DEBUG] [com.app.db.service] - Executing query SELECT * FROM users",
    "request_id": "req-001",
    "user_id": "user-123"
  },
  {
    "message": "2025-01-15T10:30:47.789Z [INFO] [com.app.db.service] - Query completed in 1234ms",
    "request_id": "req-001",
    "user_id": "user-123"
  },
  {
    "message": "2025-01-15T10:30:48.234Z [WARN] [com.app.cache] - Cache miss for key user:123",
    "request_id": "req-001",
    "user_id": "user-123"
  },
  {
    "message": "2025-01-15T10:30:49.567Z [INFO] [com.app.api.controller] - Response sent: 200 OK",
    "request_id": "req-001",
    "user_id": "user-123"
  },
  {
    "message": "2025-01-15T10:30:50.891Z [ERROR] [com.app.db.connection] - Database connection timeout after 5000ms",
    "request_id": "req-002",
    "user_id": "user-456"
  },
  {
    "message": "2025-01-15T10:30:51.234Z [ERROR] [com.app.db.connection] - Unable to recover connection, retrying...",
    "request_id": "req-002",
    "user_id": "user-456"
  },
  {
    "message": "2025-01-15T10:30:52.567Z [ERROR] [com.app.api.controller] - Request failed: DatabaseException",
    "request_id": "req-002",
    "user_id": "user-456"
  },
  {
    "message": "2025-01-15T10:30:53.891Z [INFO] [com.app.metrics] - Request duration: 3758ms",
    "request_id": "req-002",
    "user_id": "user-456"
  },
  {
    "message": "2025-01-15T10:30:54.234Z [WARN] [com.app.security] - Suspicious login attempt from IP 203.0.113.45",
    "request_id": "req-003",
    "user_id": null
  }
]'

# Enviar para Data Prepper na porta 21002
RESPONSE=$(curl -s -X POST http://localhost:21002/enriched/logs \
  -H "Content-Type: application/json" \
  -d "$ENRICHED_LOGS" \
  -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
    echo -e "${GREEN}✅ 10 logs estruturados enviados (HTTP $HTTP_CODE)${NC}\n"
else
    echo -e "${YELLOW}⚠️ HTTP $HTTP_CODE${NC}\n"
fi

# Aguardar processamento
echo -e "${YELLOW}3. Aguardando agregação...${NC}"
sleep 6
echo -e "${GREEN}✅ Processamento concluído${NC}\n"

# Consultar dados
echo -e "${YELLOW}4. Buscando dados processados...${NC}"

INDEX_PATTERN="app-logs-*"
COUNT=$(curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_count" -k 2>/dev/null | jq '.count' 2>/dev/null || echo "0")

echo -e "${GREEN}✅ Encontrados $COUNT documentos${NC}\n"

if [ "$COUNT" -gt "0" ]; then
    echo -e "${YELLOW}Documentos processados (mostrando 2):${NC}"
    curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_search?size=2" \
      -H "Content-Type: application/json" -k | jq '.hits.hits[] | {
        "_id": ._id,
        "logger": ._source.logger,
        "log_message": ._source.log_message,
        "severity_level": ._source.severity_level,
        "severity_numeric": ._source.severity_numeric,
        "is_error": ._source.is_error,
        "request_id": ._source.request_id,
        "user_id": ._source.user_id,
        "@timestamp": ._source."@timestamp"
      }' | head -80
fi

# Análise de severidade
echo -e "\n${YELLOW}5. Análise de Severidade${NC}"

echo -e "${YELLOW}Distribuição por nível:${NC}"
curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_search?size=0" \
  -H "Content-Type: application/json" \
  -d '{
    "aggs": {
      "severity_levels": {
        "terms": {
          "field": "severity_level.keyword",
          "size": 10
        }
      }
    }
  }' -k | jq '.aggregations.severity_levels.buckets[] | {
    "level": .key,
    "count": .doc_count
  }'

# Logs com erro
echo -e "\n${YELLOW}6. Filtrando apenas erros (is_error = true)${NC}"
curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match": {
        "is_error": true
      }
    },
    "size": 5
  }' -k | jq '.hits.hits[] | {
    "request_id": ._source.request_id,
    "level": ._source.severity_level,
    "message": ._source.log_message,
    "@timestamp": ._source."@timestamp"
  }'

# Top usuarios
echo -e "\n${YELLOW}7. Top usuários por logs gerados${NC}"
curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_search?size=0" \
  -H "Content-Type: application/json" \
  -d '{
    "aggs": {
      "top_users": {
        "terms": {
          "field": "user_id.keyword",
          "size": 10
        }
      }
    }
  }' -k | jq '.aggregations.top_users.buckets[] | {
    "user_id": .key,
    "log_count": .doc_count
  }'

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Exemplo 3 Completo!${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}Insights gerados:${NC}"
echo "- Campos normalizados: severity_level, severity_numeric"
echo "- Campos derivados: is_error, processing_timestamp"
echo "- Eventos agrupados por request_id"
echo "- Análise de distribuição de severidade"
echo "- Análise de erros isolados"
