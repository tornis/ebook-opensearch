# Ebook OpenSearch 3.5
## Um Guia Prático e Completo para Busca, Indexação e Análise de Dados

> Ebook técnico educacional em português (Brasil), formatado segundo normas ABNT para aprendizado progressivo de OpenSearch 3.5, com 75% conteúdo prático e 25% fundamentos teóricos.

---

## 📚 Sobre o Ebook

Este ebook é um recurso técnico-educacional abrangente que cobre desde conceitos fundamentais até técnicas avançadas de busca e análise de dados com OpenSearch 3.5. Estruturado em 4 capítulos progressivos, combina teoria sólida com exemplos práticos reproduzíveis em sala de aula.

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
├── CLAUDE.md                                    ← Instruções de contexto para IA
├── PUBLISH.sh                                   ← Script de publicação no GitHub
│
├── capitulos/                                   ← Conteúdo dos 5 capítulos
│   ├── 01_introducao_arquitetura.md            ✓ Completo
│   ├── 02_conceitos.md                         ✓ Completo
│   ├── 03_query_dsl_ppl.md                     ✓ Completo
│   ├── 04_aggregatios.md                       ✓ Completo
│   └── 05_fluentbit_ingestao.md                ✓ Completo
│
├── diagramas/                                   ← Diagramas Excalidraw
│   └── diagramas_opensearch.excalidraw.json    (Arquitetura, fluxos, conceitos)
│
├── exemplos/                                    ← Configurações e setup
│   ├── docker-compose.single-node.yml          (OpenSearch + Dashboards)
│   └── cap05/                                   (Fluent Bit + config + parsers + Lua scripts)
│
└── exercicios/                                  ← Datasets e scripts de carga
    ├── README.md                                (Instruções detalhadas)
    ├── carregar-tudo.sh                         (Executa todos os capítulos)
    ├── RELATORIO_TESTES.md                      (Testes validados)
    ├── cap01/
    │   ├── carregar.sh                          (20 livros)
    │   └── dados.ndjson
    ├── cap02/
    │   ├── carregar.sh                          (70+ documentos)
    │   └── dados.ndjson
    ├── cap03/
    │   ├── carregar.sh                          (450+ documentos)
    │   └── dados.ndjson
    ├── cap04/
    │   ├── carregar.sh                          (300+ documentos)
    │   └── dados.ndjson
    └── cap05/
        ├── README.md                            (Instruções dos exercícios)
        ├── ex1-app-logs.ndjson                  (Dados Ex 1)
        ├── ex2-apache-logs.txt                  (Dados Ex 2)
        ├── ex3-malformed-logs.txt               (Dados Ex 3)
        └── ex4-ecommerce-logs.ndjson            (Dados Ex 4)
```

---

## 🔧 Artefatos e Recursos

### 📘 Capítulos
| Capítulo | Link | Status |
|----------|------|--------|
| **01** — Introdução e Arquitetura | [Abrir](capitulos/01_introducao_arquitetura.md) | ✅ Completo |
| **02** — Conceitos Fundamentais e CRUD | [Abrir](capitulos/02_conceitos.md) | ✅ Completo |
| **03** — Query DSL e PPL | [Abrir](capitulos/03_query_dsl_ppl.md) | ✅ Completo |
| **04** — Agregações e Análise | [Abrir](capitulos/04_aggregatios.md) | ✅ Completo |
| **05** — Ingestão com Fluent Bit | [Abrir](capitulos/05_fluentbit_ingestao.md) | ✅ Completo |

### 🎨 Diagramas
| Recurso | Formato | Descrição |
|---------|---------|-----------|
| **Diagramas OpenSearch** | [Excalidraw](diagramas/diagramas_opensearch.excalidraw.json) | Arquitetura, cluster, índices, shards |

### 📊 Exemplos e Setup
| Recurso | Descrição |
|---------|-----------|
| **Docker Compose** | [exemplos/docker-compose.single-node.yml](exemplos/docker-compose.single-node.yml) — Setup completo single-node |

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

**Total:** 40+ índices com 1.200+ documentos testados e validados + Fluent Bit configs

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
| **Total** | **40+ índices** | **1.200+** |

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

## 🤝 Contribuições e Feedback

Este projeto é mantido por **Tornis** como recurso educacional aberto.

Para reportar problemas ou sugerir melhorias, abra uma issue no repositório GitHub:
[tornis/ebook-opensearch](https://github.com/tornis/ebook-opensearch)

---

## 📄 Licença

Ebook técnico educacional em português (Brasil).

---

## 🎯 Mapa de Aprendizado Recomendado

```
Iniciante          Intermediário         Avançado           Aplicado
    ↓                    ↓                    ↓                 ↓
  Cap 01          →    Cap 02        →    Cap 03    →    Cap 04    →    Cap 05
Arquitetura       CRUD & Conceitos    Queries Avançadas   Análise de Dados   Ingestão de Logs
  20 docs             70+ docs           450+ docs          300+ docs        4 exercícios
```

---

**Última atualização:** Fevereiro 2026
**Versão:** 1.0
**OpenSearch:** 3.5
**Português:** Brasil (ABNT)

