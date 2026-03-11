#!/bin/bash

# Script: 04-complex-pipeline.sh
# Descrição: Pipeline complexo com múltiplas etapas, validação e tratamento de erros
# Conceitos: dissect, conversão de tipos, tratamento de erro global, limpeza

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Exemplo 4: Pipeline Complexo com Validação${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"

# Criar pipeline
echo -e "${YELLOW}1. Criando pipeline 'processamento-completo'...${NC}"
curl -sk -X PUT -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/processamento-completo \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Pipeline complexo com parsing, validação e enriquecimento",
    "processors": [
      {
        "dissect": {
          "field": "raw_log",
          "pattern": "%{data} %{hora} [%{nivel}] %{servico} - %{mensagem}",
          "on_failure": [
            {
              "set": {
                "field": "_parse_error",
                "value": "Dissect falhou"
              }
            }
          ]
        }
      },
      {
        "date": {
          "field": "data",
          "target_field": "log_date",
          "formats": ["yyyy-MM-dd"],
          "on_failure": [
            {
              "set": {
                "field": "_date_error",
                "value": true
              }
            }
          ]
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
          "field": "duracao_segundos",
          "value": "{{ duracao_ms / 1000.0 }}"
        }
      },
      {
        "set": {
          "field": "pipeline_version",
          "value": "1.0"
        }
      },
      {
        "set": {
          "field": "pipeline_timestamp",
          "value": "{{ _ingest.timestamp }}"
        }
      },
      {
        "remove": {
          "field": ["raw_log", "data", "hora", "_parse_error", "_date_error"]
        }
      }
    ],
    "on_failure": [
      {
        "set": {
          "field": "processamento_falhou",
          "value": true
        }
      },
      {
        "set": {
          "field": "erro_detalhes",
          "value": "{{ _ingest.on_failure_message }}"
        }
      },
      {
        "set": {
          "field": "falha_no_pipeline",
          "value": "{{ _ingest.pipeline }}"
        }
      }
    ]
  }' | jq .
echo -e "${GREEN}✅ Pipeline criado${NC}\n"

# Indexar logs com sucesso
echo -e "${YELLOW}2. Indexando logs válidos...${NC}"

VALID_LOGS=(
  "2025-03-10 14:30:45 [INFO] api-server - Requisição processada com sucesso:145"
  "2025-03-10 14:30:46 [ERROR] database - Timeout na conexão:5000"
  "2025-03-10 14:30:47 [WARN] cache - Cache hit ratio baixo:250"
  "2025-03-10 14:30:48 [DEBUG] queue - Processando item 100 de 500:50"
)

for i in "${!VALID_LOGS[@]}"; do
    curl -sk -X POST -u admin:Admin@123456 \
      https://localhost:9200/logs-processed/_doc?pipeline=processamento-completo \
      -H "Content-Type: application/json" \
      -d "{\"raw_log\": \"${VALID_LOGS[$i]}\"}" > /dev/null 2>&1
    echo -ne "\r  Indexados: $((i+1))/${#VALID_LOGS[@]}"
done
echo -e "\n${GREEN}✅ Logs válidos indexados${NC}\n"

# Indexar um log inválido (falta duração)
echo -e "${YELLOW}3. Indexando log com erro (tratamento de falha)...${NC}"
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/logs-processed/_doc?pipeline=processamento-completo \
  -H "Content-Type: application/json" \
  -d '{"raw_log": "LOG INVÁLIDO SEM ESTRUTURA"}' > /dev/null 2>&1
echo -e "${GREEN}✅ Log com erro foi processado (tratamento ativo)${NC}\n"

# Aguardar indexação
sleep 2

# Analisar logs processados com sucesso
echo -e "${YELLOW}4. Logs processados com sucesso...${NC}\n"

curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-processed/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": { "bool": { "must_not": { "exists": { "field": "processamento_falhou" } } } },
    "size": 10,
    "_source": ["nivel", "servico", "mensagem", "duracao_ms", "duracao_segundos", "pipeline_version"]
  }' | jq '.hits.hits[] | {
    nivel: ._source.nivel,
    servico: ._source.servico,
    mensagem: ._source.mensagem,
    duracao_ms: ._source.duracao_ms,
    duracao_segundos: ._source.duracao_segundos
  }'

echo ""

# Analisar log com erro
echo -e "${YELLOW}5. Log que teve erro no processamento...${NC}\n"

curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-processed/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": { "exists": { "field": "processamento_falhou" } },
    "size": 10,
    "_source": ["processamento_falhou", "erro_detalhes", "raw_log"]
  }' | jq '.hits.hits[] | {
    processamento_falhou: ._source.processamento_falhou,
    erro: ._source.erro_detalhes,
    raw_log: ._source.raw_log
  }'

echo ""

# Estatísticas
echo -e "${YELLOW}6. Estatísticas de processamento...${NC}\n"

TOTAL=$(curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-processed/_count \
  -H "Content-Type: application/json" | jq '.count')

SUCESSO=$(curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-processed/_count \
  -H "Content-Type: application/json" \
  -d '{"query": {"bool": {"must_not": {"exists": {"field": "processamento_falhou"}}}}}' | jq '.count')

ERRO=$((TOTAL - SUCESSO))

echo "Total de documentos: $TOTAL"
echo "Processados com sucesso: $SUCESSO"
echo "Com erro: $ERRO"
echo ""

# Análise
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Análise:${NC}"
echo ""
echo "1. Pipeline processou múltiplas etapas em sequência"
echo "2. Conversões de tipo foram validadas com fallback"
echo "3. Campos derivados foram calculados (duracao_segundos)"
echo "4. Campos temporários foram removidos"
echo "5. Erros globais foram capturados no on_failure"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "- Executar: bash 05-simulate-test.sh"
echo "- Consultar detalhes: curl -s https://localhost:9200/logs-processed/_search | jq"
echo ""
