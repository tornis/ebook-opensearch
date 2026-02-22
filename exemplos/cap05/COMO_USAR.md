# Como Usar os Exemplos do Capítulo 5

## Setup Inicial

### 1. Clonar/Ter os Arquivos
```bash
cd exemplos/cap05/
ls -la
```

Arquivos esperados:
- `docker-compose.yml` — Orchestração
- `fluent-bit.yaml` — Config do Fluent Bit
- `parsers.conf` — Parsers customizados
- `scripts/enrich.lua` — Script Lua para Ex 4
- `setup.sh` — Script de configuração
- `COMO_USAR.md` — Este arquivo

### 2. Executar Setup
```bash
# Linux/Mac
bash setup.sh

# Windows (Git Bash ou WSL)
bash setup.sh
```

Ou manualmente:
```bash
docker-compose up -d
sleep 10
```

## Exercícios

### Exercício 1: Pipeline Básico

**Objetivo:** Input Dummy → Parser JSON → Filter → OpenSearch

**Já está configurado em `fluent-bit.yaml`**

Verificar:
```bash
# Ver logs em tempo real
docker compose logs -f fluent-bit

# Verificar dados no OpenSearch
curl -sk -u admin:<SENHA_ADMIN> https://localhost:9200/fluent-bit-exercise1/_search?pretty
```

---

### Exercício 2: Parser Regex (Apache)

**Objetivo:** Parsear logs Apache Combined Format

**Criar arquivo:** `fluent-bit-ex2.yaml`

```yaml
pipeline:
  service:
    log_level: info
    flush: 1
    http_server: on
    http_port: 2020
    parsers_file: /fluent-bit/etc/parsers.conf

  inputs:
    - name: tail
      path: /var/log/app/apache.log
      tag: exercise2
      parser: apache

  outputs:
    - name: opensearch
      match: 'exercise2'
      host: opensearch
      port: 9200
      http_user: admin
      http_passwd: <SENHA_ADMIN>
      index: fluent-bit-exercise2
      suppress_type_name: on
      tls: on
      tls.verify: off

    - name: stdout
      match: 'exercise2'
      format: json_lines
```

**Executar:**
```bash
# Copiar dados de teste
cp ../../exercicios/cap05/ex2-apache-logs.txt logs/apache.log

# Iniciar com nova config
docker compose down
docker run -v $(pwd):/config -v $(pwd)/logs:/var/log/app \
  cr.fluentbit.io/fluent/fluent-bit:4.2.2 \
  -c /config/fluent-bit-ex2.yaml -D

# Verificar parsing na saída
```

---

### Exercício 3: Debugar Parser

**Objetivo:** Identificar erros em parser e corrigir

**Usar imagem debug:**
```bash
docker run -ti \
  cr.fluentbit.io/fluent/fluent-bit:4.2.2-debug bash

# Dentro:
cd /fluent-bit
cat etc/parsers.conf
fluent-bit -c etc/fluent-bit.conf -D
```

**Com dados malformados:**
```bash
# Copiar dados
cp ../../exercicios/cap05/ex3-malformed-logs.txt logs/apache.log

# Testar parsing
docker run -v $(pwd)/parsers.conf:/parsers.conf \
  -v $(pwd)/logs:/logs \
  cr.fluentbit.io/fluent/fluent-bit:4.2.2-debug \
  fluent-bit -c /config/fluent-bit-ex2.yaml -D 2>&1 | grep -i "error\|failed"
```

---

### Exercício 4: Filter Lua

**Objetivo:** Enriquecer e normalizar logs com Lua

**Arquivo:** `fluent-bit-ex4.yaml`

```yaml
pipeline:
  service:
    log_level: info
    flush: 1
    http_server: on
    http_port: 2020
    parsers_file: /fluent-bit/etc/parsers.conf

  inputs:
    - name: tail
      path: /var/log/app/ecommerce.log
      tag: exercise4
      parser: json

  filters:
    - name: lua
      match: exercise4
      script: /fluent-bit/scripts/enrich.lua
      call: cb_filter

  outputs:
    - name: opensearch
      match: 'exercise4'
      host: opensearch
      port: 9200
      http_user: admin
      http_passwd: <SENHA_ADMIN>
      index: fluent-bit-exercise4
      suppress_type_name: on
      tls: on
      tls.verify: off

    - name: stdout
      match: 'exercise4'
      format: json_lines
```

**Executar:**
```bash
# Copiar dados
cp ../../exercicios/cap05/ex4-ecommerce-logs.ndjson logs/ecommerce.log

# Iniciar container com novo config
docker compose exec fluent-bit \
  fluent-bit -c /fluent-bit/etc/fluent-bit-ex4.yaml

# Verificar em OpenSearch
curl -sk -u admin:<SENHA_ADMIN> \
  https://localhost:9200/fluent-bit-exercise4/_search?pretty | \
  jq '.hits.hits[0]._source | {price, value_category, processed_at}'
```

---

### Exercício 5: Monitoramento de Containers Docker com docker_events e docker_metrics

**Objetivo:** Monitorar eventos e métricas do Docker daemon em tempo real com inputs nativos

**Setup:** Usar `fluent-bit-ex5-docker.yaml` com inputs oficiais:
- **docker_events**: Captura eventos (create, start, stop, die, etc)
- **docker_metrics**: Coleta métricas (CPU%, memória, I/O, pids)
- **tail**: Monitora logs do próprio Fluent Bit

**Arquivo:** `fluent-bit-ex5-docker.yaml` (já preparado com docker_events + docker_metrics)

**Executar:**

```bash
# 1. Usar docker-compose específico do Ex 5 (com volumes montados)
docker compose -f docker-compose-ex5.yml up -d

# 2. Aguardar inicialização (10s)
sleep 10

# 3. Ver logs do Fluent Bit em tempo real
docker compose logs -f fluent-bit

# 4. Em outro terminal: gerar eventos (cria eventos de "create" + "start")
docker run --rm busybox echo "evento 1"
docker run --rm alpine echo "evento 2"

# 5. Iniciar stress test (gera métricas contínuas)
docker run -d --name stress busybox sh -c "while true; do echo 'CPU'; sleep 1; done"

# 6. Verificar eventos ingestados
curl -sk -u admin:<SENHA_ADMIN> \
  'https://localhost:9200/docker-monitoring/_search?q=docker.events' | \
  jq '.hits.hits[0]._source | {Type, Action, Actor}'

# 7. Verificar métricas com alertas (Lua filter)
curl -sk -u admin:<SENHA_ADMIN> \
  'https://localhost:9200/docker-monitoring/_search?q=docker.metrics' | \
  jq '.hits.hits[0]._source | {container_id, cpu_percent, memory_percent, health_status, alert_high_cpu}'

# 8. Parar stress test
docker stop stress && docker rm stress

# 9. Contar total de eventos + métricas
curl -sk -u admin:<SENHA_ADMIN> \
  'https://localhost:9200/docker-monitoring/_count?pretty'

# 10. Listar eventos por tipo
curl -sk -u admin:<SENHA_ADMIN> \
  'https://localhost:9200/docker-monitoring/_search?size=0&q=docker.events' | \
  jq '.aggregations.types'
```

**Conceitos Abordados:**
- **docker_events input**: Monitora eventos do Docker daemon nativamente
- **docker_metrics input**: Coleta métricas via API do Docker socket
- Montar volumes do host (`/var/run/docker.sock`) para acesso ao daemon
- Script Lua para processar métricas e criar alertas inteligentes
- Índices com logstash_format (docker-YYYY.MM.DD)
- Buffer com filesystem para garantir entrega mesmo com falhas

**Documentação Oficial:**
- [Fluent Bit — Docker Events Input](https://docs.fluentbit.io/manual/data-pipeline/inputs/docker-events)
- [Fluent Bit — Docker Metrics Input](https://docs.fluentbit.io/manual/data-pipeline/inputs/docker-metrics)

**Para Verificação de Status:**

```bash
# Health check geral
docker compose ps

# Métricas específicas do Docker
curl http://localhost:2020/api/v1/metrics | grep docker

# Ver eventos capturados
docker compose logs fluent-bit | grep "docker.events"

# Ver métricas processadas
docker compose logs fluent-bit | grep "docker.metrics"

# Status do OpenSearch
curl -sk -u admin:<SENHA_ADMIN> https://localhost:9200/_cluster/health?pretty
```

---

## Comandos Úteis

```bash
# Ver status
docker compose ps

# Ver logs Fluent Bit
docker compose logs fluent-bit

# Ver logs OpenSearch
docker compose logs opensearch

# Entrar em container
docker compose exec fluent-bit bash

# Verificar métricas
curl http://localhost:2020/api/v1/metrics

# Testar conexão com OpenSearch
curl -sk -u admin:<SENHA_ADMIN> https://localhost:9200/_cluster/health?pretty

# Listar índices criados
curl -sk -u admin:<SENHA_ADMIN> https://localhost:9200/_cat/indices

# Parar tudo
docker compose down
```

---

## Troubleshooting

### "Connection refused" ao OpenSearch
```bash
docker compose logs opensearch | tail -20
# Verificar se está healthy
docker compose ps
```

### Parser não funciona
```bash
# Usar imagem debug
docker run -ti cr.fluentbit.io/fluent/fluent-bit:4.2.2-debug bash
# Testar regex em https://regex101.com/
```

### Script Lua com erro
```bash
# Ver erro
docker compose logs fluent-bit 2>&1 | grep -i lua

# Usar protected_mode
# No YAML: protected_mode: true
```

---

## Documentação Oficial

- Fluent Bit Docs: https://docs.fluentbit.io/manual
- OpenSearch Docs: https://docs.opensearch.org/
