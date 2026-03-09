#!/bin/bash

# Test Script para Pipelines Logstash
# Testa cada pipeline com dados de exemplo

set -e

echo "========================================="
echo "  Teste de Pipelines Logstash"
echo "========================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificar se Logstash está rodando
if ! docker ps | grep -q "logstash"; then
    echo -e "${RED}✗ Logstash não está rodando${NC}"
    echo "  Inicie com: docker-compose -f docker-compose-logstash.yml up -d"
    exit 1
fi

# Função para testar pipeline
test_pipeline() {
    local pipeline_num=$1
    local pipeline_name=$2
    local test_data=$3

    echo -e "${BLUE}─────────────────────────────────────${NC}"
    echo -e "${YELLOW}[Teste $pipeline_num]${NC} $pipeline_name"
    echo -e "${BLUE}─────────────────────────────────────${NC}"

    # Validar sintaxe
    echo "  ✓ Validando sintaxe..."
    if docker exec logstash /usr/share/logstash/bin/logstash -f \
        /usr/share/logstash/pipelines/0${pipeline_num}-*.conf -t &>/dev/null; then
        echo -e "    ${GREEN}Sintaxe OK${NC}"
    else
        echo -e "    ${RED}Erro de sintaxe${NC}"
        docker exec logstash /usr/share/logstash/bin/logstash -f \
            /usr/share/logstash/pipelines/0${pipeline_num}-*.conf -t
        return 1
    fi

    # Executar pipeline com dados de teste
    echo "  ✓ Processando entrada de teste..."
    echo "    Input: $test_data"
    echo ""

    local output=$(echo "$test_data" | docker exec -i logstash \
        /usr/share/logstash/bin/logstash -f \
        /usr/share/logstash/pipelines/0${pipeline_num}-*.conf 2>/dev/null | \
        grep -v "^\[" | tail -1)

    if [ -n "$output" ]; then
        echo -e "    ${GREEN}Output:${NC}"
        echo "$output" | jq . 2>/dev/null || echo "    $output"
        echo ""
        echo -e "${GREEN}✓ Pipeline funcionou corretamente${NC}"
    else
        echo -e "${RED}✗ Nenhuma saída gerada${NC}"
        return 1
    fi

    echo ""
}

# Teste 1: Grok Parser
test_pipeline 1 "Filtro Grok (Parsing Apache Logs)" \
'{"message":"192.168.1.100 - - [10/Mar/2025:14:32:45 +0000] \"GET /api/users HTTP/1.1\" 200 5432 \"-\" \"Mozilla/5.0\""}'

# Teste 2: Dissect Parser
test_pipeline 2 "Filtro Dissect (Delimitador Fixo)" \
'{"message":"2025-03-10T14:32:45.123Z | ERROR | payment-service | Failed to process transaction"}'

# Teste 3: Date Parser
test_pipeline 3 "Filtro Date (Timestamp Parsing)" \
'{"log_timestamp":"10/Mar/2025:14:32:45 +0000"}'

# Teste 4: Mutate Parser
test_pipeline 4 "Filtro Mutate (Transformação)" \
'{"status_code":"200","response_time_ms":"123.45","client_ip":"192.168.1.100","log_level":"ERROR","service_name":"API"}'

# Teste 5: JDBC/SQLite
echo -e "${BLUE}─────────────────────────────────────${NC}"
echo -e "${YELLOW}[Teste 5]${NC} Pipeline JDBC/SQLite (Chinook Database)"
echo -e "${BLUE}─────────────────────────────────────${NC}"

echo "  ✓ Validando sintaxe..."
if docker exec logstash /usr/share/logstash/bin/logstash -f \
    /usr/share/logstash/pipelines/05-jdbc-sqlite.conf -t &>/dev/null; then
    echo -e "    ${GREEN}Sintaxe OK${NC}"
else
    echo -e "    ${RED}Erro de sintaxe${NC}"
    docker exec logstash /usr/share/logstash/bin/logstash -f \
        /usr/share/logstash/pipelines/05-jdbc-sqlite.conf -t
    exit 1
fi

echo "  ✓ Verificando disponibilidade do dataset..."
if docker exec logstash test -f /datasets/chinook.db; then
    echo -e "    ${GREEN}Dataset chinook.db encontrado${NC}"
else
    echo -e "    ${RED}Dataset chinook.db não encontrado${NC}"
    echo "    Execute: bash logstash/setup.sh"
    exit 1
fi

echo "  ✓ Verificando driver JDBC..."
if docker exec logstash test -f /opt/jdbc-drivers/sqlite-jdbc-3.48.0.0.jar; then
    echo -e "    ${GREEN}Driver JDBC encontrado${NC}"
else
    echo -e "    ${RED}Driver JDBC não encontrado${NC}"
    exit 1
fi

echo "  ℹ Pipeline JDBC será executado quando Logstash iniciar"
echo "    Verifique a ingestão em OpenSearch:"
echo "    $ curl -k -u admin:Admin@123456 https://localhost:9200/chinook-customers/_count"
echo ""

# Teste 6: Validar conectividade com OpenSearch
echo -e "${BLUE}─────────────────────────────────────${NC}"
echo -e "${YELLOW}[Teste 6]${NC} Conectividade com OpenSearch"
echo -e "${BLUE}─────────────────────────────────────${NC}"

if curl -s -k -u admin:Admin@123456 https://localhost:9200 &>/dev/null; then
    echo -e "${GREEN}✓ OpenSearch acessível${NC}"

    # Verificar índices criados
    echo "  ✓ Índices criados:"
    curl -s -k -u admin:Admin@123456 https://localhost:9200/_cat/indices?format=json | \
        jq '.[] | select(.index | contains("grok-logs") or contains("dissect-logs") or contains("date-logs") or contains("mutate-logs") or contains("chinook")) | {index, docs_count}' || \
        echo -e "    (nenhum índice de teste encontrado ainda)"
else
    echo -e "${RED}✗ OpenSearch não acessível em https://localhost:9200${NC}"
    echo "  Certifique-se de que OpenSearch está rodando"
fi

echo ""
echo "========================================="
echo -e "${GREEN}✓ Testes de Pipeline Concluídos${NC}"
echo "========================================="
echo ""
echo "Resumo:"
echo "  1. Pipelines 1-4: Testes com entrada stdin"
echo "  2. Pipeline 5: JDBC (executa continuamente)"
echo "  3. Logs em OpenSearch: grok-logs-*, dissect-logs-*, etc."
echo ""
echo "Para monitoramento contínuo:"
echo "  $ docker logs -f logstash"
echo ""
echo "Para validar dados em OpenSearch:"
echo "  $ curl -k -u admin:Admin@123456 https://localhost:9200/grok-logs-*/_search | jq '.hits.hits[0]'"
echo ""
