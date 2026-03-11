# Exercícios Práticos — Capítulo 7: Data Prepper

Exercícios de fixação para consolidar o aprendizado sobre Data Prepper e ingestão de dados.

## 📋 Estrutura

- **carregar.sh** — Script para carregar dados de exemplo no Data Prepper
- **dados.ndjson** — Dados em formato NDJSON para exercícios
- **exercicios.md** — Enunciados e soluções
- **README.md** — Este arquivo

## 🚀 Quick Start

### 1. Iniciar ambiente

```bash
# Navegar até a pasta do projeto
cd /mnt/projetos/teste/ebook-opensearch

# Subir Data Prepper + OpenSearch (da pasta de exemplos)
cd exemplos/cap07
docker-compose up -d

# Voltar para exercícios
cd ../../exercicios/cap07
```

### 2. Carregar dados

```bash
# Carregar todos os dados de exercício
bash carregar.sh

# Ou listar dados disponíveis
bash carregar.sh list
```

### 3. Resolver exercícios

Consulte `exercicios.md` para enunciados, dados e soluções passo-a-passo.

## 📊 Dados Disponíveis

### Dataset: Logs Educacionais (dados.ndjson)

**Composição:**
- 100 logs de aplicação estruturados
- Múltiplos níveis de severidade (DEBUG, INFO, WARN, ERROR)
- Múltiplos serviços (api-server, database, cache, queue)
- Timestamps entre 01/Jan/2025 e 31/Jan/2025

**Formato:**
```ndjson
{"timestamp":"2025-01-01T08:15:30.123Z","level":"INFO","service":"api-server","message":"Request processed","duration_ms":145,"status":200}
{"timestamp":"2025-01-01T08:15:31.456Z","level":"ERROR","service":"database","message":"Connection timeout","duration_ms":5000,"status":500}
...
```

**Campos:**
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `timestamp` | ISO8601 | Data/hora do evento |
| `level` | string | DEBUG, INFO, WARN, ERROR, FATAL |
| `service` | string | api-server, database, cache, queue |
| `message` | string | Descrição do evento |
| `duration_ms` | integer | Duração em milissegundos |
| `status` | integer | HTTP status code ou code interno |

## 📝 Exercícios

### Estrutura de cada exercício:

1. **Enunciado** — O que você precisa fazer
2. **Dados** — Quais dados usar (índice/arquivo)
3. **Objetivo** — O que espera alcançar
4. **Solução** — Passo-a-passo com resposta

### Navegação

Todos os exercícios estão em **exercicios.md**:

```bash
# Abrir arquivo com enunciados
cat exercicios.md

# Ou usar editor
vim exercicios.md
nano exercicios.md
```

## 🔧 Troubleshooting

### Erro ao carregar dados

```bash
# Verificar se Data Prepper está rodando
curl -s http://localhost:21000/health | jq .

# Verificar logs
docker logs data-prepper | tail -50

# Reiniciar containers
docker-compose -f ../../exemplos/cap07/docker-compose.yml restart
```

### Dados não aparecem em OpenSearch

```bash
# Aguardar processamento (alguns segundos)
sleep 5

# Verificar índices criados
curl -s http://localhost:9200/_cat/indices?v

# Contar documentos
curl -s http://localhost:9200/logs-app-*/_count | jq .
```

### Resetar ambiente

```bash
# Parar containers
cd ../../exemplos/cap07
docker-compose down -v

# Remover dados locais
cd ../../exercicios/cap07
rm -f dados-carregados.txt

# Reiniciar
docker-compose -f ../../exemplos/cap07/docker-compose.yml up -d
bash carregar.sh
```

## 📚 Referências

- **Capítulo 7:** `capitulos/07_data_prepper_ingestao.md`
- **Exemplos práticos:** `exemplos/cap07/`
- **Documentação Data Prepper:** https://docs.opensearch.org/latest/data-prepper/

---

**Última atualização:** Março 2026
