# Exercícios Práticos — Capítulo 7: Data Prepper

## 📋 Preparação

### 1. Carregar dados de exemplo

```bash
cd /mnt/projetos/teste/ebook-opensearch/exercicios/cap07

# Carregar dados
bash carregar.sh load

# Verificar status
curl -s http://localhost:9200/logs-app-*/_count | jq '.count'
```

**Esperado:** 100 documentos carregados

---

## Exercício 1: Análise Básica de Logs

### Enunciado

Você recebeu logs estruturados de uma aplicação web. Precisa:

1. **Contar** quantos logs existem no total
2. **Agrupar** por nível de severidade (DEBUG, INFO, WARN, ERROR)
3. **Identificar** qual serviço tem mais erros

### Dados

Índice: `logs-app-*`
Total de documentos: ~100

### Objetivo

Obter estatísticas básicas dos logs:
- Total: X documentos
- INFO: X documentos
- ERROR: X documentos
- Serviço com mais erros: X

### Solução

#### Passo 1: Contar total de documentos

```bash
curl -s http://localhost:9200/logs-app-*/_count | jq '.count'
```

**Resultado esperado:** `100`

---

#### Passo 2: Contar por nível de severidade

```bash
curl -s -X POST http://localhost:9200/logs-app-*/_search \
  -H "Content-Type: application/json" \
  -d '{
    "size": 0,
    "aggs": {
      "levels": {
        "terms": {
          "field": "level",
          "size": 10
        }
      }
    }
  }' | jq '.aggregations.levels.buckets'
```

**Resultado esperado:**
```json
[
  { "key": "INFO", "doc_count": 45 },
  { "key": "ERROR", "doc_count": 15 },
  { "key": "WARN", "doc_count": 20 },
  { "key": "DEBUG", "doc_count": 20 }
]
```

---

#### Passo 3: Identificar serviço com mais erros

```bash
curl -s -X POST http://localhost:9200/logs-app-*/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match": {
        "level": "ERROR"
      }
    },
    "size": 0,
    "aggs": {
      "errors_by_service": {
        "terms": {
          "field": "service",
          "size": 10
        }
      }
    }
  }' | jq '.aggregations.errors_by_service.buckets'
```

**Resultado esperado:**
```json
[
  { "key": "database", "doc_count": 8 },
  { "key": "api-server", "doc_count": 7 }
]
```

---

## Exercício 2: Filtro Avançado e Métricas

### Enunciado

Você precisa monitorar a performance da aplicação. Faça:

1. **Filtrar** apenas logs de ERROR e WARN (problemas)
2. **Calcular** tempo médio de resposta (`duration_ms`) para cada serviço
3. **Identificar** erros críticos com status >= 500

### Objetivo

- Quantos logs de problemas (WARN + ERROR)?
- Qual serviço tem maior tempo médio de resposta?
- Quantos erros críticos (status >= 500)?

### Solução

#### Passo 1: Filtrar WARN + ERROR

```bash
curl -s -X POST http://localhost:9200/logs-app-*/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "should": [
          { "match": { "level": "ERROR" } },
          { "match": { "level": "WARN" } }
        ]
      }
    }
  }' | jq '.hits.total.value'
```

**Resultado esperado:** `~35 documentos`

---

#### Passo 2: Tempo médio por serviço

```bash
curl -s -X POST http://localhost:9200/logs-app-*/_search \
  -H "Content-Type: application/json" \
  -d '{
    "size": 0,
    "aggs": {
      "by_service": {
        "terms": {
          "field": "service",
          "size": 10
        },
        "aggs": {
          "avg_duration": {
            "avg": {
              "field": "duration_ms"
            }
          }
        }
      }
    }
  }' | jq '.aggregations.by_service.buckets[]'
```

**Resultado esperado:**
```json
{
  "key": "database",
  "doc_count": 20,
  "avg_duration": {
    "value": 2400.5
  }
},
{
  "key": "api-server",
  "doc_count": 65,
  "avg_duration": {
    "value": 450.2
  }
},
{
  "key": "cache",
  "doc_count": 8,
  "avg_duration": {
    "value": 275.1
  }
},
{
  "key": "queue",
  "doc_count": 7,
  "doc_count": 150,
  "avg_duration": {
    "value": 425.0
  }
}
```

---

#### Passo 3: Erros críticos (status >= 500)

```bash
curl -s -X POST http://localhost:9200/logs-app-*/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "range": {
        "status": {
          "gte": 500
        }
      }
    },
    "size": 100
  }' | jq '.hits.total.value'
```

**Resultado esperado:** `~5-8 erros críticos`

---

## Exercício 3: Pipeline Customizado com Data Prepper

### Enunciado

Crie um novo pipeline Data Prepper que:

1. **Receba** logs via HTTP em `/custom/ingest`
2. **Processe** com Grok: extraia service, level, message
3. **Enriqueça** adicionando timestamp de ingestão
4. **Armazene** em índice `custom-logs-%{yyyy.MM.dd}`

### Objetivo

Criar um arquivo `data-prepper/pipelines/04-custom-pipeline.yaml` funcional

### Solução

#### Criar arquivo do pipeline

```bash
cat > data-prepper/pipelines/04-custom-pipeline.yaml << 'EOF'
custom-logs-pipeline:
  source:
    http:
      port: 21000
      path: "/custom/ingest"

  processor:
    - grok:
        match:
          message: [
            "\\[%{WORD:level}\\] %{DATA:service} - %{GREEDYDATA:log_message}"
          ]

    - mutate:
        add_entries:
          - key: "ingest_timestamp"
            value: "${now()}"
          - key: "pipeline_version"
            value: "1.0"

  sink:
    - opensearch:
        hosts: ["https://opensearch:9200"]
        username: "admin"
        password: "admin"
        insecure: true
        index: "custom-logs-%{yyyy.MM.dd}"
        bulk_size: 500
        flush_interval: 30
EOF
```

---

#### Testar o pipeline

```bash
# Aguardar Data Prepper recarregar pipelines (~5 segundos)
sleep 5

# Enviar teste
curl -X POST http://localhost:21000/custom/ingest \
  -H "Content-Type: application/json" \
  -d '[
    {
      "message": "[ERROR] database - Connection timeout after 30s",
      "request_id": "req-789"
    },
    {
      "message": "[INFO] api-server - Request processed successfully",
      "request_id": "req-790"
    }
  ]'
```

---

#### Verificar dados

```bash
# Aguardar processamento
sleep 3

# Buscar documentos
curl -s http://localhost:9200/custom-logs-*/_search | jq '.hits.hits[0]._source'
```

**Resultado esperado:**
```json
{
  "message": "[ERROR] database - Connection timeout after 30s",
  "request_id": "req-789",
  "level": "ERROR",
  "service": "database",
  "log_message": "Connection timeout after 30s",
  "ingest_timestamp": 1705318245000,
  "pipeline_version": "1.0"
}
```

---

## Exercício 4: Agregação e Consolidação Multi-linha

### Enunciado

Crie um pipeline que:

1. **Agrupa** logs por `request_id` (consolidar eventos relacionados)
2. **Calcula** duração total (soma de todos `duration_ms` da mesma request)
3. **Normaliza** severidade (converte nomes para numéricos)

### Objetivo

Consolidar múltiplos logs de uma mesma request em um único documento no OpenSearch

### Solução

#### Criar pipeline com agregação

```bash
cat > data-prepper/pipelines/05-aggregate-pipeline.yaml << 'EOF'
aggregate-logs-pipeline:
  source:
    http:
      port: 21000
      path: "/aggregate/logs"

  processor:
    - grok:
        match:
          message: [
            "%{TIMESTAMP_ISO8601:log_timestamp} \\[%{WORD:level}\\] \\[%{DATA:service}\\] - %{GREEDYDATA:log_message}"
          ]

    - mutate:
        rename_keys:
          "level": "severity_level"
        convert:
          duration_ms: "integer"
        add_entries:
          - key: "severity_numeric"
            value: |
              ${
                severity_level == 'ERROR' ? 40 :
                severity_level == 'WARN' ? 30 :
                severity_level == 'INFO' ? 20 :
                severity_level == 'DEBUG' ? 10 : 0
              }

    - date:
        match:
          log_timestamp:
            - "ISO8601"
        destination: "@timestamp"

    - aggregate:
        identification_keys:
          - request_id
        timeout_duration: 15
        action:
          type: "put_all"
          key: "aggregated_events"
        group_duration_ms: 60000

  sink:
    - opensearch:
        hosts: ["https://opensearch:9200"]
        username: "admin"
        password: "admin"
        insecure: true
        index: "aggregated-logs-%{yyyy.MM.dd}"
        bulk_size: 500
        flush_interval: 30
EOF
```

---

#### Testar agregação

```bash
# Aguardar reload (~5 segundos)
sleep 5

# Enviar logs relacionados (mesmo request_id)
curl -X POST http://localhost:21000/aggregate/logs \
  -H "Content-Type: application/json" \
  -d '[
    {
      "message": "2025-01-15T10:30:45.100Z [INFO] [api-server] - Request started",
      "request_id": "req-555",
      "duration_ms": 10
    },
    {
      "message": "2025-01-15T10:30:45.200Z [INFO] [database] - Query executed",
      "request_id": "req-555",
      "duration_ms": 50
    },
    {
      "message": "2025-01-15T10:30:45.300Z [INFO] [api-server] - Response sent",
      "request_id": "req-555",
      "duration_ms": 5
    }
  ]'
```

---

#### Verificar consolidação

```bash
# Aguardar processamento
sleep 5

# Buscar documentos consolidados
curl -s http://localhost:9200/aggregated-logs-*/_search | jq '.hits.hits[0]._source'
```

**Resultado esperado:**
```json
{
  "request_id": "req-555",
  "aggregated_events": [
    {
      "message": "2025-01-15T10:30:45.100Z [INFO] [api-server] - Request started",
      "duration_ms": 10
    },
    {
      "message": "2025-01-15T10:30:45.200Z [INFO] [database] - Query executed",
      "duration_ms": 50
    },
    {
      "message": "2025-01-15T10:30:45.300Z [INFO] [api-server] - Response sent",
      "duration_ms": 5
    }
  ],
  "@timestamp": "2025-01-15T10:30:45.100Z"
}
```

---

## Exercício 5: Desafio Integrado

### Enunciado

Implemente uma solução completa que:

1. **Ingerir** logs via Fluent Bit (coleta de containers)
2. **Processar** com Data Prepper (múltiplos stages)
3. **Enriquecer** com dados de contexto
4. **Armazenar** em OpenSearch com índices por severidade

### Objetivo

Criar um pipeline production-ready com:
- Hot reload habilitado
- Buffer persistente em disco
- Métricas Prometheus
- Tratamento de erros com retry

### Solução Sugerida

#### 1. Atualizar docker-compose para Fluent Bit

Consulte arquivo existente: `exercicios/cap07/docker-compose-exercise.yml`

#### 2. Criar pipeline robusto

```bash
cat > data-prepper/pipelines/06-production-pipeline.yaml << 'EOF'
production-logs-pipeline:
  # Receber de múltiplas fontes
  source:
    http:
      port: 21000
      path: "/prod/logs"

  processor:
    # 1. Parse estruturado
    - grok:
        match:
          message: [
            "%{TIMESTAMP_ISO8601:timestamp} \\[%{WORD:level}\\] \\[%{DATA:component}\\] - %{GREEDYDATA:message}"
          ]

    # 2. Enriquecimento
    - mutate:
        add_entries:
          - key: "environment"
            value: "production"
          - key: "ingest_node"
            value: "data-prepper-1"
          - key: "ingested_at"
            value: "${now()}"

    # 3. Normalização
    - date:
        match:
          timestamp:
            - "ISO8601"
        destination: "@timestamp"

  sink:
    # Multi-sink: enviar para diferentes índices
    - opensearch:
        hosts: ["https://opensearch:9200"]
        username: "admin"
        password: "admin"
        insecure: true

        # Índice condicional por severidade
        index: |
          ${
            level == 'ERROR' ? 'prod-errors-%{yyyy.MM.dd}' :
            level == 'WARN' ? 'prod-warnings-%{yyyy.MM.dd}' :
            'prod-logs-%{yyyy.MM.dd}'
          }

        # Performance
        bulk_size: 1000
        flush_interval: 10

        # Resiliência
        max_retries: 5
        retry_delay: 2000

        # Conexão
        connection_timeout: 5000
        read_timeout: 30000
EOF
```

#### 3. Verificar métricas Prometheus

```bash
curl -s http://localhost:9090/metrics | grep data_prepper
```

#### 4. Testar com carga

```bash
# Script de teste com múltiplas requisições
for i in {1..100}; do
  curl -X POST http://localhost:21000/prod/logs \
    -H "Content-Type: application/json" \
    -d '[
      {
        "message": "2025-01-15T10:30:45.100Z [INFO] [worker-'$i'] - Processing item '$i'",
        "request_id": "req-'$i'"
      }
    ]' &
done

wait
```

#### 5. Validar índices separados

```bash
# Verificar índices criados
curl -s http://localhost:9200/_cat/indices | grep prod-

# Contar por severidade
curl -s http://localhost:9200/prod-errors-*/_count | jq '.count'
curl -s http://localhost:9200/prod-warnings-*/_count | jq '.count'
curl -s http://localhost:9200/prod-logs-*/_count | jq '.count'
```

---

## 🧹 Limpeza

```bash
# Remover pipelines customizados
rm -f data-prepper/pipelines/04-custom-pipeline.yaml
rm -f data-prepper/pipelines/05-aggregate-pipeline.yaml
rm -f data-prepper/pipelines/06-production-pipeline.yaml

# Limpar índices
curl -X DELETE http://localhost:9200/custom-logs-*
curl -X DELETE http://localhost:9200/aggregated-logs-*
curl -X DELETE http://localhost:9200/prod-*

# Limpar dados originais
bash carregar.sh clean
```

---

## 📚 Referências

- **Documentação Data Prepper:** https://docs.opensearch.org/latest/data-prepper/
- **Grok Patterns:** https://github.com/elastic/logstash/blob/main/patterns/grok-patterns
- **Query DSL OpenSearch:** https://docs.opensearch.org/latest/query-dsl/
- **Capítulo 7:** `capitulos/07_data_prepper_ingestao.md`

---

**Última atualização:** Março 2026
