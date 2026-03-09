# EXEMPLOS PRÁTICOS - CAPÍTULO 7: DATA PREPPER

Este diretório contém exemplos práticos de configuração e uso do Data Prepper para ingestão de dados no OpenSearch.

## Estrutura de Arquivos

```
exemplo/cap07/
├── README.md                          # Este arquivo
├── 01-http-basic-logs.sh             # Exemplo 1: HTTP básico
├── 02-apache-logs.sh                 # Exemplo 2: Apache parsing
├── 03-enriched-logs.sh               # Exemplo 3: Logs enriquecidos
├── 04-fluentbit-to-dataprepper.sh    # Exemplo 4: Fluent Bit integração
└── dados/
    ├── apache-sample-logs.txt         # Logs Apache para teste
    └── app-logs-sample.json           # Logs estruturados para teste
```

## Pré-requisitos

1. **Data Prepper rodando:**
   ```bash
   cd /mnt/projetos/teste/ebook-opensearch
   docker-compose -f docker-compose-data-prepper.yml up -d
   ```

2. **OpenSearch rodando** (parte do docker-compose acima)

3. **curl instalado** (para testar APIs)

4. **jq instalado** (para formatar JSON)
   ```bash
   sudo apt-get install jq
   ```

## Executar os Exemplos

### Exemplo 1: HTTP Básico (Log JSON simples)

```bash
bash exemplo/cap07/01-http-basic-logs.sh
```

**O que faz:**
- Envia logs JSON via HTTP para Data Prepper
- Adiciona timestamp de ingestão automaticamente
- Armazena em índice `logs-app-*` no OpenSearch

**Resultado esperado:**
```json
{
  "message": "Application started successfully",
  "level": "INFO",
  "service": "api-server",
  "ingest_timestamp": 1234567890000
}
```

---

### Exemplo 2: Apache Log Parsing com Grok

```bash
bash exemplo/cap07/02-apache-logs.sh
```

**O que faz:**
- Parse de logs Apache em formato Common Log Format
- Estrutura campos (IP, timestamp, método HTTP, status code, bytes)
- Converte timestamp para ISO8601
- Calcula categoria de resposta (success/redirect/error)

**Log de entrada:**
```
192.168.1.10 - frank [01/Jan/2025:12:00:00 +0000] "GET /apache.html HTTP/1.0" 200 2326
```

**Resultado estruturado:**
```json
{
  "clientip": "192.168.1.10",
  "auth": "frank",
  "timestamp": "01/Jan/2025:12:00:00 +0000",
  "verb": "GET",
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

### Exemplo 3: Logs Estruturados com Enriquecimento

```bash
bash exemplo/cap07/03-enriched-logs.sh
```

**O que faz:**
- Parse de logs ISO8601 estruturados
- Normaliza níveis de severidade
- Calcula score numérico de severidade
- Agrega eventos multi-linha por request_id

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
  "severity_level": "ERROR",
  "severity_numeric": 40,
  "is_error": true,
  "processing_timestamp": 1705318245123,
  "@timestamp": "2025-01-15T10:30:45.123Z"
}
```

---

### Exemplo 4: Fluent Bit → Data Prepper → OpenSearch

```bash
bash exemplo/cap07/04-fluentbit-to-dataprepper.sh
```

**O que faz:**
- Inicia Fluent Bit como container
- Coleta logs do Docker (container logs)
- Encaminha para Data Prepper via HTTP
- Data Prepper processa e armazena no OpenSearch

**Pipeline:**
```
Docker Container Logs → Fluent Bit → HTTP POST → Data Prepper → OpenSearch
```

---

## Verificar Resultados

### Listar índices criados

```bash
curl -s -u admin:admin https://localhost:9200/_cat/indices \
  -H "Content-Type: application/json" -k
```

### Buscar dados em um índice

```bash
# Buscar todos os documentos em logs-app-*
curl -s -u admin:admin https://localhost:9200/logs-app-*/_search \
  -H "Content-Type: application/json" -k | jq '.hits.hits'

# Buscar em apache-logs-*
curl -s -u admin:admin https://localhost:9200/apache-logs-*/_search \
  -H "Content-Type: application/json" -k | jq '.hits.hits'
```

### Contar documentos por índice

```bash
curl -s -u admin:admin https://localhost:9200/logs-app-*/_count \
  -H "Content-Type: application/json" -k | jq '.count'
```

---

## Troubleshooting

### Data Prepper não está respondendo

```bash
# Verificar saúde
curl -s http://localhost:21000/health

# Verificar logs
docker logs -f data-prepper

# Reconectar
docker restart data-prepper
```

### Erro de conexão OpenSearch

```bash
# Verificar se OpenSearch está rodando
curl -s -u admin:admin https://localhost:9200/ -k

# Verificar logs do OpenSearch
docker logs -f opensearch
```

### Nenhum documento aparece

1. Verificar se o pipeline está carregado:
   ```bash
   curl -s http://localhost:21000/list-pipelines
   ```

2. Verificar logs de pipeline:
   ```bash
   docker logs data-prepper | grep -i pipeline
   ```

3. Verificar formato de dados esperado:
   - Log JSON deve ser array: `[ { ... } ]`
   - Verificar formatação no arquivo de teste

---

## Referências

- [Data Prepper Documentation](https://docs.opensearch.org/latest/data-prepper/)
- [Grok Patterns](https://github.com/elastic/logstash/blob/main/patterns/grok-patterns)
- [OpenSearch API](https://docs.opensearch.org/latest/api-reference/)
