# Exemplos Práticos — Capítulo 6: Logstash

Exemplos executáveis de uso do **Logstash 8.15** com **OpenSearch 3.5**.

## 📋 Estrutura

- **Dockerfile** — Imagem customizada com plugin `logstash-output-opensearch`
- **docker-compose.yml** — Orquestração Logstash + OpenSearch
- **logstash/pipelines/** — Configurações de pipelines (Grok, Dissect, Date, Mutate, JDBC)
- **logstash/drivers/** — Drivers JDBC (SQLite)
- **datasets/** — Dados de exemplo (Chinook database)

## 🚀 Quick Start

### 1. Criar network do OpenSearch (uma única vez)

```bash
docker network create opensearch-net
```

### 2. Subir OpenSearch (se ainda não estiver rodando)

```bash
cd ../..
docker-compose -f exemplos/docker-compose.single-node.yml up -d
```

### 3. Build e iniciar Logstash

```bash
cd exemplos/cap06
docker-compose up -d --build
```

Aguarde 10-15 segundos para o container ficar saudável.

### 4. Verificar saúde

```bash
# Verificar status dos containers
docker-compose ps

# Acessar API de monitoramento
curl -s http://localhost:9600/ | jq .

# Verificar plugins instalados
docker exec logstash /usr/share/logstash/bin/logstash-plugin list | grep opensearch
```

## 📚 Exemplos Disponíveis

### Pipeline 1: Grok Parser
Parsing de logs Apache com expressões regulares nomeadas.

```bash
# Testar pipeline
docker exec -it logstash /usr/share/logstash/bin/logstash -f \
  /usr/share/logstash/pipelines/01-grok-parser.conf -t
```

### Pipeline 2: Dissect Parser
Parsing rápido de logs com delimitadores fixos.

### Pipeline 3: Date Parser
Normalização de timestamps para ISO 8601.

### Pipeline 4: Mutate
Transformação e enriquecimento de dados.

### Pipeline 5: JDBC SQLite
Ingestão de dados estruturados do banco Chinook (e-commerce).

## 🛠️ Configuração de Pipelines

Edite `logstash/config/pipelines.yml` para ativar/desativar pipelines:

```yaml
- pipeline.id: grok_parser
  path.config: "/usr/share/logstash/pipelines/01-grok-parser.conf"
  pipeline.workers: 2
  pipeline.batch.size: 125
```

## 📊 Verificar Dados em OpenSearch

```bash
# Listar índices criados pelo Logstash
curl -sk -u admin:Admin#123456 https://localhost:9200/_cat/indices?v

# Contar documentos de um índice
curl -s -k -u admin:Admin#123456 \
  https://localhost:9200/grok-logs-*/_count | jq .count

# Buscar um documento
curl -s -k -u admin:Admin#123456 \
  https://localhost:9200/grok-logs-*/_search | jq '.hits.hits[0]._source'
```

## 🔧 Troubleshooting

### Verificar logs
```bash
docker logs -f logstash
```

### Entrar no container
```bash
docker exec -it logstash /bin/bash
```

### Limpar tudo e recomeçar
```bash
docker-compose down
docker-compose up -d --build
```

## 📖 Referência

Para mais detalhes, consulte o **Capítulo 6** em `capitulos/06_logstash_ingestao.md`.

---

**Última atualização:** Março 2026
