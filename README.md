# Ebook OpenSearch 3.5
## Um Guia Prático e Completo para Busca, Indexação e Análise de Dados

> Ebook técnico educacional em português (Brasil), formatado segundo normas ABNT para aprendizado progressivo de OpenSearch 3.5, com 75% conteúdo prático e 25% fundamentos teóricos.

---

## 🏢 Criado pela Tornis Tecnologia

**Este ebook é desenvolvido e mantido pela [Tornis Tecnologia](https://www.tornis.com.br)**

Parte integrante do programa de treinamento profissional **[Curso OpenSearch Total](https://www.opensearchtotal.com.br)**.

> Desde 2020, a Tornis Tecnologia oferece soluções especializadas em busca, indexação e análise de dados em tempo real com OpenSearch.

---

## 📚 Sobre o Ebook

Este ebook é um recurso técnico-educacional abrangente que cobre desde conceitos fundamentais até técnicas avançadas de busca, ingestão e análise de dados com OpenSearch 3.5. Estruturado em 8 capítulos progressivos, combina teoria sólida com exemplos práticos reproduzíveis em sala de aula, incluindo pipelines de ingestão com Fluent Bit, Logstash, Data Prepper e Ingest Pipelines.

**Parte integrante do [Curso OpenSearch Total](https://www.opensearchtotal.com.br)** — Programa de treinamento profissional oferecido pela **[Tornis Tecnologia](https://www.tornis.com.br)**.

### Público-Alvo
- Desenvolvedores iniciando com OpenSearch
- Engenheiros de dados buscando otimizar buscas
- Arquitetos de sistemas que trabalham com análise em tempo real
- Profissionais de DevOps configurando ambientes de busca

### Características
✅ **100% Prático** — Todos os exemplos executáveis em seu ambiente local
✅ **Datasets Realistas** — Mais de 1.200 documentos preparados para cada capítulo
✅ **Formato ABNT** — Ebook formatado conforme normas acadêmicas brasileiras
✅ **Diagramas Visuais** — Arquitetura e fluxos explicados com diagramas Excalidraw
✅ **Exercícios Validados** — Todas as queries testadas e documentadas

---

## 📖 Capítulos

### [Capítulo 1: Introdução e Arquitetura](capitulos/01_introducao_arquitetura.md)
**O que você aprenderá:**
- Histórico e evolução do Elasticsearch para OpenSearch
- Arquitetura distribuída: nós, shards e replicas
- Conceitos de cluster, índice e documento
- Instalação e setup com Docker Compose single-node
- Primeiros passos com REST API

**Índices de Exemplo:**
`livros` (CRUD básico), `vendas-2025` (mapping com shards)

---

### [Capítulo 2: Conceitos Fundamentais e CRUD](capitulos/02_conceitos.md)
**O que você aprenderá:**
- Tipos de dados e mapeamento explícito vs. dinâmico
- Analyzers e análise de texto
- Inverted index e tokenização
- Operações CRUD: CREATE, READ, UPDATE, DELETE via REST API
- Scripting e atualizações complexas

**Índices de Exemplo:**
`usuarios`, `produtos`, `produtos-dinamico`, `produtos-explicitamente-mapeado`, `blog-posts`, `logs-api`

---

### [Capítulo 3: Query DSL e PPL](capitulos/03_query_dsl_ppl.md)
**O que você aprenderá:**
- Query Context vs. Filter Context e scoring
- Queries de texto completo: match, multi_match, match_phrase
- Queries de termo único: term, range, exists, prefix
- Bool queries: combinação complexa de condições
- PPL (Piped Processing Language): análise de dados com pipelines
- Introdução a SQL no OpenSearch

**Índices de Exemplo:**
`articles`, `users`, `documents`, `products`, `events`, `store`, `news`, `job-listings`, `blog`, `api-logs`, `application-logs`, `orders`, `logs`, `customer-interactions`, `transactions`, `metrics`, `e-commerce`, `sales`, `error-logs` (19 índices)

---

### [Capítulo 4: Agregações e Análise de Dados](capitulos/04_aggregatios.md)
**O que você aprenderá:**
- Agregações de métricas: avg, sum, min, max, stats
- Agregações de buckets: terms, date_histogram, range
- Agregações aninhadas e sub-agregações
- Pipeline aggregations: moving_avg, derivative
- Casos de uso: dashboards, relatórios, análise temporal
- Otimização de performance

**Índices de Exemplo:**
`ecommerce-products`, `vendas`, `vendas-ecommerce`, `logs-api-2024`, `logs-web`, `sensor-iot`, `dados-financeiros`, `avaliacoes-clientes`, `analytics-website`, `system-health`, `product-reviews`, `abandoned-carts`, `transacoes-financeiras` (13 índices)

---

### [Capítulo 5: Ingestão de Dados com Fluent Bit](capitulos/05_fluentbit_ingestao.md)
**O que você aprenderá:**
- Conceitos de data pipelines e stream processing
- Instalação e configuração do Fluent Bit 4.2 em Docker
- Parsers para estruturação de logs (JSON, Regex, Logfmt, Multiline)
- Filters para transformação de dados (grep, record_modifier, lua)
- Ingestão end-to-end em OpenSearch com tratamento de erros
- Debugging e observabilidade com métricas HTTP

**Exercícios Práticos:** 4 exercícios com dados reais e scripts auxiliares

---

### [Capítulo 6: Ingestão de Dados com Logstash](capitulos/06_logstash_ingestao.md)
**O que você aprenderá:**
- Arquitetura de Logstash: input, filter, output pipeline
- Instalação e configuração do Logstash 8.x em Docker
- Filtros avançados: Grok, Dissect, Date, Mutate, Translate
- Ingestão de dados estruturados via JDBC (SQLite, MySQL)
- Desenvolvimento e validação de pipelines complexos
- Comparação: Logstash vs. Fluent Bit (quando usar cada um)

**Índices de Exemplo:**
5 pipelines de exemplo com processamento progressivo

---

### [Capítulo 7: Ingestão de Dados com Data Prepper](capitulos/07_data_prepper_ingestao.md)
**O que você aprenderá:**
- Arquitetura Data Prepper: sources, buffers, processors, sinks
- Instalação e configuração do Data Prepper 3.x em Docker
- Pipelines HTTP para ingestão de logs com OpenSearch sink
- Processadores especializados: Grok, Mutate, Date, Service Map
- Integração com Fluent Bit e OpenTelemetry Collector
- Comparação: Data Prepper vs. Logstash (quando usar cada um)

**Índices de Exemplo:**
4+ pipelines com diferentes padrões de ingestão

---

### [Capítulo 8: Ingest Pipelines: Processamento de Dados Antes da Indexação](capitulos/08_ingest_pipelines.md)
**O que você aprenderá:**
- Conceitos de Ingest Pipelines e seu papel na ingestão
- Arquitetura de processadores: sequencial, condicional, error handling
- Processadores essenciais: Set, Grok, Dissect, Remove, Rename, Convert, HTML Strip, Date
- Lógica condicional com Painless e variáveis dinâmicas
- Validação de pipelines com `_simulate` antes de produção
- Processadores foreach, drop, fail e pipeline nesting
- Comparação: Ingest vs. Data Prepper vs. Logstash (quando usar cada um)

**Índices de Exemplo:**
4+ pipelines com transformações progressivas

---

## 🚀 Quick Start

### 1. Pré-requisitos
```bash
# Docker Desktop instalado e em execução
# Git (para clonar o repositório)
```

### 2. Subir OpenSearch Localmente
```bash
docker compose -f exemplos/docker-compose.single-node.yml up -d
```

### 3. Carregar Todos os Datasets
```bash
bash exercicios/carregar-tudo.sh
```

### 4. Verificar Índices Carregados
```bash
curl -sk -u admin:<SENHA_ADMIN> https://localhost:9200/_cat/indices?v
```

### 5. Acessar OpenSearch Dashboards
Abra em seu navegador: **http://localhost:5601**

---

## 📁 Estrutura do Projeto

```
ebook-opensearch/
├── README.md                                    ← Este arquivo
├── CLAUDE.md                                    ← Instruções para Claude Code/IA
├── PUBLISH.sh                                   ← Script de publicação GitHub
│
├── capitulos/                                   ← CONTEÚDO TEÓRICO (25%)
│   ├── 01_introducao_arquitetura.md            ✓ Pronto
│   ├── 02_conceitos.md                         ✓ Pronto
│   ├── 03_query_dsl_ppl.md                     ✓ Pronto
│   ├── 04_aggregatios.md                       ✓ Pronto
│   ├── 05_fluentbit_ingestao.md                ✓ Pronto
│   ├── 06_logstash_ingestao.md                 ✓ Pronto
│   ├── 07_data_prepper_ingestao.md             ✓ Pronto
│   └── 08_ingest_pipelines.md                  ✓ Pronto
│
├── exemplos/                                    ← EXEMPLOS PRÁTICOS (75%)
│   ├── docker-compose.single-node.yml
│   ├── cap01/                                   ← Exemplos Cap 1
│   ├── cap02/                                   ← Exemplos Cap 2
│   ├── cap03/                                   ← Exemplos Cap 3
│   ├── cap04/                                   ← Exemplos Cap 4
│   ├── cap05/                                   ← Fluent Bit: config, parsers, Lua
│   ├── cap06/                                   ← Logstash: Dockerfile, pipelines, JDBC
│   ├── cap07/                                   ← Data Prepper: config, pipelines, sources
│   └── cap08/                                   ← Ingest Pipelines: processadores, validação
│
├── exercicios/                                  ← EXERCÍCIOS DE FIXAÇÃO
│   ├── README.md                                (Instruções gerais)
│   ├── carregar-tudo.sh                         (Carrega todos dados)
│   ├── cap01/                                   ← Exercícios Cap 1 (20 docs)
│   │   ├── carregar.sh
│   │   ├── dados.ndjson
│   │   └── exercicios.md
│   ├── cap02/                                   ← Exercícios Cap 2 (70+ docs)
│   │   ├── carregar.sh
│   │   ├── dados.ndjson
│   │   └── exercicios.md
│   ├── cap03/                                   ← Exercícios Cap 3 (450+ docs)
│   │   ├── carregar.sh
│   │   ├── dados.ndjson
│   │   └── exercicios.md
│   ├── cap04/                                   ← Exercícios Cap 4 (300+ docs)
│   │   ├── carregar.sh
│   │   ├── dados.ndjson
│   │   └── exercicios.md
│   ├── cap05/                                   ← Exercícios Cap 5 (Logs)
│   │   ├── README.md
│   │   ├── ex1-app-logs.ndjson
│   │   ├── ex2-apache-logs.txt
│   │   ├── ex3-malformed-logs.txt
│   │   └── ex4-ecommerce-logs.ndjson
│   ├── cap06/                                   ← Exercícios Cap 6 (Logstash)
│   │   ├── Dockerfile
│   │   ├── docker-compose-logstash.yml
│   │   ├── logstash/
│   │   │   ├── pipelines/
│   │   │   ├── setup.sh
│   │   │   └── test-pipelines.sh
│   │   └── datasets/
│   ├── cap07/                                   ← Exercícios Cap 7 (Data Prepper)
│   │   ├── docker-compose-dataprepper.yml
│   │   ├── config/
│   │   │   └── pipelines.yml
│   │   └── datasets/
│   └── cap08/                                   ← Exercícios Cap 8 (Ingest Pipelines)
│       ├── carregar.sh
│       ├── dados.ndjson
│       └── exercicios.md
│
├── testes/                                      ← RELATÓRIOS DE TESTES
│   ├── RELATORIO_TESTES_cap01_FINAL.md
│   ├── RELATORIO_TESTES_cap02_FINAL.md
│   ├── RELATORIO_TESTES_cap03_FINAL.md
│   ├── RELATORIO_TESTES_cap04_FINAL.md
│   ├── RELATORIO_TESTES_cap05_FINAL.md
│   ├── RELATORIO_TESTES_cap06_FINAL.md
│   ├── RELATORIO_TESTES_cap07_FINAL.md
│   └── RELATORIO_TESTES_cap08_FINAL.md
│
├── diagramas/                                   ← DIAGRAMAS (Excalidraw)
│   └── diagramas_opensearch.excalidraw.json
│
└── (Outros arquivos)
```

---

## 🔧 Artefatos e Recursos

### 📚 Capítulos com Exemplos e Exercícios

| # | Capítulo | Conteúdo | Exemplos | Exercícios | Testes |
|---|----------|----------|----------|-----------|--------|
| **01** | [Introdução e Arquitetura](capitulos/01_introducao_arquitetura.md) | Histórico, setup | [cap01/](exemplos/cap01/) | [cap01/](exercicios/cap01/) | [Relatório](testes/RELATORIO_TESTES_cap01_FINAL.md) |
| **02** | [Conceitos Fundamentais e CRUD](capitulos/02_conceitos.md) | Tipos, mappings | [cap02/](exemplos/cap02/) | [cap02/](exercicios/cap02/) | [Relatório](testes/RELATORIO_TESTES_cap02_FINAL.md) |
| **03** | [Query DSL e PPL](capitulos/03_query_dsl_ppl.md) | Queries, DSL, SQL | [cap03/](exemplos/cap03/) | [cap03/](exercicios/cap03/) | [Relatório](testes/RELATORIO_TESTES_cap03_FINAL.md) |
| **04** | [Agregações e Análise](capitulos/04_aggregatios.md) | Métricas, buckets | [cap04/](exemplos/cap04/) | [cap04/](exercicios/cap04/) | [Relatório](testes/RELATORIO_TESTES_cap04_FINAL.md) |
| **05** | [Ingestão com Fluent Bit](capitulos/05_fluentbit_ingestao.md) | Pipelines, logs | [cap05/](exemplos/cap05/) | [cap05/](exercicios/cap05/) | [Relatório](testes/RELATORIO_TESTES_cap05_FINAL.md) |
| **06** | [Ingestão com Logstash](capitulos/06_logstash_ingestao.md) | Filtros, JDBC | [cap06/](exemplos/cap06/) | [cap06/](exercicios/cap06/) | [Relatório](testes/RELATORIO_TESTES_cap06_FINAL.md) |
| **07** | [Ingestão com Data Prepper](capitulos/07_data_prepper_ingestao.md) | Pipelines, sources | [cap07/](exemplos/cap07/) | [cap07/](exercicios/cap07/) | [Relatório](testes/RELATORIO_TESTES_cap07_FINAL.md) |
| **08** | [Ingest Pipelines](capitulos/08_ingest_pipelines.md) | Processadores, condicional | [cap08/](exemplos/cap08/) | [cap08/](exercicios/cap08/) | [Relatório](testes/RELATORIO_TESTES_cap08_FINAL.md) |

### 🎨 Diagramas Visuais
| Recurso | Formato | Descrição |
|---------|---------|-----------|
| **Arquitetura OpenSearch** | [Excalidraw](diagramas/diagramas_opensearch.excalidraw.json) | Cluster, índices, shards, fluxos |

### 📊 Exemplos Práticos por Capítulo
| Capítulo | Link | Recursos |
|----------|------|----------|
| **Setup Base** | [exemplos/docker-compose.single-node.yml](exemplos/docker-compose.single-node.yml) | OpenSearch + Dashboards |
| **Cap 01** | [exemplos/cap01/](exemplos/cap01/) | Scripts e dados exemplo |
| **Cap 02** | [exemplos/cap02/](exemplos/cap02/) | Scripts e dados exemplo |
| **Cap 03** | [exemplos/cap03/](exemplos/cap03/) | Scripts e dados exemplo |
| **Cap 04** | [exemplos/cap04/](exemplos/cap04/) | Scripts e dados exemplo |
| **Cap 05** | [exemplos/cap05/](exemplos/cap05/) | Fluent Bit config + parsers + Lua |
| **Cap 06** | [exemplos/cap06/](exemplos/cap06/) | Logstash Dockerfile + pipelines JDBC |
| **Cap 07** | [exemplos/cap07/](exemplos/cap07/) | Data Prepper config + sources + sinks |
| **Cap 08** | [exemplos/cap08/](exemplos/cap08/) | Ingest Pipelines + Grok + validação |

### 💻 Exercícios e Datasets
| Recurso | Link | Documentos | Status |
|---------|------|-----------|--------|
| **Instruções** | [exercicios/README.md](exercicios/README.md) | — | ✅ |
| **Relatório de Testes** | [exercicios/RELATORIO_TESTES.md](exercicios/RELATORIO_TESTES.md) | — | ✅ |
| **Cap 01 — Introdução** | [exercicios/cap01/](exercicios/cap01/) | 20 | ✅ |
| **Cap 02 — Conceitos** | [exercicios/cap02/](exercicios/cap02/) | 70+ | ✅ |
| **Cap 03 — Query DSL** | [exercicios/cap03/](exercicios/cap03/) | 450+ | ✅ |
| **Cap 04 — Agregações** | [exercicios/cap04/](exercicios/cap04/) | 300+ | ✅ |
| **Cap 05 — Fluent Bit** | [exercicios/cap05/](exercicios/cap05/) | Logs + configs | ✅ |
| **Cap 06 — Logstash** | [exercicios/cap06/](exercicios/cap06/) | Pipelines + JDBC | ✅ |
| **Cap 07 — Data Prepper** | [exercicios/cap07/](exercicios/cap07/) | Pipelines + sources | ✅ |
| **Cap 08 — Ingest Pipelines** | [exercicios/cap08/](exercicios/cap08/) | 100 docs + pipelines | ✅ |

**Total:** 40+ índices com 1.200+ documentos testados e validados + Logstash + Data Prepper + Ingest Pipelines

---

## 🛠 Instruções Detalhadas de Uso

### Carregar Datasets por Capítulo

**Opção 1: Tudo de uma vez** (recomendado para primeira execução)
```bash
bash exercicios/carregar-tudo.sh
```

**Opção 2: Por capítulo individual**
```bash
# Capítulo 1
bash exercicios/cap01/carregar.sh

# Capítulo 2
bash exercicios/cap02/carregar.sh

# Capítulo 3
bash exercicios/cap03/carregar.sh

# Capítulo 4
bash exercicios/cap04/carregar.sh
```

> ℹ️ Cada script é **idempotente**: pode ser executado múltiplas vezes para reiniciar os dados.

### Verificar Saúde da Instalação
```bash
curl -sk -u admin:<SENHA_ADMIN> https://localhost:9200/_cluster/health?pretty
```

### Acessar os Dashboards
- **OpenSearch Dashboards:** http://localhost:5601
- **Dev Tools (Console):** http://localhost:5601/app/dev_tools

---

## 📚 Referências Oficiais

- [OpenSearch Documentation](https://docs.opensearch.org/)
- [OpenSearch Query DSL](https://docs.opensearch.org/latest/query-dsl/)
- [OpenSearch Aggregations](https://docs.opensearch.org/latest/aggregations/)
- [OpenSearch PPL](https://docs.opensearch.org/latest/search-plugins/sql/ppl/)

---

## 🔐 Credenciais Padrão (Ambiente Local)

| Config | Valor |
|--------|-------|
| **URL** | `https://localhost:9200` |
| **Usuário** | `admin` |
| **Senha** | `<SENHA_ADMIN>` |
| **OpenSearch Dashboards** | `http://localhost:5601` |

> ⚠️ **Nota:** Use `-k` em comandos curl para ignorar validação SSL (certificado autoassinado).

---

## 📋 Conteúdo do Ebook

### Proporção de Conteúdo
- **75%** — Exemplos práticos, exercícios e casos de uso
- **25%** — Fundamentos teóricos e conceitos

### Indices Criados por Capítulo
| Capítulo | Quantidade | Total de Docs |
|----------|-----------|---------------|
| Cap 01 | 2 índices | 20 |
| Cap 02 | 6 índices | 70+ |
| Cap 03 | 19 índices | 450+ |
| Cap 04 | 13 índices | 300+ |
| Cap 05 | Fluent Bit | Logs (exercícios) |
| Cap 06 | 5 pipelines | Logstash (estruturado) |
| Cap 07 | 4+ pipelines | Data Prepper (observability) |
| Cap 08 | 4 pipelines | 100 docs (exercícios) |
| **Total** | **45+ índices + pipelines** | **1.300+ + ingestão contínua** |

---

## ✅ Validação e Testes

Todos os exercícios e queries inclusos foram:
- ✅ Testados com dados reais
- ✅ Validados quanto a sintaxe
- ✅ Documentados com resultados esperados
- ✅ Reproduzíveis em ambiente single-node

Veja [exercicios/RELATORIO_TESTES.md](exercicios/RELATORIO_TESTES.md) para detalhes completos.

---

## 📝 Como Usar em Sala de Aula

### Preparação Antes da Aula
```bash
# 1. Iniciar Docker Compose
docker compose -f exemplos/docker-compose.single-node.yml up -d

# 2. Carregar todos os dados
bash exercicios/carregar-tudo.sh

# 3. Verificar que tudo está pronto
curl -sk -u admin:<SENHA_ADMIN> https://localhost:9200/_cat/indices?v
```

### Durante a Aula
1. Abra o capítulo correspondente (markdown ou PDF)
2. Execute os exemplos via OpenSearch Dashboards (Dev Tools)
3. Adapte as queries conforme necessário
4. Use os datasets carregados para demonstrações ao vivo

### Após a Aula
```bash
# Para limpar dados e reiniciar
bash exercicios/carregar-tudo.sh
```

---

## 🤝 Sobre a Tornis Tecnologia

Este ebook é desenvolvido e mantido pela **[Tornis Tecnologia](https://www.tornis.com.br)**, empresa especializada em soluções de busca, indexação e análise de dados em tempo real.

**Recursos Relacionados:**
- 🌐 **Site Corporativo:** [www.tornis.com.br](https://www.tornis.com.br)
- 📚 **Plataforma de Treinamento:** [www.opensearchtotal.com.br](https://www.opensearchtotal.com.br)
- 💬 **GitHub:** [tornis/ebook-opensearch](https://github.com/tornis/ebook-opensearch)

Para reportar problemas ou sugerir melhorias, abra uma issue no repositório GitHub ou entre em contato através do site.

---

## 📄 Licença

**Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0)**

Este ebook está licenciado sob a Creative Commons Attribution-ShareAlike 4.0 International License. Você é livre para usar, modificar e distribuir este conteúdo conforme os termos da licença, **desde que mantenha a atribuição a Tornis Tecnologia**.

**Você pode:**
- ✅ Usar para fins comerciais (cursos pagos, treinamentos, consultoria)
- ✅ Modificar e adaptar o conteúdo
- ✅ Distribuir cópias e versões derivadas
- ✅ Usar em projetos privados e públicos
- ✅ Criar materiais baseados neste ebook

**Você deve:**
- 📋 **Atribuição:** Citar sempre "Tornis Tecnologia" como criador original
- 📋 **Indicar mudanças:** Documentar modificações significativas ao conteúdo
- 📋 **Mesmo licenciamento:** Se distribuir versões derivadas, manter a licença CC BY-SA 4.0
- 📋 **Credenciar o trabalho:** Incluir link para este repositório quando possível

**Exemplo de Atribuição:**
```
Este material é uma adaptação de "Ebook OpenSearch 3.5"
criado por Tornis Tecnologia (https://www.tornis.com.br),
licenciado sob CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)
```

Para detalhes completos, consulte a [Creative Commons Attribution-ShareAlike 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

---

## 🎯 Mapa de Aprendizado Recomendado

```
Iniciante          Intermediário         Avançado           Aplicado - Ingestão
    ↓                    ↓                    ↓                 ↓
  Cap 01          →    Cap 02        →    Cap 03    →    Cap 04    →    Cap 05
Arquitetura       CRUD & Conceitos    Queries Avançadas   Análise de Dados   Fluent Bit
  20 docs             70+ docs           450+ docs          300+ docs        Logs streaming

                                                              ↓
                                      Ingestão Avançada (Cap 06 | Cap 07 | Cap 08)
                                          ↙          ↓          ↖
                                       Cap 06     Cap 08      Cap 07
                                     Logstash  Ingest Pipes  Data Prepper
                                    (JDBC, Grok) Processadores  Cloud-Native
                                                  Embutido       (K8s, Pipelines)
```

---

---

**Última atualização:** Março 2026
**Versão:** 1.1
**OpenSearch:** 3.5
**Logstash:** 8.x
**Data Prepper:** 3.x
**Português:** Brasil (ABNT)
**Licença:** Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0)
**Autoria:** Tornis Tecnologia
**Curso:** [OpenSearch Total](https://www.opensearchtotal.com.br)

© 2026 Tornis Tecnologia. Licenciado sob CC BY-SA 4.0.

