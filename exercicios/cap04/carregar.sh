#!/bin/bash
# =============================================================================
# cap04/carregar.sh — Dataset do Capítulo 4: Agregações
# Índice: customer_transactions (carregado do arquivo sample_dataset.csv)
# =============================================================================

set -e

OPENSEARCH_URL="https://localhost:9200"
OPENSEARCH_USER="admin"
OPENSEARCH_PASS="Admin#123456"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="${SCRIPT_DIR}/sample_dataset.csv"
PYTHON_LOADER="${SCRIPT_DIR}/load_data.py"
INDEX_NAME="customer_transactions"

echo "═══════════════════════════════════════════════════════════════════"
echo "  OpenSearch Customer Transactions Loader - Capítulo 4"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Verificar arquivo CSV
if [ ! -f "$CSV_FILE" ]; then
    echo "❌ Erro: Arquivo $CSV_FILE não encontrado!"
    exit 1
fi

if [ ! -f "$PYTHON_LOADER" ]; then
    echo "❌ Erro: Arquivo $PYTHON_LOADER não encontrado!"
    exit 1
fi

echo "✓ Arquivo CSV encontrado: $CSV_FILE"
LINES=$(wc -l < "$CSV_FILE")
echo "  Linhas no arquivo: $LINES (1 cabeçalho + $((LINES-1)) registros)"
echo ""

# Deletar índice existente
echo "🔄 Verificando índice existente..."
if curl -s -k -u "$OPENSEARCH_USER:$OPENSEARCH_PASS" \
    -X GET "$OPENSEARCH_URL/$INDEX_NAME" > /dev/null 2>&1; then
    echo "   ⚠️  Índice '$INDEX_NAME' já existe. Deletando..."
    curl -s -k -u "$OPENSEARCH_USER:$OPENSEARCH_PASS" \
        -X DELETE "$OPENSEARCH_URL/$INDEX_NAME" > /dev/null
    sleep 1
    echo "   ✓ Índice deletado"
else
    echo "   ✓ Novo índice"
fi

# Criar índice com mapping
echo ""
echo "📝 Criando índice com mapping..."

curl -s -k -u "$OPENSEARCH_USER:$OPENSEARCH_PASS" \
    -X PUT "$OPENSEARCH_URL/$INDEX_NAME" \
    -H "Content-Type: application/json" \
    -d '{
  "settings": {
    "index": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    }
  },
  "mappings": {
    "properties": {
      "customer_id": {
        "type": "keyword"
      },
      "name": {
        "type": "text",
        "fields": {
          "keyword": {
            "type": "keyword"
          }
        }
      },
      "surname": {
        "type": "text",
        "fields": {
          "keyword": {
            "type": "keyword"
          }
        }
      },
      "gender": {
        "type": "keyword"
      },
      "birthdate": {
        "type": "date",
        "format": "yyyy-MM-dd"
      },
      "transaction_amount": {
        "type": "double"
      },
      "date": {
        "type": "date",
        "format": "yyyy-MM-dd"
      },
      "merchant_name": {
        "type": "text",
        "fields": {
          "keyword": {
            "type": "keyword"
          }
        }
      },
      "category": {
        "type": "keyword"
      }
    }
  }
}' > /dev/null

echo "   ✓ Índice criado com mapping"

# Importar dados
echo ""
echo "📥 Importando dados (aguarde, processando arquivo grande)..."

python3 "$PYTHON_LOADER" "$CSV_FILE" "$INDEX_NAME" | \
curl -s -k -u "$OPENSEARCH_USER:$OPENSEARCH_PASS" \
    -X POST "$OPENSEARCH_URL/_bulk" \
    -H "Content-Type: application/x-ndjson" \
    --data-binary @- > /dev/null

sleep 2

# Verificar resultado
echo ""
echo "✅ Importação concluída!"
echo ""
echo "📊 Informações do Índice:"

DOC_COUNT=$(curl -s -k -u "$OPENSEARCH_USER:$OPENSEARCH_PASS" \
    -X GET "$OPENSEARCH_URL/$INDEX_NAME/_count" | grep -o '"count":[0-9]*' | cut -d: -f2)

echo "   Índice: $INDEX_NAME"
echo "   Documentos: $DOC_COUNT"

if [ "$DOC_COUNT" -gt 0 ]; then
    echo ""
    echo "✨ Sucesso! Índice 'customer_transactions' pronto para consultas."
    echo ""
    echo "Próximos passos:"
    echo "1. Consulte os exemplos de agregações"
    echo "2. Execute: bash testes.sh"
else
    echo ""
    echo "⚠️  Aviso: Nenhum documento foi carregado. Verifique o arquivo CSV."
fi
