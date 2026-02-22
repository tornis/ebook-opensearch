#!/bin/bash
# =============================================================================
# cap02/carregar.sh — Datasets do Capítulo 2: Conceitos, Mappings e CRUD
# Índices: usuarios, produtos, produtos-dinamico,
#          produtos-explicitamente-mapeado, blog-posts, logs-api
# =============================================================================

OPENSEARCH_URL="https://localhost:9200"
OPENSEARCH_USER="admin"
OPENSEARCH_PASS="<SENHA_ADMIN>"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURL="curl -sk -u ${OPENSEARCH_USER}:${OPENSEARCH_PASS}"

echo "--- Capítulo 2: Conceitos, Mappings e CRUD ---"

# ─────────────────────────────────────────────
# Índice: usuarios
# Seções: 2.5.1, 2.5.2, 2.5.3, 2.5.4, 2.6.1, 2.6.2
# ─────────────────────────────────────────────
echo "Recriando índice 'usuarios'..."
$CURL -X DELETE "${OPENSEARCH_URL}/usuarios" > /dev/null 2>&1 || true

$CURL -X PUT "${OPENSEARCH_URL}/usuarios" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
    "mappings": {
      "properties": {
        "nome":          { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
        "email":         { "type": "keyword" },
        "idade":         { "type": "integer" },
        "ativo":         { "type": "boolean" },
        "criado_em":     { "type": "date" },
        "atualizado_em": { "type": "date" }
      }
    }
  }' > /dev/null
echo "  [OK] Índice 'usuarios' criado."

# ─────────────────────────────────────────────
# Índice: produtos
# Seções: 2.5.1 (op_type=create), 2.5.3 (update com script)
# ─────────────────────────────────────────────
echo "Recriando índice 'produtos'..."
$CURL -X DELETE "${OPENSEARCH_URL}/produtos" > /dev/null 2>&1 || true

$CURL -X PUT "${OPENSEARCH_URL}/produtos" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
    "mappings": {
      "properties": {
        "nome":        { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
        "descricao":   { "type": "text", "analyzer": "portuguese" },
        "preco":       { "type": "float" },
        "categoria":   { "type": "keyword" },
        "marca":       { "type": "keyword" },
        "em_estoque":  { "type": "boolean" },
        "estoque":     { "type": "integer" },
        "criado_em":   { "type": "date" }
      }
    }
  }' > /dev/null
echo "  [OK] Índice 'produtos' criado."

# ─────────────────────────────────────────────
# Índice: produtos-dinamico
# Seção: 2.2.1 — Mapping dinâmico
# ─────────────────────────────────────────────
echo "Recriando índice 'produtos-dinamico'..."
$CURL -X DELETE "${OPENSEARCH_URL}/produtos-dinamico" > /dev/null 2>&1 || true
# Sem mapping explícito — demonstra auto-detecção de tipos
echo "  [OK] Índice 'produtos-dinamico' será criado automaticamente no primeiro documento."

# ─────────────────────────────────────────────
# Índice: produtos-explicitamente-mapeado
# Seção: 2.2.2 — Mapping explícito completo
# ─────────────────────────────────────────────
echo "Recriando índice 'produtos-explicitamente-mapeado'..."
$CURL -X DELETE "${OPENSEARCH_URL}/produtos-explicitamente-mapeado" > /dev/null 2>&1 || true

$CURL -X PUT "${OPENSEARCH_URL}/produtos-explicitamente-mapeado" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
    "mappings": {
      "properties": {
        "id_produto":    { "type": "keyword" },
        "nome":          { "type": "text", "fields": { "raw": { "type": "keyword" } }, "analyzer": "portuguese" },
        "descricao":     { "type": "text", "analyzer": "portuguese" },
        "preco":         { "type": "float" },
        "categoria":     { "type": "keyword" },
        "estoque":       { "type": "integer" },
        "ativo":         { "type": "boolean" },
        "criado_em":     { "type": "date", "format": "strict_date_time" },
        "atualizado_em": { "type": "date", "format": "strict_date_time" },
        "localizacao":   { "type": "geo_point" }
      }
    }
  }' > /dev/null
echo "  [OK] Índice 'produtos-explicitamente-mapeado' criado."

# ─────────────────────────────────────────────
# Índice: blog-posts
# Seções: Exercícios 2.7.1 e 2.7.2
# ─────────────────────────────────────────────
echo "Recriando índice 'blog-posts'..."
$CURL -X DELETE "${OPENSEARCH_URL}/blog-posts" > /dev/null 2>&1 || true

$CURL -X PUT "${OPENSEARCH_URL}/blog-posts" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "analysis": {
        "analyzer": {
          "portuguese_custom": {
            "type": "custom",
            "tokenizer": "standard",
            "filter": ["lowercase", "portuguese_stop", "portuguese_stemmer"]
          }
        },
        "filter": {
          "portuguese_stop": { "type": "stop", "stopwords": "_portuguese_" },
          "portuguese_stemmer": { "type": "stemmer", "language": "portuguese" }
        }
      }
    },
    "mappings": {
      "properties": {
        "titulo":           { "type": "text", "analyzer": "portuguese" },
        "conteudo":         { "type": "text", "analyzer": "portuguese" },
        "autor":            { "type": "keyword" },
        "data_publicacao":  { "type": "date" },
        "categoria":        { "type": "keyword" },
        "tags":             { "type": "keyword" },
        "visualizacoes":    { "type": "integer" },
        "curtidas":         { "type": "integer" },
        "ativo":            { "type": "boolean" }
      }
    }
  }' > /dev/null
echo "  [OK] Índice 'blog-posts' criado."

# ─────────────────────────────────────────────
# Índice: logs-api (versão cap02)
# Seção: 2.3.3 — Custom analyzer (log_analyzer)
# ─────────────────────────────────────────────
echo "Recriando índice 'logs-api'..."
$CURL -X DELETE "${OPENSEARCH_URL}/logs-api" > /dev/null 2>&1 || true

$CURL -X PUT "${OPENSEARCH_URL}/logs-api" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "analysis": {
        "char_filter": {
          "html_strip_custom": {
            "type": "html_strip",
            "escaped_tags": ["b", "i"]
          }
        },
        "filter": {
          "stop_pt": {
            "type": "stop",
            "stopwords": ["_english_", "para", "de", "a", "o", "e"]
          }
        },
        "analyzer": {
          "log_analyzer": {
            "type": "custom",
            "char_filter": ["html_strip_custom"],
            "tokenizer": "standard",
            "filter": ["lowercase", "stop_pt", "snowball"]
          }
        }
      }
    },
    "mappings": {
      "properties": {
        "mensagem":  { "type": "text", "analyzer": "log_analyzer" },
        "level":     { "type": "keyword" },
        "timestamp": { "type": "date" },
        "endpoint":  { "type": "keyword" },
        "status_code": { "type": "integer" },
        "response_time_ms": { "type": "integer" },
        "service":   { "type": "keyword" }
      }
    }
  }' > /dev/null
echo "  [OK] Índice 'logs-api' criado."

# ─────────────────────────────────────────────
# Carregar dados via bulk
# ─────────────────────────────────────────────
echo "  Carregando dados..."
$CURL -X POST "${OPENSEARCH_URL}/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary @"${SCRIPT_DIR}/dados.ndjson" > /dev/null

# Aguardar indexação
sleep 1

echo ""
echo "  Contagem de documentos:"
$CURL "${OPENSEARCH_URL}/_cat/indices/usuarios,produtos,produtos-dinamico,produtos-explicitamente-mapeado,blog-posts,logs-api?v&h=index,docs.count" 2>/dev/null
echo ""
echo "--- Cap02 concluído ---"
