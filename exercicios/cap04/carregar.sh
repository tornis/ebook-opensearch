#!/bin/bash
# =============================================================================
# cap04/carregar.sh — Datasets do Capítulo 4: Agregações
# Índices: ecommerce-products, vendas, vendas-ecommerce, logs-api-2024,
#          logs-web, sensor-iot, dados-financeiros, avaliacoes-clientes,
#          analytics-website, system-health, product-reviews,
#          abandoned-carts, transacoes-financeiras
# =============================================================================

OPENSEARCH_URL="https://localhost:9200"
OPENSEARCH_USER="admin"
OPENSEARCH_PASS="<SENHA_ADMIN>"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURL="curl -sk -u ${OPENSEARCH_USER}:${OPENSEARCH_PASS}"

echo "--- Capítulo 4: Agregações ---"

create_index() {
  local name=$1
  local body=$2
  $CURL -X DELETE "${OPENSEARCH_URL}/${name}" > /dev/null 2>&1 || true
  $CURL -X PUT "${OPENSEARCH_URL}/${name}" \
    -H "Content-Type: application/json" \
    -d "$body" > /dev/null
  echo "  [OK] '${name}' criado."
}

# ── ecommerce-products ────────────────────────────────────────────────────────
create_index "ecommerce-products" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "nome":          { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
    "preco":         { "type": "float" },
    "categoria":     { "type": "keyword" },
    "marca":         { "type": "keyword" },
    "dias_entrega":  { "type": "integer" },
    "em_estoque":    { "type": "boolean" },
    "avaliacao":     { "type": "float" }
  }}
}'

# ── vendas ────────────────────────────────────────────────────────────────────
create_index "vendas" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "data_venda":         { "type": "date" },
    "valor":              { "type": "float" },
    "valor_venda":        { "type": "float" },
    "quantidade":         { "type": "integer" },
    "categoria":          { "type": "keyword" },
    "subcategoria":       { "type": "keyword" },
    "regiao":             { "type": "keyword" },
    "canal_venda":        { "type": "keyword" },
    "cliente_id":         { "type": "keyword" },
    "nota_satisfacao":    { "type": "float" },
    "margem_percentual":  { "type": "float" }
  }}
}'

# ── vendas-ecommerce ──────────────────────────────────────────────────────────
create_index "vendas-ecommerce" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "data_venda":         { "type": "date" },
    "valor_total":        { "type": "float" },
    "quantidade":         { "type": "integer" },
    "categoria":          { "type": "keyword" },
    "marca":              { "type": "keyword" },
    "regiao":             { "type": "keyword" },
    "canal_venda":        { "type": "keyword" },
    "cliente_id":         { "type": "keyword" },
    "nota_satisfacao":    { "type": "float" },
    "margem_percentual":  { "type": "float" },
    "taxa_conversao":     { "type": "float" },
    "produto":            { "type": "keyword" }
  }}
}'

# ── logs-api-2024 ─────────────────────────────────────────────────────────────
create_index "logs-api-2024" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "timestamp":        { "type": "date" },
    "endpoint":         { "type": "keyword" },
    "status_code":      { "type": "integer" },
    "response_time_ms": { "type": "integer" },
    "latencia_ms":      { "type": "integer" },
    "service":          { "type": "keyword" },
    "method":           { "type": "keyword" }
  }}
}'

# ── logs-web ──────────────────────────────────────────────────────────────────
create_index "logs-web" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "timestamp":        { "type": "date" },
    "request_id":       { "type": "keyword" },
    "status_code":      { "type": "integer" },
    "response_time_ms": { "type": "integer" },
    "path":             { "type": "keyword" },
    "method":           { "type": "keyword" },
    "bytes":            { "type": "integer" }
  }}
}'

# ── sensor-iot ────────────────────────────────────────────────────────────────
create_index "sensor-iot" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "timestamp":    { "type": "date" },
    "temperatura":  { "type": "float" },
    "umidade":      { "type": "float" },
    "sensor_id":    { "type": "keyword" },
    "localizacao":  { "type": "keyword" }
  }}
}'

# ── dados-financeiros ─────────────────────────────────────────────────────────
create_index "dados-financeiros" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "data":                { "type": "date" },
    "ativo":               { "type": "keyword" },
    "retorno_percentual":  { "type": "float" },
    "preco_abertura":      { "type": "float" },
    "preco_fechamento":    { "type": "float" },
    "volume":              { "type": "long" }
  }}
}'

# ── avaliacoes-clientes ───────────────────────────────────────────────────────
create_index "avaliacoes-clientes" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "data_avaliacao":   { "type": "date" },
    "nota_satisfacao":  { "type": "float" },
    "comentario":       { "type": "text", "analyzer": "portuguese" },
    "produto":          { "type": "keyword" },
    "cliente_id":       { "type": "keyword" },
    "canal":            { "type": "keyword" }
  }}
}'

# ── analytics-website ────────────────────────────────────────────────────────
create_index "analytics-website" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "timestamp":   { "type": "date" },
    "visitantes":  { "type": "integer" },
    "sessoes":     { "type": "integer" },
    "pagina":      { "type": "keyword" },
    "dispositivo": { "type": "keyword" },
    "pais":        { "type": "keyword" }
  }}
}'

# ── system-health ─────────────────────────────────────────────────────────────
create_index "system-health" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "timestamp":       { "type": "date" },
    "cpu_percentage":  { "type": "float" },
    "memoria_mb":      { "type": "integer" },
    "disco_usado_mb":  { "type": "integer" },
    "host":            { "type": "keyword" },
    "servico":         { "type": "keyword" }
  }}
}'

# ── product-reviews ───────────────────────────────────────────────────────────
create_index "product-reviews" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "product_id":    { "type": "keyword" },
    "rating":        { "type": "float" },
    "texto_review":  { "type": "text" },
    "data_avaliacao":{ "type": "date" },
    "verificado":    { "type": "boolean" },
    "helpful_votes": { "type": "integer" }
  }}
}'

# ── abandoned-carts ───────────────────────────────────────────────────────────
create_index "abandoned-carts" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "customer_id":              { "type": "keyword" },
    "valor_carrinho":           { "type": "float" },
    "items_count":              { "type": "integer" },
    "tempo_sessao_minutos":     { "type": "integer" },
    "data_abandono":            { "type": "date" },
    "categoria_principal":      { "type": "keyword" }
  }}
}'

# ── transacoes-financeiras ────────────────────────────────────────────────────
create_index "transacoes-financeiras" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "cliente_id":    { "type": "keyword" },
    "valor":         { "type": "float" },
    "lucro":         { "type": "float" },
    "data":          { "type": "date" },
    "tipo_produto":  { "type": "keyword" },
    "status":        { "type": "keyword" }
  }}
}'

# ─────────────────────────────────────────────
# Carregar dados
# ─────────────────────────────────────────────
echo ""
echo "  Carregando dados (arquivo grande, aguarde)..."
$CURL -X POST "${OPENSEARCH_URL}/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary @"${SCRIPT_DIR}/dados.ndjson" > /dev/null

sleep 2

echo ""
echo "  Contagem de documentos por índice:"
$CURL "${OPENSEARCH_URL}/_cat/indices/ecommerce-products,vendas,vendas-ecommerce,logs-api-2024,logs-web,sensor-iot,dados-financeiros,avaliacoes-clientes,analytics-website,system-health,product-reviews,abandoned-carts,transacoes-financeiras?v&h=index,docs.count&s=index" 2>/dev/null
echo ""
echo "--- Cap04 concluído ---"
