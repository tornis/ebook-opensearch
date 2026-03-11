# Exemplos Práticos — Capítulo 7: Data Prepper

Exemplos executáveis de uso do **Data Prepper 3.5** com **OpenSearch 3.5**.

## 📋 Estrutura

- **docker-compose.yml** — Orquestração Data Prepper (OpenSearch externo)
- **data-prepper/config/** — Configuração do servidor Data Prepper
- **data-prepper/pipelines/** — Pipelines de processamento (HTTP, Apache, Enriched)
- **01-http-basic-logs.sh** — Script teste: ingestão JSON via HTTP
- **02-apache-logs.sh** — Script teste: parsing Apache com Grok
- **03-enriched-logs.sh** — Script teste: logs enriquecidos com agregação
- **04-fluentbit-to-dataprepper.sh** — Script teste: Fluent Bit → Data Prepper

## 🚀 Quick Start

### 1. Pré-requisito: OpenSearch já deve estar rodando

```bash
# Verificar se OpenSearch está operacional
curl -s http://localhost:9200/_cluster/health | jq .

# Se não estiver rodando, inicie:
cd ../..
docker-compose -f exemplos/docker-compose.single-node.yml up -d
```

### 2. Subir Data Prepper

```bash
cd exemplos/cap07
docker-compose up -d
```

Aguarde 10-15 segundos para Data Prepper ficar saudável.

### 3. Verificar saúde

```bash
# Data Prepper
curl -s http://localhost:21000/health | jq .

# OpenSearch
curl -s http://localhost:9200/_cluster/health | jq .

# Verificar containers
docker-compose ps
```

### 4. Executar exemplos

```bash
# Executar no diretório exemplos/cap07/

# Exemplo 1: HTTP Básico
bash 01-http-basic-logs.sh

# Exemplo 2: Apache Logs
bash 02-apache-logs.sh

# Exemplo 3: Logs Enriquecidos
bash 03-enriched-logs.sh

# Exemplo 4: Fluent Bit Integration
bash 04-fluentbit-to-dataprepper.sh
```

## 📚 Exemplos Disponíveis

### Pipeline 1: HTTP Basic Logs (01-http-basic-logs.yaml)

**Objetivo:** Ingestão simples de logs JSON estruturados via HTTP

**Características:**
- Source: HTTP porta 21000, path `/log/ingest`
- Processor: Mutate (adicionar timestamp de ingestão)
- Sink: OpenSearch índice `logs-app-*`

**Teste:**
```bash
bash 01-http-basic-logs.sh
```

**Resultado esperado:**
```json
{
  "message": "Application started successfully",
  "level": "INFO",
  "service": "api-server",
  "component": "bootstrap",
  "ingest_timestamp": 1705318245000,
  "ingest_hostname": "data-prepper",
  "pipeline_name": "log-ingestion"
}
```

---

### Pipeline 2: Apache Logs (02-apache-logs.yaml)

**Objetivo:** Parse de logs Apache com Grok patterns

**Características:**
- Source: HTTP porta 21000, path `/apache/logs`
- Processors:
  - Grok: Extrai clientip, verb, request, response, bytes, etc.
  - Date: Normaliza timestamp para ISO8601
  - Mutate: Converte tipos e adiciona campos calculados
- Sink: OpenSearch índice `apache-logs-*`

**Teste:**
```bash
bash 02-apache-logs.sh
```

**Log de entrada:**
```
192.168.1.10 - frank [01/Jan/2025:12:00:00 +0000] "GET /apache.html HTTP/1.0" 200 2326
```

**Resultado estruturado:**
```json
{
  "clientip": "192.168.1.10",
  "auth": "frank",
  "http_method_lower": "get",
  "request": "/apache.html",
  "httpversion": "1.0",
  "response": 200,
  "bytes": 2326,
  "response_category": "success",
  "bytes_kb": 2.27,
  "@timestamp": "2025-01-01T12:00:00.000Z"
}
```

---

### Pipeline 3: Enriched Logs (03-enriched-logs.yaml)

**Objetivo:** Processamento avançado com enriquecimento e agregação

**Características:**
- Source: HTTP porta 21000, path `/enriched/logs`
- Processors:
  - Grok: Parse de logs estruturados com timestamp ISO8601
  - Mutate: Normaliza severidade com valores numéricos
  - Date: Padroniza timestamp
  - Aggregate: Consolida logs multi-linha por request_id
- Sink: OpenSearch índice `app-logs-*`

**Teste:**
```bash
bash 03-enriched-logs.sh
```

**Log de entrada:**
```json
{
  "message": "2025-01-15T10:30:45.123Z [ERROR] [com.app.service] - Database connection timeout",
  "request_id": "req-12345"
}
```

**Resultado enriquecido:**
```json
{
  "message": "2025-01-15T10:30:45.123Z [ERROR] [com.app.service] - Database connection timeout",
  "request_id": "req-12345",
  "log_message": "Database connection timeout",
  "logger": "com.app.service",
  "severity_level": "ERROR",
  "severity_numeric": 40,
  "is_error": true,
  "processing_timestamp": 1705318245123,
  "@timestamp": "2025-01-15T10:30:45.123Z"
}
```

---

### Pipeline 4: Fluent Bit Integration (04-fluentbit-to-dataprepper.sh)

**Objetivo:** Integração com Fluent Bit como collector

**Pipeline:**
```
Docker Container Logs → Fluent Bit → HTTP POST → Data Prepper → OpenSearch
```

**Teste:**
```bash
bash 04-fluentbit-to-dataprepper.sh
```

---

## 📊 Verificar Dados em OpenSearch

```bash
# Listar índices criados
curl -s http://localhost:9200/_cat/indices?v

# Contar documentos
curl -s http://localhost:9200/logs-app-*/_count | jq .count
curl -s http://localhost:9200/apache-logs-*/_count | jq .count
curl -s http://localhost:9200/app-logs-*/_count | jq .count

# Buscar documentos
curl -s http://localhost:9200/logs-app-*/_search?size=5 | jq '.hits.hits[0]._source'

# Buscar com filtro
curl -s http://localhost:9200/apache-logs-*/_search -H "Content-Type: application/json" -d '{
  "query": {
    "match": {
      "response_category": "error"
    }
  }
}' | jq '.hits.hits | length'
```

---

## 🔧 Configuração de Pipelines

Edite arquivos em `data-prepper/pipelines/*.yaml` para customizar:

- **Mudar portas:** Edite `source.http.port`
- **Mudar índice OpenSearch:** Edite `sink.opensearch.index`
- **Adicionar processadores:** Insira novos `processor` na lista
- **Hot reload:** Data Prepper recarrega pipelines a cada 5 segundos

**Exemplo: Adicionar novo processador após Grok**

```yaml
processor:
  - grok:
      match:
        message: ["%{COMMONAPACHELOG}"]

  # NOVO: CSV parser para dados estruturados
  - csv:
      source: "csv_field"
      delimiter: ","
      quote_character: '"'
      column_names: ["id", "name", "value"]

  - date:
      match:
        timestamp:
          - "dd/MMM/yyyy:HH:mm:ss Z"
      destination: "@timestamp"
```

---

## 🛠️ Troubleshooting

### Data Prepper não está respondendo

```bash
# Verificar saúde
curl -s http://localhost:21000/health

# Verificar logs
docker logs -f data-prepper | head -100

# Reconectar/reiniciar
docker restart data-prepper
```

### Erro de conexão OpenSearch

```bash
# Verificar saúde do OpenSearch
curl -s http://localhost:9200/_cluster/health

# Verificar logs
docker logs -f opensearch

# Verificar credenciais em pipeline
# (padrão: admin/admin)
```

### Pipeline não carrega

```bash
# Listar pipelines carregados
curl -s http://localhost:21000/list-pipelines | jq .

# Verificar sintaxe YAML
docker exec data-prepper cat /usr/share/data-prepper/pipelines/*.yaml

# Forçar reload
curl -X POST http://localhost:21000/reload-pipeline -H "Content-Type: application/json"
```

### Nenhum documento aparece no OpenSearch

1. Verificar se os dados foram enviados:
   ```bash
   docker logs data-prepper | grep -i "processing\|received"
   ```

2. Verificar logs do OpenSearch:
   ```bash
   docker logs opensearch | grep -i "error\|exception"
   ```

3. Validar formato de entrada (deve ser array JSON):
   ```bash
   # Testar payload
   curl -X POST http://localhost:21000/log/ingest \
     -H "Content-Type: application/json" \
     -d '[{"message":"test", "level":"INFO"}]' -v
   ```

---

## 📖 Referência

Para detalhes técnicos, consulte:

- **Capítulo 7:** `capitulos/07_data_prepper_ingestao.md`
- **Docs Oficiais:** https://docs.opensearch.org/latest/data-prepper/
- **Grok Patterns:** https://github.com/elastic/logstash/blob/main/patterns/grok-patterns

---

## 🧹 Limpeza

```bash
# Parar apenas Data Prepper (OpenSearch continua rodando)
docker-compose down

# Limpar índices no OpenSearch (sem parar containers)
curl -X DELETE http://localhost:9200/logs-app-*
curl -X DELETE http://localhost:9200/apache-logs-*
curl -X DELETE http://localhost:9200/app-logs-*

# Se precisar parar tudo (incluindo OpenSearch):
cd ../..
docker-compose -f exemplos/docker-compose.single-node.yml down
```

---

**Última atualização:** Março 2026
