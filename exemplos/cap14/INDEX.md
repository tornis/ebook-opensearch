# Capítulo 14 - Ferramentas Práticas para OpenSearch

Índice de recursos e ferramentas práticas para trabalhar com OpenSearch.

## 📚 Recursos Disponíveis

### 1. 📊 Gerador de Logs Apache
**Arquivo:** `apache_log_generator.py`

Simula logs de acesso Apache em formato JSON para análise e testes.

**Características:**
- ✅ Taxa de sucessos (2xx): 80-90%
- ✅ Taxa de erros (4xx): 5-10% (400, 401, 403)
- ✅ Taxa de latência alta: 0-30% configurável
- ✅ 10 IPs fixos sempre os mesmos
- ✅ URLs realistas (login, busca, exploração)
- ✅ Envio automático para OpenSearch via Bulk API
- ✅ Formato Apache Combined + JSON estruturado

**Uso Rápido:**
```bash
python apache_log_generator.py \
  --opensearch-url https://localhost:9200 \
  --opensearch-user admin \
  --opensearch-password Admin@123456 \
  --count 100
```

**Com Latência Customizada:**
```bash
python apache_log_generator.py \
  --latency-rate 20 \
  --latency-threshold 2000 \
  --count 500
```

**Documentação:** [README.md](./README.md)

---

### 2. 📝 Dataset de Textos para Vetorização
**Arquivo:** `gerar-dataset-textos.py`

Gera dataset com 50 textos sobre 3 temas para experimentos de RAG e vetorização.

**Características:**
- ✅ 50 textos distribuídos em 3 temas
- ✅ ~20 linhas por texto
- ✅ Temas: OpenSearch, Elasticsearch, RAG
- ✅ Formato NDJSON para Bulk API
- ✅ Índice: `temas-ti`
- ✅ Pronto para embeddings e vector search

**Temas Cobertos:**
- 🔍 **OpenSearch** (~17 textos) — busca, clustering, ingestão, segurança, performance
- 📊 **Elasticsearch** (~17 textos) — query DSL, agregações, beats, logstash, stack
- 🤖 **RAG** (~16 textos) — retrieval, generation, embeddings, integração, avaliação

**Uso Rápido:**
```bash
# Gerar dataset
python gerar-dataset-textos.py

# Carregar em OpenSearch
bash carregar-dataset-textos.sh
```

**Documentação:** [DATASET-README.md](./DATASET-README.md)

---

### 3. 🔄 Script de Carregamento
**Arquivo:** `carregar-dataset-textos.sh`

Carrega o dataset de textos no OpenSearch via Bulk API com validação.

**Características:**
- ✅ Interface interativa
- ✅ Validação de arquivo
- ✅ Estatísticas do upload
- ✅ Verificação pós-indexação
- ✅ Mensagens de erro claras

**Uso:**
```bash
bash carregar-dataset-textos.sh
```

---

### 4. 🧪 Teste Local de Logs
**Arquivo:** `teste-local.py`

Testa geração de logs localmente sem OpenSearch para validação.

**Características:**
- ✅ Validação de distribuição de rates
- ✅ Teste de latência customizada
- ✅ Exemplos de logs gerados
- ✅ Sem dependências externas

**Uso:**
```bash
python teste-local.py
```

---

### 5. 📍 Exemplos de Uso com Latência
**Arquivo:** `exemplo-uso-latencia.sh`

Script interativo com 4 exemplos de uso do gerador com diferentes configurações de latência.

**Exemplos Inclusos:**
1. 10% latência alta (padrão) — 100 logs
2. 20% latência alta — 500 logs
3. 30% latência alta — 200 logs
4. Customizado (erro + latência) — 1000 logs

**Uso:**
```bash
bash exemplo-uso-latencia.sh
```

---

### 6. 🔍 Exemplos de Consultas ao Dataset
**Arquivo:** `exemplo-consultas-dataset.sh`

10 exemplos de consultas ao dataset de textos em OpenSearch.

**Exemplos Inclusos:**
1. Contar documentos
2. Buscar por tema (OpenSearch)
3. Buscar por tema (Elasticsearch)
4. Full-text search
5. Agregação por tema
6. Estatísticas de tamanho
7. Busca com filtro múltiplo
8. Busca com wildcard
9. Scroll para paginação
10. Exportar documentos

**Uso:**
```bash
bash exemplo-consultas-dataset.sh
```

---

## 🚀 Fluxo de Uso Recomendado

### Cenário 1: Análise de Logs

```bash
# 1. Gerar 1000 logs com diferentes rates
python apache_log_generator.py --count 1000

# 2. Visualizar no Kibana
# https://localhost:5601

# 3. Analisar padrões
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/apache-logs/_search \
  -H "Content-Type: application/json" \
  -d '{"aggs": {"por_status": {"terms": {"field": "status"}}}}'
```

### Cenário 2: Preparação para RAG

```bash
# 1. Gerar dataset de textos
python gerar-dataset-textos.py

# 2. Carregar em OpenSearch
bash carregar-dataset-textos.sh

# 3. Explorar dataset
bash exemplo-consultas-dataset.sh

# 4. Gerar embeddings
# (Seu código aqui para vetorização)

# 5. Testar RAG com vector search
# (Sua implementação de RAG)
```

### Cenário 3: Teste de Performance

```bash
# 1. Gerar muitos logs
python apache_log_generator.py --count 50000 --batch-size 500

# 2. Medir latência
time python apache_log_generator.py --count 10000

# 3. Analisar índices
curl -sk -u admin:Admin@123456 https://localhost:9200/_cat/indices?v
```

---

## 📊 Parâmetros Apache Log Generator

| Parâmetro | Padrão | Descrição |
|-----------|--------|-----------|
| `--opensearch-url` | `https://localhost:9200` | URL do OpenSearch |
| `--opensearch-user` | `admin` | Usuário |
| `--opensearch-password` | `Admin@123456` | Senha |
| `--verify-cert` | `false` | Verificar SSL |
| `--success-rate` | `85` | Taxa 2xx (80-90%) |
| `--error-rate` | `8` | Taxa 4xx (5-10%) |
| `--latency-rate` | `10` | Taxa latência alta (0-30%) |
| `--latency-threshold` | `1000` | Limiar latência (ms) |
| `--count` | `100` | Número de logs |
| `--interval` | `0` | Intervalo entre logs (s) |
| `--batch-size` | `50` | Tamanho do lote |
| `--index` | `apache-logs` | Nome do índice |

---

## 📂 Arquivos do Capítulo 14

```
exemplos/cap14/
├── apache_log_generator.py           ← Gerador de logs (principal)
├── teste-local.py                    ← Testes locais sem OpenSearch
├── exemplo-uso-latencia.sh           ← Exemplos interativos
├── gerar-dataset-textos.py           ← Gerador de textos (RAG)
├── carregar-dataset-textos.sh        ← Carregador de dataset
├── exemplo-consultas-dataset.sh      ← Exemplos de consultas
├── README.md                         ← Documentação do gerador
├── DATASET-README.md                 ← Documentação do dataset
└── INDEX.md                          ← Este arquivo
```

---

## 🔧 Dependências

### apache_log_generator.py
```bash
pip install requests
```

### gerar-dataset-textos.py
```
# Nenhuma dependência! Usa apenas stdlib
```

### Scripts .sh
```bash
# curl (geralmente pré-instalado)
# jq (para formatação JSON)
# bash 4+
```

---

## 💡 Dicas Práticas

### 1. Testar Sem OpenSearch
```bash
# Validar geração antes de enviar
python teste-local.py
```

### 2. Gerar Dados Continuamente
```bash
# Loop infinito a cada 60 segundos
while true; do
  python apache_log_generator.py --count 100 --interval 0.5
  sleep 60
done
```

### 3. Analisar com jq
```bash
# Extrair campos específicos
curl ... | jq '.hits.hits[] | {status: ._source.status, latency: ._source.response_time_ms}'
```

### 4. Exportar para CSV
```bash
curl ... | jq -r '.hits.hits[] | [._source.status, ._source.response_time_ms] | @csv' > data.csv
```

### 5. Monitorar em Tempo Real
```bash
# Contar documentos a cada 5 segundos
watch -n 5 'curl -sk -u admin:Admin@123456 https://localhost:9200/apache-logs/_count | jq .'
```

---

## 🎯 Casos de Uso

| Caso | Ferramenta | Comando |
|------|-----------|---------|
| Testar busca full-text | apache_log_generator | `--count 1000` |
| Testar agregações | dataset-textos | `--count 50` |
| Testar vector search | dataset-textos + embeddings | N/A |
| Testar latência | apache_log_generator | `--latency-rate 25` |
| Benchmark | apache_log_generator | `--count 100000` |
| RAG preparation | dataset-textos | Completo |
| Log analysis | apache_log_generator | Padrão |
| Security testing | apache_log_generator | 5% exploração |

---

## 📞 Suporte

**Problemas com apache_log_generator?**
- Verificar conexão com OpenSearch
- Usar `--verify-cert false` para auto-assinado
- Testar com `python teste-local.py`

**Problemas com dataset?**
- Verificar arquivo NDJSON gerado
- Usar `bash carregar-dataset-textos.sh` para interface amigável
- Consultar `DATASET-README.md`

**Erros de conexão?**
- Iniciar OpenSearch: `docker compose -f exemplos/docker-compose.single-node.yml up -d`
- Verificar URL e credenciais
- Testar com curl: `curl -sk -u admin:Admin@123456 https://localhost:9200`

---

## 📖 Referências

- [Documentação OpenSearch](https://docs.opensearch.org/)
- [Bulk API](https://docs.opensearch.org/latest/api-reference/document-apis/bulk/)
- [Query DSL](https://docs.opensearch.org/latest/query-dsl/)
- [Vector Search](https://docs.opensearch.org/latest/search-plugins/neural-search/)

---

**Criado:** Março 2026
**Última atualização:** 2026-03-20
