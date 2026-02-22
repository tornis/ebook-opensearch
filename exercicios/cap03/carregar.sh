#!/bin/bash
# =============================================================================
# cap03/carregar.sh — Datasets do Capítulo 3: Query DSL e PPL
# Índices: articles, users, documents, products, events, store, news,
#          job-listings, blog, api-logs, application-logs, orders, logs,
#          customer-interactions, transactions, metrics, e-commerce,
#          sales, error-logs
# =============================================================================

OPENSEARCH_URL="https://localhost:9200"
OPENSEARCH_USER="admin"
OPENSEARCH_PASS="<SENHA_ADMIN>"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURL="curl -sk -u ${OPENSEARCH_USER}:${OPENSEARCH_PASS}"

echo "--- Capítulo 3: Query DSL e PPL ---"

# Helper para criar índice
create_index() {
  local name=$1
  local body=$2
  $CURL -X DELETE "${OPENSEARCH_URL}/${name}" > /dev/null 2>&1 || true
  $CURL -X PUT "${OPENSEARCH_URL}/${name}" \
    -H "Content-Type: application/json" \
    -d "$body" > /dev/null
  echo "  [OK] Índice '${name}' criado."
}

# ── articles ──────────────────────────────────────────────────────────────────
create_index "articles" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "title":           { "type": "text" },
    "content":         { "type": "text" },
    "author":          { "type": "keyword" },
    "author_verified": { "type": "boolean" },
    "publish_date":    { "type": "date" },
    "category":        { "type": "keyword" },
    "views":           { "type": "integer" }
  }}
}'

# ── users (English — fuzziness, term queries) ─────────────────────────────────
create_index "users" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "user_id":  { "type": "keyword" },
    "name":     { "type": "text" },
    "email":    { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
    "age":      { "type": "integer" },
    "active":   { "type": "boolean" }
  }}
}'

# ── documents ─────────────────────────────────────────────────────────────────
create_index "documents" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "title":    { "type": "text" },
    "abstract": { "type": "text" },
    "content":  { "type": "text" },
    "author":   { "type": "keyword" },
    "category": { "type": "keyword" },
    "published":{ "type": "date" }
  }}
}'

# ── products (English — term/range/bool queries) ──────────────────────────────
create_index "products" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "name":               { "type": "text" },
    "description":        { "type": "text" },
    "brand":              { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
    "category":           { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
    "price":              { "type": "float" },
    "rating":             { "type": "float" },
    "available":          { "type": "boolean" },
    "in_stock":           { "type": "boolean" },
    "warranty":           { "type": "keyword" },
    "discontinued_date":  { "type": "date" }
  }}
}'

# ── events ────────────────────────────────────────────────────────────────────
create_index "events" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "title":       { "type": "text" },
    "description": { "type": "text" },
    "location":    { "type": "keyword" },
    "event_date":  { "type": "date", "format": "yyyy-MM-dd" },
    "category":    { "type": "keyword" },
    "capacity":    { "type": "integer" }
  }}
}'

# ── store (bool complexo — Dell laptops) ──────────────────────────────────────
create_index "store" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "product_name": { "type": "text" },
    "description":  { "type": "text" },
    "brand":        { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
    "price":        { "type": "float" },
    "rating":       { "type": "float" },
    "in_stock":     { "type": "boolean" },
    "category":     { "type": "keyword" }
  }}
}'

# ── news ──────────────────────────────────────────────────────────────────────
create_index "news" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "title":     { "type": "text" },
    "content":   { "type": "text" },
    "author":    { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
    "category":  { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
    "published": { "type": "date" }
  }}
}'

# ── job-listings ──────────────────────────────────────────────────────────────
create_index "job-listings" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "title":       { "type": "text" },
    "company":     { "type": "keyword" },
    "location":    { "type": "keyword" },
    "salary_min":  { "type": "integer" },
    "salary_max":  { "type": "integer" },
    "remote":      { "type": "boolean" },
    "posted_date": { "type": "date" }
  }}
}'

# ── blog (bool must: match + range de views) ──────────────────────────────────
create_index "blog" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "title":   { "type": "text" },
    "content": { "type": "text" },
    "author":  { "type": "keyword" },
    "views":   { "type": "integer" },
    "tags":    { "type": "keyword" },
    "date":    { "type": "date" }
  }}
}'

# ── api-logs ──────────────────────────────────────────────────────────────────
create_index "api-logs" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "timestamp":     { "type": "date" },
    "endpoint":      { "type": "keyword" },
    "status_code":   { "type": "integer" },
    "response_time": { "type": "integer" },
    "service":       { "type": "keyword" },
    "method":        { "type": "keyword" },
    "user_id":       { "type": "keyword" }
  }}
}'

# ── application-logs (PPL pipeline complexo) ──────────────────────────────────
create_index "application-logs" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "timestamp":     { "type": "date" },
    "service":       { "type": "keyword" },
    "environment":   { "type": "keyword" },
    "response_time": { "type": "integer" },
    "user_id":       { "type": "keyword" },
    "error_flag":    { "type": "integer" },
    "level":         { "type": "keyword" },
    "message":       { "type": "text" }
  }}
}'

# ── orders (PPL where complexo) ───────────────────────────────────────────────
create_index "orders" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "order_id":          { "type": "keyword" },
    "status":            { "type": "keyword" },
    "order_total":       { "type": "float" },
    "customer_verified": { "type": "boolean" },
    "customer_id":       { "type": "keyword" },
    "items_count":       { "type": "integer" },
    "created_at":        { "type": "date" }
  }}
}'

# ── logs (PPL: fields, where, dedup, fillnull, rare) ─────────────────────────
create_index "logs" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "timestamp":    { "type": "date" },
    "level":        { "type": "keyword" },
    "message":      { "type": "text" },
    "service_name": { "type": "keyword" },
    "user_id":      { "type": "keyword" },
    "status_code":  { "type": "integer" }
  }}
}'

# ── customer-interactions (exercício 4.1) ─────────────────────────────────────
create_index "customer-interactions" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "timestamp":        { "type": "date" },
    "customer_id":      { "type": "keyword" },
    "interaction_type": { "type": "keyword" },
    "duration_seconds": { "type": "integer" },
    "resolved":         { "type": "boolean" },
    "department":       { "type": "keyword" }
  }}
}'

# ── transactions (dedup demo) ─────────────────────────────────────────────────
create_index "transactions" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "user_id":          { "type": "keyword" },
    "transaction_type": { "type": "keyword" },
    "amount":           { "type": "float" },
    "created_at":       { "type": "date" }
  }}
}'

# ── metrics (PPL análise temporal) ────────────────────────────────────────────
create_index "metrics" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "timestamp":    { "type": "date" },
    "cpu_usage":    { "type": "float" },
    "memory_usage": { "type": "float" },
    "disk_io":      { "type": "float" },
    "server_type":  { "type": "keyword" },
    "host":         { "type": "keyword" }
  }}
}'

# ── e-commerce (PPL eval múltiplo) ────────────────────────────────────────────
create_index "e-commerce" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "product_name":   { "type": "text" },
    "original_price": { "type": "float" },
    "final_price":    { "type": "float" },
    "order_date":     { "type": "date" },
    "delivery_date":  { "type": "date" },
    "order_status":   { "type": "keyword" },
    "customer_id":    { "type": "keyword" }
  }}
}'

# ── sales (PPL eval profit, sort) ─────────────────────────────────────────────
create_index "sales" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "product":    { "type": "keyword" },
    "revenue":    { "type": "float" },
    "cost":       { "type": "float" },
    "region":     { "type": "keyword" },
    "salesperson":{ "type": "keyword" },
    "amount":     { "type": "float" },
    "sale_date":  { "type": "date" }
  }}
}'

# ── error-logs (PPL error pattern detection) ──────────────────────────────────
create_index "error-logs" '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": { "properties": {
    "timestamp":  { "type": "date" },
    "level":      { "type": "keyword" },
    "host":       { "type": "keyword" },
    "service":    { "type": "keyword" },
    "error_type": { "type": "keyword" },
    "message":    { "type": "text" }
  }}
}'

# ─────────────────────────────────────────────
# Carregar dados via bulk
# ─────────────────────────────────────────────
echo ""
echo "  Carregando dados (arquivo grande, aguarde)..."
$CURL -X POST "${OPENSEARCH_URL}/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary @"${SCRIPT_DIR}/dados.ndjson" > /dev/null

sleep 2

echo ""
echo "  Contagem de documentos por índice:"
$CURL "${OPENSEARCH_URL}/_cat/indices/articles,users,documents,products,events,store,news,job-listings,blog,api-logs,application-logs,orders,logs,customer-interactions,transactions,metrics,e-commerce,sales,error-logs?v&h=index,docs.count&s=index" 2>/dev/null
echo ""
echo "--- Cap03 concluído ---"
