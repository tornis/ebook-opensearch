# Exercícios Práticos — Capítulo 8: Ingest Pipelines

Exercícios de fixação para consolidar o aprendizado sobre Ingest Pipelines.

## 📋 Estrutura

- **carregar.sh** — Script para carregar dados de exemplo
- **dados.ndjson** — Dados em formato NDJSON para exercícios
- **exercicios.md** — Enunciados e soluções
- **README.md** — Este arquivo

## 🚀 Quick Start

### 1. Iniciar ambiente

```bash
# OpenSearch já deve estar rodando
curl -sk -u admin:Admin@123456 https://localhost:9200/_cluster/health | jq .
```

### 2. Carregar dados

```bash
cd exercicios/cap08

# Carregar dados de exemplo
bash carregar.sh

# Ou limpar dados
bash carregar.sh clean
```

### 3. Resolver exercícios

Consulte `exercicios.md` para enunciados, dados e soluções passo-a-passo.

## 📊 Dados Disponíveis

### Dataset: Logs Estruturados (dados.ndjson)

**Composição:**
- 100 logs de aplicação estruturados
- Múltiplos níveis (DEBUG, INFO, WARN, ERROR, FATAL)
- Múltiplos serviços (api-server, database, cache, queue)
- Timestamps variados

**Formato:**
```ndjson
{"timestamp":"2025-03-10T08:00:00Z","level":"INFO","service":"api-server","message":"Request received","duration_ms":145,"status_code":200}
{"timestamp":"2025-03-10T08:00:01Z","level":"ERROR","service":"database","message":"Connection timeout","duration_ms":5000,"status_code":500}
```

**Campos:**
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `timestamp` | ISO8601 | Data/hora do evento |
| `level` | string | DEBUG, INFO, WARN, ERROR, FATAL |
| `service` | string | api-server, database, cache, queue |
| `message` | string | Descrição do evento |
| `duration_ms` | integer | Duração em milissegundos |
| `status_code` | integer | HTTP status ou código interno |

## 📝 Exercícios

Todos os exercícios estão em **exercicios.md**:

### Estrutura de cada exercício:

1. **Enunciado** — O que você precisa fazer
2. **Dados** — Quais dados usar
3. **Objetivo** — O que espera alcançar
4. **Solução** — Passo-a-passo com resposta

### Exercícios disponíveis:

1. **Exercício 1:** Criar pipeline básico de transformação
2. **Exercício 2:** Parsing de logs com Grok
3. **Exercício 3:** Enriquecimento com lógica condicional
4. **Exercício 4:** Pipeline com tratamento de erro
5. **Exercício 5:** Desafio integrado com múltiplas transformações

### Consultar exercícios:

```bash
cat exercicios.md
```

## 🔧 Troubleshooting

### Erro ao carregar dados

```bash
# Verificar se OpenSearch está rodando
curl -sk -u admin:Admin@123456 https://localhost:9200/_cluster/health | jq .

# Verificar pipelines disponíveis
curl -sk -u admin:Admin@123456 https://localhost:9200/_ingest/pipeline | jq .
```

### Dados não aparecem no índice

Aguardar alguns segundos para indexação:

```bash
sleep 2
curl -sk -u admin:Admin@123456 https://localhost:9200/logs-*/_count | jq .
```

### Resetar ambiente

```bash
# Limpar dados locais
rm -f dados-carregados.txt

# Deletar índices
curl -sk -X DELETE -u admin:Admin@123456 https://localhost:9200/logs-*

# Deletar pipelines
curl -sk -X DELETE -u admin:Admin@123456 https://localhost:9200/_ingest/pipeline/*
```

## 📚 Referências

- **Capítulo 8:** `capitulos/08_ingest_pipelines.md`
- **Exemplos práticos:** `exemplos/cap08/`
- **Documentação Oficial:** https://docs.opensearch.org/latest/ingest-pipelines/

---

**Última atualização:** Março 2026
