#!/bin/bash
# =============================================================================
# cap04/testes.sh — Testes de Agregações com customer_transactions
# Valida todos os tipos de agregações apresentados no Capítulo 4
# =============================================================================

OPENSEARCH_URL="https://localhost:9200"
OPENSEARCH_USER="admin"
OPENSEARCH_PASS="Admin#123456"
INDEX_NAME="customer_transactions"

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contadores
PASSED=0
FAILED=0
TESTS=()

# Função para executar teste
test_aggregation() {
    local name="$1"
    local query="$2"
    local check_field="$3"

    echo -n "🧪 Testando: $name ... "

    response=$(curl -s -k -u "$OPENSEARCH_USER:$OPENSEARCH_PASS" \
        -X POST "$OPENSEARCH_URL/$INDEX_NAME/_search" \
        -H "Content-Type: application/json" \
        -d "$query")

    # Verificar se tem agregações na resposta
    if echo "$response" | grep -q "\"aggregations\""; then
        # Verificar se tem o campo esperado
        if echo "$response" | grep -q "$check_field"; then
            echo -e "${GREEN}✅ PASSOU${NC}"
            PASSED=$((PASSED + 1))
            TESTS+=("| $name | ✅ PASSOU | - |")
        else
            echo -e "${RED}❌ FALHOU${NC} (campo '$check_field' não encontrado)"
            FAILED=$((FAILED + 1))
            TESTS+=("| $name | ❌ FALHOU | Campo '$check_field' não encontrado |")
        fi
    else
        echo -e "${RED}❌ FALHOU${NC} (sem agregações na resposta)"
        FAILED=$((FAILED + 1))
        TESTS+=("| $name | ❌ FALHOU | Sem agregações na resposta |")
    fi
}

echo "═══════════════════════════════════════════════════════════════════"
echo "  Testes de Agregações - Índice: customer_transactions"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# METRICS AGGREGATIONS
# ─────────────────────────────────────────────────────────────────────────────

echo "📊 METRICS AGGREGATIONS"
echo "─────────────────────────────────────────────────────────────────"

# Teste 1: Average (Transação Média)
test_aggregation "Average Aggregation" \
'{
  "size": 0,
  "aggs": {
    "transacao_media": {
      "avg": {
        "field": "transaction_amount"
      }
    }
  }
}' \
"transacao_media"

# Teste 2: Sum (Valor Total)
test_aggregation "Sum Aggregation" \
'{
  "size": 0,
  "aggs": {
    "valor_total": {
      "sum": {
        "field": "transaction_amount"
      }
    }
  }
}' \
"valor_total"

# Teste 3: Stats (Estatísticas Completas)
test_aggregation "Stats Aggregation" \
'{
  "size": 0,
  "aggs": {
    "transaction_stats": {
      "stats": {
        "field": "transaction_amount"
      }
    }
  }
}' \
"\"count\""

# Teste 4: Min e Max
test_aggregation "Min/Max Aggregation" \
'{
  "size": 0,
  "aggs": {
    "transacao_minima": {
      "min": {
        "field": "transaction_amount"
      }
    },
    "transacao_maxima": {
      "max": {
        "field": "transaction_amount"
      }
    }
  }
}' \
"transacao_minima"

# Teste 5: Extended Stats
test_aggregation "Extended Stats Aggregation" \
'{
  "size": 0,
  "aggs": {
    "extended_stats": {
      "extended_stats": {
        "field": "transaction_amount"
      }
    }
  }
}' \
"\"std_deviation\""

# Teste 6: Cardinality (Clientes Únicos)
test_aggregation "Cardinality Aggregation" \
'{
  "size": 0,
  "aggs": {
    "clientes_unicos": {
      "cardinality": {
        "field": "customer_id"
      }
    }
  }
}' \
"clientes_unicos"

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# BUCKET AGGREGATIONS
# ─────────────────────────────────────────────────────────────────────────────

echo "📊 BUCKET AGGREGATIONS"
echo "─────────────────────────────────────────────────────────────────"

# Teste 7: Terms (Categorias)
test_aggregation "Terms Aggregation (Categorias)" \
'{
  "size": 0,
  "aggs": {
    "por_categoria": {
      "terms": {
        "field": "category",
        "size": 10
      }
    }
  }
}' \
"por_categoria"

# Teste 8: Terms com Sub-aggregation
test_aggregation "Terms com Sub-aggregation (Categoria + Valor Médio)" \
'{
  "size": 0,
  "aggs": {
    "por_categoria": {
      "terms": {
        "field": "category",
        "size": 10
      },
      "aggs": {
        "valor_medio": {
          "avg": {
            "field": "transaction_amount"
          }
        }
      }
    }
  }
}' \
"valor_medio"

# Teste 9: Date Histogram (Transações por Dia)
test_aggregation "Date Histogram Aggregation" \
'{
  "size": 0,
  "aggs": {
    "transacoes_diarias": {
      "date_histogram": {
        "field": "date",
        "calendar_interval": "day",
        "min_doc_count": 1
      }
    }
  }
}' \
"transacoes_diarias"

# Teste 10: Date Histogram com Sub-aggregation
test_aggregation "Date Histogram com Sum (Total Diário)" \
'{
  "size": 0,
  "aggs": {
    "transacoes_diarias": {
      "date_histogram": {
        "field": "date",
        "calendar_interval": "day",
        "min_doc_count": 1
      },
      "aggs": {
        "total_dia": {
          "sum": {
            "field": "transaction_amount"
          }
        }
      }
    }
  }
}' \
"total_dia"

# Teste 11: Histogram (Intervalo Numérico)
test_aggregation "Histogram Aggregation (Faixas de Valor)" \
'{
  "size": 0,
  "aggs": {
    "faixas_transacao": {
      "histogram": {
        "field": "transaction_amount",
        "interval": 100,
        "min_doc_count": 1
      }
    }
  }
}' \
"faixas_transacao"

# Teste 12: Range (Ranges Customizados)
test_aggregation "Range Aggregation (Faixas Customizadas)" \
'{
  "size": 0,
  "aggs": {
    "faixas_valor": {
      "range": {
        "field": "transaction_amount",
        "ranges": [
          { "to": 50 },
          { "from": 50, "to": 200 },
          { "from": 200, "to": 500 },
          { "from": 500 }
        ]
      },
      "aggs": {
        "quantidade": {
          "value_count": {
            "field": "_id"
          }
        }
      }
    }
  }
}' \
"quantidade"

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# NESTED & COMPLEX AGGREGATIONS
# ─────────────────────────────────────────────────────────────────────────────

echo "📊 NESTED & COMPLEX AGGREGATIONS"
echo "─────────────────────────────────────────────────────────────────"

# Teste 13: Múltiplos níveis de Terms (Categoria + Merchant)
test_aggregation "Multi-level Terms (Categoria > Merchant)" \
'{
  "size": 0,
  "aggs": {
    "por_categoria": {
      "terms": {
        "field": "category",
        "size": 5
      },
      "aggs": {
        "por_merchant": {
          "terms": {
            "field": "merchant_name.keyword",
            "size": 5
          },
          "aggs": {
            "valor_total": {
              "sum": {
                "field": "transaction_amount"
              }
            }
          }
        }
      }
    }
  }
}' \
"valor_total"

# Teste 14: Filter Aggregation
test_aggregation "Filter Aggregation (Transações Altas)" \
'{
  "size": 0,
  "aggs": {
    "transacoes_altas": {
      "filter": {
        "range": {
          "transaction_amount": {
            "gte": 500
          }
        }
      },
      "aggs": {
        "valor_total_alto": {
          "sum": {
            "field": "transaction_amount"
          }
        },
        "quantidade_alta": {
          "value_count": {
            "field": "_id"
          }
        }
      }
    }
  }
}' \
"valor_total_alto"

# Teste 15: Temporal + Categoria
test_aggregation "Date Histogram + Terms (Dia > Categoria)" \
'{
  "size": 0,
  "aggs": {
    "por_dia": {
      "date_histogram": {
        "field": "date",
        "calendar_interval": "week",
        "min_doc_count": 1
      },
      "aggs": {
        "por_categoria": {
          "terms": {
            "field": "category",
            "size": 5
          },
          "aggs": {
            "valor": {
              "sum": {
                "field": "transaction_amount"
              }
            }
          }
        }
      }
    }
  }
}' \
"valor"

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# PIPELINE AGGREGATIONS
# ─────────────────────────────────────────────────────────────────────────────

echo "📊 PIPELINE AGGREGATIONS"
echo "─────────────────────────────────────────────────────────────────"

# Teste 16: Derivative (Taxa de Variação)
test_aggregation "Derivative Aggregation (Tendência Diária)" \
'{
  "size": 0,
  "aggs": {
    "transacoes_diarias": {
      "date_histogram": {
        "field": "date",
        "calendar_interval": "day",
        "min_doc_count": 1
      },
      "aggs": {
        "total_dia": {
          "sum": {
            "field": "transaction_amount"
          }
        },
        "variacao_dia_anterior": {
          "derivative": {
            "buckets_path": "total_dia"
          }
        }
      }
    }
  }
}' \
"variacao_dia_anterior"

# Teste 17: Moving Average
test_aggregation "Moving Average Aggregation (Média Móvel)" \
'{
  "size": 0,
  "aggs": {
    "transacoes_diarias": {
      "date_histogram": {
        "field": "date",
        "calendar_interval": "day",
        "min_doc_count": 1
      },
      "aggs": {
        "valor_dia": {
          "sum": {
            "field": "transaction_amount"
          }
        },
        "media_movel_7d": {
          "moving_avg": {
            "buckets_path": "valor_dia",
            "window": 7
          }
        }
      }
    }
  }
}' \
"media_movel_7d"

# Teste 18: Bucket Sort (Top Buckets)
test_aggregation "Bucket Sort (Top 3 Categorias)" \
'{
  "size": 0,
  "aggs": {
    "por_categoria": {
      "terms": {
        "field": "category",
        "size": 100
      },
      "aggs": {
        "valor_total": {
          "sum": {
            "field": "transaction_amount"
          }
        }
      }
    },
    "top_categorias": {
      "bucket_sort": {
        "buckets_path": "por_categoria",
        "size": 3
      }
    }
  }
}' \
"bucket_sort"

# Teste 19: Percentiles Bucket
test_aggregation "Percentiles Bucket (Distribuição de Valores)" \
'{
  "size": 0,
  "aggs": {
    "por_categoria": {
      "terms": {
        "field": "category",
        "size": 10
      },
      "aggs": {
        "valor_total": {
          "sum": {
            "field": "transaction_amount"
          }
        }
      }
    },
    "percentis_valor": {
      "percentiles_bucket": {
        "buckets_path": "por_categoria>valor_total",
        "percents": [25, 50, 75, 90, 95]
      }
    }
  }
}' \
"percentis_valor"

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# COMPLEX BUSINESS CASES
# ─────────────────────────────────────────────────────────────────────────────

echo "📊 BUSINESS INTELLIGENCE CASES"
echo "─────────────────────────────────────────────────────────────────"

# Teste 20: Dashboard KPI Completo
test_aggregation "KPI Dashboard (Métrica + Distribuição)" \
'{
  "size": 0,
  "aggs": {
    "metricas_gerais": {
      "aggs": {
        "valor_total": {
          "sum": {
            "field": "transaction_amount"
          }
        },
        "transacoes_total": {
          "value_count": {
            "field": "_id"
          }
        },
        "valor_medio": {
          "avg": {
            "field": "transaction_amount"
          }
        }
      }
    },
    "distribuicao_categoria": {
      "terms": {
        "field": "category",
        "size": 10
      },
      "aggs": {
        "valor": {
          "sum": {
            "field": "transaction_amount"
          }
        },
        "quantidade": {
          "value_count": {
            "field": "_id"
          }
        }
      }
    },
    "por_faixa_valor": {
      "range": {
        "field": "transaction_amount",
        "ranges": [
          { "to": 100 },
          { "from": 100, "to": 500 },
          { "from": 500 }
        ]
      },
      "aggs": {
        "count": {
          "value_count": {
            "field": "_id"
          }
        }
      }
    }
  }
}' \
"valor_total"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  RESUMO DOS TESTES"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Total de Testes: $((PASSED + FAILED))"
echo -e "Passou: ${GREEN}${PASSED}${NC}"
echo -e "Falhou: ${RED}${FAILED}${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ TODOS OS TESTES PASSARAM!${NC}"
    exit 0
else
    echo -e "${RED}❌ ALGUNS TESTES FALHARAM${NC}"
    exit 1
fi
