#!/bin/bash

# Script: carregar.sh
# Descrição: Carrega dados de exercício no Data Prepper/OpenSearch
# Modo de uso: bash carregar.sh [list|clean|load]

set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DADOS_FILE="$SCRIPT_DIR/dados.ndjson"
LOG_FILE="$SCRIPT_DIR/dados-carregados.txt"

# Verificar se Data Prepper está rodando
check_data_prepper() {
    if ! curl -s http://localhost:21000/health > /dev/null 2>&1; then
        echo -e "${RED}❌ Data Prepper não está respondendo em http://localhost:21000${NC}"
        echo -e "${YELLOW}Inicie com:${NC}"
        echo "  cd exemplos/cap07 && docker-compose up -d"
        exit 1
    fi
}

# Verificar se OpenSearch está rodando
check_opensearch() {
    if ! curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; then
        echo -e "${RED}❌ OpenSearch não está respondendo em http://localhost:9200${NC}"
        exit 1
    fi
}

# Listar pipelines disponíveis
list_pipelines() {
    echo -e "${BLUE}Pipelines disponíveis em Data Prepper:${NC}\n"
    curl -s http://localhost:21000/list-pipelines | jq '.pipelines[] | {name: .name, status: .status}' || echo "Nenhum pipeline encontrado"
}

# Carregar dados no Data Prepper
load_data() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}CARREGANDO DADOS — Capítulo 7${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    # Verificar ambiente
    echo -e "${YELLOW}1. Verificando ambiente...${NC}"
    check_data_prepper
    check_opensearch
    echo -e "${GREEN}✅ Ambiente válido${NC}\n"

    # Verificar arquivo de dados
    if [ ! -f "$DADOS_FILE" ]; then
        echo -e "${RED}❌ Arquivo $DADOS_FILE não encontrado${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Arquivo de dados encontrado${NC}\n"

    # Contar linhas
    TOTAL_LINES=$(wc -l < "$DADOS_FILE")
    echo -e "${YELLOW}2. Carregando $TOTAL_LINES registros...${NC}\n"

    # Converter NDJSON para array JSON para Data Prepper
    # (Data Prepper espera array JSON no endpoint HTTP)
    TEMP_JSON="/tmp/cap07-logs-array.json"
    echo "[" > "$TEMP_JSON"

    # Contar registros carregados
    COUNTER=0
    while IFS= read -r line; do
        if [ -z "$line" ]; then continue; fi

        if [ $COUNTER -gt 0 ]; then
            echo "," >> "$TEMP_JSON"
        fi
        echo "$line" >> "$TEMP_JSON"

        COUNTER=$((COUNTER + 1))

        # Mostrar progresso a cada 20 registros
        if [ $((COUNTER % 20)) -eq 0 ]; then
            echo -ne "\r  Processados: $COUNTER/$TOTAL_LINES"
        fi
    done < "$DADOS_FILE"

    echo "]" >> "$TEMP_JSON"
    echo -e "\n${GREEN}✅ Array JSON preparado${NC}\n"

    # Enviar para Data Prepper
    echo -e "${YELLOW}3. Enviando para Data Prepper...${NC}"

    RESPONSE=$(curl -s -X POST http://localhost:21000/log/ingest \
        -H "Content-Type: application/json" \
        -d @"$TEMP_JSON" \
        -w "\n%{http_code}")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
        echo -e "${GREEN}✅ Dados enviados com sucesso (HTTP $HTTP_CODE)${NC}\n"
    else
        echo -e "${RED}❌ Erro ao enviar dados (HTTP $HTTP_CODE)${NC}"
        echo "Resposta: $BODY"
        exit 1
    fi

    # Aguardar processamento
    echo -e "${YELLOW}4. Aguardando processamento (5 segundos)...${NC}"
    sleep 5
    echo -e "${GREEN}✅ Processamento completo${NC}\n"

    # Verificar dados em OpenSearch
    echo -e "${YELLOW}5. Verificando dados no OpenSearch...${NC}"

    INDEX_COUNT=$(curl -s http://localhost:9200/logs-app-*/_count 2>/dev/null | jq '.count' || echo "0")

    if [ "$INDEX_COUNT" = "0" ] || [ -z "$INDEX_COUNT" ]; then
        echo -e "${YELLOW}⚠️ Aguardando indexação... aguarde 10 segundos${NC}"
        sleep 10
        INDEX_COUNT=$(curl -s http://localhost:9200/logs-app-*/_count 2>/dev/null | jq '.count' || echo "0")
    fi

    echo -e "${GREEN}✅ Encontrados $INDEX_COUNT documentos em logs-app-*${NC}\n"

    # Registrar log
    {
        echo "Data de carregamento: $(date)"
        echo "Total de registros: $TOTAL_LINES"
        echo "Índices criados: logs-app-*"
        echo "Documentos no OpenSearch: $INDEX_COUNT"
        echo "Status: Sucesso"
    } > "$LOG_FILE"

    # Dicas finais
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Dados carregados com sucesso!${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    echo -e "${YELLOW}Próximos passos:${NC}"
    echo "1. Consultar dados:"
    echo "   curl -s http://localhost:9200/logs-app-*/_search | jq '.hits.hits[0]._source'"
    echo ""
    echo "2. Contar documentos:"
    echo "   curl -s http://localhost:9200/logs-app-*/_count | jq '.count'"
    echo ""
    echo "3. Buscar por nível:"
    echo "   curl -s -H 'Content-Type: application/json' http://localhost:9200/logs-app-*/_search -d '{\"query\":{\"match\":{\"level\":\"ERROR\"}}}' | jq '.hits.total.value'"
    echo ""
    echo "4. Resolver exercícios: cat exercicios.md"
    echo ""

    # Cleanup
    rm -f "$TEMP_JSON"
}

# Limpar dados
clean_data() {
    echo -e "${BLUE}Limpando dados...${NC}"

    check_opensearch

    # Deletar índices
    curl -s -X DELETE http://localhost:9200/logs-app-* || true
    curl -s -X DELETE http://localhost:9200/apache-logs-* || true
    curl -s -X DELETE http://localhost:9200/app-logs-* || true

    # Deletar log
    rm -f "$LOG_FILE"

    echo -e "${GREEN}✅ Dados limpados${NC}"
}

# Main
case "${1:-load}" in
    list)
        check_data_prepper
        list_pipelines
        ;;
    clean)
        clean_data
        ;;
    load)
        load_data
        ;;
    *)
        echo "Uso: bash carregar.sh [list|clean|load]"
        echo ""
        echo "  list  — Listar pipelines disponíveis"
        echo "  clean — Limpar dados carregados"
        echo "  load  — Carregar dados (padrão)"
        exit 1
        ;;
esac
