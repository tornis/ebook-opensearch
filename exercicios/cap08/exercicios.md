# Exercícios Práticos — Capítulo 8: Ingest Pipelines

## 📋 Preparação

### 1. Carregar dados de exemplo

```bash
cd /mnt/projetos/teste/ebook-opensearch/exercicios/cap08

# Carregar dados
bash carregar.sh load

# Verificar status
curl -sk -u admin:Admin@123456 https://localhost:9200/logs-exercicio/_count | jq '.count'
```

**Esperado:** 100 documentos carregados

---

## Exercício 1: Criar Pipeline Básico de Transformação

### Enunciado

Crie um **Ingest Pipeline** que realiza as seguintes transformações em logs simples:

1. **Adicione** o timestamp de ingestão em cada documento
2. **Converta** o campo `duration_ms` para integer (pode ser string na entrada)
3. **Calcule** um campo derivado `duration_segundos` dividindo `duration_ms` por 1000
4. **Marque** o documento como processado com um campo booleano

### Dados

Índice: `logs-exercicio`
Documentos com campos: `timestamp`, `level`, `service`, `message`, `duration_ms`, `status_code`

### Objetivo

- Criar pipeline: `transformacao-simples`
- Indexar 5 documentos teste
- Verificar transformação de tipos e campos derivados

### Solução

#### Passo 1: Criar o pipeline

```bash
curl -sk -X PUT -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/transformacao-simples \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Pipeline básico de transformação de logs",
    "processors": [
      {
        "set": {
          "field": "ingest_timestamp",
          "value": "{{ _ingest.timestamp }}"
        }
      },
      {
        "convert": {
          "field": "duration_ms",
          "type": "integer"
        }
      },
      {
        "set": {
          "field": "duration_segundos",
          "value": "{{ duracao_ms / 1000.0 }}"
        }
      },
      {
        "set": {
          "field": "processado",
          "value": true
        }
      }
    ]
  }'
```

#### Passo 2: Indexar documentos com o pipeline

```bash
# Documento 1
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-ex1/_doc?pipeline=transformacao-simples \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2025-03-10T14:30:00Z",
    "level": "INFO",
    "service": "api-server",
    "message": "Request processed",
    "duration_ms": "150",
    "status_code": 200
  }'

# Documento 2
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-ex1/_doc?pipeline=transformacao-simples \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2025-03-10T14:30:01Z",
    "level": "ERROR",
    "service": "database",
    "message": "Connection timeout",
    "duration_ms": "5000",
    "status_code": 500
  }'
```

#### Passo 3: Verificar documento transformado

```bash
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-ex1/_search | jq '.hits.hits[0]._source'
```

**Resultado esperado:**
```json
{
  "timestamp": "2025-03-10T14:30:00Z",
  "level": "INFO",
  "service": "api-server",
  "message": "Request processed",
  "duration_ms": 150,
  "status_code": 200,
  "ingest_timestamp": "2025-03-10T14:30:45.123Z",
  "duration_segundos": 0.15,
  "processado": true
}
```

---

## Exercício 2: Parsing com Grok

### Enunciado

Crie um pipeline que **extrai campos de logs em formato estruturado**:

1. **Parse** logs com padrão: `[NIVEL] SERVIÇO - MENSAGEM`
2. **Extraia** os campos `nivel`, `servico`, `mensagem`
3. **Normalize** o nível para minúsculas
4. **Trate erros** se o padrão não corresponder

### Dados

Formato de entrada: `[INFO] api-server - Request received successfully`

### Objetivo

- Criar pipeline: `parsing-estruturado`
- Extrair 3 campos corretamente
- Testar com dados válidos e inválidos

### Solução

#### Passo 1: Criar pipeline com Grok

```bash
curl -sk -X PUT -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/parsing-estruturado \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Pipeline de parsing com Grok",
    "processors": [
      {
        "grok": {
          "field": "raw_message",
          "patterns": ["\\[%{WORD:nivel_original}\\] %{DATA:servico} - %{GREEDYDATA:mensagem}"],
          "on_failure": [
            {
              "set": {
                "field": "grok_error",
                "value": "Padrão não correspondeu"
              }
            }
          ]
        }
      },
      {
        "lowercase": {
          "field": "nivel_original",
          "target_field": "nivel"
        }
      },
      {
        "remove": {
          "field": "nivel_original",
          "if": "ctx.grok_error == null"
        }
      }
    ]
  }'
```

#### Passo 2: Testar com documentos

```bash
# Log válido
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-ex2/_doc?pipeline=parsing-estruturado \
  -H "Content-Type: application/json" \
  -d '{
    "raw_message": "[INFO] api-server - Request received successfully"
  }'

# Log inválido (sem estrutura)
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-ex2/_doc?pipeline=parsing-estruturado \
  -H "Content-Type: application/json" \
  -d '{
    "raw_message": "LOG SEM ESTRUTURA VÁLIDA"
  }'
```

#### Passo 3: Verificar resultado

```bash
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-ex2/_search | jq '.hits.hits[] | ._source | {raw_message, nivel, servico, mensagem, grok_error}'
```

**Resultado esperado para log válido:**
```json
{
  "raw_message": "[INFO] api-server - Request received successfully",
  "nivel": "info",
  "servico": "api-server",
  "mensagem": "Request received successfully"
}
```

---

## Exercício 3: Enriquecimento Condicional

### Enunciado

Crie um pipeline que **enriquece documentos com campos derivados** baseado em lógica condicional:

1. **Mapeie** níveis de severidade para valores numéricos (DEBUG=10, INFO=20, WARN=30, ERROR=40)
2. **Marque** como `eh_critico: true` se `status_code >= 500`
3. **Categorize** erro entre cliente, servidor ou sem erro
4. **Gere** uma mensagem de alerta se for crítico

### Objetivo

- Criar pipeline: `enriquecimento-condicional`
- Indexar logs com diferentes níveis e status
- Verificar categorização e alertas

### Solução

#### Passo 1: Criar pipeline com lógica condicional

```bash
curl -sk -X PUT -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/enriquecimento-condicional \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Pipeline com enriquecimento condicional",
    "processors": [
      {
        "set": {
          "field": "severidade_num",
          "value": 10,
          "if": "ctx.level == '\''DEBUG'\''"
        }
      },
      {
        "set": {
          "field": "severidade_num",
          "value": 20,
          "if": "ctx.level == '\''INFO'\''"
        }
      },
      {
        "set": {
          "field": "severidade_num",
          "value": 30,
          "if": "ctx.level == '\''WARN'\''"
        }
      },
      {
        "set": {
          "field": "severidade_num",
          "value": 40,
          "if": "ctx.level == '\''ERROR'\''"
        }
      },
      {
        "set": {
          "field": "eh_critico",
          "value": true,
          "if": "ctx.status_code >= 500"
        }
      },
      {
        "set": {
          "field": "eh_critico",
          "value": false,
          "if": "ctx.status_code < 500"
        }
      },
      {
        "set": {
          "field": "tipo_erro",
          "value": "cliente",
          "if": "ctx.status_code >= 400 && ctx.status_code < 500"
        }
      },
      {
        "set": {
          "field": "tipo_erro",
          "value": "servidor",
          "if": "ctx.status_code >= 500"
        }
      },
      {
        "set": {
          "field": "tipo_erro",
          "value": "nenhum",
          "if": "ctx.status_code < 400"
        }
      },
      {
        "set": {
          "field": "alerta",
          "value": "ALERTA: {{ service }} falhou com {{ message }}",
          "if": "ctx.eh_critico"
        }
      }
    ]
  }'
```

#### Passo 2: Indexar documentos variados

```bash
# Log sucesso
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-ex3/_doc?pipeline=enriquecimento-condicional \
  -H "Content-Type: application/json" \
  -d '{
    "level": "INFO",
    "service": "api-server",
    "message": "Request successful",
    "status_code": 200
  }'

# Log erro crítico
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-ex3/_doc?pipeline=enriquecimento-condicional \
  -H "Content-Type: application/json" \
  -d '{
    "level": "ERROR",
    "service": "database",
    "message": "Connection timeout",
    "status_code": 500
  }'
```

#### Passo 3: Análise de resultados

```bash
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-ex3/_search \
  -H "Content-Type: application/json" \
  -d '{
    "size": 10,
    "aggs": {
      "por_severidade": {
        "terms": {
          "field": "severidade_num"
        }
      },
      "criticos": {
        "terms": {
          "field": "eh_critico"
        }
      }
    }
  }' | jq '.aggregations'
```

---

## Exercício 4: Pipeline com Tratamento de Erro

### Enunciado

Crie um pipeline **robusto que trata erros em múltiplos processadores**:

1. **Parse** log com Dissect
2. **Converta** duracao_ms para integer com fallback
3. **Processe** condicionalmente baseado em sucesso/falha
4. **Limpe** campos temporários
5. **Trate** erros globais com `on_failure`

### Objetivo

- Criar pipeline: `tratamento-robusto`
- Processar logs válidos e inválidos
- Demonstrar fallback e tratamento de erro

### Solução

#### Passo 1: Criar pipeline com tratamento completo

```bash
curl -sk -X PUT -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/tratamento-robusto \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Pipeline com tratamento robusto de erros",
    "processors": [
      {
        "dissect": {
          "field": "raw",
          "pattern": "%{timestamp} [%{level}] %{service} %{duration}ms"
        }
      },
      {
        "convert": {
          "field": "duration",
          "type": "integer",
          "on_failure": [
            {
              "set": {
                "field": "duration",
                "value": 0
              }
            }
          ]
        }
      },
      {
        "set": {
          "field": "duration_segundos",
          "value": "{{ duration / 1000.0 }}"
        }
      },
      {
        "remove": {
          "field": ["raw", "timestamp"]
        }
      }
    ],
    "on_failure": [
      {
        "set": {
          "field": "erro_processamento",
          "value": true
        }
      },
      {
        "set": {
          "field": "erro_msg",
          "value": "{{ _ingest.on_failure_message }}"
        }
      }
    ]
  }'
```

#### Passo 2: Testar com sucessos e falhas

```bash
# Sucesso
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-ex4/_doc?pipeline=tratamento-robusto \
  -H "Content-Type: application/json" \
  -d '{
    "raw": "2025-03-10T14:30:00Z [INFO] api-server 145ms"
  }'

# Falha (falta de conformidade)
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-ex4/_doc?pipeline=tratamento-robusto \
  -H "Content-Type: application/json" \
  -d '{
    "raw": "MENSAGEM SEM ESTRUTURA"
  }'
```

---

## Exercício 5: Desafio Integrado — Pipeline Multi-Processador

### Enunciado

Implemente uma **solução completa** que:

1. **Receba** logs do índice `logs-exercicio`
2. **Crie** um pipeline que combina parsing, validação, enriquecimento e limpeza
3. **Indexe** em novo índice com campos transformados
4. **Valide** pipeline antes de usar com `_simulate`

### Objetivo

Criar pipeline: `solucao-integrada`
Processar e reindexar dados com múltiplas transformações

### Solução

#### Passo 1: Simular pipeline antes de usar

```bash
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/_simulate \
  -H "Content-Type: application/json" \
  -d '{
    "pipeline": {
      "processors": [
        {
          "set": {
            "field": "processado_em",
            "value": "{{ _ingest.timestamp }}"
          }
        },
        {
          "convert": {
            "field": "duration_ms",
            "type": "integer"
          }
        },
        {
          "set": {
            "field": "severidade_num",
            "value": 40,
            "if": "ctx.level == '\''ERROR'\''"
          }
        }
      ]
    },
    "docs": [
      {
        "_source": {
          "level": "ERROR",
          "service": "database",
          "duration_ms": "5000"
        }
      }
    ]
  }' | jq '.docs[0].doc._source'
```

#### Passo 2: Criar e usar pipeline

```bash
curl -sk -X PUT -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/solucao-integrada \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Pipeline integrado com múltiplas transformações",
    "processors": [
      {
        "set": {
          "field": "processado_em",
          "value": "{{ _ingest.timestamp }}"
        }
      },
      {
        "convert": {
          "field": "duration_ms",
          "type": "integer"
        }
      },
      {
        "set": {
          "field": "eh_erro",
          "value": true,
          "if": "ctx.status_code >= 400"
        }
      }
    ]
  }'

# Reindexar usando pipeline
curl -sk -X POST -u admin:Admin@123456 \
  https://localhost:9200/_reindex \
  -H "Content-Type: application/json" \
  -d '{
    "source": {
      "index": "logs-exercicio"
    },
    "dest": {
      "index": "logs-transformados",
      "pipeline": "solucao-integrada"
    }
  }'
```

#### Passo 3: Verificar resultado

```bash
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-transformados/_count | jq '.count'

curl -sk -u admin:Admin@123456 \
  https://localhost:9200/logs-transformados/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": { "term": { "eh_erro": true } },
    "size": 5
  }' | jq '.hits.hits[] | ._source'
```

---

## 🧹 Limpeza

```bash
# Remover pipelines criados
curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/transformacao-simples
curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/parsing-estruturado
curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/enriquecimento-condicional
curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/tratamento-robusto
curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/solucao-integrada

# Limpar índices
curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/logs-exercicio-*
curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/logs-transformados

# Limpar dados originais
bash carregar.sh clean
```

---

## 📚 Referências

- **Documentação Ingest Pipelines:** https://docs.opensearch.org/latest/ingest-pipelines/
- **Processadores:** https://docs.opensearch.org/latest/ingest-pipelines/processors/
- **Capítulo 8:** `capitulos/08_ingest_pipelines.md`

---

**Última atualização:** Março 2026
