# 🚀 Exercício Prático: Ingestão de Logs Apache com Fluent Bit

## Visão Geral

Este exercício prático guia você através de um pipeline completo de ingestão de dados usando Fluent Bit. Você irá:

1. **Descompactar** um arquivo de logs Apache reais (2.3MB)
2. **Configurar** Fluent Bit para ler e processar os logs
3. **Filtrar** requisições para recursos estáticos (imagens, CSS, fontes)
4. **Aplicar sampling** inteligente baseado em HTTP status codes
5. **Ingerir** dados no OpenSearch seguindo padrões Logstash

---

## 📋 Pré-requisitos

- ✅ OpenSearch 3.5 rodando em `https://localhost:9200`
- ✅ Credenciais: `admin` / `<SENHA_ADMIN>` (ou outra conforme seu ambiente)
- ✅ Docker e Docker Compose (recomendado)
- ✅ Fluent Bit 3.0.4+ (opcional se usar Docker)
- ✅ `curl` ou similar para validação

### Verificar OpenSearch

```bash
# Verificar conectividade
curl -s -k -u admin:<SENHA_ADMIN> https://localhost:9200 | jq .

# Resposta esperada
{
  "name": "opensearch-node1",
  "cluster_name": "opensearch-cluster",
  "version": {
    "number": "3.5.0"
  }
}
```

---

## 🎯 Passo-a-Passo do Exercício

### Passo 1️⃣: Descompactar os Logs Apache

O arquivo `archive.zip` contém um log Apache de 2.3MB com ~14.000 requisições reais.

```bash
# Executar script de descompactação
bash 01-descompactar-logs.sh

# Esperado:
# === Preparação de Logs Apache para Ingestão ===
#
# 📦 Descompactando arquivo...
# ✅ Arquivo descompactado com sucesso
#
# 📊 Informações dos Logs:
#    Total de linhas: 14612
#
# ✅ Logs descompactados e prontos em:
#    /mnt/projetos/teste/ebook-opensearch/exercicios/cap05/apache_logs_prepared.log
```

**Resultado esperado:**
- Arquivo `apache_logs_prepared.log` criado (2.3MB)
- Contém ~14.612 requisições HTTP no formato Apache Combined Log Format

### Passo 2️⃣: Entender o Formato dos Logs

Exemplo de uma linha de log Apache:

```
83.149.9.216 - - [17/May/2015:10:05:03 +0000] "GET /presentations/logstash-monitorama-2013/ HTTP/1.1" 200 203023 "http://semicomplete.com/presentations/logstash-monitorama-2013/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36"
```

**Campos extraídos pelo parser:**
- `remote`: 83.149.9.216 (IP do cliente)
- `method`: GET (método HTTP)
- `path`: /presentations/logstash-monitorama-2013/ (URI requisitado)
- `code`: 200 (HTTP status code)
- `size`: 203023 (bytes enviados)
- `referrer`: URL de origem
- `agent`: User-Agent (navegador/cliente)

### Passo 3️⃣: Analisar Arquivos de Configuração

#### `fluent-bit.conf` (Configuração Principal)

```yaml
[SERVICE]
    Flush: 5 segundos
    Parsers_File: parsers.conf
    HTTP_Server: Endpoint de monitoramento na porta 2020

[INPUT]
    Name: tail
    Path: apache_logs_prepared.log
    Parser: apache2
    Tag: apache.access

[FILTER 1] - Parser
    Estrutura os logs em JSON

[FILTER 2] - Grep (Filtragem)
    Remove: .png, .jpg, .jpeg, .gif, .svg, .ico, .css, .ttf, .woff

[FILTER 3] - Lua Sampling
    HTTP 200: 10% das requisições
    HTTP 4xx: 100% das requisições
    HTTP 5xx: 100% das requisições

[OUTPUT]
    Envia para OpenSearch
    Index: logstash-apache-YYYY.MM.DD
```

#### `parsers.conf` (Padrões de Parser)

Define a expressão regular para extrair campos do log Apache:

```regex
^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+) (?<path>[^ ]*) (?<protocol>[^\"]*)" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referrer>[^\"]*)" "(?<agent>[^\"]*)")?$
```

#### `sampling.lua` (Script de Sampling)

Implementa lógica inteligente de captura:

```lua
-- Se HTTP 200: incluir apenas 10% (random <= 0.10)
-- Se HTTP 4xx/5xx: incluir 100% (random <= 1.0)
```

### Passo 4️⃣: Executar Fluent Bit

#### Opção A: Com Docker Compose (Recomendado)

```bash
# 1. Certifique-se que os logs foram descompactados
bash 01-descompactar-logs.sh

# 2. Inicie o Fluent Bit
docker-compose -f docker-compose-fluentbit.yml up -d

# 3. Monitore os logs
docker-compose -f docker-compose-fluentbit.yml logs -f fluentbit-apache-ingestor

# 4. Verifique no segundo terminal
bash 02-verificar-ingestao.sh

# 5. Para parar
docker-compose -f docker-compose-fluentbit.yml down
```

#### Opção B: Fluent Bit Local (Sem Docker)

```bash
# 1. Instalar Fluent Bit (Ubuntu/Debian)
curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh

# 2. Executar com configuração customizada
fluent-bit -c fluent-bit.conf -R ./

# 3. Verifique no segundo terminal
bash 02-verificar-ingestao.sh
```

### Passo 5️⃣: Verificar Ingestão

```bash
# Script automático de verificação
bash 02-verificar-ingestao.sh

# Ou use curl manualmente:

# Listar índices criados
curl -s -k -u admin:<SENHA_ADMIN> https://localhost:9200/_cat/indices | grep apache

# Contar documentos
curl -s -k -u admin:<SENHA_ADMIN> https://localhost:9200/logstash-apache-*/_count | jq .

# Amostra de documento
curl -s -k -u admin:<SENHA_ADMIN> https://localhost:9200/logstash-apache-*/_search?size=1 | jq .
```

**Esperado:**
```json
{
  "count": 4700,  // ~10% de 47000 requisições (só 200) + todas as 4xx/5xx
  "_shards": {
    "total": 1,
    "successful": 1,
    "skipped": 0,
    "failed": 0
  }
}
```

---

## 🔍 Validações Esperadas

### ✅ 1. Filtragem de Recursos Estáticos

```bash
# Procurar por .png (não deve encontrar)
curl -s -k -u admin:<SENHA_ADMIN> \
  'https://localhost:9200/logstash-apache-*/_search?q=request:*.png' | jq '.hits.total'

# Resposta: { "value": 0 }
```

### ✅ 2. Aplicação de Sampling

```bash
# Contar HTTP 200 (devem ser ~10% do original)
curl -s -k -u admin:<SENHA_ADMIN> \
  'https://localhost:9200/logstash-apache-*/_count?q=code:200' | jq '.count'

# Contar HTTP 404 (devem ser 100%)
curl -s -k -u admin:<SENHA_ADMIN> \
  'https://localhost:9200/logstash-apache-*/_count?q=code:404' | jq '.count'
```

### ✅ 3. Estrutura de Documento

```bash
curl -s -k -u admin:<SENHA_ADMIN> \
  'https://localhost:9200/logstash-apache-*/_search?size=1' | jq '.hits.hits[0]._source'
```

**Esperado:**
```json
{
  "remote": "83.149.9.216",
  "method": "GET",
  "path": "/presentations/logstash-monitorama-2013/index.html",
  "code": 200,
  "size": 7697,
  "referrer": "http://semicomplete.com/presentations/logstash-monitorama-2013/",
  "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) ...",
  "@timestamp": "2015-05-17T10:05:03.000Z",
  "ingest_timestamp": "2015-05-17T10:05:03.000Z",
  "source": "apache-webserver",
  "_sampling_rate": "10%",
  "_sampled": "true"
}
```

---

## 🛠️ Troubleshooting

### ❌ Problema: "Connection refused" ao OpenSearch

**Causa:** OpenSearch não está rodando ou credenciais incorretas

**Solução:**
```bash
# Verificar se OpenSearch está rodando
curl -s -k -u admin:<SENHA_ADMIN> https://localhost:9200 | jq .

# Se não responder, inicie OpenSearch (ver capítulo 1)
docker-compose -f ../../docker-compose.yml up -d opensearch
```

### ❌ Problema: "Permission denied" ao executar scripts

**Solução:**
```bash
chmod +x *.sh
bash 01-descompactar-logs.sh
```

### ❌ Problema: Nenhum documento ingerido após 5 minutos

**Verificações:**

1. Verifique logs do Fluent Bit:
   ```bash
   docker-compose -f docker-compose-fluentbit.yml logs -f
   ```

2. Verifique se arquivo de log existe:
   ```bash
   ls -lh apache_logs_prepared.log
   ```

3. Verifique sintaxe de configuração:
   ```bash
   fluent-bit -c fluent-bit.conf --dry-run
   ```

### ❌ Problema: Fluent Bit encerra com erro no Lua

**Solução:** Verifique sintaxe do `sampling.lua`

```bash
# Testar Lua localmente
lua5.1 -c sampling.lua
```

---

## 📊 Análise dos Dados Ingeridos

Após a ingestão bem-sucedida, você pode executar análises:

```bash
# 1. Estatísticas gerais
curl -s -k -u admin:<SENHA_ADMIN> \
  -H "Content-Type: application/json" \
  https://localhost:9200/logstash-apache-*/_search \
  -d '{
    "size": 0,
    "aggs": {
      "status_distribution": {
        "terms": { "field": "code", "size": 10 }
      }
    }
  }' | jq '.aggregations'

# 2. Top 10 caminhos requisitados
curl -s -k -u admin:<SENHA_ADMIN> \
  -H "Content-Type: application/json" \
  https://localhost:9200/logstash-apache-*/_search \
  -d '{
    "size": 0,
    "aggs": {
      "top_paths": {
        "terms": { "field": "path", "size": 10 }
      }
    }
  }' | jq '.aggregations'

# 3. Taxa de sucesso (200) vs erros (4xx/5xx)
curl -s -k -u admin:<SENHA_ADMIN> \
  -H "Content-Type: application/json" \
  https://localhost:9200/logstash-apache-*/_search \
  -d '{
    "size": 0,
    "aggs": {
      "success_rate": {
        "filters": {
          "filters": {
            "success": { "term": { "code": 200 } },
            "client_error": { "range": { "code": { "gte": 400, "lt": 500 } } },
            "server_error": { "range": { "code": { "gte": 500, "lt": 600 } } }
          }
        }
      }
    }
  }' | jq '.aggregations'
```

---

## 📚 Aprendizados Principais

1. **Parsers REGEX**: Como estruturar dados não-estruturados
2. **Filtragem com Grep**: Remover dados desnecessários no pipeline
3. **Lua Scripting**: Lógica customizada em Fluent Bit
4. **Sampling**: Técnica de redução de dados mantendo qualidade
5. **Padrão Logstash**: Nomenclatura de índices com data (`logstash-YYYY.MM.DD`)
6. **Pipeline de Processamento**: INPUT → FILTER → OUTPUT

---

## ✅ Conclusão

Quando completado, você terá:

- ✅ Descompactado e explorado um dataset real de ~14.000 requisições
- ✅ Configurado um pipeline completo de ingestão
- ✅ Implementado filtragem inteligente de dados
- ✅ Aplicado estratégia de sampling baseada em lógica
- ✅ Ingerido dados no OpenSearch seguindo padrões profissionais
- ✅ Validado a qualidade dos dados ingeridos

Este exercício fornece as bases para construir pipelines de ingestão em ambientes reais!

---

## 📖 Referências

- [Fluent Bit Documentation](https://docs.fluentbit.io)
- [Fluent Bit Output: OpenSearch](https://docs.fluentbit.io/manual/pipeline/outputs/opensearch)
- [Fluent Bit Filters](https://docs.fluentbit.io/manual/pipeline/filters)
- [OpenSearch Logstash Index Pattern](https://opensearch.org/docs)
