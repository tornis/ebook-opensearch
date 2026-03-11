#!/bin/bash

# Script: 05-simulate-test.sh
# Descrição: Testa pipelines usando _simulate antes de usar em produção
# Conceitos: teste sem indexação, análise de transformações, tratamento de erro

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Exemplo 5: Simulação e Testes de Pipelines${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"

# Listar pipelines
echo -e "${YELLOW}1. Pipelines disponíveis...${NC}\n"
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline \
  -H "Content-Type: application/json" | jq 'to_entries[] | {
    pipeline: .key,
    descricao: .value.description,
    processadores: (.value.processors | length)
  }'

echo ""

# Testar pipeline básico
echo -e "${YELLOW}2. Testando 'transformacao-basica' com simulação...${NC}\n"

echo "Teste 1: Documento com tipos corretos"
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/transformacao-basica/_simulate \
  -H "Content-Type: application/json" \
  -d '{
    "docs": [
      {
        "_source": {
          "tipo": "requisicao",
          "duracao_ms": "2500",
          "usuario": "alice"
        }
      }
    ]
  }' | jq '.docs[0].doc._source'

echo ""
echo "Teste 2: Documento com duracao_ms inválido"
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/transformacao-basica/_simulate \
  -H "Content-Type: application/json" \
  -d '{
    "docs": [
      {
        "_source": {
          "tipo": "requisicao",
          "duracao_ms": "nao-eh-numero",
          "usuario": "bob"
        }
      }
    ]
  }' | jq '.docs[0].doc._source'

echo ""

# Testar pipeline Apache
echo -e "${YELLOW}3. Testando 'parse-apache-logs' com simulação...${NC}\n"

echo "Teste 1: Log Apache válido"
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/parse-apache-logs/_simulate \
  -H "Content-Type: application/json" \
  -d '{
    "docs": [
      {
        "_source": {
          "message": "192.168.1.100 - - [10/Mar/2025:14:32:45 +0000] \"GET /api/users HTTP/1.1\" 200 1234 \"-\" \"Mozilla/5.0\""
        }
      }
    ]
  }' | jq '.docs[0].doc._source | {
    client_ip,
    metodo,
    recurso,
    status_code,
    categoria_erro,
    "@timestamp"
  }'

echo ""
echo "Teste 2: Log Apache com status 500"
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/parse-apache-logs/_simulate \
  -H "Content-Type: application/json" \
  -d '{
    "docs": [
      {
        "_source": {
          "message": "192.168.1.200 - - [10/Mar/2025:15:00:00 +0000] \"POST /api/data HTTP/1.1\" 500 0 \"-\" \"curl/7.68\""
        }
      }
    ]
  }' | jq '.docs[0].doc._source | {
    client_ip,
    metodo,
    status_code,
    categoria_erro
  }'

echo ""
echo "Teste 3: Log malformado (tratamento de erro)"
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/parse-apache-logs/_simulate \
  -H "Content-Type: application/json" \
  -d '{
    "docs": [
      {
        "_source": {
          "message": "LOG COMPLETAMENTE INVÁLIDO"
        }
      }
    ]
  }' | jq '.docs[0].doc._source | {
    message,
    parse_error
  }'

echo ""

# Testar pipeline de enriquecimento
echo -e "${YELLOW}4. Testando 'enriquecimento-inteligente' com simulação...${NC}\n"

echo "Teste 1: Log DEBUG (menor severidade)"
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/enriquecimento-inteligente/_simulate \
  -H "Content-Type: application/json" \
  -d '{
    "docs": [
      {
        "_source": {
          "level": "DEBUG",
          "servico": "cache",
          "mensagem": "Cache hit para chave user:123"
        }
      }
    ]
  }' | jq '.docs[0].doc._source | {
    level,
    severidade_numerica,
    eh_critico,
    alerta_slack,
    indice_destino
  }'

echo ""
echo "Teste 2: Log ERROR (crítico)"
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/enriquecimento-inteligente/_simulate \
  -H "Content-Type: application/json" \
  -d '{
    "docs": [
      {
        "_source": {
          "level": "ERROR",
          "servico": "database",
          "mensagem": "Falha na conexão com timeout"
        }
      }
    ]
  }' | jq '.docs[0].doc._source | {
    level,
    severidade_numerica,
    eh_critico,
    alerta_slack,
    indice_destino
  }'

echo ""

# Testar pipeline complexo
echo -e "${YELLOW}5. Testando 'processamento-completo' com simulação...${NC}\n"

echo "Teste 1: Log válido com estrutura correta"
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/processamento-completo/_simulate \
  -H "Content-Type: application/json" \
  -d '{
    "docs": [
      {
        "_source": {
          "raw_log": "2025-03-10 14:30:45 [INFO] api-server - Requisição processada:145"
        }
      }
    ]
  }' | jq '.docs[0].doc._source | {
    nivel,
    servico,
    mensagem,
    duracao_ms,
    duracao_segundos,
    pipeline_version,
    processamento_falhou
  }'

echo ""
echo "Teste 2: Log inválido (tratamento de erro)"
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/processamento-completo/_simulate \
  -H "Content-Type: application/json" \
  -d '{
    "docs": [
      {
        "_source": {
          "raw_log": "ESTRUTURA INVÁLIDA SEM CAMPOS"
        }
      }
    ]
  }' | jq '.docs[0].doc._source | {
    raw_log,
    processamento_falhou,
    erro_detalhes
  }'

echo ""

# Testar múltiplos documentos
echo -e "${YELLOW}6. Testando múltiplos documentos em um pipeline...${NC}\n"

curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/transformacao-basica/_simulate \
  -H "Content-Type: application/json" \
  -d '{
    "docs": [
      {
        "_source": {
          "tipo": "requisicao",
          "duracao_ms": "100",
          "usuario": "alice"
        }
      },
      {
        "_source": {
          "tipo": "requisicao",
          "duracao_ms": "5000",
          "usuario": "bob"
        }
      },
      {
        "_source": {
          "tipo": "requisicao",
          "duracao_ms": "250",
          "usuario": "charlie"
        }
      }
    ]
  }' | jq '.docs[] | .doc._source | {
    usuario,
    duracao_ms,
    processado
  }' | jq -s 'sort_by(.duracao_ms) | reverse'

echo ""

# Resumo
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Resumo de Testes:${NC}"
echo ""
echo "1. transformacao-basica: Converte tipos e adiciona campos ✅"
echo "2. parse-apache-logs: Extrai campos e classifica erros ✅"
echo "3. enriquecimento-inteligente: Normaliza severidade ✅"
echo "4. processamento-completo: Processa com tratamento de erro ✅"
echo ""
echo -e "${YELLOW}Boas práticas:${NC}"
echo "- Sempre teste com _simulate antes de usar em produção"
echo "- Teste casos de sucesso e erro"
echo "- Valide tratamento de tipos esperado"
echo "- Verifique campos derivados"
echo ""
