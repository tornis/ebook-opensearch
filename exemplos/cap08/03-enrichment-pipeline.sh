#!/bin/bash

# Script: 03-enrichment-pipeline.sh
# Descrição: Pipeline que enriquece documentos com lógica condicional
# Conceitos: múltiplas condições, campos derivados, normalização

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Exemplo 3: Enriquecimento Condicional${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"

# Criar pipeline
echo -e "${YELLOW}1. Criando pipeline 'enriquecimento-inteligente'...${NC}"
curl -sk -X PUT -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/enriquecimento-inteligente \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Pipeline que enriquece logs com severidade normalizada e alertas",
    "processors": [
      {
        "set": {
          "field": "severidade_numerica",
          "value": 10,
          "if": "ctx.level == '\''DEBUG'\''"
        }
      },
      {
        "set": {
          "field": "severidade_numerica",
          "value": 20,
          "if": "ctx.level == '\''INFO'\''"
        }
      },
      {
        "set": {
          "field": "severidade_numerica",
          "value": 30,
          "if": "ctx.level == '\''WARN'\''"
        }
      },
      {
        "set": {
          "field": "severidade_numerica",
          "value": 40,
          "if": "ctx.level == '\''ERROR'\''"
        }
      },
      {
        "set": {
          "field": "severidade_numerica",
          "value": 50,
          "if": "ctx.level == '\''FATAL'\''"
        }
      },
      {
        "set": {
          "field": "eh_critico",
          "value": true,
          "if": "ctx.severidade_numerica >= 40"
        }
      },
      {
        "set": {
          "field": "eh_critico",
          "value": false,
          "if": "ctx.severidade_numerica < 40"
        }
      },
      {
        "set": {
          "field": "alerta_slack",
          "value": ":rotating_light: ERRO em {{ servico }}: {{ mensagem }}",
          "if": "ctx.eh_critico"
        }
      },
      {
        "set": {
          "field": "indice_destino",
          "value": "logs-criticos",
          "if": "ctx.eh_critico"
        }
      },
      {
        "set": {
          "field": "indice_destino",
          "value": "logs-normais",
          "if": "!ctx.eh_critico"
        }
      }
    ]
  }' | jq .
echo -e "${GREEN}✅ Pipeline criado${NC}\n"

# Indexar logs de exemplo
echo -e "${YELLOW}2. Indexando logs para enriquecimento...${NC}"

LOGS=(
  '{"level":"DEBUG","servico":"cache","mensagem":"Cache lookup performance","duracao_ms":5}'
  '{"level":"INFO","servico":"api-server","mensagem":"Requisição processada","duracao_ms":145}'
  '{"level":"WARN","servico":"database","mensagem":"Conexão lenta detectada","duracao_ms":2500}'
  '{"level":"ERROR","servico":"queue","mensagem":"Falha ao processar mensagem","duracao_ms":0}'
  '{"level":"FATAL","servico":"api-server","mensagem":"Serviço indisponível","duracao_ms":0}'
)

for i in "${!LOGS[@]}"; do
    curl -sk -X POST -u admin:Admin@123456 \
      https://localhost:9200/logs-enriched/_doc?pipeline=enriquecimento-inteligente \
      -H "Content-Type: application/json" \
      -d "${LOGS[$i]}" > /dev/null 2>&1
    echo -ne "\r  Indexados: $((i+1))/${#LOGS[@]}"
done
echo -e "\n${GREEN}✅ Logs indexados${NC}\n"

# Aguardar indexação
sleep 2

# Analisar logs enriquecidos
echo -e "${YELLOW}3. Analisando logs enriquecidos...${NC}\n"

curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-enriched/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": { "match_all": {} },
    "size": 10
  }' | jq '.hits.hits[] | ._source | {
    level,
    servico,
    mensagem,
    severidade_numerica,
    eh_critico,
    alerta_slack,
    indice_destino
  }'

echo ""

# Contar por severidade
echo -e "${YELLOW}4. Distribuição por severidade...${NC}\n"
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-enriched/_search \
  -H "Content-Type: application/json" \
  -d '{
    "size": 0,
    "aggs": {
      "por_severidade": {
        "terms": {
          "field": "level",
          "size": 10
        }
      },
      "criticos_vs_normais": {
        "terms": {
          "field": "eh_critico",
          "size": 2
        }
      }
    }
  }' | jq '
    "Severidade (nome):
    " + (.aggregations.por_severidade.buckets | map("  \(.key): \(.doc_count)") | join("\n")) +
    "

    Crítico vs Normal:
    " + (.aggregations.criticos_vs_normais.buckets | map("  \(if .key == 1 then \"CRÍTICO\" else \"NORMAL\" end): \(.doc_count)") | join("\n"))
  '

echo ""

# Alertas gerados
echo -e "${YELLOW}5. Alertas que seriam disparados...${NC}\n"
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-enriched/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": { "term": { "eh_critico": true } },
    "size": 10,
    "_source": ["alerta_slack", "servico", "mensagem", "level"]
  }' | jq '.hits.hits[] | {
    alerta: ._source.alerta_slack,
    servico: ._source.servico,
    mensagem: ._source.mensagem,
    nivel: ._source.level
  }'

echo ""

# Análise
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Análise:${NC}"
echo ""
echo "1. Níveis de log foram mapeados para valores numéricos"
echo "2. Lógica condicional identificou eventos críticos"
echo "3. Campos derivados foram criados para roteamento"
echo "4. Mensagens de alerta foram geradas automaticamente"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "- Executar: bash 04-complex-pipeline.sh"
echo "- Consultar: curl -s https://localhost:9200/logs-enriched/_search | jq"
echo ""
