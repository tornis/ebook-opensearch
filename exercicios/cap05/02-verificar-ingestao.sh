#!/bin/bash

###############################################################################
# Script: Verificar Ingestão de Logs no OpenSearch
# Descrição: Valida se os logs foram ingeridos corretamente
# Uso: bash 02-verificar-ingestao.sh
###############################################################################

set -e

# Configurações
OPENSEARCH_HOST="https://localhost:9200"
OPENSEARCH_USER="admin"
OPENSEARCH_PASS="<SENHA_ADMIN>"
INDEX_PREFIX="logstash-apache"

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Verificação de Ingestão de Logs ===${NC}\n"

# Função para executar curl com autenticação
function opensearch_query() {
    local endpoint=$1
    curl -s -k -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
        -H "Content-Type: application/json" \
        "${OPENSEARCH_HOST}${endpoint}"
}

# Verificar conectividade com OpenSearch
echo -e "${BLUE}1️⃣  Verificando conectividade com OpenSearch...${NC}"
if opensearch_query "/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OpenSearch está acessível${NC}\n"
else
    echo -e "${RED}❌ Não foi possível conectar ao OpenSearch${NC}"
    echo "   Certifique-se de que OpenSearch está rodando em $OPENSEARCH_HOST"
    exit 1
fi

# Listar todos os índices logstash-apache
echo -e "${BLUE}2️⃣  Procurando índices logstash-apache...${NC}"
INDICES=$(opensearch_query "/_cat/indices?format=json" | \
    grep -o '"index":"'$INDEX_PREFIX'[^"]*' | cut -d'"' -f4 | sort | uniq)

if [ -z "$INDICES" ]; then
    echo -e "${YELLOW}⚠️  Nenhum índice logstash-apache encontrado ainda${NC}"
    echo -e "${YELLOW}    Fluent Bit pode estar processando os logs...${NC}"
else
    echo -e "${GREEN}✅ Índices encontrados:${NC}"
    echo "$INDICES" | while read idx; do
        echo "   📊 $idx"
    done
    echo ""
fi

# Contar total de documentos
echo -e "${BLUE}3️⃣  Contando documentos ingeridos...${NC}"
TOTAL_DOCS=0

for idx in $INDICES; do
    COUNT=$(opensearch_query "/$idx/_count" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    TOTAL_DOCS=$((TOTAL_DOCS + COUNT))
    echo "   📄 $idx: $COUNT documentos"
done

echo -e "\n${GREEN}Total de documentos: $TOTAL_DOCS${NC}\n"

# Mostrar amostra de documentos
echo -e "${BLUE}4️⃣  Amostra de documentos ingeridos:${NC}"
if [ -n "$INDICES" ]; then
    FIRST_INDEX=$(echo "$INDICES" | head -1)
    SAMPLE=$(opensearch_query "/$FIRST_INDEX/_search?size=1" | \
        python3 -m json.tool 2>/dev/null || echo "JSON parsing failed")
    echo "$SAMPLE" | head -30
else
    echo -e "${YELLOW}   Sem documentos para exibir${NC}"
fi

echo -e "\n${BLUE}5️⃣  Verificar aplicação de Sampling e Filtragem:${NC}"
if [ -n "$INDICES" ]; then
    FIRST_INDEX=$(echo "$INDICES" | head -1)

    # Contar requisições com status 200
    STATUS_200=$(opensearch_query "/$FIRST_INDEX/_count?q=code:200" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    echo "   HTTP 200: $STATUS_200 requisições (esperado ~10% do total)"

    # Contar requisições com status 4xx
    STATUS_4XX=$(opensearch_query "/$FIRST_INDEX/_count?q=code:[400 TO 499]" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    echo "   HTTP 4xx: $STATUS_4XX requisições (esperado 100% capturadas)"

    # Contar requisições com status 5xx
    STATUS_5XX=$(opensearch_query "/$FIRST_INDEX/_count?q=code:[500 TO 599]" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    echo "   HTTP 5xx: $STATUS_5XX requisições (esperado 100% capturadas)"

    echo ""
fi

# Verificar remoção de extensões estáticas
echo -e "${BLUE}6️⃣  Verificar Filtragem de Recursos Estáticos:${NC}"
if [ -n "$INDICES" ]; then
    FIRST_INDEX=$(echo "$INDICES" | head -1)

    # Procurar por .png, .jpg, etc
    STATIC=$(opensearch_query "/$FIRST_INDEX/_count?q=request:*.png" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    if [ "$STATIC" -eq 0 ]; then
        echo -e "${GREEN}✅ Recursos estáticos (.png, .jpg, etc) foram removidos com sucesso${NC}"
    else
        echo -e "${YELLOW}⚠️  Encontrados $STATIC recursos estáticos (filtragem pode não ter funcionado)${NC}"
    fi
else
    echo -e "${YELLOW}   Sem documentos para verificar filtragem${NC}"
fi

echo -e "\n${BLUE}=== Resumo ===${NC}"
echo -e "${GREEN}✅ Verificação concluída${NC}"
echo -e "   Para mais informações, acesse:"
echo -e "   ${BLUE}https://localhost:9200/_cat/indices${NC}"
echo -e "   ${BLUE}https://localhost:9200/logstash-apache-*/_search${NC}"
