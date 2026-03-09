# EXERCÍCIO PRÁTICO - CAPÍTULO 7: DATA PREPPER

## Exercício: Pipeline Completo - Fluent Bit + Apache2 + Data Prepper + OpenSearch

**Objetivo:** Implementar um pipeline real de ingestão de logs, coletando logs do Apache2 via Fluent Bit, processando com Data Prepper e armazenando estruturado no OpenSearch.

**Tempo estimado:** 30-40 minutos

**Nível:** Intermediário

---

## PARTE 1: PREPARAÇÃO DO AMBIENTE

### 1.1 Verificar Status dos Serviços

```bash
# Verificar Docker
docker --version

# Verificar Data Prepper
curl -s http://localhost:21000/health | jq .

# Verificar OpenSearch
curl -s -u admin:admin https://localhost:9200/_cluster/health -k | jq .
```

**Resultado esperado:**
```json
{
  "status": "UP"
}
```

### 1.2 Criar Estrutura de Diretórios

```bash
# Garantir que diretórios existem
mkdir -p ~/tmp/apache-logs
mkdir -p ~/tmp/fluent-bit

# Copiar configurações
cp exercicios/cap07/fluentbit-config/fluent-bit.conf ~/tmp/fluent-bit/
cp exercicios/cap07/fluentbit-config/parsers.conf ~/tmp/fluent-bit/
```

### 1.3 Verificar Pipelines Carregados

```bash
# Listar pipelines do Data Prepper
curl -s http://localhost:21000/list-pipelines | jq .

# Ou verificar os logs
docker logs data-prepper | grep -i "pipeline\|loaded" | tail -10
```

---

## PARTE 2: CONFIGURAÇÃO DO APACHE2

Você tem duas opções:

### Opção A: Usar Apache2 Já Instalado (Local)

Se você tem Apache2 instalado na máquina:

```bash
# 1. Iniciar Apache2
sudo systemctl start apache2

# 2. Verificar status
sudo systemctl status apache2

# 3. Gerar logs de teste
# Acessar localhost em navegador: http://localhost
# Ou via curl:
curl -s http://localhost/ > /dev/null
curl -s http://localhost/notfound 2>/dev/null > /dev/null || true
curl -s http://localhost/ > /dev/null

# 4. Verificar logs
tail -5 /var/log/apache2/access.log
```

### Opção B: Usar Apache2 em Container Docker (Recomendado)

```bash
# 1. Criar docker-compose com Apache2
cat > /tmp/docker-compose-apache.yml << 'EOF'
version: '3.8'

services:
  apache2:
    image: httpd:2.4-alpine
    container_name: apache2-test
    ports:
      - "8080:80"
    volumes:
      - apache-logs:/usr/local/apache2/logs
    networks:
      - opensearch-net

volumes:
  apache-logs:

networks:
  opensearch-net:
    external: true
EOF

# 2. Iniciar Apache2
docker-compose -f /tmp/docker-compose-apache.yml up -d

# 3. Gerar logs
for i in {1..20}; do
  curl -s http://localhost:8080/ > /dev/null
  sleep 0.5
done

# 4. Verificar logs
docker exec apache2-test tail -5 /usr/local/apache2/logs/access_log
```

---

## PARTE 3: CONFIGURAÇÃO DO FLUENT BIT

### 3.1 Criar Docker Compose com Fluent Bit + Apache2

Crie `exercicios/cap07/docker-compose-exercise.yml`:

```yaml
version: '3.8'

services:
  apache2:
    image: httpd:2.4-alpine
    container_name: apache2-exercise
    ports:
      - "8080:80"
    volumes:
      - apache-logs:/usr/local/apache2/logs
    networks:
      - opensearch-net
    restart: unless-stopped

  fluent-bit:
    image: fluent/fluent-bit:3.0
    container_name: fluent-bit-exercise
    volumes:
      - ./fluentbit-config/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf:ro
      - ./fluentbit-config/parsers.conf:/fluent-bit/etc/parsers.conf:ro
      - apache-logs:/var/log/apache2:ro
    networks:
      - opensearch-net
    depends_on:
      - apache2
    command: /fluent-bit/bin/fluent-bit -c /fluent-bit/etc/fluent-bit.conf
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  apache-logs:

networks:
  opensearch-net:
    external: true
```

### 3.2 Iniciar Stack do Exercício

```bash
# Navegar para diretório do exercício
cd /mnt/projetos/teste/ebook-opensearch/exercicios/cap07

# Iniciar Apache2 + Fluent Bit
docker-compose -f docker-compose-exercise.yml up -d

# Aguardar inicialização
sleep 5

# Verificar logs
docker logs fluent-bit-exercise
```

---

## PARTE 4: GERAR LOGS DE TESTE

### 4.1 Simular Tráfego Apache

```bash
# 1. Acessos bem-sucedidos (200)
for i in {1..10}; do
  curl -s http://localhost:8080/index.html > /dev/null
  echo "Request $i - 200 OK"
  sleep 1
done

# 2. Acessos falhados (404)
for i in {1..5}; do
  curl -s http://localhost:8080/notfound-$i.html > /dev/null 2>&1 || true
  echo "Request $i - 404 Not Found"
  sleep 1
done

# 3. Redirecionamentos (301)
curl -s -L http://localhost:8080/old-page > /dev/null 2>&1 || true

# 4. Erros de servidor (500)
# Nota: Apache padrão não gera 500 automaticamente
# Você pode criar uma página dinâmica ou usar um script
```

### 4.2 Verificar Logs Gerados

```bash
# Ver logs Apache no container
docker exec apache2-exercise tail -20 /usr/local/apache2/logs/access_log

# Ver logs Fluent Bit
docker logs -f fluent-bit-exercise
```

---

## PARTE 5: CONSULTAR DADOS NO OPENSEARCH

### 5.1 Verificar Ingestão

```bash
# 1. Listar índices criados
curl -s -u admin:admin https://localhost:9200/_cat/indices -k | grep apache

# 2. Contar documentos
curl -s -u admin:admin https://localhost:9200/apache-logs-*/_count -k | jq '.count'

# 3. Ver primeiros documentos
curl -s -u admin:admin "https://localhost:9200/apache-logs-*/_search?size=5" \
  -H "Content-Type: application/json" -k | jq '.hits.hits[] | ._source'
```

### 5.2 Análise dos Dados Processados

#### a) Ver Campos Parseados

```bash
# Mapping do índice (quais campos foram criados)
curl -s -u admin:admin https://localhost:9200/apache-logs-*/_mapping -k | jq '.[] | .mappings.properties | keys'
```

**Resultado esperado:**
```json
[
  "@timestamp",
  "clientip",
  "response",
  "request",
  "bytes",
  "response_category",
  ...
]
```

#### b) Distribuição de Códigos HTTP

```bash
curl -s -u admin:admin "https://localhost:9200/apache-logs-*/_search?size=0" \
  -H "Content-Type: application/json" \
  -d '{
    "aggs": {
      "status_codes": {
        "terms": {
          "field": "response",
          "size": 10
        }
      }
    }
  }' -k | jq '.aggregations.status_codes.buckets[]'
```

**Resultado esperado:**
```json
{
  "key": 200,
  "doc_count": 10
}
{
  "key": 404,
  "doc_count": 5
}
```

#### c) Top Recursos Acessados

```bash
curl -s -u admin:admin "https://localhost:9200/apache-logs-*/_search?size=0" \
  -H "Content-Type: application/json" \
  -d '{
    "aggs": {
      "top_requests": {
        "terms": {
          "field": "request.keyword",
          "size": 5
        }
      }
    }
  }' -k | jq '.aggregations.top_requests.buckets[]'
```

#### d) Erros (Status >= 400)

```bash
curl -s -u admin:admin "https://localhost:9200/apache-logs-*/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "range": {
        "response": {
          "gte": 400
        }
      }
    },
    "size": 10
  }' -k | jq '.hits.hits[] | {
    client: ._source.clientip,
    request: ._source.request,
    status: ._source.response,
    bytes: ._source.bytes,
    time: ._source."@timestamp"
  }'
```

---

## PARTE 6: VALIDAÇÃO E TESTES

### 6.1 Checklist de Validação

- [ ] Data Prepper está rodando e respondendo (health check OK)
- [ ] OpenSearch está acessível
- [ ] Apache2 está gerando logs
- [ ] Fluent Bit está coletando logs
- [ ] Data Prepper recebeu os logs (sem erros)
- [ ] Índice `apache-logs-*` foi criado
- [ ] Documentos foram parseados com campos estruturados
- [ ] Agregações funcionam (status codes, top requests, etc.)

### 6.2 Resolver Problemas Comuns

#### Problema: "Connection refused" no Fluent Bit

```bash
# Verificar conectividade entre containers
docker exec fluent-bit-exercise ping data-prepper

# Se falhar, verificar rede
docker network ls
docker network inspect opensearch-net
```

#### Problema: Nenhum documento aparece em 5 minutos

```bash
# 1. Verificar logs Fluent Bit
docker logs fluent-bit-exercise | tail -30

# 2. Verificar logs Data Prepper
docker logs data-prepper | tail -30

# 3. Verificar se há logs Apache
docker exec apache2-exercise tail -20 /usr/local/apache2/logs/access_log

# 4. Testar Data Prepper manualmente
curl -X POST http://localhost:21001/apache/logs \
  -H "Content-Type: application/json" \
  -d '[{"message": "127.0.0.1 - - [01/Jan/2025:12:00:00 +0000] \"GET / HTTP/1.1\" 200 100"}]'
```

#### Problema: Campos não foram parseados

```bash
# Verificar formato esperado no log
docker exec apache2-exercise tail -1 /usr/local/apache2/logs/access_log

# Comparar com padrão Grok esperado
# Padrão: %{COMMONAPACHELOG}
# Espera: IP USER USER [TIMESTAMP] "METHOD REQUEST HTTP/VERSION" STATUS BYTES
```

---

## PARTE 7: LIMPEZA

Quando terminar, limpar os recursos:

```bash
# Parar exercício
cd exercicios/cap07
docker-compose -f docker-compose-exercise.yml down -v

# Limpar índices de teste (opcional)
curl -X DELETE -u admin:admin https://localhost:9200/apache-logs-* -k

# Manter Data Prepper e OpenSearch rodando
# docker-compose -f docker-compose-data-prepper.yml up -d
```

---

## PARTE 8: QUESTÕES PARA REFLEXÃO

1. **Quais campos foram parseados do log Apache?**
   - Listar todos os campos no documento estruturado

2. **Qual é a diferença entre `response` e `response_category`?**
   - `response`: número (200, 404, etc.)
   - `response_category`: valor derivado (success, error, redirect)

3. **Como Data Prepper trataria logs malformados?**
   - Pesquisar comportamento de fallback

4. **Qual seria o impacto de desabilitar o Fluent Bit parser?**
   - Os logs chegariam como string bruta no OpenSearch

5. **Como monitorar performance do pipeline Fluent Bit → Data Prepper?**
   - Latência
   - Taxa de erro
   - Throughput

---

## REFERÊNCIAS

- [Fluent Bit Apache Parser](https://docs.fluentbit.io/manual/pipeline/parsers/apache-parser)
- [Data Prepper Grok Processor](https://docs.opensearch.org/latest/data-prepper/common-use-cases/log-analytics/)
- [Apache Log Format](https://httpd.apache.org/docs/current/logs.html)
- [OpenSearch API Reference](https://docs.opensearch.org/latest/api-reference/)

---

## SUCESSO!

Ao completar este exercício, você terá:

✅ Configurado um pipeline real de ingestão de logs
✅ Utilizado Fluent Bit para coleta de logs
✅ Processado logs com Data Prepper
✅ Armazenado dados estruturado no OpenSearch
✅ Realizado análises sobre os dados coletados
✅ Debugado e resolvido problemas comuns

**Próxima etapa:** Implementar um pipeline similar em produção com múltiplas fontes!
