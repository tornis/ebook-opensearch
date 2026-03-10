# Setup Prático: Logstash + OpenSearch

Guia passo-a-passo para inicializar Logstash e testar os pipelines de ingestão.

---

## 1. PRÉ-REQUISITOS

✅ OpenSearch 3.5+ rodando em Docker
✅ Docker Compose instalado
✅ Network `opensearch-net` criada

Verificar:
```bash
docker network ls | grep opensearch-net
```

Se não existir, criar:
```bash
docker network create opensearch-net
```

---

## 2. ESTRUTURA DE DIRETÓRIOS

Crie a estrutura esperada:

```bash
# A partir da raiz do projeto (ebook-opensearch/)

# Diretórios de configuração
mkdir -p logstash/config
mkdir -p logstash/pipelines
mkdir -p logstash/drivers
mkdir -p logstash/logs

# Diretório de dados
mkdir -p datasets
```

---

## 3. DOWNLOAD DO DRIVER JDBC

SQLite requer driver JDBC específico:

```bash
cd logstash/drivers

# Download do sqlite-jdbc 3.48.0.0
wget https://github.com/xerial/sqlite-jdbc/releases/download/3.48.0.0/sqlite-jdbc-3.48.0.0.jar

# Verificar download
ls -lh sqlite-jdbc-*.jar
# Esperado: ~7.5MB

cd ../..
```

---

## 4. DOWNLOAD DO DATASET CHINOOK

O banco de dados Chinook contém dados reais de e-commerce:

```bash
cd datasets

# Download do chinook.db
wget https://raw.githubusercontent.com/tornis/esstackenterprise/master/datasets/chinook.db

# Verificar integridade
ls -lh chinook.db
# Esperado: ~600KB

# Explorar o banco (opcional, requer sqlite3)
sqlite3 chinook.db ".tables"
# Tabelas disponíveis: customers, invoices, invoice_items, tracks, albums, artists, etc.

cd ..
```

---

## 5. INICIAR LOGSTASH

### Opção A: Manualmente via Docker Compose

```bash
# Iniciar apenas Logstash (pressupõe OpenSearch já rodando)
docker-compose -f docker-compose-logstash.yml up -d

# Verificar se iniciou corretamente
docker logs -f logstash

# Esperado após ~15 segundos:
# [INFO] logstash.runner - Logstash shut down.
# (Significa que está esperando input ou processando)
```

### Opção B: Com OpenSearch (ambiente completo)

Se você ainda não tem OpenSearch rodando:

```bash
# Supondo que existe docker-compose.yml para OpenSearch
docker-compose up -d opensearch logstash

# Verificar services
docker ps | grep -E "opensearch|logstash"
```

---

## 6. TESTAR PIPELINES DE EXEMPLO

### Teste 1: Filtro Grok (Parsing de Logs Apache)

```bash
# Entrar no container
docker exec -it logstash /bin/bash

# Validar sintaxe do pipeline
/usr/share/logstash/bin/logstash -f \
  /usr/share/logstash/pipelines/01-grok-parser.conf -t

# Esperado: "Configuration OK"
```

**Preparar entrada de teste:**

Crie arquivo `test-grok.json`:

```json
{"message":"192.168.1.100 - - [10/Mar/2025:14:32:45 +0000] \"GET /api/users HTTP/1.1\" 200 5432 \"-\" \"Mozilla/5.0\""}
```

**Executar pipeline em foreground:**

```bash
# Do host
cat test-grok.json | docker exec -i logstash \
  /usr/share/logstash/bin/logstash -f \
  /usr/share/logstash/pipelines/01-grok-parser.conf
```

**Esperado na saída:**
```json
{
  "client_ip": "192.168.1.100",
  "method": "GET",
  "request": "/api/users",
  "status_code": 200,
  "bytes": 5432,
  "parse_status": "success",
  ...
}
```

### Teste 2: Filtro Dissect

```bash
# Validar sintaxe
docker exec logstash /usr/share/logstash/bin/logstash -f \
  /usr/share/logstash/pipelines/02-dissect-parser.conf -t
```

**Entrada de teste:**

```json
{"message":"2025-03-10T14:32:45.123Z | ERROR | payment-service | Failed to process transaction"}
```

**Executar:**

```bash
echo '{"message":"2025-03-10T14:32:45.123Z | ERROR | payment-service | Failed to process transaction"}' | \
docker exec -i logstash /usr/share/logstash/bin/logstash -f \
  /usr/share/logstash/pipelines/02-dissect-parser.conf
```

### Teste 3: Filtro Date

```bash
# Validar
docker exec logstash /usr/share/logstash/bin/logstash -f \
  /usr/share/logstash/pipelines/03-date-parser.conf -t
```

**Entrada de teste (múltiplos formatos):**

```json
{"log_timestamp":"10/Mar/2025:14:32:45 +0000"}
```

ou

```json
{"log_timestamp":"2025-03-10T14:32:45.123Z"}
```

### Teste 4: Filtro Mutate

```bash
# Validar
docker exec logstash /usr/share/logstash/bin/logstash -f \
  /usr/share/logstash/pipelines/04-mutate-parser.conf -t
```

**Entrada de teste:**

```json
{
  "status_code": "200",
  "response_time_ms": "123.45",
  "client_ip": "192.168.1.100",
  "log_level": "ERROR",
  "service_name": "API_GATEWAY"
}
```

---

## 7. EXERCÍCIO PRÁTICO: INGESTÃO JDBC/SQLITE

### Instalação do Plugin JDBC

O plugin JDBC deve ser instalado no Logstash:

```bash
# Instalar plugin logstash-input-jdbc
docker exec logstash /usr/share/logstash/bin/logstash-plugin install logstash-input-jdbc

# Verificar instalação
docker exec logstash /usr/share/logstash/bin/logstash-plugin list | grep jdbc
```

### Validar Pipeline JDBC

```bash
# Testar sintaxe
docker exec logstash /usr/share/logstash/bin/logstash -f \
  /usr/share/logstash/pipelines/05-jdbc-sqlite.conf -t

# Esperado: "Configuration OK"
```

### Executar Ingestão Completa

```bash
# Modo foreground (para debug)
docker exec -it logstash /usr/share/logstash/bin/logstash -f \
  /usr/share/logstash/pipelines/05-jdbc-sqlite.conf

# A execução processará todos os 59 clientes do Chinook
# Esperado após ~10s:
# [2025-03-10T14:32:48][INFO] logstash.agent - Pipeline started successfully
```

---

## 8. VALIDAR INGESTÃO EM OPENSEARCH

### Verificar Índice Criado

```bash
# Contar documentos ingestados
curl -s -k -u admin:Admin#123456 \
  https://localhost:9200/chinook-customers/_count | jq '.count'

# Esperado: 59
```

### Visualizar Documento

```bash
# Ver cliente ID 1
curl -s -k -u admin:Admin#123456 \
  https://localhost:9200/chinook-customers/_doc/1 | jq '._source'
```

**Esperado:**

```json
{
  "customer_id": 1,
  "first_name": "Luís",
  "last_name": "Gonçalves",
  "full_name": "Luís Gonçalves",
  "email": "luisg@embraer.com.br",
  "phone": "+55 (11) 3308-7161",
  "city": "São Paulo",
  "country": "Brazil",
  "location": "São Paulo, Brazil",
  "total_invoices": 7,
  "lifetime_value": 39.62,
  "avg_invoice_value": 5.66,
  "is_high_value": false,
  "customer_segment": "Regular",
  "data_source": "sqlite_chinook",
  "entity_type": "customer",
  "ingest_timestamp": "2025-03-10T14:32:48.000Z",
  "@timestamp": "2025-03-10T14:32:48.000Z"
}
```

### Query: Clientes VIP

```bash
curl -s -k -u admin:Admin#123456 \
  https://localhost:9200/chinook-customers/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match": { "customer_segment": "VIP" }
    },
    "size": 10
  }' | jq '.hits.hits[] | ._source | {full_name, customer_segment, lifetime_value}'
```

### Query: Clientes por País

```bash
curl -s -k -u admin:Admin#123456 \
  https://localhost:9200/chinook-customers/_search \
  -H "Content-Type: application/json" \
  -d '{
    "aggs": {
      "by_country": {
        "terms": {
          "field": "country",
          "size": 10
        }
      }
    }
  }' | jq '.aggregations.by_country.buckets[] | {country: .key, count: .doc_count}'
```

---

## 9. TROUBLESHOOTING

### Problema: "Connection refused" ao conectar OpenSearch

```bash
# Verificar se OpenSearch está rodando
docker ps | grep opensearch

# Se não estiver, iniciar:
docker-compose up -d opensearch

# Verificar conectividade
curl -k -u admin:Admin#123456 https://localhost:9200
```

### Problema: "jdbc_driver_library not found"

```bash
# Verificar se driver JDBC foi baixado
ls -lh logstash/drivers/sqlite-jdbc-*.jar

# Se não existir, baixar:
cd logstash/drivers
wget https://github.com/xerial/sqlite-jdbc/releases/download/3.48.0.0/sqlite-jdbc-3.48.0.0.jar
```

### Problema: Logstash não está parseando dados

```bash
# Aumentar verbosidade de logs
docker exec logstash /usr/share/logstash/bin/logstash -f \
  /usr/share/logstash/pipelines/XX-nome.conf --log.level=debug

# Verificar logs do container
docker logs logstash | tail -100
```

### Problema: Índice não criado em OpenSearch

```bash
# Verificar se há erros no output
docker logs logstash | grep -i "opensearch\|error"

# Verificar credenciais
docker logs logstash | grep -i "unauthorized\|authentication"

# Confirmar que OpenSearch está acessível
curl -k -u admin:Admin#123456 https://localhost:9200/_cat/indices
```

---

## 10. LIMPEZA (RESET)

Se precisar recomeçar:

```bash
# Parar Logstash
docker-compose -f docker-compose-logstash.yml down

# Deletar índices (opcional)
curl -X DELETE -k -u admin:Admin#123456 \
  https://localhost:9200/grok-logs-*
curl -X DELETE -k -u admin:Admin#123456 \
  https://localhost:9200/dissect-logs-*
curl -X DELETE -k -u admin:Admin#123456 \
  https://localhost:9200/date-logs-*
curl -X DELETE -k -u admin:Admin#123456 \
  https://localhost:9200/mutate-logs-*
curl -X DELETE -k -u admin:Admin#123456 \
  https://localhost:9200/chinook-customers

# Limpar logs
rm -f logstash/logs/*

# Reiniciar
docker-compose -f docker-compose-logstash.yml up -d
```

---

## 11. PRÓXIMOS PASSOS

✅ Implementar inputs adicionais (Kafka, HTTP, S3)
✅ Desenvolver pipelines custom com filtros avançados
✅ Integrar com alertas e monitoramento em OpenSearch
✅ Escalar para processamento em tempo real

---

**Documentação de referência:**
- [Logstash Docs](https://www.elastic.co/guide/en/logstash/current/index.html)
- [OpenSearch Logstash Plugin](https://docs.opensearch.org/latest/tools/logstash/index/)
