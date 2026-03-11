# 8 Ingest Pipelines: Processamento de Dados Antes da Indexação

## 8.1 Objetivos de Aprendizagem

Ao finalizar este capítulo, você será capaz de:

1. **Compreender** a arquitetura de Ingest Pipelines e seu papel na ingestão de dados
2. **Criar** pipelines funcionais com múltiplos processadores em sequência
3. **Implementar** transformações de dados usando Grok, Dissect, Set e outros processadores
4. **Aplicar** lógica condicional para processamento seletivo de documentos
5. **Validar** pipelines antes da implantação em produção
6. **Resolver** problemas comuns de processamento usando error handlers

---

## 8.2 O que é um Ingest Pipeline?

### 8.2.1 Definição

Um **Ingest Pipeline** é um fluxo de processamento de dados que transforma, enriquece ou manipula documentos **antes de serem indexados** no OpenSearch. É a primeira linha de processamento na ingestão de dados, permitindo tratamento de informações sem necessidade de aplicações externas.

**Analogia útil:** Se você estivesse recebendo correspondência, um Ingest Pipeline seria como os funcionários que abrem envelopes, verificam conteúdo, corrigem endereços e organizam cartas antes de arquivá-las.

### 8.2.2 Quando Usar Ingest Pipelines?

#### ✅ Use Ingest Pipelines quando:

- Você precisa **transformar dados estruturados** (logs, eventos, mensagens)
- A transformação é **simples a moderada** (não requer integração externa)
- Você quer **centralizar lógica de processamento** no OpenSearch
- Precisa **extrair campos** de textos não estruturados
- Necessita **enriquecer dados** com campos calculados
- Deseja **validar ou limpar dados** antes da indexação

#### ❌ Não use Ingest Pipelines para:

- **Processamento complexo** (use Data Prepper ou Logstash)
- **Enriquecimento com APIs externas** (latência impactaria indexação)
- **Machine Learning em tempo real** (use plugins dedicados)
- **Processamento em lote** que pode falhar

### 8.2.3 Arquitetura e Fluxo

```
Documento Incoming (JSON)
           ↓
    ┌──────────────────┐
    │  Ingest Pipeline │
    │  ┌────────────┐  │
    │  │ Processor 1│  │  (Grok, Set, Remove, etc.)
    │  └────────────┘  │
    │        ↓         │
    │  ┌────────────┐  │
    │  │ Processor 2│  │  (Conditional, Foreach, etc.)
    │  └────────────┘  │
    │        ↓         │
    │  ┌────────────┐  │
    │  │ Processor N│  │  (Error Handler)
    │  └────────────┘  │
    │        ↓         │
    └──────────────────┘
           ↓
    Documento Processado
           ↓
      OpenSearch Index
```

**Características principais:**

1. **Sequencial** — Processadores executam em ordem
2. **Transacional** — Se uma etapa falha, há opções de tratamento
3. **Inteligente** — Pode acessar e referenciar campos dinamicamente
4. **Eficiente** — Executado junto com a requisição de indexação

---

## 8.3 Conceitos Fundamentais

### 8.3.1 Processadores (Processors)

Um **processador** é uma unidade de operação que realiza uma ação específica em um documento. O OpenSearch fornece 40+ processadores categorizados:

| Categoria | Exemplos | Uso |
|-----------|----------|-----|
| **Transformação** | `set`, `remove`, `rename`, `copy`, `convert`, `append` | Modificar campos |
| **Parsing** | `grok`, `dissect`, `json`, `csv`, `kv` | Extrair estrutura |
| **Texto** | `lowercase`, `uppercase`, `trim`, `gsub`, `html_strip` | Normalizar texto |
| **Controle** | `drop`, `fail`, `foreach`, `pipeline`, `conditional` | Lógica e fluxo |
| **Enriquecimento** | `user_agent`, `geoip`, `date` | Adicionar contexto |
| **ML/Vetores** | `text_embedding`, `inference`, `text_chunking` | Processamento avançado |

### 8.3.2 Sintaxe Básica de um Pipeline

```json
PUT _ingest/pipeline/nome-do-pipeline
{
  "description": "Descrição do que o pipeline faz",
  "processors": [
    {
      "processor_name": {
        "field": "campo_de_entrada",
        "value": "valor_ou_expressão",
        "target_field": "campo_de_saida",
        "if": "ctx.campo != null"
      }
    }
  ],
  "on_failure": [
    {
      "set": {
        "field": "error_message",
        "value": "Pipeline falhou: {{ _ingest.on_failure_message }}"
      }
    }
  ]
}
```

**Componentes:**

- **`processors`** — Array de processadores executados sequencialmente
- **`field`** — Campo de entrada (pode usar notação ponto: `user.name`)
- **`value`** — Valor a processar (suporta templating: `{{ field }}`)
- **`target_field`** — Onde armazenar resultado (padrão: sobrescreve `field`)
- **`if`** — Condição Painless para execução condicional
- **`on_failure`** — Processadores executados se houver erro

### 8.3.3 Referenciação Dinâmica

Os pipelines suportam **templating** para acessar dados dinamicamente:

```json
{
  "set": {
    "field": "processed_at",
    "value": "{{ _ingest.timestamp }}"
  }
}
```

**Variáveis disponíveis:**

| Variável | Descrição |
|----------|-----------|
| `{{ campo }}` | Acesso a campo do documento |
| `{{ campo.subcamp }}` | Acesso a campo aninhado |
| `{{ _ingest.timestamp }}` | Timestamp de ingestão |
| `{{ _ingest.pipeline }}` | Nome do pipeline |
| `{{ _ingest.doc.source }}` | Documento completo |

---

## 8.4 Processadores Essenciais

### 8.4.1 Set — Atribuir Valores

```json
{
  "set": {
    "field": "ambiente",
    "value": "producao"
  }
}
```

**Casos de uso:** Adicionar metadados, marcar versão, definir valores padrão.

### 8.4.2 Grok — Extrair Padrões

```json
{
  "grok": {
    "field": "mensagem",
    "patterns": ["%{WORD:tipo} - %{GREEDYDATA:descricao}"]
  }
}
```

**Exemplos de padrões:**
- `%{WORD}` — Uma palavra
- `%{NUMBER}` — Um número
- `%{IPORHOST}` — IP ou hostname
- `%{TIMESTAMP_ISO8601}` — Data ISO
- `%{GREEDYDATA}` — Resto da linha

### 8.4.3 Dissect — Analisar Padrões Simples

```json
{
  "dissect": {
    "field": "mensagem",
    "pattern": "%{nivel} - %{servico} - %{mensagem}"
  }
}
```

**Diferença do Grok:** Mais simples, mais rápido, sem expressões regulares.

### 8.4.4 Remove — Deletar Campos

```json
{
  "remove": {
    "field": ["campo_temporario", "debug_info"]
  }
}
```

### 8.4.5 Rename — Renomear Campos

```json
{
  "rename": {
    "field": "old_name",
    "target_field": "new_name"
  }
}
```

### 8.4.6 Convert — Converter Tipo de Dado

```json
{
  "convert": {
    "field": "status_code",
    "type": "integer"
  }
}
```

**Tipos suportados:** `integer`, `float`, `string`, `boolean`, `auto`

### 8.4.7 HTML Strip — Remover HTML

```json
{
  "html_strip": {
    "field": "descricao_html"
  }
}
```

### 8.4.8 Date — Converter Timestamps

```json
{
  "date": {
    "field": "log_timestamp",
    "target_field": "@timestamp",
    "formats": ["ISO8601", "yyyy-MM-dd HH:mm:ss"]
  }
}
```

---

## 8.5 Lógica Condicional

### 8.5.1 Execução Condicional com `if`

Execute um processador apenas se uma condição for verdadeira:

```json
{
  "set": {
    "field": "alerta",
    "value": "CRÍTICO",
    "if": "ctx.status_code >= 500"
  }
}
```

**Expressões válidas:**

```javascript
// Comparações
ctx.age > 30
ctx.level == "ERROR"
ctx.bytes_transferidos < 1024

// Operadores lógicos
ctx.status_code >= 400 && ctx.status_code < 500
ctx.log_level == "ERROR" || ctx.log_level == "FATAL"

// Null checks
ctx.correlacao_id != null
ctx.user != null && ctx.user.id != null

// String operations
ctx.tipo.contains("timeout")
ctx.mensagem.startsWith("[ERROR]")
```

### 8.5.2 Processador `foreach` — Iterar sobre Arrays

```json
{
  "foreach": {
    "field": "items",
    "processor": {
      "set": {
        "field": "_ingest._value.status",
        "value": "processado"
      }
    }
  }
}
```

### 8.5.3 Tratamento de Erros com `on_failure`

```json
{
  "grok": {
    "field": "mensagem",
    "patterns": ["%{WORD:tipo} %{GREEDYDATA:msg}"],
    "on_failure": [
      {
        "set": {
          "field": "parse_error",
          "value": "Grok falhou: {{ _ingest.on_failure_message }}"
        }
      },
      {
        "set": {
          "field": "tipo",
          "value": "desconhecido"
        }
      }
    ]
  }
}
```

---

## 8.6 Exemplos Práticos Completos

### 8.6.1 Pipeline 1: Transformação Básica

**Objetivo:** Converter um documento simples adicionando campos calculados.

```json
PUT _ingest/pipeline/transformacao-basica
{
  "description": "Adiciona campos calculados e converte tipos",
  "processors": [
    {
      "set": {
        "field": "data_ingestao",
        "value": "{{ _ingest.timestamp }}"
      }
    },
    {
      "convert": {
        "field": "duracao_ms",
        "type": "integer"
      }
    },
    {
      "set": {
        "field": "duracao_segundos",
        "value": "{{ duracao_ms / 1000 }}"
      }
    }
  ]
}
```

**Documento de entrada:**

```json
{
  "tipo": "requisicao",
  "duracao_ms": "2500",
  "usuario": "joão"
}
```

**Documento indexado:**

```json
{
  "tipo": "requisicao",
  "duracao_ms": 2500,
  "usuario": "joão",
  "data_ingestao": "2025-03-11T14:30:45.123Z",
  "duracao_segundos": 2.5
}
```

### 8.6.2 Pipeline 2: Parsing de Logs com Grok

**Objetivo:** Extrair campos estruturados de logs não estruturados.

```json
PUT _ingest/pipeline/parse-logs-apache
{
  "description": "Parse de Apache Common Log Format",
  "processors": [
    {
      "grok": {
        "field": "message",
        "patterns": [
          "%{IPORHOST:client_ip} %{HTTPDUSER:ident} %{HTTPDUSER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:metodo} %{DATA:recurso} HTTP/%{NUMBER:versao_http}\" %{NUMBER:status_code:int} (?:%{NUMBER:bytes:int}|-) \"%{DATA:referrer}\" \"%{GREEDYDATA:user_agent}\""
        ],
        "on_failure": [
          {
            "set": {
              "field": "parse_error",
              "value": true
            }
          }
        ]
      }
    },
    {
      "date": {
        "field": "timestamp",
        "target_field": "@timestamp",
        "formats": ["dd/MMM/yyyy:HH:mm:ss Z"]
      }
    },
    {
      "set": {
        "field": "tipo_erro",
        "value": "cliente",
        "if": "ctx.status_code >= 400 && ctx.status_code < 500"
      }
    },
    {
      "set": {
        "field": "tipo_erro",
        "value": "servidor",
        "if": "ctx.status_code >= 500"
      }
    }
  ]
}
```

**Documento de entrada:**

```json
{
  "message": "192.168.1.100 - - [10/Mar/2025:14:32:45 +0000] \"GET /api/users HTTP/1.1\" 200 1234 \"-\" \"Mozilla/5.0\""
}
```

**Documento indexado:**

```json
{
  "message": "192.168.1.100 - - [10/Mar/2025:14:32:45 +0000] \"GET /api/users HTTP/1.1\" 200 1234 \"-\" \"Mozilla/5.0\"",
  "client_ip": "192.168.1.100",
  "metodo": "GET",
  "recurso": "/api/users",
  "status_code": 200,
  "bytes": 1234,
  "user_agent": "Mozilla/5.0",
  "@timestamp": "2025-03-10T14:32:45.000Z"
}
```

### 8.6.3 Pipeline 3: Enriquecimento Condicional

**Objetivo:** Adicionar contexto e marcar eventos críticos.

```json
PUT _ingest/pipeline/enriquecimento-inteligente
{
  "description": "Enriquece logs com classificação de severidade",
  "processors": [
    {
      "set": {
        "field": "severidade_numerica",
        "value": 10,
        "if": "ctx.level == 'DEBUG'"
      }
    },
    {
      "set": {
        "field": "severidade_numerica",
        "value": 20,
        "if": "ctx.level == 'INFO'"
      }
    },
    {
      "set": {
        "field": "severidade_numerica",
        "value": 30,
        "if": "ctx.level == 'WARN'"
      }
    },
    {
      "set": {
        "field": "severidade_numerica",
        "value": 40,
        "if": "ctx.level == 'ERROR'"
      }
    },
    {
      "set": {
        "field": "critico",
        "value": true,
        "if": "ctx.severidade_numerica >= 40"
      }
    },
    {
      "set": {
        "field": "alerta_slack",
        "value": "Erro crítico em {{ servico }}: {{ mensagem }}",
        "if": "ctx.critico"
      }
    }
  ]
}
```

### 8.6.4 Pipeline 4: Cadeia Complexa com Validação

**Objetivo:** Processar logs com validação em múltiplas etapas.

```json
PUT _ingest/pipeline/processamento-completo
{
  "description": "Pipeline completo com parsing, validação e enriquecimento",
  "processors": [
    {
      "dissect": {
        "field": "raw_log",
        "pattern": "%{data} %{hora} [%{nivel}] %{servico} - %{mensagem}"
      }
    },
    {
      "date": {
        "field": "data",
        "target_field": "data_parsed",
        "formats": ["yyyy-MM-dd"]
      }
    },
    {
      "convert": {
        "field": "duracao_ms",
        "type": "integer",
        "on_failure": [
          {
            "set": {
              "field": "duracao_ms",
              "value": 0
            }
          }
        ]
      }
    },
    {
      "set": {
        "field": "pipeline_version",
        "value": "1.0"
      }
    },
    {
      "remove": {
        "field": ["raw_log", "data", "hora"]
      }
    }
  ],
  "on_failure": [
    {
      "set": {
        "field": "processamento_falhou",
        "value": true
      }
    },
    {
      "set": {
        "field": "erro_detalhes",
        "value": "{{ _ingest.on_failure_message }}"
      }
    }
  ]
}
```

---

## 8.7 Validação e Testes

### 8.7.1 Simulando um Pipeline (Dry Run)

Antes de implantar um pipeline em produção, **sempre simule** com dados de teste:

```bash
POST _ingest/pipeline/meu-pipeline/_simulate
{
  "docs": [
    {
      "_source": {
        "campo": "valor"
      }
    }
  ]
}
```

**Resposta:** Mostra exatamente como cada processador modificou o documento.

### 8.7.2 Usando Kibana Console

No Kibana/OpenSearch Dashboard:

1. Acesse **Dev Tools** → **Console**
2. Cole sua definição de pipeline
3. Execute com `PUT _ingest/pipeline/...`
4. Valide com `POST _ingest/pipeline/.../simulate`

### 8.7.3 Checklist de Validação

Antes de usar em produção:

- [ ] Pipeline simula corretamente com dados de teste
- [ ] Campos obrigatórios são validados
- [ ] Erros são tratados no `on_failure`
- [ ] Performance é aceitável (< 10ms por documento)
- [ ] Tipagem de dados está correta
- [ ] Valores nulos são tratados

---

## 8.8 Boas Práticas

### ✅ Faça:

1. **Use nomes descritivos** — `parse-apache-logs`, não `pipeline1`
2. **Documente com `description`** — Explique o propósito
3. **Teste antes de implantar** — Use `_simulate`
4. **Trate erros** — Sempre implemente `on_failure`
5. **Valide tipos** — Use `convert` para garantir tipos esperados
6. **Remova campos temporários** — Limpe campos de processamento intermediários
7. **Reutilize pipelines** — Use `pipeline` processor para chamar outros pipelines

### ❌ Evite:

1. **Processadores pesados** — Não abuse de Grok complexos
2. **Lógica externa** — Não chame APIs (use enriquecimento estático)
3. **Pipelines muito longos** — Divida em pipelines menores e reutilizáveis
4. **Campos não documentados** — Sempre documente novos campos
5. **Ignorar erros** — Sempre trate exceções

---

## 8.9 Síntese

Um **Ingest Pipeline** é um processador de dados integrado ao OpenSearch que:

- **Transforma** documentos antes da indexação
- **Extrai** campos de logs não estruturados (com Grok/Dissect)
- **Enriquece** com contexto e campos calculados
- **Valida** dados e trata erros
- **Melhora** a qualidade dos dados no índice

Use Ingest Pipelines para **transformações leves e estruturadas**. Para processamento complexo, use Data Prepper ou Logstash.

---

## 8.10 Referências

- 📘 [Documentação Oficial: Ingest Pipelines](https://docs.opensearch.org/latest/ingest-pipelines/)
- 📘 [Processadores Disponíveis](https://docs.opensearch.org/latest/ingest-pipelines/processors/index/)
- 📘 [Padrões Grok](https://github.com/elastic/logstash/blob/main/patterns/grok-patterns)
- 📘 [Simulação e Testes](https://docs.opensearch.org/latest/ingest-pipelines/test-pipeline/)
- 📘 Capítulo 7: `capitulos/07_data_prepper_ingestao.md` — Para comparação com Data Prepper
- 📚 Exemplos práticos: `exemplos/cap08/`
- 📚 Exercícios de fixação: `exercicios/cap08/`

---

**Última atualização:** Março 2026
