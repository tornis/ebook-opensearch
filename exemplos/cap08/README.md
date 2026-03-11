# Exemplos Práticos — Capítulo 8: Ingest Pipelines

Exemplos executáveis de **Ingest Pipelines** do OpenSearch 3.5.

## 📋 Estrutura

- **README.md** — Este arquivo
- **01-basic-pipeline.sh** — Pipeline básico com transformação
- **02-parsing-apache.sh** — Parsing de Apache Log com Grok
- **03-enrichment-pipeline.sh** — Enriquecimento condicional
- **04-complex-pipeline.sh** — Pipeline complexo com validação
- **05-simulate-test.sh** — Testes e simulação de pipelines
- **dados-exemplo.json** — Dados para testes

## 🚀 Quick Start

### 1. Pré-requisito: OpenSearch já deve estar rodando

```bash
# Verificar se OpenSearch está operacional
curl -sk -u admin:Admin@123456 https://localhost:9200/_cluster/health | jq .
```

### 2. Executar exemplos

```bash
cd exemplos/cap08

# Exemplo 1: Pipeline básico
bash 01-basic-pipeline.sh

# Exemplo 2: Parsing Apache
bash 02-parsing-apache.sh

# Exemplo 3: Enriquecimento
bash 03-enrichment-pipeline.sh

# Exemplo 4: Pipeline complexo
bash 04-complex-pipeline.sh

# Exemplo 5: Simulação e testes
bash 05-simulate-test.sh
```

## 📊 O que cada exemplo demonstra

### Exemplo 1: Transformação Básica

```bash
bash 01-basic-pipeline.sh
```

**Conceitos:**
- Criar pipeline simples
- Adicionar campos com `set`
- Converter tipos com `convert`
- Indexar documento usando o pipeline
- Verificar resultado

**Pipeline criado:** `transformacao-basica`

**Entrada:**
```json
{
  "tipo": "requisicao",
  "duracao_ms": "2500",
  "usuario": "alice"
}
```

**Saída:** Campo `duracao_ms` convertido para integer, `data_ingestao` adicionado.

---

### Exemplo 2: Parsing Apache com Grok

```bash
bash 02-parsing-apache.sh
```

**Conceitos:**
- Usar `grok` processor para parsing
- Padrões IPORHOST, WORD, DATA, GREEDYDATA
- Tratamento de erros com `on_failure`
- Converter timestamp para @timestamp
- Lógica condicional para classificar status codes

**Pipeline criado:** `parse-apache-logs`

**Entrada:** Linha de log Apache em formato Combined Log Format
```
192.168.1.100 - - [10/Mar/2025:14:32:45 +0000] "GET /api/users HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
```

**Saída:** Campos extraídos (client_ip, metodo, recurso, status_code, bytes, user_agent, @timestamp)

---

### Exemplo 3: Enriquecimento Condicional

```bash
bash 03-enrichment-pipeline.sh
```

**Conceitos:**
- Múltiplas condições `if`
- Mapear valores (DEBUG → 10, INFO → 20, WARN → 30, ERROR → 40)
- Marcar registros críticos
- Adicionar campos derivados baseados em lógica

**Pipeline criado:** `enriquecimento-inteligente`

**Transformações:**
- `level` (string) → `severidade_numerica` (integer)
- Se `severidade_numerica >= 40`, marcar como `critico: true`
- Se `critico`, adicionar `alerta_slack` com mensagem formatada

---

### Exemplo 4: Pipeline Complexo com Validação

```bash
bash 04-complex-pipeline.sh
```

**Conceitos:**
- Parsing com `dissect` (alternativa simples ao Grok)
- Conversão de tipos com tratamento de erro
- Remover campos temporários
- Tratamento global de falhas com `on_failure` no pipeline
- Múltiplos processadores em sequência

**Pipeline criado:** `processamento-completo`

**Fluxo:**
1. Parse com Dissect
2. Converter data e duracao_ms
3. Adicionar versão
4. Remover campos temporários
5. Se falhar, marcar erro

---

### Exemplo 5: Simulação e Testes

```bash
bash 05-simulate-test.sh
```

**Conceitos:**
- Usar `_simulate` antes de usar pipeline em produção
- Testar com múltiplos documentos
- Validar transformações
- Verificar tratamento de erros
- Listar todos os pipelines criados

**Demonstra:**
- Simulação de pipeline sem indexar documentos
- Comparação entre sucesso e erro
- Resposta de simulação mostrando cada etapa

---

## 🔧 Troubleshooting

### Erro: "Pipeline não encontrado"

O pipeline ainda não foi criado. Execute o exemplo correspondente primeiro:

```bash
bash 01-basic-pipeline.sh
```

### Erro ao indexar com pipeline

Verifique se o pipeline foi criado corretamente:

```bash
curl -sk -u admin:Admin@123456 https://localhost:9200/_ingest/pipeline | jq .
```

### Documentos não aparecem no índice

Aguarde alguns segundos para indexação:

```bash
sleep 2
curl -sk -u admin:Admin@123456 https://localhost:9200/pipelines-*/_count | jq .
```

## 🧹 Limpeza

```bash
# Deletar pipelines criados
curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/transformacao-basica

curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/parse-apache-logs

curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/enriquecimento-inteligente

curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/_ingest/pipeline/processamento-completo

# Deletar índices criados
curl -sk -X DELETE -u admin:Admin@123456 \
  https://localhost:9200/pipelines-*
```

## 📚 Referências

- **Documentação Ingest Pipelines:** https://docs.opensearch.org/latest/ingest-pipelines/
- **Processadores:** https://docs.opensearch.org/latest/ingest-pipelines/processors/
- **Capítulo 8:** `capitulos/08_ingest_pipelines.md`
- **Exercícios:** `exercicios/cap08/`

---

**Última atualização:** Março 2026
