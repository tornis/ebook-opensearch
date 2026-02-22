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
curl -sk -u admin:M1nhavid@ https://localhost:9200/fluent-bit-exercise1/_search?pretty
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
      http_passwd: M1nhavid@
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
      http_passwd: M1nhavid@
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
curl -sk -u admin:M1nhavid@ \
  https://localhost:9200/fluent-bit-exercise4/_search?pretty | \
  jq '.hits.hits[0]._source | {price, value_category, processed_at}'
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
curl -sk -u admin:M1nhavid@ https://localhost:9200/_cluster/health?pretty

# Listar índices criados
curl -sk -u admin:M1nhavid@ https://localhost:9200/_cat/indices

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
