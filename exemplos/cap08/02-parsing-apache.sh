#!/bin/bash

# Script: 02-parsing-apache.sh
# Descrição: Pipeline para parsing de Apache Combined Log Format com Grok
# Conceitos: grok, date processor, conditional logic

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Exemplo 2: Parsing Apache Logs com Grok${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"

# Criar pipeline
echo -e "${YELLOW}1. Criando pipeline 'parse-apache-logs'...${NC}"
curl -sk -X PUT -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/parse-apache-logs \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Parsing de Apache Combined Log Format",
    "processors": [
      {
        "grok": {
          "field": "message",
          "patterns": [
            "%{IPORHOST:client_ip} %{HTTPDUSER:ident} %{HTTPDUSER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:metodo} %{DATA:recurso} HTTP/%{NUMBER:versao_http}\" %{NUMBER:status_code:int} (?:%{NUMBER:bytes:int}|-) \"%{DATA:referrer}\" \"%{GREEDYDATA:user_agent}\""
          ],
          "on_failure": [
            {
              "set": {
                "field": "parse_error",
                "value": true
              }
            }
          ]
        }
      },
      {
        "date": {
          "field": "timestamp",
          "target_field": "@timestamp",
          "formats": ["dd/MMM/yyyy:HH:mm:ss Z"]
        }
      },
      {
        "set": {
          "field": "categoria_erro",
          "value": "cliente",
          "if": "ctx.status_code >= 400 && ctx.status_code < 500"
        }
      },
      {
        "set": {
          "field": "categoria_erro",
          "value": "servidor",
          "if": "ctx.status_code >= 500"
        }
      },
      {
        "set": {
          "field": "categoria_erro",
          "value": "sucesso",
          "if": "ctx.status_code >= 200 && ctx.status_code < 300"
        }
      },
      {
        "remove": {
          "field": ["timestamp", "ident", "auth", "referrer"]
        }
      }
    ],
    "on_failure": [
      {
        "set": {
          "field": "erro_pipeline",
          "value": "{{ _ingest.on_failure_message }}"
        }
      }
    ]
  }' | jq .
echo -e "${GREEN}✅ Pipeline criado${NC}\n"

# Indexar logs de exemplo
echo -e "${YELLOW}2. Indexando logs Apache...${NC}"

LOGS=(
  "192.168.1.100 - - [10/Mar/2025:14:32:45 +0000] \"GET /api/users HTTP/1.1\" 200 1234 \"-\" \"Mozilla/5.0\""
  "192.168.1.101 - - [10/Mar/2025:14:32:46 +0000] \"POST /api/users HTTP/1.1\" 201 5678 \"-\" \"Chrome/100\""
  "192.168.1.102 - - [10/Mar/2025:14:32:47 +0000] \"GET /api/invalid HTTP/1.1\" 404 0 \"-\" \"Firefox/95\""
  "192.168.1.103 - - [10/Mar/2025:14:32:48 +0000] \"DELETE /api/users/1 HTTP/1.1\" 500 0 \"-\" \"Safari/15\""
)

for i in "${!LOGS[@]}"; do
    curl -sk -X POST -u admin:Admin@123456 \
      https://localhost:9200/apache-logs/_doc?pipeline=parse-apache-logs \
      -H "Content-Type: application/json" \
      -d "{\"message\": \"${LOGS[$i]}\"}" > /dev/null 2>&1
    echo -ne "\r  Indexados: $((i+1))/${#LOGS[@]}"
done
echo -e "\n${GREEN}✅ Logs indexados${NC}\n"

# Aguardar indexação
sleep 2

# Buscar e analisar
echo -e "${YELLOW}3. Analisando logs processados...${NC}\n"

curl -sk -u admin:Admin@123456 \
  https://localhost:9200/apache-logs/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": { "match_all": {} },
    "size": 10,
    "sort": [{ "@timestamp": { "order": "asc" } }]
  }' | jq '.hits.hits[] | {
    ip: ._source.client_ip,
    metodo: ._source.metodo,
    recurso: ._source.recurso,
    status: ._source.status_code,
    categoria: ._source.categoria_erro,
    bytes: ._source.bytes,
    user_agent: ._source.user_agent,
    timestamp: ._source."@timestamp"
  }' | jq -s 'sort_by(.status)'

echo ""

# Estatísticas
echo -e "${YELLOW}4. Estatísticas por status...${NC}\n"
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/apache-logs/_search \
  -H "Content-Type: application/json" \
  -d '{
    "size": 0,
    "aggs": {
      "por_status": {
        "terms": {
          "field": "status_code",
          "size": 10
        }
      },
      "por_categoria": {
        "terms": {
          "field": "categoria_erro",
          "size": 10
        }
      }
    }
  }' | jq '
    "Status codes:
    " + (.aggregations.por_status.buckets | map("  \(.key): \(.doc_count)") | join("\n")) +
    "
    Categorias:
    " + (.aggregations.por_categoria.buckets | map("  \(.key): \(.doc_count)") | join("\n"))
  '

echo ""

# Análise
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Análise:${NC}"
echo ""
echo "1. Padrão Grok extraiu: IP, método, recurso, status_code, bytes, user_agent"
echo "2. Timestamp Apache foi normalizado para @timestamp ISO8601"
echo "3. Lógica condicional classificou erros em categorias"
echo "4. Campos temporários foram removidos"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "- Executar: bash 03-enrichment-pipeline.sh"
echo "- Buscar logs: curl -s https://localhost:9200/apache-logs/_search | jq"
echo ""
