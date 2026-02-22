#!/bin/bash
# =============================================================================
# cap01/carregar.sh — Datasets do Capítulo 1: Introdução e Arquitetura
# Índices: livros, vendas-2025
# =============================================================================

OPENSEARCH_URL="https://localhost:9200"
OPENSEARCH_USER="admin"
OPENSEARCH_PASS="<SENHA_ADMIN>"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURL="curl -sk -u ${OPENSEARCH_USER}:${OPENSEARCH_PASS}"

echo "--- Capítulo 1: Introdução e Arquitetura ---"

# ─────────────────────────────────────────────
# Índice: livros
# Seções: 1.6.1, 1.6.2, 1.6.3
# ─────────────────────────────────────────────
echo "Recriando índice 'livros'..."
$CURL -X DELETE "${OPENSEARCH_URL}/livros" > /dev/null 2>&1 || true

$CURL -X PUT "${OPENSEARCH_URL}/livros" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1
    },
    "mappings": {
      "properties": {
        "titulo":           { "type": "text", "analyzer": "portuguese" },
        "autor":            { "type": "keyword" },
        "preco":            { "type": "float" },
        "data_publicacao":  { "type": "date" }
      }
    }
  }' > /dev/null
echo "  [OK] Índice 'livros' criado."

echo "  Carregando dados em 'livros'..."
$CURL -X POST "${OPENSEARCH_URL}/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary @"${SCRIPT_DIR}/dados.ndjson" > /dev/null
echo "  [OK] Dados carregados."

# ─────────────────────────────────────────────
# Índice: vendas-2025
# Seção: Exercício 1.9.2 — Alocação de shards
# (Apenas criação de índice, sem dados — exercício de infraestrutura)
# ─────────────────────────────────────────────
echo "Recriando índice 'vendas-2025'..."
$CURL -X DELETE "${OPENSEARCH_URL}/vendas-2025" > /dev/null 2>&1 || true

$CURL -X PUT "${OPENSEARCH_URL}/vendas-2025" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1
    },
    "mappings": {
      "properties": {
        "produto":     { "type": "text" },
        "valor":       { "type": "float" },
        "quantidade":  { "type": "integer" },
        "data_venda":  { "type": "date" },
        "vendedor":    { "type": "keyword" }
      }
    }
  }' > /dev/null
echo "  [OK] Índice 'vendas-2025' criado (exercício de alocação de shards)."

# ─────────────────────────────────────────────
# Verificação
# ─────────────────────────────────────────────
echo ""
echo "  Contagem de documentos:"
$CURL "${OPENSEARCH_URL}/_cat/indices/livros,vendas-2025?v&h=index,docs.count" 2>/dev/null
echo ""
echo "--- Cap01 concluído ---"
