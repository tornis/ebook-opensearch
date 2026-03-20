#!/bin/bash
# Exemplos de consultas ao dataset de textos

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASSWORD="${OPENSEARCH_PASSWORD:-Admin@123456}"

echo ""
echo "=================================================="
echo "🔍 Exemplos de Consultas - Dataset Temas TI"
echo "=================================================="
echo ""

# Verificar se índice existe
echo "✅ Verificando índice..."
COUNT=$(curl -sk -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" \
  "$OPENSEARCH_URL/temas-ti/_count" 2>/dev/null | grep -o '"count":[0-9]*' | cut -d: -f2)

if [ -z "$COUNT" ] || [ "$COUNT" = "0" ]; then
    echo "❌ Índice não encontrado ou vazio"
    echo ""
    echo "💡 Carregue o dataset primeiro:"
    echo "   python gerar-dataset-textos.py"
    echo "   bash carregar-dataset-textos.sh"
    exit 1
fi

echo "✅ Índice 'temas-ti' encontrado com $COUNT documentos"
echo ""

# Exemplo 1: Contar documentos
echo "1️⃣  CONTAR DOCUMENTOS"
echo "   Comando: GET /temas-ti/_count"
echo ""
curl -sk -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" \
  "$OPENSEARCH_URL/temas-ti/_count" | jq .
echo ""

# Exemplo 2: Buscar por tema
echo "2️⃣  BUSCAR DOCUMENTOS POR TEMA (OpenSearch)"
echo "   Comando: GET /temas-ti/_search"
echo ""
curl -sk -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" -X POST \
  "$OPENSEARCH_URL/temas-ti/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "term": {
        "tema": "opensearch"
      }
    },
    "size": 2,
    "_source": ["id", "tema"]
  }' | jq '.hits.hits[0:2]'
echo ""

# Exemplo 3: Buscar por tema (Elasticsearch)
echo "3️⃣  BUSCAR DOCUMENTOS POR TEMA (Elasticsearch)"
echo "   Comando: GET /temas-ti/_search"
echo ""
curl -sk -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" -X POST \
  "$OPENSEARCH_URL/temas-ti/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "term": {
        "tema": "elasticsearch"
      }
    },
    "size": 2,
    "_source": ["id", "tema"]
  }' | jq '.hits.hits[0:2]'
echo ""

# Exemplo 4: Full-text search
echo "4️⃣  BUSCA FULL-TEXT (buscar 'segurança')"
echo "   Comando: GET /temas-ti/_search"
echo ""
curl -sk -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" -X POST \
  "$OPENSEARCH_URL/temas-ti/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match": {
        "conteudo": "segurança"
      }
    },
    "size": 3,
    "_source": ["id", "tema", "conteudo"],
    "highlight": {
      "fields": {
        "conteudo": {}
      }
    }
  }' | jq '.hits.hits[0:1] | .[0] | {id, tema, encontrado: .highlight.conteudo[0:100]}'
echo ""

# Exemplo 5: Agregação por tema
echo "5️⃣  AGREGAÇÃO - CONTAR POR TEMA"
echo "   Comando: GET /temas-ti/_search (com aggregations)"
echo ""
curl -sk -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" -X POST \
  "$OPENSEARCH_URL/temas-ti/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "aggs": {
      "por_tema": {
        "terms": {
          "field": "tema",
          "size": 10
        }
      }
    },
    "size": 0
  }' | jq '.aggregations.por_tema.buckets'
echo ""

# Exemplo 6: Estatísticas de tamanho
echo "6️⃣  AGREGAÇÃO - ESTATÍSTICAS DE TAMANHO"
echo "   Comando: GET /temas-ti/_search (com stats)"
echo ""
curl -sk -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" -X POST \
  "$OPENSEARCH_URL/temas-ti/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "aggs": {
      "stats_tamanho": {
        "stats": {
          "field": "tamanho_bytes"
        }
      }
    },
    "size": 0
  }' | jq '.aggregations.stats_tamanho'
echo ""

# Exemplo 7: Busca com filtro múltiplo
echo "7️⃣  BUSCA COM FILTRO - Tema RAG e tamanho > 1000 bytes"
echo "   Comando: GET /temas-ti/_search (com bool query)"
echo ""
curl -sk -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" -X POST \
  "$OPENSEARCH_URL/temas-ti/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "must": [
          {"term": {"tema": "rag"}}
        ],
        "filter": [
          {"range": {"tamanho_bytes": {"gte": 1000}}}
        ]
      }
    },
    "size": 5,
    "_source": ["id", "tema", "tamanho_bytes"]
  }' | jq '.hits | {total: .total.value, docs: .hits[].id}'
echo ""

# Exemplo 8: Sugerir (suggestion/autocomplete)
echo "8️⃣  BUSCAR DOCUMENTOS COM PADRÃO (wildcard)"
echo "   Comando: GET /temas-ti/_search (wildcard)"
echo ""
curl -sk -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" -X POST \
  "$OPENSEARCH_URL/temas-ti/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "wildcard": {
        "conteudo": "*performance*"
      }
    },
    "size": 2,
    "_source": ["id", "tema"]
  }' | jq '.hits.hits[0:2] | .[] | {id, tema}'
echo ""

# Exemplo 9: Scroll para paginação
echo "9️⃣  BUSCAR TODOS OS DOCUMENTOS (com scroll)"
echo "   Comando: GET /temas-ti/_search?scroll=1m"
echo ""
echo "   # Primeiramente, iniciar scroll:"
SCROLL_ID=$(curl -sk -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" -X POST \
  "$OPENSEARCH_URL/temas-ti/_search?scroll=1m" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 10,
    "_source": ["id", "tema"]
  }' | jq -r '._scroll_id')

echo "   Scroll ID: $SCROLL_ID"
echo ""
echo "   # Recuperar próximas páginas:"
echo "   curl -sk -u admin:Admin@123456 -X GET \\"
echo "     https://localhost:9200/_search/scroll \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"scroll\": \"1m\", \"scroll_id\": \"$SCROLL_ID\"}'"
echo ""

# Exemplo 10: Exportar para processamento
echo "🔟 EXPORTAR DOCUMENTOS PARA PROCESSAMENTO"
echo "   Comando: GET /temas-ti/_search (formato JSON)"
echo ""
echo "   # Exportar todos os IDs:"
curl -sk -u "$OPENSEARCH_USER:$OPENSEARCH_PASSWORD" -X POST \
  "$OPENSEARCH_URL/temas-ti/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 50,
    "_source": ["id", "tema"]
  }' | jq '.hits.hits | map({id: ._id, tema: ._source.tema}) | .[]'
echo ""

echo "=================================================="
echo "✅ Exemplos Concluídos!"
echo "=================================================="
echo ""
echo "💡 Dica: Use jq para processar respostas JSON"
echo "   Exemplo: curl ... | jq '.hits.hits[] | .._source'"
echo ""
echo "📚 Referências:"
echo "   - https://docs.opensearch.org/latest/query-dsl/"
echo "   - https://docs.opensearch.org/latest/aggregations/"
echo ""
