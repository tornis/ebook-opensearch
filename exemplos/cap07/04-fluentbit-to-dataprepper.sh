#!/bin/bash

# EXEMPLO 4: Fluent Bit → Data Prepper → OpenSearch
# Descrição: Integração completa com coleta de logs do Docker
# Fluent Bit coleta logs e encaminha para Data Prepper via HTTP
# Data Prepper processa e armazena no OpenSearch

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EXEMPLO 4: Fluent Bit + Data Prepper${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Verificações iniciais
echo -e "${YELLOW}1. Verificando serviços...${NC}"

# Data Prepper
if ! curl -s http://localhost:21000/health > /dev/null 2>&1; then
    echo -e "${RED}❌ Data Prepper não disponível${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Data Prepper OK${NC}"

# OpenSearch
if ! curl -s -u admin:admin https://localhost:9200/_cluster/health -k > /dev/null 2>&1; then
    echo -e "${RED}❌ OpenSearch não disponível${NC}"
    exit 1
fi
echo -e "${GREEN}✅ OpenSearch OK${NC}\n"

# Criar diretórios para Fluent Bit
echo -e "${YELLOW}2. Preparando configuração do Fluent Bit...${NC}"

FLUENT_BIT_CONFIG="/tmp/fluent-bit.conf"
FLUENT_BIT_PARSERS="/tmp/parsers.conf"

# Criar arquivo de configuração do Fluent Bit
cat > "$FLUENT_BIT_CONFIG" << 'EOF'
[SERVICE]
    Flush         5
    Daemon        off
    Log_Level     info

# INPUT: Coletar logs do Docker
[INPUT]
    Name              docker
    Tag               docker.*
    Path              /var/run/docker.sock
    Parser            docker
    DB                /var/log/fluent-bit-docker.db
    DB.locking        true

# FILTER: Adicionar metadata
[FILTER]
    Name    modify
    Match   docker.*
    Add     environment prod
    Add     source fluent-bit

# OUTPUT: Enviar para Data Prepper
[OUTPUT]
    Name   http
    Match  docker.*
    Host   localhost
    Port   21000
    URI    /log/ingest
    Format json_lines
    Header User-Agent Fluent-Bit
    Header X-Source fluent-bit-docker
    json_date_key timestamp
    json_date_format iso8601
EOF

# Criar arquivo de parsers
cat > "$FLUENT_BIT_PARSERS" << 'EOF'
[PARSER]
    Name   docker
    Format json
    Time_Key time
    Time_Format %Y-%m-%dT%H:%M:%S.%L%z
    Time_Keep On
EOF

echo -e "${GREEN}✅ Configuração criada${NC}\n"

# Iniciar Fluent Bit em um container
echo -e "${YELLOW}3. Iniciando Fluent Bit...${NC}"

# Verificar se o container já existe
if docker ps -a --format '{{.Names}}' | grep -q '^fluent-bit-example$'; then
    echo "Removendo container antigo..."
    docker rm -f fluent-bit-example > /dev/null 2>&1
fi

# Iniciar Fluent Bit
docker run -d \
    --name fluent-bit-example \
    --network host \
    -v "$FLUENT_BIT_CONFIG":/fluent-bit/etc/fluent-bit.conf:ro \
    -v "$FLUENT_BIT_PARSERS":/fluent-bit/etc/parsers.conf:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    fluent/fluent-bit:3.0 \
    /fluent-bit/bin/fluent-bit -c /fluent-bit/etc/fluent-bit.conf \
    > /dev/null 2>&1

sleep 2

if docker ps --format '{{.Names}}' | grep -q '^fluent-bit-example$'; then
    echo -e "${GREEN}✅ Fluent Bit iniciado${NC}\n"
else
    echo -e "${RED}❌ Falha ao iniciar Fluent Bit${NC}"
    exit 1
fi

# Gerar logs de teste
echo -e "${YELLOW}4. Gerando logs de teste em container...${NC}"

# Criar e executar um container que gera logs
docker run -d \
    --name test-logger \
    --rm \
    busybox \
    sh -c 'for i in {1..10}; do echo "Test log entry $i - $(date +%s)"; sleep 1; done' \
    > /dev/null 2>&1

echo -e "${GREEN}✅ Container de teste iniciado${NC}"
echo "   Gerando 10 logs com intervalo de 1 segundo...\n"

# Aguardar coleta de logs
echo -e "${YELLOW}5. Aguardando coleta e processamento (15 segundos)...${NC}"
sleep 15
echo -e "${GREEN}✅ Coleta completa${NC}\n"

# Consultar dados no OpenSearch
echo -e "${YELLOW}6. Consultando dados coletados...${NC}"

INDEX_PATTERN="logs-app-*"
COUNT=$(curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_count" -k 2>/dev/null | jq '.count' 2>/dev/null || echo "0")

echo -e "${GREEN}✅ Encontrados $COUNT documentos coletados via Fluent Bit${NC}\n"

if [ "$COUNT" -gt "0" ]; then
    echo -e "${YELLOW}Últimos 3 documentos coletados:${NC}"
    curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_search?size=3&sort=@timestamp:desc" \
      -H "Content-Type: application/json" -k | jq '.hits.hits[] | {
        "timestamp": ._source."@timestamp",
        "source": ._source.source,
        "environment": ._source.environment,
        "message_preview": (._source.message // ._source.log // "")[:50],
        "container": (._source.container_id // "N/A")[:12]
      }' | head -50
fi

# Limpar containers de teste
echo -e "\n${YELLOW}7. Limpando containers de teste...${NC}"

docker stop fluent-bit-example > /dev/null 2>&1 || true
docker rm fluent-bit-example > /dev/null 2>&1 || true
docker stop test-logger > /dev/null 2>&1 || true

echo -e "${GREEN}✅ Limpeza completa${NC}\n"

# Estatísticas finais
echo -e "${YELLOW}8. Estatísticas da coleta${NC}"

# Contar logs por source
echo -e "${YELLOW}Distribuição por source:${NC}"
curl -s -u admin:admin "https://localhost:9200/$INDEX_PATTERN/_search?size=0" \
  -H "Content-Type: application/json" \
  -d '{
    "aggs": {
      "by_source": {
        "terms": {
          "field": "source.keyword",
          "size": 10
        }
      }
    }
  }' -k 2>/dev/null | jq '.aggregations.by_source.buckets[] | {
    "source": .key,
    "count": .doc_count
  }' || echo "Aguarde um pouco mais para processamento..."

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Exemplo 4 Completo!${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}Pipeline demonstrado:${NC}"
echo "Docker Container → Fluent Bit → Data Prepper → OpenSearch"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Ver todos os índices: curl -s -u admin:admin https://localhost:9200/_cat/indices -k"
echo "2. Buscar logs: curl -s -u admin:admin https://localhost:9200/logs-app-*/_search -k | jq"
echo "3. Executar exercício: bash exercicios/cap07/exercicio-completo.sh"
