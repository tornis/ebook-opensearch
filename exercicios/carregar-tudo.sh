#!/bin/bash
# =============================================================================
# carregar-tudo.sh — Script mestre para carga de todos os datasets
# Ebook: OpenSearch 3.5 na Prática
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================="
echo "  CARGA COMPLETA DOS DATASETS — OPENSEARCH"
echo "=============================================="
echo ""

# Verificar conectividade antes de começar
OPENSEARCH_URL="https://localhost:9200"
OPENSEARCH_USER="admin"
OPENSEARCH_PASS="<SENHA_ADMIN>"

echo "Verificando conexão com OpenSearch..."
STATUS=$(curl -sk -o /dev/null -w "%{http_code}" -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" "${OPENSEARCH_URL}/_cluster/health")
if [ "$STATUS" != "200" ]; then
    echo "[ERRO] OpenSearch não está acessível em ${OPENSEARCH_URL} (HTTP $STATUS)"
    echo "       Certifique-se de que o Docker está rodando:"
    echo "       docker compose -f exemplos/docker-compose.single-node.yml up -d"
    exit 1
fi
echo "[OK] OpenSearch acessível."
echo ""

echo "[1/4] Carregando dados do Capítulo 1..."
bash "${SCRIPT_DIR}/cap01/carregar.sh"
echo ""

echo "[2/4] Carregando dados do Capítulo 2..."
bash "${SCRIPT_DIR}/cap02/carregar.sh"
echo ""

echo "[3/4] Carregando dados do Capítulo 3..."
bash "${SCRIPT_DIR}/cap03/carregar.sh"
echo ""

echo "[4/4] Carregando dados do Capítulo 4..."
bash "${SCRIPT_DIR}/cap04/carregar.sh"
echo ""

echo "=============================================="
echo "  CARGA CONCLUÍDA COM SUCESSO!"
echo "=============================================="
echo ""
echo "Resumo dos índices criados:"
curl -sk -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
    "${OPENSEARCH_URL}/_cat/indices?v&s=index&h=index,docs.count,store.size"
echo ""
