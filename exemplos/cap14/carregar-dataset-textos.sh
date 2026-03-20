#!/bin/bash
# Script para carregar dataset de textos no OpenSearch

set -e

# Configurações
OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASSWORD="${OPENSEARCH_PASSWORD:-Admin#123456}"
DATASET_FILE="${1:-dataset-temas-ti.ndjson}"

echo ""
echo "=================================================="
echo "📤 Carregador de Dataset - RAG/Vetorização"
echo "=================================================="
echo ""

# Verificar se arquivo existe
if [ ! -f "$DATASET_FILE" ]; then
    echo "❌ Erro: Arquivo '$DATASET_FILE' não encontrado"
    echo ""
    echo "💡 Dica: Execute primeiro:"
    echo "   python gerar-dataset-textos.py"
    exit 1
fi

echo "📋 Informações do Upload:"
echo "   OpenSearch: $OPENSEARCH_URL"
echo "   Dataset: $DATASET_FILE"
echo "   Índice: temas-ti"
echo ""

# Calcular estatísticas do arquivo
TOTAL_LINHAS=$(wc -l < "$DATASET_FILE")
TOTAL_DOCS=$((TOTAL_LINHAS / 2))
TAMANHO_KB=$(du -k "$DATASET_FILE" | cut -f1)

echo "📊 Estatísticas do Dataset:"
echo "   Total de documentos: $TOTAL_DOCS"
echo "   Total de linhas: $TOTAL_LINHAS"
echo "   Tamanho: ${TAMANHO_KB}KB"
echo ""

# Confirmação
read -p "🔄 Deseja carregar o dataset? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Carregamento cancelado"
    exit 0
fi

echo ""
echo "⏳ Carregando dataset via Bulk API..."
echo ""

# Enviar dataset para OpenSearch via Bulk API
START_TIME=$(date +%s)

RESPONSE=$(curl -sk \
    -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" \
    -X POST \
    "$OPENSEARCH_URL/_bulk" \
    -H "Content-Type: application/x-ndjson" \
    --data-binary "@$DATASET_FILE" \
    -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$RESPONSE" | head -n -1)

END_TIME=$(date +%s)
DURACAO=$((END_TIME - START_TIME))

echo ""
echo "🔍 Resposta do OpenSearch:"
echo "   HTTP Status: $HTTP_CODE"
echo "   Duração: ${DURACAO}s"

if [ "$HTTP_CODE" = "200" ]; then
    echo ""
    echo "✅ Dataset carregado com sucesso!"

    # Extrair informações da resposta
    ERRORS=$(echo "$RESPONSE_BODY" | grep -o '"errors":false' || echo "")

    if [ -n "$ERRORS" ]; then
        echo "   Todos os documentos foram indexados sem erros"
    fi

    echo ""
    echo "📈 Verificando índice..."
    echo ""

    # Contar documentos
    COUNT=$(curl -sk \
        -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" \
        "$OPENSEARCH_URL/temas-ti/_count" \
        -H "Content-Type: application/json" | grep -o '"count":[0-9]*' | grep -o '[0-9]*')

    echo "   Total de documentos no índice: $COUNT"

    # Obter informações do índice
    curl -sk \
        -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" \
        "$OPENSEARCH_URL/temas-ti/_stats" > /dev/null 2>&1

    echo ""
    echo "💾 Estatísticas do Índice:"
    curl -sk \
        -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" \
        "$OPENSEARCH_URL/temas-ti/_stats?pretty=true" | grep -A5 "store" | head -10

    echo ""
    echo "=================================================="
    echo "🎉 Dataset Carregado com Sucesso!"
    echo "=================================================="
    echo ""
    echo "📌 Próximos Passos:"
    echo "   1. Verificar documentos:"
    echo "      curl -sk -u admin:Admin#123456 \\"
    echo "        https://localhost:9200/temas-ti/_search?size=1 | jq"
    echo ""
    echo "   2. Buscar por tema:"
    echo "      curl -sk -u admin:Admin#123456 \\"
    echo "        https://localhost:9200/temas-ti/_search -d '{"
    echo "          \"query\": {\"term\": {\"tema\": \"opensearch\"}}"
    echo "        }' | jq"
    echo ""
    echo "   3. Busca semântica (com embeddings):"
    echo "      Veja README.md para exemplos de vector search"
    echo ""
else
    echo ""
    echo "❌ Erro ao carregar dataset (HTTP $HTTP_CODE)"
    echo ""
    echo "Resposta do servidor:"
    echo "$RESPONSE_BODY" | jq . 2>/dev/null || echo "$RESPONSE_BODY"
    exit 1
fi
