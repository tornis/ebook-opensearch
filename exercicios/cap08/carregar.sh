#!/bin/bash

# Script: carregar.sh
# Descrição: Carrega dados de exercício no OpenSearch usando Ingest Pipelines
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

# Verificar se OpenSearch está rodando
check_opensearch() {
    if ! curl -sk -u admin:Admin@123456 https://localhost:9200/_cluster/health > /dev/null 2>&1; then
        echo -e "${RED}❌ OpenSearch não está respondendo em https://localhost:9200${NC}"
        echo -e "${YELLOW}Inicie com:${NC}"
        echo "  cd ../.. && docker-compose -f exemplos/docker-compose.single-node.yml up -d"
        exit 1
    fi
}

# Listar pipelines disponíveis
list_pipelines() {
    echo -e "${BLUE}Pipelines disponíveis em OpenSearch:${NC}\n"
    curl -sk -u admin:Admin@123456 https://localhost:9200/_ingest/pipeline | jq 'to_entries[] | {pipeline: .key, descricao: .value.description}' || echo "Nenhum pipeline encontrado"
}

# Carregar dados no OpenSearch
load_data() {
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}CARREGANDO DADOS — Capítulo 8: Ingest Pipelines${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

    # Verificar ambiente
    echo -e "${YELLOW}1. Verificando ambiente...${NC}"
    check_opensearch
    echo -e "${GREEN}✅ OpenSearch válido${NC}\n"

    # Verificar arquivo de dados
    if [ ! -f "$DADOS_FILE" ]; then
        echo -e "${RED}❌ Arquivo $DADOS_FILE não encontrado${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Arquivo de dados encontrado${NC}\n"

    # Contar linhas
    TOTAL_LINES=$(wc -l < "$DADOS_FILE")
    echo -e "${YELLOW}2. Carregando $TOTAL_LINES registros...${NC}\n"

    # Converter NDJSON para array JSON
    TEMP_JSON="/tmp/cap08-logs-array.json"
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

    # Criar pipeline básico se não existir
    echo -e "${YELLOW}3. Criando pipeline padrão se necessário...${NC}"
    curl -sk -X PUT -u admin:Admin@123456 \
      https://localhost:9200/_ingest/pipeline/logs-default \
      -H "Content-Type: application/json" \
      -d '{
        "description": "Pipeline padrão para logs de exercício",
        "processors": [
          {
            "set": {
              "field": "@ingest_timestamp",
              "value": "{{ _ingest.timestamp }}"
            }
          }
        ]
      }' > /dev/null 2>&1
    echo -e "${GREEN}✅ Pipeline padrão criado${NC}\n"

    # Enviar para OpenSearch
    echo -e "${YELLOW}4. Enviando dados para OpenSearch...${NC}"

    RESPONSE=$(curl -sk -X POST -u admin:Admin@123456 \
        https://localhost:9200/logs-exercicio/_bulk \
        -H "Content-Type: application/json" \
        --data-binary @"$TEMP_JSON" \
        -w "\n%{http_code}")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        echo -e "${GREEN}✅ Dados enviados com sucesso (HTTP $HTTP_CODE)${NC}\n"
    else
        echo -e "${RED}❌ Erro ao enviar dados (HTTP $HTTP_CODE)${NC}"
        echo "Resposta: $BODY"
        exit 1
    fi

    # Aguardar processamento
    echo -e "${YELLOW}5. Aguardando indexação (5 segundos)...${NC}"
    sleep 5
    echo -e "${GREEN}✅ Indexação completa${NC}\n"

    # Verificar dados em OpenSearch
    echo -e "${YELLOW}6. Verificando dados no OpenSearch...${NC}"

    INDEX_COUNT=$(curl -sk -u admin:Admin@123456 https://localhost:9200/logs-exercicio/_count 2>/dev/null | jq '.count' || echo "0")

    if [ "$INDEX_COUNT" = "0" ] || [ -z "$INDEX_COUNT" ]; then
        echo -e "${YELLOW}⚠️ Aguardando indexação... aguarde 10 segundos${NC}"
        sleep 10
        INDEX_COUNT=$(curl -sk -u admin:Admin@123456 https://localhost:9200/logs-exercicio/_count 2>/dev/null | jq '.count' || echo "0")
    fi

    echo -e "${GREEN}✅ Encontrados $INDEX_COUNT documentos em logs-exercicio${NC}\n"

    # Registrar log
    {
        echo "Data de carregamento: $(date)"
        echo "Total de registros: $TOTAL_LINES"
        echo "Índices criados: logs-exercicio"
        echo "Documentos no OpenSearch: $INDEX_COUNT"
        echo "Status: Sucesso"
    } > "$LOG_FILE"

    # Dicas finais
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Dados carregados com sucesso!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

    echo -e "${YELLOW}Próximos passos:${NC}"
    echo "1. Listar pipelines:"
    echo "   curl -s https://localhost:9200/_ingest/pipeline | jq"
    echo ""
    echo "2. Contar documentos:"
    echo "   curl -sk -u admin:Admin@123456 https://localhost:9200/logs-exercicio/_count | jq"
    echo ""
    echo "3. Buscar documentos:"
    echo "   curl -sk -u admin:Admin@123456 https://localhost:9200/logs-exercicio/_search | jq"
    echo ""
    echo "4. Resolver exercícios:"
    echo "   cat exercicios.md"
    echo ""

    # Cleanup
    rm -f "$TEMP_JSON"
}

# Limpar dados
clean_data() {
    echo -e "${BLUE}Limpando dados...${NC}"

    check_opensearch

    # Deletar índices
    curl -sk -X DELETE -u admin:Admin@123456 https://localhost:9200/logs-* || true
    echo -e "${GREEN}✅ Índices deletados${NC}"

    # Deletar log
    rm -f "$LOG_FILE"
    echo -e "${GREEN}✅ Arquivo de log deletado${NC}"
}

# Main
case "${1:-load}" in
    list)
        check_opensearch
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
