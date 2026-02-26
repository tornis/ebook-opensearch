# CAPÍTULO 2: CONCEITOS FUNDAMENTAIS

## 2. CONCEITOS FUNDAMENTAIS

### Objetivos de Aprendizagem

Ao final deste capítulo, você será capaz de:

1. Compreender a estrutura hierárquica de índices, documentos e tipos de dados no OpenSearch
2. Implementar mapeamentos dinâmicos e explícitos para estruturação de dados
3. Aplicar analyzers e tokenização para otimizar buscas textuais
4. Explicar o funcionamento do inverted index e suas estruturas internas
5. Executar operações CRUD completas via API REST do OpenSearch

---

## 2.1 FUNDAÇÕES: ÍNDICES, DOCUMENTOS E TIPOS DE DADOS

### Introdução Conceitual

O OpenSearch organiza dados em uma hierarquia bem definida: **cluster** → **índice** → **documento** → **campo**. Compreender essa estrutura é fundamental para trabalhar efetivamente com a plataforma, pois determina como os dados são armazenados, indexados e recuperados.

Diferentemente de bancos de dados relacionais tradicionais, onde você trabalha com tabelas e registros, o OpenSearch utiliza um modelo baseado em **documentos JSON** armazenados em **índices**. Essa abordagem oferece flexibilidade estrutural e escalabilidade horizontal, permitindo buscas ultra-rápidas em volumes massivos de dados.

### 2.1.1 Índices: O Contenedor de Dados

Um **índice** no OpenSearch é a unidade básica de armazenamento e representa um conjunto lógico de documentos relacionados. Você pode pensar em um índice como equivalente a uma tabela em um banco de dados relacional, mas com capacidades muito mais robustas de busca.

**Características principais de um índice:**

- **Distribuído**: Os dados são divididos em shards (fragmentos) distribuídos entre múltiplos nós
- **Replicável**: Cada shard possui réplicas para alta disponibilidade
- **Versionado**: Suporta controle de versão automático de documentos
- **Mapeável**: Possui um schema flexível que pode ser definido ou evoluir dinamicamente

Um índice é identificado por um **nome único** no cluster. Por convenção, os nomes devem seguir padrões como: `logs-aplicacao-2025`, `produtos-ecommerce`, `usuarios-ativa`.

**Arquitetura hierárquica de um índice:**

```mermaid
graph TD
    A["Cluster OpenSearch"] --> B["Índice: logs-api-2025"]
    B --> C["Shard 0<br/>Primário<br/>Nó 1"]
    B --> D["Shard 1<br/>Primário<br/>Nó 2"]
    B --> E["Shard 2<br/>Primário<br/>Nó 3"]
    
    C --> C1["Doc 1<br/>Doc 3<br/>Doc 6"]
    C --> C2["Réplica<br/>Nó 4"]
    
    D --> D1["Doc 2<br/>Doc 5<br/>Doc 8"]
    D --> D2["Réplica<br/>Nó 5"]
    
    E --> E1["Doc 4<br/>Doc 7<br/>Doc 9"]
    E --> E2["Réplica<br/>Nó 6"]
    
    style A fill:#e1f5ff
    style B fill:#b3e5fc
    style C fill:#81d4fa
    style D fill:#81d4fa
    style E fill:#81d4fa
    style C2 fill:#ffccbc
    style D2 fill:#ffccbc
    style E2 fill:#ffccbc
```

### 2.1.2 Documentos: Registros de Dados

Um **documento** é a unidade fundamental de dados no OpenSearch. Trata-se de um objeto JSON que contém dados estruturados ou semi-estruturados associados a um identificador único (\_id).

**Estrutura e composição de um documento:**

```mermaid
graph LR
    A["Documento JSON"] --> B["Metadados"]
    A --> C["Dados"]
    
    B --> B1["_id"]
    B --> B2["_index"]
    B --> B3["_type"]
    B --> B4["_version"]
    B --> B5["_score"]
    
    C --> C1["_source"]
    C1 --> C1A["campo1"]
    C1 --> C1B["campo2"]
    C1 --> C1C["...campoN"]
```

**Exemplo de documento completo:**

```json
{
  "_id": "12345",
  "_index": "produtos-ecommerce",
  "_type": "_doc",
  "_version": 1,
  "_score": 1.0,
  "_source": {
    "nome": "Notebook Dell XPS 13",
    "preco": 4500.00,
    "categoria": "Eletrônicos",
    "estoque": 25,
    "descricao": "Notebook ultraportátil com processador Intel Core i7",
    "criado_em": "2025-01-10T14:30:00Z",
    "ativo": true
  }
}
```

**Campos de metadados:**

- **\_id**: Identificador único do documento. Pode ser gerado automaticamente ou definido pelo usuário
- **\_index**: Nome do índice ao qual o documento pertence
- **\_type**: Tipo do documento (no OpenSearch 2.0+, sempre \_doc)
- **\_version**: Número de versão do documento (incrementado a cada modificação)
- **\_score**: Relevância do documento em uma busca (presente apenas em resultados de queries)
- **\_source**: Dados reais do documento em formato JSON

### 2.1.3 Tipos de Dados Suportados

O OpenSearch suporta diversos tipos de dados nativamente. A correta escolha de tipos impacta diretamente em performance, armazenamento e capacidades de busca.

**Categorização de tipos de dados:**

```mermaid
graph TD
    A["Tipos de Dados<br/>OpenSearch"] --> B["Primitivos"]
    A --> C["Textuais"]
    A --> D["Numéricos"]
    A --> E["Temporais"]
    A --> F["Geoespaciais"]
    A --> G["Complexos"]
    
    B --> B1["boolean"]
    
    C --> C1["text"]
    C --> C2["keyword"]
    
    D --> D1["integer, long"]
    D --> D2["float, double"]
    
    E --> E1["date"]
    
    F --> F1["geo_point"]
    F --> F2["geo_shape"]
    
    G --> G1["object"]
    G --> G2["nested"]
    G --> G3["array"]
    
    style B1 fill:#ffccbc
    style C1 fill:#c8e6c9
    style C2 fill:#c8e6c9
    style D1 fill:#bbdefb
    style D2 fill:#bbdefb
    style E1 fill:#f8bbd0
    style F1 fill:#fff9c4
    style F2 fill:#fff9c4
    style G1 fill:#e1bee7
    style G2 fill:#e1bee7
    style G3 fill:#e1bee7
```

**Tipos de dados primitivos:**

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| text | Texto completo, analisado para buscas | "O rápido raposa marrom" |
| keyword | Texto exato, não analisado | "eletrônicos", "ativo" |
| integer | Número inteiro | 42, -100 |
| long | Número inteiro grande | 9223372036854775807 |
| float | Número decimal | 3.14, 99.99 |
| double | Número decimal de alta precisão | 2.718281828 |
| boolean | Verdadeiro/Falso | true, false |
| date | Data e hora ISO 8601 | "2025-01-15T10:30:00Z" |
| geo_point | Coordenadas geográficas | {"lat": -23.55, "lon": -46.63} |
| ip | Endereço IP | "192.168.1.1" |

**Tipos de dados complexos:**

| Tipo | Descrição | Uso |
|------|-----------|-----|
| object | Documento aninhado | Dados hierárquicos |
| nested | Array de objetos | Manter relação entre campos |
| keyword | Array de palavras-chave | Tags, categorias |
| text | Array de textos | Descrições múltiplas |

---

### 📌 **BOX DE DEFINIÇÃO: Diferença Entre text e keyword**

**text**: Campo analisado pelo analyzer padrão. Ideal para buscas em texto completo. Exemplo: descrições de produtos.

**keyword**: Campo não analisado, armazenado como valor exato. Ideal para filtros e agregações. Exemplo: status, categoria.

---

## 2.2 MAPPING: DEFININDO A ESTRUTURA DE DADOS

### Conceito e Importância

**Mapping** é o esquema que define como os documentos e seus campos devem ser indexados. É análogo ao schema de um banco de dados relacional, mas com maior flexibilidade e capacidades de busca.

Um bom mapping é crítico para:

- **Performance**: Tipos incorretos causam ineficiência de busca
- **Precisão**: Determina como dados são interpretados (número vs. texto)
- **Funcionalidade**: Habilita agregações, sorting e análises avançadas
- **Armazenamento**: Otimiza espaço em disco

### 2.2.1 Mapping Dinâmico

Quando você indexa um documento sem pré-definir um mapping, o OpenSearch **automaticamente detecta** os tipos de campos e cria o mapping dinamicamente. Isso oferece flexibilidade mas pode levar a inconsistências.

**Processo de mapping dinâmico vs. explícito:**

```mermaid
graph TD
    A["Novo Documento<br/>Chegando"] --> B{Existe<br/>Mapping?}
    
    B -->|Não| C["Mapping Dinâmico"]
    B -->|Sim| D["Mapping Explícito"]
    
    C --> C1["OpenSearch analisa<br/>cada campo"]
    C1 --> C2["Detecta tipos"]
    C2 --> C3["Cria mapping<br/>automaticamente"]
    C3 --> C4["Rápido<br/>Flexível<br/>Pode ter<br/>inconsistências"]
    
    D --> D1["Valida contra<br/>schema pré-definido"]
    D1 --> D2["Aplica tipos<br/>específicos"]
    D2 --> D3["Rejeita se<br/>não conformar"]
    D3 --> D4["Controlado<br/>Consistente<br/>Seguro"]
    
    style C4 fill:#fff9c4
    style D4 fill:#c8e6c9
```

**Exemplo: Criando um índice e adicionando documento sem mapping prévio**

```bash
# Requisição HTTP POST
POST http://localhost:9200/produtos-dinamico/_doc
Content-Type: application/json

{
  "nome": "Mouse Logitech MX Master 3",
  "preco": 350.00,
  "em_estoque": true,
  "tags": ["periférico", "wireless"],
  "criado_em": "2025-01-15T10:30:00Z"
}
```

O OpenSearch automaticamente cria o mapping:

```json
{
  "produtos-dinamico": {
    "mappings": {
      "properties": {
        "nome": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        "preco": {
          "type": "float"
        },
        "em_estoque": {
          "type": "boolean"
        },
        "tags": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        "criado_em": {
          "type": "date"
        }
      }
    }
  }
}
```

**Vantagens:**

- ✓ Prototipagem rápida
- ✓ Flexibilidade imediata
- ✓ Ideal para dados exploratórios

**Desvantagens:**

- ✗ Tipos podem não ser ótimos
- ✗ Dificil controlar formato de datas
- ✗ Pode causar inconsistências entre documentos

### 2.2.2 Mapping Explícito

Para aplicações em produção, é recomendado definir o mapping **explicitamente** antes de indexar dados. Isso garante consistência, performance e controle total.

**Exemplo: Criando um índice com mapping explícito**

```bash
# Requisição HTTP PUT
PUT http://localhost:9200/produtos-explicitamente-mapeado
Content-Type: application/json

{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "id_produto": {
        "type": "keyword",
        "index": true
      },
      "nome": {
        "type": "text",
        "analyzer": "standard",
        "fields": {
          "raw": {
            "type": "keyword"
          }
        }
      },
      "descricao": {
        "type": "text",
        "analyzer": "portuguese"
      },
      "preco": {
        "type": "float"
      },
      "categoria": {
        "type": "keyword"
      },
      "estoque": {
        "type": "integer"
      },
      "ativo": {
        "type": "boolean"
      },
      "criado_em": {
        "type": "date",
        "format": "strict_date_time"
      },
      "atualizado_em": {
        "type": "date",
        "format": "strict_date_time"
      },
      "localizacao": {
        "type": "geo_point"
      }
    }
  }
}
```

**Parâmetros importantes do mapping:**

- **type**: Tipo de dado (text, keyword, integer, date, etc.)
- **analyzer**: Analisador para processamento de texto
- **index**: Se o campo deve ser indexável (true/false)
- **store**: Se o valor original deve ser armazenado separadamente
- **fields**: Sub-campos adicionais (exemplo: nome.raw para valor exato)
- **format**: Formato específico para datas

### 2.2.3 Padrão Multi-Campo (Multi-field)

Uma abordagem poderosa é mapear um campo de múltiplas formas, permitindo diferentes tipos de buscas:

```json
{
  "properties": {
    "titulo": {
      "type": "text",
      "analyzer": "portuguese",
      "fields": {
        "raw": {
          "type": "keyword"
        },
        "comprimento": {
          "type": "token_count",
          "analyzer": "standard"
        }
      }
    }
  }
}
```

Isso permite:
- Busca em texto completo: `GET /_search { "query": { "match": { "titulo": "opensearch" } } }`
- Filtro exato: `GET /_search { "query": { "term": { "titulo.raw": "OpenSearch" } } }`
- Contagem de palavras: `GET /_search { "aggs": { "media_palavras": { "avg": { "field": "titulo.comprimento" } } } }`

---

### ⚠️ **BOX DE ALERTA: Modificar Mapping em Produção**

Uma vez que um índice está criado e contém dados, **não é possível modificar o tipo de um campo existente**. Para alterar o mapping, você deve:

1. Criar um novo índice com o mapping corrigido
2. Reindexar dados do índice antigo para o novo
3. Atualizar aliases para apontar ao novo índice
4. Remover o índice antigo

Esta é uma operação crítica que deve ser planejada com cuidado em produção.

---

### 2.2.4 Controle Dinâmico de Mapping: dynamic_templates, dynamic: false e dynamic: strict

O OpenSearch oferece um controle granular sobre como novos campos são tratados durante a indexação através da propriedade `dynamic`. Essa configuração é crítica para garantir qualidade de dados e evitar problemas em produção.

#### **Opção 1: dynamic: true (Padrão)**

Permite que qualquer novo campo seja indexado automaticamente, criando o mapping dinamicamente:

```bash
PUT http://localhost:9200/usuarios-dinamico
Content-Type: application/json

{
  "mappings": {
    "dynamic": true,
    "properties": {
      "id": { "type": "keyword" },
      "nome": { "type": "text" }
    }
  }
}
```

```bash
# Indexando documento com campos extras
POST http://localhost:9200/usuarios-dinamico/_doc
Content-Type: application/json

{
  "id": "user123",
  "nome": "João Silva",
  "email": "joao@example.com",
  "data_nascimento": "1990-05-15",
  "ativo": true
}
```

**Resultado**: Os campos `email`, `data_nascimento` e `ativo` são **automaticamente adicionados** ao mapping com tipos detectados.

**Impactos:**
- ✅ Flexibilidade para dados exploratórios
- ✅ Prototipagem rápida
- ❌ Pode criar mappings sub-ótimos (tipos incorretos)
- ❌ Difícil controlar crescimento descontrolado de campos
- ❌ Consumo adicional de memória e disco

---

#### **Opção 2: dynamic: false**

Novos campos são **ignorados** durante a indexação. O documento é armazenado, mas os novos campos não são indexados nem consultáveis:

```bash
PUT http://localhost:9200/usuarios-restritivo
Content-Type: application/json

{
  "mappings": {
    "dynamic": false,
    "properties": {
      "id": { "type": "keyword" },
      "nome": { "type": "text" },
      "email": { "type": "keyword" }
    }
  }
}
```

```bash
# Indexando documento com campo extra não definido
POST http://localhost:9200/usuarios-restritivo/_doc/1
Content-Type: application/json

{
  "id": "user123",
  "nome": "Maria Santos",
  "email": "maria@example.com",
  "telefone": "(11) 99999-8888"
}
```

**Resultado**: O campo `telefone` é **armazenado mas não indexado**. Buscas pelo telefone falharão, mas o dado original está presente no documento original (_source).

**Impactos:**
- ✅ Controle total sobre schema
- ✅ Evita crescimento descontrolado de campos
- ✅ Melhor previsibilidade e estabilidade
- ✅ Economiza memória e espaço
- ❌ Dados extras são ignorados (não consultáveis)
- ❌ Menos flexibilidade

---

#### **Opção 3: dynamic: strict**

Rejeita qualquer documento que contenha campos não definidos no mapping, lançando um erro:

```bash
PUT http://localhost:9200/usuarios-rigoroso
Content-Type: application/json

{
  "mappings": {
    "dynamic": "strict",
    "properties": {
      "id": { "type": "keyword" },
      "nome": { "type": "text" },
      "email": { "type": "keyword" }
    }
  }
}
```

```bash
# Tentativa de indexar documento com campo extra
POST http://localhost:9200/usuarios-rigoroso/_doc/1
Content-Type: application/json

{
  "id": "user123",
  "nome": "Pedro Costa",
  "email": "pedro@example.com",
  "telefone": "(11) 88888-7777"
}
```

**Resultado**: Erro 400 (Bad Request):

```json
{
  "error": {
    "root_cause": [
      {
        "type": "strict_dynamic_mapping_exception",
        "reason": "mapping set to strict, dynamic introduction of [telefone] within [_doc] is not allowed"
      }
    ]
  }
}
```

**Impactos:**
- ✅ Máxima integridade de dados
- ✅ Detecta problemas imediatamente
- ✅ Força conscientização sobre estrutura
- ✅ Ideal para APIs bem definidas
- ❌ Muito rígido para dados exploratórios
- ❌ Requer predefinição completa de campos

---

#### **Opção 4: dynamic_templates (Padrão Inteligente)**

Permite criar padrões que aplicam tipos automáticos com base em nomes ou valores de campos:

```bash
PUT http://localhost:9200/produtos-inteligente
Content-Type: application/json

{
  "mappings": {
    "dynamic": "true",
    "dynamic_templates": [
      {
        "strings_como_keyword": {
          "match_mapping_type": "string",
          "mapping": {
            "type": "keyword"
          }
        }
      },
      {
        "campos_data": {
          "match": "*_data",
          "match_mapping_type": "string",
          "mapping": {
            "type": "date",
            "format": "yyyy-MM-dd||strict_date_time"
          }
        }
      },
      {
        "campos_preco": {
          "match": "preco*",
          "match_mapping_type": "double",
          "mapping": {
            "type": "scaled_float",
            "scaling_factor": 100
          }
        }
      }
    ],
    "properties": {
      "id": { "type": "keyword" },
      "nome": { "type": "text" }
    }
  }
}
```

```bash
# Indexando documento
POST http://localhost:9200/produtos-inteligente/_doc
Content-Type: application/json

{
  "id": "prod001",
  "nome": "Notebook",
  "categoria": "eletrônicos",
  "lancamento_data": "2025-01-15",
  "preco_unitario": 2500.50,
  "preco_promocional": 1999.99
}
```

**Resultado**: Os campos são mapeados segundo as regras definidas:
- `categoria` → keyword (strings como keyword)
- `lancamento_data` → date (campo com sufixo _data)
- `preco_unitario` e `preco_promocional` → scaled_float (campos com prefixo preco)

**Impactos:**
- ✅ Flexibilidade com controle inteligente
- ✅ Detecta padrões e aplica tipos apropriados
- ✅ Reduz necessidade de mapping explícito completo
- ✅ Ideal para esquemas semi-estruturados
- ⚠️ Requer compreensão das regras de correspondência

---

#### **Comparação Prática: Impactos na Indexação**

```mermaid
graph TD
    A["Novo Campo Detectado<br/>na Indexação"] --> B{"Qual configuração<br/>dynamic?"}

    B -->|dynamic: true| C["Campo Indexado<br/>Tipo Auto-detectado"]
    B -->|dynamic: false| D["Campo Não Indexado<br/>Armazenado em _source"]
    B -->|dynamic: strict| E["Erro 400<br/>Documento Rejeitado"]
    B -->|dynamic_templates| F["Padrões Aplicados<br/>Tipo Inteligente"]

    C --> C1["✅ Flexível<br/>❌ Menos Previsível"]
    D --> D1["✅ Controlado<br/>❌ Dados não consultáveis"]
    E --> E1["✅ Seguro<br/>❌ Rígido demais"]
    F --> F1["✅ Equilibrado<br/>✅ Controlado"]

    style C fill:#fff9c4
    style D fill:#ffccbc
    style E fill:#ffccbc
    style F fill:#c8e6c9
```

---

#### **📌 BOX DE DEFINIÇÃO: Quando Usar Cada Opção**

| Cenário | Recomendação | Razão |
|---------|--------------|-------|
| Desenvolvimento/Prototipagem | `dynamic: true` | Flexibilidade máxima |
| APIs com schema definido | `dynamic: strict` | Garantir integridade |
| Dados log/eventos variáveis | `dynamic_templates` | Padrões inteligentes |
| Dados estruturados em produção | `dynamic: false` | Controle + armazenamento |
| Mix: estruturado + exploratório | `dynamic_templates` | Melhor dos dois mundos |

---

## 2.3 ANALYZERS E TOKENIZAÇÃO

### Testando Analyzers com a API _analyze

Antes de definir analyzers em seus índices, é essencial entender como eles processam textos. A API `POST _analyze` permite testar analyzers sem criar índices:

#### **Testando Analyzer Padrão (Standard)**

```bash
POST http://localhost:9200/_analyze
Content-Type: application/json

{
  "analyzer": "standard",
  "text": "O rápido raposa marrom pulou sobre a cerca!"
}
```

**Resposta detalhada:**

```json
{
  "tokens": [
    {
      "token": "o",
      "start_offset": 0,
      "end_offset": 1,
      "type": "<ALPHANUM>",
      "position": 0
    },
    {
      "token": "rápido",
      "start_offset": 2,
      "end_offset": 8,
      "type": "<ALPHANUM>",
      "position": 1
    },
    {
      "token": "raposa",
      "start_offset": 9,
      "end_offset": 15,
      "type": "<ALPHANUM>",
      "position": 2
    },
    {
      "token": "marrom",
      "start_offset": 16,
      "end_offset": 22,
      "type": "<ALPHANUM>",
      "position": 3
    },
    {
      "token": "pulou",
      "start_offset": 23,
      "end_offset": 28,
      "type": "<ALPHANUM>",
      "position": 4
    },
    {
      "token": "sobre",
      "start_offset": 29,
      "end_offset": 34,
      "type": "<ALPHANUM>",
      "position": 5
    },
    {
      "token": "a",
      "start_offset": 35,
      "end_offset": 36,
      "type": "<ALPHANUM>",
      "position": 6
    },
    {
      "token": "cerca",
      "start_offset": 37,
      "end_offset": 42,
      "type": "<ALPHANUM>",
      "position": 7
    }
  ]
}
```

**Interpretação dos resultados:**

| Campo | Significado |
|-------|-----------|
| `token` | Palavra processada (lowercased, sem pontuação) |
| `start_offset` | Posição inicial no texto original |
| `end_offset` | Posição final no texto original |
| `type` | Tipo de token (`<ALPHANUM>`, `<NUM>`, etc.) |
| `position` | Posição sequencial do token |

---

#### **Testando Portuguese Analyzer (Stopwords + Stemming)**

```bash
POST http://localhost:9200/_analyze
Content-Type: application/json

{
  "analyzer": "portuguese",
  "text": "Os usuários executando operações de busca e indexação rapidamente"
}
```

**Resposta:**

```json
{
  "tokens": [
    {
      "token": "usuár",
      "start_offset": 4,
      "end_offset": 12,
      "type": "<ALPHANUM>",
      "position": 1
    },
    {
      "token": "execut",
      "start_offset": 13,
      "end_offset": 24,
      "type": "<ALPHANUM>",
      "position": 2
    },
    {
      "token": "operaç",
      "start_offset": 25,
      "end_offset": 35,
      "type": "<ALPHANUM>",
      "position": 3
    },
    {
      "token": "busc",
      "start_offset": 39,
      "end_offset": 45,
      "type": "<ALPHANUM>",
      "position": 4
    },
    {
      "token": "index",
      "start_offset": 48,
      "end_offset": 57,
      "type": "<ALPHANUM>",
      "position": 5
    },
    {
      "token": "rapid",
      "start_offset": 58,
      "end_offset": 67,
      "type": "<ALPHANUM>",
      "position": 6
    }
  ]
}
```

**Observe que:**
- ✅ Stopwords removidas: "os", "de", "e"
- ✅ Stemming aplicado: "usuários" → "usuár", "executando" → "execut", "busca" → "busc"
- ✅ Posições sequenciais refletem remoção de stopwords (pos 1, 2, 3, 4, 5, 6)

---

#### **Testando Whitespace Analyzer (Sem Processamento)**

```bash
POST http://localhost:9200/_analyze
Content-Type: application/json

{
  "analyzer": "whitespace",
  "text": "OpenSearch é poderoso, eficiente e escalável!"
}
```

**Resposta:**

```json
{
  "tokens": [
    {
      "token": "OpenSearch",
      "start_offset": 0,
      "end_offset": 10,
      "type": "word",
      "position": 0
    },
    {
      "token": "é",
      "start_offset": 11,
      "end_offset": 12,
      "type": "word",
      "position": 1
    },
    {
      "token": "poderoso,",
      "start_offset": 13,
      "end_offset": 22,
      "type": "word",
      "position": 2
    },
    {
      "token": "eficiente",
      "start_offset": 23,
      "end_offset": 32,
      "type": "word",
      "position": 3
    },
    {
      "token": "e",
      "start_offset": 33,
      "end_offset": 34,
      "type": "word",
      "position": 4
    },
    {
      "token": "escalável!",
      "start_offset": 35,
      "end_offset": 45,
      "type": "word",
      "position": 5
    }
  ]
}
```

**Observe que:**
- ⚠️ Pontuação preservada: "poderoso," e "escalável!" mantêm a pontuação
- ⚠️ Case preservado: "OpenSearch" mantém capitalização
- ✅ Apenas divide por espaços em branco

---

#### **Comparação: Standard vs Portuguese vs Whitespace**

Texto de entrada: *"Rapidamente buscando documentos importantes"*

```mermaid
graph TD
    A["Text: Rapidamente buscando<br/>documentos importantes"] -->|Standard| B["rapidly<br/>buscando<br/>documentos<br/>importante"]
    A -->|Portuguese| C["rapid<br/>busc<br/>document<br/>important"]
    A -->|Whitespace| D["Rapidamente<br/>buscando<br/>documentos<br/>importantes"]

    style B fill:#bbdefb
    style C fill:#c8e6c9
    style D fill:#ffccbc
```

---

#### **Testando Analyzer Customizado**

Criar um analyzer customizado e testá-lo:

```bash
PUT http://localhost:9200/teste-custom-analyzer
Content-Type: application/json

{
  "settings": {
    "analysis": {
      "analyzer": {
        "meu_analyzer": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase", "stop", "snowball"]
        }
      }
    }
  }
}
```

```bash
# Testando o analyzer customizado
POST http://localhost:9200/teste-custom-analyzer/_analyze
Content-Type: application/json

{
  "analyzer": "meu_analyzer",
  "text": "O OpenSearch é excelente para buscas em texto!"
}
```

**Resposta:**

```json
{
  "tokens": [
    {
      "token": "opensearch",
      "start_offset": 2,
      "end_offset": 12,
      "type": "<ALPHANUM>",
      "position": 0
    },
    {
      "token": "excelent",
      "start_offset": 16,
      "end_offset": 25,
      "type": "<ALPHANUM>",
      "position": 1
    },
    {
      "token": "busc",
      "start_offset": 30,
      "end_offset": 36,
      "type": "<ALPHANUM>",
      "position": 2
    },
    {
      "token": "text",
      "start_offset": 37,
      "end_offset": 42,
      "type": "<ALPHANUM>",
      "position": 3
    }
  ]
}
```

---

### Conceito Fundamental

### Conceito Fundamental

Um **analyzer** é um componente que processa texto para preparar campos do tipo `text` para indexação e busca. Ele transforma texto bruto em tokens (palavras individuais) que são indexados no inverted index.

A tokenização correta é essencial para a qualidade das buscas. Por exemplo:

- Texto original: "O rápido raposa marrom pulou sobre a cerca"
- Tokens após análise: ["rápido", "raposa", "marrom", "pulou", "cerca"]

### 2.3.1 Componentes de um Analyzer

Um analyzer é composto por três componentes:

1. **Character Filter**: Processa caracteres antes da tokenização
2. **Tokenizer**: Divide o texto em tokens
3. **Token Filter**: Modifica tokens após tokenização

**Fluxo de análise passo a passo:**

```mermaid
graph TD
    A["Texto Original:<br/>Hello WORLD!<br/>ação rápida"] --> B["Character Filters"]
    B --> B1["Remove HTML<br/>Normaliza espaços"]
    B1 --> C["Tokenizer"]
    C --> C1["Divide por<br/>espaço/pontuação"]
    C1 --> D["Token Filters"]
    D --> D1["lowercase<br/>remove stopwords<br/>stemming"]
    D1 --> E["Tokens Indexados:<br/>hello, world<br/>acao, rapid"]
    
    style A fill:#fff9c4
    style B fill:#f8bbd0
    style C fill:#bbdefb
    style D fill:#c8e6c9
    style E fill:#ffe0b2
```

### 2.3.2 Analyzers Pré-configurados

O OpenSearch fornece diversos analyzers prontos para uso:

**Comparação visual de analyzers:**

```mermaid
graph TD
    A["Texto: Hello World!"] --> B["Standard"]
    A --> C["Simple"]
    A --> D["Whitespace"]
    A --> E["Keyword"]
    
    B --> B1["hello, world"]
    C --> C1["hello, world"]
    D --> D1["Hello, World!"]
    E --> E1["hello world!"]
    
    style B1 fill:#c8e6c9
    style C1 fill:#c8e6c9
    style D1 fill:#ffccbc
    style E1 fill:#fff9c4
```

**Características de cada analyzer:**

**Standard Analyzer** (padrão)
- Character Filter: Nenhum
- Tokenizer: standard (divide por espaço e pontuação)
- Token Filter: lowercase
- Exemplo: "Hello World!" → ["hello", "world"]

**Simple Analyzer**
- Tokenizer: lowercase
- Divide por caracteres não-alfanuméricos
- Exemplo: "Hello World!" → ["hello", "world"]

**Whitespace Analyzer**
- Tokenizer: whitespace
- Divide apenas por espaço em branco
- Exemplo: "Hello-World!" → ["hello-world!"]

**Keyword Analyzer**
- Não divide o texto, trata como single token
- Ideal para valores que devem permanecer íntegros
- Exemplo: "Hello World!" → ["hello world!"]

**Language Analyzers**
- Específicos por idioma (english, portuguese, spanish, etc.)
- Incluem stopwords removal e stemming
- Exemplo com "portuguese": "executando" → ["execut"]

### 2.3.3 Criando Analyzers Customizados

Para necessidades específicas, você pode criar analyzers personalizados:

**Exemplo: Analyzer customizado para logs de API**

```bash
PUT http://localhost:9200/logs-api
Content-Type: application/json

{
  "settings": {
    "analysis": {
      "analyzer": {
        "log_analyzer": {
          "type": "custom",
          "char_filter": ["html_strip"],
          "tokenizer": "standard",
          "filter": ["lowercase", "stop", "snowball"]
        }
      },
      "char_filter": {
        "html_strip": {
          "type": "html_strip",
          "escaped_tags": ["b", "i"]
        }
      },
      "filter": {
        "stop": {
          "type": "stop",
          "stopwords": ["_english_", "para", "de", "a"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "mensagem": {
        "type": "text",
        "analyzer": "log_analyzer"
      },
      "level": {
        "type": "keyword"
      },
      "timestamp": {
        "type": "date"
      }
    }
  }
}
```

**Exemplo: Analyzer para busca de nomes próprios (case-insensitive, sem stemming)**

```json
{
  "settings": {
    "analysis": {
      "analyzer": {
        "nome_analyzer": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "nome_pessoa": {
        "type": "text",
        "analyzer": "nome_analyzer"
      }
    }
  }
}
```

### 2.3.4 Token Filters Importantes

| Filter | Função | Exemplo |
|--------|--------|---------|
| lowercase | Converte para minúsculas | "HELLO" → "hello" |
| stop | Remove palavras comuns | "the quick brown" → "quick brown" |
| snowball | Stemming (raiz da palavra) | "running" → "run" |
| synonym | Substitui por sinônimos | "carro" → "carro, automóvel" |
| length | Filtra por comprimento | Mantém tokens com 3-20 caracteres |

---

### 💡 **BOX DE DICA: Escolhendo o Analyzer Correto**

- **Buscas em texto completo**: Use language analyzers específicos (portuguese, english)
- **Buscas facetadas/filtros**: Use keyword (sem análise)
- **URLs e códigos**: Use whitespace ou custom sem stemming
- **Buscas multi-idioma**: Crie múltiplos campos com analyzers diferentes

---

## 2.4 INVERTED INDEX E ESTRUTURAS INTERNAS

### O Coração da Busca: Inverted Index

O **inverted index** é a estrutura de dados fundamental que permite buscas ultra-rápidas no OpenSearch. Diferentemente de um índice tradicional que mapeia documentos → conteúdo, o inverted index mapeia **termos → documentos**.

**Visualização comparativa: Forward vs. Inverted Index**

```mermaid
graph LR
    subgraph "Forward Index<br/>(Tradicional)"
        A1["Doc 1 → termos"]
        A2["Doc 2 → termos"]
        A3["Doc 3 → termos"]
    end
    
    subgraph "Inverted Index<br/>(OpenSearch)"
        B1["Termo → docs"]
        B2["Termo → docs"]
        B3["Termo → docs"]
    end
    
    A1 -->|Busca lenta| X["Resultado"]
    A2 -->|Busca lenta| X
    A3 -->|Busca lenta| X
    
    B1 -->|Busca rápida| X
    B2 -->|Busca rápida| X
    B3 -->|Busca rápida| X
    
    style A1 fill:#ffccbc
    style A2 fill:#ffccbc
    style A3 fill:#ffccbc
    style B1 fill:#c8e6c9
    style B2 fill:#c8e6c9
    style B3 fill:#c8e6c9
```

**Exemplo detalhado de inverted index:**

```
Documentos originais:
Doc 1: "OpenSearch é um mecanismo de busca"
Doc 2: "OpenSearch é distribuído"
Doc 3: "Busca rápida com OpenSearch"

Inverted Index resultante:
┌─────────────┬──────────────────┐
│ Termo       │ Documentos       │
├─────────────┼──────────────────┤
│ OpenSearch  │ [Doc 1, Doc 2, Doc 3] │
│ é           │ [Doc 1, Doc 2]   │
│ um          │ [Doc 1]          │
│ mecanismo   │ [Doc 1]          │
│ de          │ [Doc 1, Doc 3]   │
│ busca       │ [Doc 1, Doc 3]   │
│ distribuído │ [Doc 2]          │
│ rápida      │ [Doc 3]          │
│ com         │ [Doc 3]          │
└─────────────┴──────────────────┘
```

Quando você busca por "OpenSearch busca", o sistema consulta o índice invertido:
- Encontra "OpenSearch" → [Doc 1, Doc 2, Doc 3]
- Encontra "busca" → [Doc 1, Doc 3]
- Retorna intersecção: [Doc 1, Doc 3]

**Vantagem**: Em vez de ler todos os documentos sequencialmente, o sistema encontra diretamente quais documentos contêm os termos procurados.

### 2.4.1 Estrutura Interna de um Inverted Index

Para cada termo, o inverted index armazena mais que apenas a lista de documentos. Ele mantém informações detalhadas para scoring (cálculo de relevância):

**Componentes de uma posting list:**

```mermaid
graph TD
    A["Termo: OpenSearch"] --> B["Metadados do Termo"]
    A --> C["Posting List"]
    
    B --> B1["Document Frequency: 3"]
    B --> B2["Total occurrences: 3"]
    
    C --> C1["Doc 1"]
    C --> C2["Doc 2"]
    C --> C3["Doc 3"]
    
    C1 --> C1A["TF: 1"]
    C1 --> C1B["Posição: 0"]
    C1 --> C1C["Offsets: 0-10"]
    
    C2 --> C2A["TF: 1"]
    C2 --> C2B["Posição: 0"]
    C2 --> C2C["Offsets: 0-10"]
    
    C3 --> C3A["TF: 1"]
    C3 --> C3B["Posição: 2"]
    C3 --> C3C["Offsets: 16-26"]
    
    style B fill:#bbdefb
    style C fill:#c8e6c9
```

Estrutura detalhada em formato textual:

```
Termo: "OpenSearch"
├── Document Frequency: 3 (aparece em 3 documentos)
├── Posting List:
│   ├── Doc 1
│   │   ├── Term Frequency: 1 (aparece 1 vez)
│   │   ├── Posição: 0 (primeira palavra)
│   │   └── Offsets: 0-10 (bytes no documento)
│   ├── Doc 2
│   │   ├── Term Frequency: 1
│   │   ├── Posição: 0
│   │   └── Offsets: 0-10
│   └── Doc 3
│       ├── Term Frequency: 1
│       ├── Posição: 2
│       └── Offsets: 16-26
```

### 2.4.2 BM25: Algoritmo de Scoring de Relevância

O OpenSearch utiliza por padrão o **BM25** (Best Matching 25) como algoritmo de scoring para calcular a relevância de cada documento em uma busca. O BM25 é uma evolução sofisticada do TF-IDF que leva em conta fatores adicionais para resultados mais relevantes.

**Por que BM25 em vez de TF-IDF?**

O BM25 melhora o TF-IDF com:
- **Saturação de frequência**: Não assume que frequência infinita sempre = maior relevância
- **Normalização por comprimento**: Documentos mais curtos não são penalizados automaticamente
- **Parametrização**: Permite ajuste fino via parâmetros k1 e b
- **IDF melhorado**: Cálculo mais robusto da raridade do termo

**Componentes do BM25:**

```mermaid
graph LR
    A["BM25<br/>Okapi"] --> B["IDF<br/>Raridade"]
    A --> C["TF<br/>Frequência"]
    A --> D["Field Length<br/>Normalização"]

    B --> B1["Penaliza termos<br/>muito comuns"]
    B --> B2["Premia termos<br/>raros"]

    C --> C1["Saturação:<br/>frequência 5 vs 10<br/>não é 2x melhor"]
    C --> C2["Ajustável com<br/>parâmetro k1"]

    D --> D1["Compensa por<br/>tamanho do doc"]
    D --> D2["Ajustável com<br/>parâmetro b"]

    style B1 fill:#c8e6c9
    style B2 fill:#c8e6c9
    style C1 fill:#bbdefb
    style C2 fill:#bbdefb
    style D1 fill:#fff9c4
    style D2 fill:#fff9c4
```

**Fórmula de scoring BM25:**

```
Score(D, Q) = Σ IDF(qi) × ((k1 + 1) × TF(qi, D)) / (TF(qi, D) + k1 × (1 - b + b × (|D| / avgdl)))

Onde:
  D = documento
  Q = query (termos pesquisados)
  IDF(qi) = log((N - n(qi) + 0.5) / (n(qi) + 0.5))
  N = total de documentos
  n(qi) = documentos contendo o termo qi
  TF(qi, D) = frequência do termo no documento
  |D| = comprimento do documento (em termos)
  avgdl = comprimento médio dos documentos
  k1 = parâmetro de saturação (padrão: 1.2)
  b = parâmetro de normalização (padrão: 0.75)
```

**Componentes explicados:**

**IDF (Inverse Document Frequency):**
```
IDF(termo) = log((total_docs - docs_com_termo + 0.5) / (docs_com_termo + 0.5))
```
- Maior IDF = termo mais raro = mais importante
- 0.5 adicionado para evitar divisão por zero

**TF (Term Frequency com saturação):**
```
TF saturado = ((k1 + 1) × freq) / (freq + k1)
```
- Com k1=1.2, a frequência é saturada
- Frequência 1 contribui ~55% do máximo
- Frequência 2 contribui ~73% do máximo
- Frequência infinita contribui 100%

**Field Length Normalization:**
```
normalização = (1 - b + b × (comprimento_doc / comprimento_médio))
```
- Com b=0.75, documentos menores são ligeiramente favorecidos
- b=0 desativa normalização completamente
- b=1 penaliza fortemente documentos grandes

---

**Exemplo prático de cálculo BM25:**

Cenário: 100 documentos no índice, 40 contêm "OpenSearch", 5 contêm "distribuído"

```
Busca: "OpenSearch distribuído"

Comprimentos:
- Documento 1: 150 termos
- Documento 2: 100 termos
- Documento 3: 120 termos
- Comprimento médio (avgdl): 115 termos

Cálculo de IDF:
- IDF("OpenSearch") = log((100 - 40 + 0.5) / (40 + 0.5)) = log(1.48) = 0.392
- IDF("distribuído") = log((100 - 5 + 0.5) / (5 + 0.5)) = log(19.1) = 2.95

════════════════════════════════════════════════════════════════

Documento 1: "OpenSearch é um mecanismo de busca distribuído..." (150 termos)
├── Contém "OpenSearch": 2 vezes
├── Contém "distribuído": 1 vez
├──
├── Cálculo TF("OpenSearch"):
│   TF saturado = (2.2 × 2) / (2 + 1.2) = 4.4 / 3.2 = 1.375
│
├── Normalização de comprimento:
│   norm = (1 - 0.75 + 0.75 × (150 / 115)) = 0.25 + 0.978 = 1.228
│
├── Score para "OpenSearch":
│   0.392 × 1.375 / 1.228 = 0.440
│
├── Score para "distribuído":
│   TF saturado = (2.2 × 1) / (1 + 1.2) = 2.2 / 2.2 = 1.0
│   2.95 × 1.0 / 1.228 = 2.402
│
└── SCORE TOTAL: 0.440 + 2.402 = 2.842 ✓ BOM

════════════════════════════════════════════════════════════════

Documento 2: "OpenSearch é distribuído e rápido" (100 termos)
├── Contém "OpenSearch": 1 vez
├── Contém "distribuído": 1 vez
├──
├── Cálculo TF("OpenSearch"):
│   TF saturado = (2.2 × 1) / (1 + 1.2) = 2.2 / 2.2 = 1.0
│
├── Normalização de comprimento:
│   norm = (1 - 0.75 + 0.75 × (100 / 115)) = 0.25 + 0.652 = 0.902
│
├── Score para "OpenSearch":
│   0.392 × 1.0 / 0.902 = 0.435
│
├── Score para "distribuído":
│   2.95 × 1.0 / 0.902 = 3.270
│
└── SCORE TOTAL: 0.435 + 3.270 = 3.705 ✓ MELHOR (doc mais conciso)

════════════════════════════════════════════════════════════════

Documento 3: "Busca rápida com OpenSearch" (50 termos)
├── Contém "OpenSearch": 1 vez
├── Não contém "distribuído"
├──
├── Cálculo TF("OpenSearch"):
│   TF saturado = (2.2 × 1) / (1 + 1.2) = 1.0
│
├── Normalização de comprimento:
│   norm = (1 - 0.75 + 0.75 × (50 / 115)) = 0.25 + 0.326 = 0.576
│
├── Score para "OpenSearch":
│   0.392 × 1.0 / 0.576 = 0.680
│
├── Score para "distribuído":
│   0 (não contém)
│
└── SCORE TOTAL: 0.680 + 0 = 0.680 (não corresponde bem)
```

**Visualização comparativa de scores:**

```mermaid
bar
    title Scores BM25 para "OpenSearch distribuído"
    x-axis [Doc 1, Doc 2, Doc 3]
    y-axis "Score" 0 --> 4.0
    bar [2.842, 3.705, 0.680]
```

**Resultado**: Documento 2 (3.705) aparece primeiro, pois é conciso e contém ambos os termos. Documento 1 (2.842) também é relevante apesar de maior, por conter "distribuído" 1 vez. Documento 3 (0.680) é menos relevante por não conter "distribuído".

---

#### **Ajustando BM25 em seu índice:**

Por padrão, o OpenSearch usa k1=1.2 e b=0.75, o que funciona bem para a maioria dos casos. Você pode customizar:

```bash
PUT http://localhost:9200/produtos/_mapping
Content-Type: application/json

{
  "properties": {
    "descricao": {
      "type": "text",
      "analyzer": "portuguese",
      "similarity": "custom_bm25"
    }
  }
}
```

Com definição customizada no índice:

```bash
PUT http://localhost:9200/produtos
Content-Type: application/json

{
  "settings": {
    "similarity": {
      "custom_bm25": {
        "type": "BM25",
        "k1": 1.5,          # ↑ Favorece frequência (1.5 > 1.2)
        "b": 0.5            # ↓ Menos penalização por comprimento
      }
    }
  },
  "mappings": {
    "properties": {
      "titulo": {
        "type": "text",
        "similarity": "custom_bm25"
      }
    }
  }
}
```

**Ajustes práticos:**
- **k1 maior (1.5-2.0)**: Use quando frequência do termo é muito indicativa de relevância
- **k1 menor (0.8-1.0)**: Use quando quer reduzir impacto da frequência
- **b maior (0.9)**: Use para corpus com documentos de tamanho muito variável
- **b menor (0.2)**: Use para corpus com documentos de tamanho consistente

### 2.4.3 Shards e Replicas: Distribuição

Um índice é dividido em **shards** (fragmentos) para distribuição horizontal:

**Arquitetura de shards e réplicas:**

```mermaid
graph TD
    A["Índice: produtos<br/>3 Shards + Replicação"] --> B["Cluster de 6 Nós"]
    
    B --> N1["Nó 1"]
    B --> N2["Nó 2"]
    B --> N3["Nó 3"]
    B --> N4["Nó 4"]
    B --> N5["Nó 5"]
    B --> N6["Nó 6"]
    
    N1 --> S1["Shard 0<br/>PRIMARY<br/>Docs 0,3,6,9..."]
    N2 --> S1R["Shard 0<br/>REPLICA<br/>Docs 0,3,6,9..."]
    
    N3 --> S2["Shard 1<br/>PRIMARY<br/>Docs 1,4,7,10..."]
    N4 --> S2R["Shard 1<br/>REPLICA<br/>Docs 1,4,7,10..."]
    
    N5 --> S3["Shard 2<br/>PRIMARY<br/>Docs 2,5,8,11..."]
    N6 --> S3R["Shard 2<br/>REPLICA<br/>Docs 2,5,8,11..."]
    
    style S1 fill:#81d4fa
    style S2 fill:#81d4fa
    style S3 fill:#81d4fa
    style S1R fill:#ffccbc
    style S2R fill:#ffccbc
    style S3R fill:#ffccbc
```

**Estrutura visual de um shard:**

```
Shard 0 (Primary) em Nó A
├── Inverted Index (termos → documentos)
├── Documentos 0, 3, 6, 9, ...
└── Metadados do shard
    ├── Tamanho
    ├── Data de criação
    └── Status

    ↓ Replicado para ↓
    
Shard 0 (Replica) em Nó B
├── Cópia idêntica do Primary
├── Pode servir buscas
└── Atualizado automaticamente
```

**Benefícios da arquitetura distribuída:**

```mermaid
graph LR
    A["Shards + Replicas"] --> B["Paralelismo"]
    A --> C["Escalabilidade"]
    A --> D["Resiliência"]
    
    B --> B1["Múltiplos shards processam<br/>queries simultaneamente"]
    C --> C1["Novos nós aumentam<br/>capacidade"]
    D --> D1["Replicas garantem<br/>disponibilidade"]
    
    style B1 fill:#c8e6c9
    style C1 fill:#c8e6c9
    style D1 fill:#c8e6c9
```

---

## 2.5 OPERAÇÕES CRUD VIA API REST

**Ciclo de vida de um documento:**

```mermaid
stateDiagram-v2
    [*] --> CREATE: PUT/POST
    CREATE --> Indexado
    Indexado --> READ: GET
    Indexado --> UPDATE: POST _update
    UPDATE --> Indexado: Versão incrementa
    Indexado --> DELETE: DELETE
    DELETE --> [*]
    
    Indexado --> Busca: Disponível em buscas
    Busca --> Indexado
```

### 2.5.1 CREATE: Criando Documentos

**Operação Create**: Adiciona novo documento ao índice. O OpenSearch retorna erro se o documento já existe.

**Sintaxe:**
```
PUT /<index>/_doc/<_id>
POST /<index>/_doc
```

**Fluxo de criação de documento:**

```mermaid
graph TD
    A["Requisição CREATE"] --> B{ID Fornecido?}
    B -->|Sim| C["PUT com ID específico"]
    B -->|Não| D["POST com ID auto-gerado"]
    
    C --> E["Verifica se doc<br/>já existe"]
    D --> E
    
    E --> F{Doc existe?}
    F -->|Não| G["Cria novo documento<br/>Version = 1"]
    F -->|Sim| H["Retorna erro<br/>version_conflict"]
    
    G --> I["Documento<br/>indexado"]
    H --> J["Operação falha"]
    
    I --> K["Status 201 Created"]
    J --> K
    
    style G fill:#c8e6c9
    style I fill:#c8e6c9
    style H fill:#ffccbc
    style J fill:#ffccbc
```

**Exemplo 1: Criar documento com ID especificado**

```bash
PUT http://localhost:9200/usuarios/_doc/user-001
Content-Type: application/json

{
  "nome": "João Silva",
  "email": "joao@example.com",
  "idade": 28,
  "ativo": true,
  "criado_em": "2025-01-15T10:30:00Z"
}
```

**Resposta:**
```json
{
  "_index": "usuarios",
  "_type": "_doc",
  "_id": "user-001",
  "_version": 1,
  "result": "created",
  "_shards": {
    "total": 2,
    "successful": 1,
    "failed": 0
  },
  "_seq_no": 0,
  "_primary_term": 1
}
```

**Exemplo 2: Criar documento com ID auto-gerado**

```bash
POST http://localhost:9200/usuarios/_doc
Content-Type: application/json

{
  "nome": "Maria Santos",
  "email": "maria@example.com",
  "idade": 32,
  "ativo": true,
  "criado_em": "2025-01-15T11:45:00Z"
}
```

**Resposta:**
```json
{
  "_index": "usuarios",
  "_id": "aBc123DeF456",
  "_version": 1,
  "result": "created"
}
```

**Exemplo 3: Criar documento com operação de índice (upsert)**

```bash
PUT http://localhost:9200/produtos/_doc/prod-laptop-001?op_type=create
Content-Type: application/json

{
  "nome": "Notebook Dell XPS 13",
  "preco": 4500.00,
  "categoria": "Eletrônicos",
  "em_estoque": true
}
```

Se o documento já existir, retorna erro:
```json
{
  "error": {
    "type": "version_conflict_engine_exception",
    "reason": "[prod-laptop-001]: version conflict"
  }
}
```

---

### 2.5.2 READ: Recuperando Documentos

**Operação Read**: Recupera documento existente por ID.

**Sintaxe:**
```
GET /<index>/_doc/<_id>
```

**Exemplo 1: Recuperar documento específico**

```bash
GET http://localhost:9200/usuarios/_doc/user-001
```

**Resposta:**
```json
{
  "_index": "usuarios",
  "_type": "_doc",
  "_id": "user-001",
  "_version": 1,
  "found": true,
  "_source": {
    "nome": "João Silva",
    "email": "joao@example.com",
    "idade": 28,
    "ativo": true,
    "criado_em": "2025-01-15T10:30:00Z"
  }
}
```

**Exemplo 2: Recuperar apenas campos específicos (partial read)**

```bash
GET http://localhost:9200/usuarios/_doc/user-001?_source=nome,email
```

**Resposta:**
```json
{
  "_index": "usuarios",
  "_id": "user-001",
  "found": true,
  "_source": {
    "nome": "João Silva",
    "email": "joao@example.com"
  }
}
```

**Exemplo 3: Verificar existência do documento (apenas header)**

```bash
HEAD http://localhost:9200/usuarios/_doc/user-001
```

Retorna status 200 se existe, 404 se não existe.

**Exemplo 4: Recuperar múltiplos documentos (mget)**

```bash
GET http://localhost:9200/_mget
Content-Type: application/json

{
  "docs": [
    {
      "_index": "usuarios",
      "_id": "user-001"
    },
    {
      "_index": "usuarios",
      "_id": "user-002"
    },
    {
      "_index": "produtos",
      "_id": "prod-laptop-001"
    }
  ]
}
```

**Resposta:**
```json
{
  "docs": [
    {
      "_index": "usuarios",
      "_id": "user-001",
      "found": true,
      "_source": { ... }
    },
    {
      "_index": "usuarios",
      "_id": "user-002",
      "found": false
    },
    {
      "_index": "produtos",
      "_id": "prod-laptop-001",
      "found": true,
      "_source": { ... }
    }
  ]
}
```

---

### 2.5.3 UPDATE: Modificando Documentos

**Operação Update**: Modifica um documento existente. OpenSearch atualiza apenas os campos especificados.

**Sintaxe:**
```
POST /<index>/_update/<_id>
PUT /<index>/_doc/<_id> (substitui completamente)
```

**Comparação entre UPDATE parcial vs. substituição completa:**

```mermaid
graph TD
    A["Documento Original<br/>v1"] --> B["Documento Original<br/>nome: João<br/>email: joao@ex.com<br/>idade: 28<br/>ativo: true"]
    
    C["POST _update<br/>Parcial"] --> D["Apenas campos<br/>na requisição são<br/>modificados"]
    D --> E["Resultado v2<br/>nome: João<br/>email: joao@ex.com<br/>idade: 29<br/>ativo: true"]
    
    F["PUT _doc<br/>Substituição"] --> G["Documento completo<br/>substitui o antigo"]
    G --> H["Resultado v2<br/>novo_campo1: xxx<br/>novo_campo2: yyy<br/>(campos antigos perdidos)"]
    
    style B fill:#bbdefb
    style E fill:#c8e6c9
    style H fill:#ffccbc
```

**Fluxo de atualização:**

```mermaid
graph TD
    A["Requisição UPDATE"] --> B{Tipo de update?}
    
    B -->|Parcial| C["POST _update"]
    B -->|Completo| D["PUT _doc"]
    
    C --> C1["Lê documento<br/>atual"]
    C1 --> C2["Mescla campos<br/>novos"]
    C2 --> C3["Mantém campos<br/>não informados"]
    C3 --> C4["Version incrementa"]
    
    D --> D1["Substitui<br/>completamente"]
    D1 --> D2["Campos não<br/>informados<br/>são perdidos"]
    D2 --> D3["Version incrementa"]
    
    C4 --> E["Documento<br/>atualizado"]
    D3 --> E
    
    style C3 fill:#c8e6c9
    style D2 fill:#ffccbc
```

**Exemplo 1: Update parcial (apenas campos alterados)**

```bash
POST http://localhost:9200/usuarios/_update/user-001
Content-Type: application/json

{
  "doc": {
    "idade": 29,
    "atualizado_em": "2025-01-16T14:20:00Z"
  }
}
```

**Resposta:**
```json
{
  "_index": "usuarios",
  "_id": "user-001",
  "_version": 2,
  "result": "updated",
  "_shards": {
    "total": 2,
    "successful": 1,
    "failed": 0
  }
}
```

O documento agora contém: nome, email, idade (29), ativo, criado_em, atualizado_em.

**Exemplo 2: Update com script**

```bash
POST http://localhost:9200/produtos/_update/prod-laptop-001
Content-Type: application/json

{
  "script": {
    "source": "ctx._source.estoque -= params.quantidade",
    "params": {
      "quantidade": 5
    }
  }
}
```

Este script reduz o estoque em 5 unidades. Pode ser executado atomicamente.

**Exemplo 3: Update com upsert (atualizar ou criar)**

```bash
POST http://localhost:9200/usuarios/_update/user-999
Content-Type: application/json

{
  "doc": {
    "nome": "Pedro Costa",
    "email": "pedro@example.com",
    "idade": 35,
    "ativo": true
  },
  "doc_as_upsert": true
}
```

Se user-999 não existe, será criado. Se existe, será atualizado.

**Exemplo 4: Substituição completa (PUT com ID)**

```bash
PUT http://localhost:9200/usuarios/_doc/user-001
Content-Type: application/json

{
  "nome": "João Silva Atualizado",
  "email": "joao.novo@example.com",
  "idade": 29,
  "ativo": true,
  "criado_em": "2025-01-15T10:30:00Z",
  "atualizado_em": "2025-01-16T14:20:00Z"
}
```

Substitui completamente o documento anterior. Versão incrementa para 2.

---

### 2.5.4 DELETE: Removendo Documentos

**Operação Delete**: Remove um documento do índice.

**Sintaxe:**
```
DELETE /<index>/_doc/<_id>
```

**Estados e fluxo de deleção:**

```mermaid
graph TD
    A["Requisição DELETE"] --> B["Procura documento<br/>por ID"]
    
    B --> C{Documento<br/>existe?}
    
    C -->|Sim| D["Remove documento<br/>do índice"]
    C -->|Não| E["Retorna<br/>not_found"]
    
    D --> F["Marca como<br/>deletado"]
    F --> G["Version incrementa"]
    G --> H["Espaço pode ser<br/>reclamado<br/>em Merge"]
    
    H --> I["Status 200 OK<br/>result: deleted"]
    E --> J["Status 200 OK<br/>result: not_found"]
    
    style D fill:#c8e6c9
    style I fill:#c8e6c9
    style E fill:#fff9c4
    style J fill:#fff9c4
```

**Ciclo de vida pós-deleção:**

```mermaid
sequenceDiagram
    participant Client as Cliente
    participant OS as OpenSearch
    participant Index as Índice
    
    Client->>OS: DELETE /usuarios/_doc/user-001
    OS->>Index: Procura documento
    Index-->>OS: Encontrado (version: 5)
    OS->>Index: Marca como deletado<br/>Nova versão: 6
    Index->>Index: Inverted index<br/>atualizado
    OS-->>Client: Status 200<br/>result: deleted
    
    Note over Index: Documento físicamente<br/>ainda pode estar<br/>em segmentos
    Note over Index: Será reclamado<br/>em operações<br/>de merge
```

**Exemplo 1: Deletar documento específico**

```bash
DELETE http://localhost:9200/usuarios/_doc/user-999
```

**Resposta:**
```json
{
  "_index": "usuarios",
  "_id": "user-999",
  "_version": 1,
  "result": "deleted",
  "_shards": {
    "total": 2,
    "successful": 1,
    "failed": 0
  }
}
```

**Exemplo 2: Tentativa de deletar documento inexistente**

```bash
DELETE http://localhost:9200/usuarios/_doc/nao-existe
```

**Resposta:**
```json
{
  "_index": "usuarios",
  "_id": "nao-existe",
  "_version": 1,
  "result": "not_found"
}
```

**Exemplo 3: Deletar múltiplos documentos por query (bulk delete)**

```bash
POST http://localhost:9200/_bulk
Content-Type: application/json

{"delete":{"_index":"usuarios","_id":"user-001"}}
{"delete":{"_index":"usuarios","_id":"user-002"}}
{"delete":{"_index":"produtos","_id":"prod-laptop-001"}}
```

**Resposta:**
```json
{
  "took": 45,
  "errors": false,
  "items": [
    {
      "delete": {
        "_index": "usuarios",
        "_id": "user-001",
        "_version": 3,
        "result": "deleted"
      }
    },
    {
      "delete": {
        "_index": "usuarios",
        "_id": "user-002",
        "result": "not_found"
      }
    },
    {
      "delete": {
        "_index": "produtos",
        "_id": "prod-laptop-001",
        "result": "deleted"
      }
    }
  ]
}
```

---

### 🔐 **BOX DE ALERTA: Considerar Soft Delete em Produção**

Deletar documentos permanentemente pode ser irreversível. Em muitos cenários de produção, é preferível usar **soft delete**:

```bash
POST /usuarios/_update/user-001
{
  "doc": {
    "deletado": true,
    "data_deletacao": "2025-01-16T15:00:00Z"
  }
}
```

Depois filtrar nas queries:
```bash
GET /usuarios/_search
{
  "query": {
    "term": {
      "deletado": false
    }
  }
}
```

---

## 2.6 OPERAÇÕES AVANÇADAS COM DOCUMENTOS

### 2.6.1 Bulk Operations

Para inserir, atualizar ou deletar múltiplos documentos eficientemente, use a API Bulk:

**Fluxo de processamento de bulk operations:**

```mermaid
graph TD
    A["Requisição BULK<br/>4 operações"] --> B["OpenSearch processa<br/>sequencialmente"]
    
    B --> C["1. Index user-101<br/>✓ Status 201"]
    B --> D["2. Index user-102<br/>✓ Status 201"]
    B --> E["3. Update user-001<br/>✓ Status 200"]
    B --> F["4. Delete user-999<br/>✓ Status 200"]
    
    C --> G["Resposta consolidada<br/>took: 120ms<br/>errors: false"]
    D --> G
    E --> G
    F --> G
    
    G --> H["Array com status<br/>de cada operação"]
    
    style C fill:#c8e6c9
    style D fill:#c8e6c9
    style E fill:#bbdefb
    style F fill:#ffccbc
    style G fill:#fff9c4
    style H fill:#fff9c4
```

**Comparação: Single vs. Bulk Operations:**

```mermaid
graph LR
    subgraph "3 Single Requests"
        A1["PUT /usuarios/_doc/user-101"]
        A2["PUT /usuarios/_doc/user-102"]
        A3["DELETE /usuarios/_doc/user-999"]
        A1 --> B1["HTTP Round Trip 1"]
        A2 --> B2["HTTP Round Trip 2"]
        A3 --> B3["HTTP Round Trip 3"]
        B1 --> C["Total Latência:<br/>3x latência de rede"]
    end
    
    subgraph "1 Bulk Request"
        D["POST /_bulk<br/>3 operações"]
        D --> E["HTTP Round Trip 1"]
        E --> F["Total Latência:<br/>1x latência de rede<br/>+ processamento"]
    end
    
    C -->|Mais lento| G["~300ms"]
    F -->|Mais rápido| H["~100ms"]
    
    style C fill:#ffccbc
    style F fill:#c8e6c9
```

```bash
POST http://localhost:9200/_bulk
Content-Type: application/json

{"index":{"_index":"usuarios","_id":"user-101"}}
{"nome":"Alice","email":"alice@example.com","idade":25,"ativo":true}
{"index":{"_index":"usuarios","_id":"user-102"}}
{"nome":"Bob","email":"bob@example.com","idade":31,"ativo":true}
{"update":{"_index":"usuarios","_id":"user-001"}}
{"doc":{"idade":30}}
{"delete":{"_index":"usuarios","_id":"user-999"}}
```

**Resposta:**
```json
{
  "took": 120,
  "errors": false,
  "items": [
    {
      "index": {
        "_index": "usuarios",
        "_id": "user-101",
        "_version": 1,
        "result": "created"
      }
    },
    {
      "index": {
        "_index": "usuarios",
        "_id": "user-102",
        "_version": 1,
        "result": "created"
      }
    },
    {
      "update": {
        "_index": "usuarios",
        "_id": "user-001",
        "_version": 2,
        "result": "updated"
      }
    },
    {
      "delete": {
        "_index": "usuarios",
        "_id": "user-999",
        "result": "deleted"
      }
    }
  ]
}
```

**Vantagens:**
- ✓ Uma única requisição HTTP para múltiplas operações
- ✓ Reduz latência de rede significativamente
- ✓ OpenSearch processa em paralelo nos shards
- ✓ Ideal para grandes volumes de dados

---

### 2.6.2 Versionamento de Documentos

O OpenSearch mantém automaticamente a versão de cada documento. Isso é útil para controle de concorrência:

**Histórico de versões durante operações:**

```mermaid
graph LR
    A["Doc criado<br/>v1"] --> B["Primeiro update<br/>v2"]
    B --> C["Segundo update<br/>v3"]
    C --> D["Delete<br/>v4"]
    D --> E["Recreado<br/>v5"]
    
    style A fill:#c8e6c9
    style B fill:#bbdefb
    style C fill:#bbdefb
    style D fill:#ffccbc
    style E fill:#c8e6c9
```

**Controle de concorrência com versionamento:**

```mermaid
sequenceDiagram
    participant Client1 as Cliente 1
    participant Client2 as Cliente 2
    participant OS as OpenSearch
    
    OS->>Client1: GET user-001<br/>v5
    OS->>Client2: GET user-001<br/>v5
    
    Client1->>OS: PUT user-001?if_seq_no=5<br/>Novos dados
    OS->>OS: Valida versão OK
    OS-->>Client1: Status 200<br/>v6 criada
    
    Client2->>OS: PUT user-001?if_seq_no=5<br/>Novos dados diferentes
    OS->>OS: Verifica: seq_no agora é 6<br/>Conflito!
    OS-->>Client2: Status 409<br/>version_conflict_engine_exception
    
    Note over Client2: Cliente 2 precisa<br/>recarregar e<br/>tentar novamente
```

```bash
PUT http://localhost:9200/usuarios/_doc/user-001?if_seq_no=5&if_primary_term=1
Content-Type: application/json

{
  "nome": "João Silva",
  "email": "joao@example.com",
  "idade": 30
}
```

Se a versão não corresponder, retorna erro de conflito:
```json
{
  "error": {
    "type": "version_conflict_engine_exception",
    "reason": "[user-001]: version conflict"
  }
}
```

Isso previne race conditions quando múltiplos clientes atualizam o mesmo documento.

---

## 2.7 EXERCÍCIOS PRÁTICOS DE FIXAÇÃO

### Exercício 2.1: Criando um Índice com Mapping Explícito

**Objetivo**: Criar um índice para gerenciar artigos de blog com tipos de dados apropriados.

**Tarefa:**
1. Crie um índice chamado `blog-posts` com mapping explícito
2. Defina os seguintes campos:
   - `titulo` (text com analyzer portuguese)
   - `conteudo` (text com analyzer portuguese)
   - `autor` (keyword)
   - `data_publicacao` (date)
   - `categoria` (keyword)
   - `tags` (array de keywords)
   - `visualizacoes` (integer)
   - `curtidas` (integer)
   - `ativo` (boolean)

3. Teste inserindo um documento de exemplo

**Resposta esperada:**
```bash
PUT http://localhost:9200/blog-posts
Content-Type: application/json

{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "titulo": {
        "type": "text",
        "analyzer": "portuguese"
      },
      "conteudo": {
        "type": "text",
        "analyzer": "portuguese"
      },
      "autor": {
        "type": "keyword"
      },
      "data_publicacao": {
        "type": "date"
      },
      "categoria": {
        "type": "keyword"
      },
      "tags": {
        "type": "keyword"
      },
      "visualizacoes": {
        "type": "integer"
      },
      "curtidas": {
        "type": "integer"
      },
      "ativo": {
        "type": "boolean"
      }
    }
  }
}
```

### Exercício 2.2: Operações CRUD Completas

**Objetivo**: Executar todas as operações CRUD em um índice.

**Tarefa:**
1. Crie um documento no índice `blog-posts` com ID `post-001`
2. Recupere o documento
3. Atualize apenas o campo `visualizacoes` para 150
4. Recupere novamente para confirmar
5. Delete o documento
6. Tente recuperar (deve retornar not found)

**Passo a passo:**

```bash
# CREATE
POST http://localhost:9200/blog-posts/_doc/post-001
Content-Type: application/json

{
  "titulo": "Introdução ao OpenSearch",
  "conteudo": "OpenSearch é um fork do Elasticsearch...",
  "autor": "João Silva",
  "data_publicacao": "2025-01-15T10:00:00Z",
  "categoria": "Tecnologia",
  "tags": ["opensearch", "busca", "tutorial"],
  "visualizacoes": 0,
  "curtidas": 0,
  "ativo": true
}

# READ
GET http://localhost:9200/blog-posts/_doc/post-001

# UPDATE
POST http://localhost:9200/blog-posts/_update/post-001
Content-Type: application/json

{
  "doc": {
    "visualizacoes": 150
  }
}

# READ novamente
GET http://localhost:9200/blog-posts/_doc/post-001

# DELETE
DELETE http://localhost:9200/blog-posts/_doc/post-001

# READ (not found)
GET http://localhost:9200/blog-posts/_doc/post-001
```

### Exercício 2.3: Testando Diferentes Analyzers

**Objetivo**: Compreender o impacto de analyzers na tokenização.

**Tarefa:**
1. Crie um índice `analyzer-test` com dois campos:
   - `texto_standard` (usando analyzer padrão)
   - `texto_portuguese` (usando analyzer português)
2. Insira um documento com texto em português
3. Use a API de análise para ver como cada analyzer processa o texto

**Teste de análise:**

```bash
POST http://localhost:9200/analyzer-test/_analyze
Content-Type: application/json

{
  "analyzer": "standard",
  "text": "O rápido raposa marrom pulou sobre a cerca"
}
```

**Resultado:**
```json
{
  "tokens": [
    {"token":"o","start_offset":0,"end_offset":1,"type":"<ALPHANUM>","position":0},
    {"token":"rápido","start_offset":2,"end_offset":8,"type":"<ALPHANUM>","position":1},
    {"token":"raposa","start_offset":9,"end_offset":15,"type":"<ALPHANUM>","position":2},
    {"token":"marrom","start_offset":16,"end_offset":22,"type":"<ALPHANUM>","position":3},
    {"token":"pulou","start_offset":23,"end_offset":28,"type":"<ALPHANUM>","position":4},
    {"token":"sobre","start_offset":29,"end_offset":34,"type":"<ALPHANUM>","position":5},
    {"token":"a","start_offset":35,"end_offset":36,"type":"<ALPHANUM>","position":6},
    {"token":"cerca","start_offset":37,"end_offset":42,"type":"<ALPHANUM>","position":7}
  ]
}
```

```bash
POST http://localhost:9200/analyzer-test/_analyze
Content-Type: application/json

{
  "analyzer": "portuguese",
  "text": "O rápido raposa marrom pulou sobre a cerca"
}
```

**Resultado (note a remoção de stopwords):**
```json
{
  "tokens": [
    {"token":"rápid","start_offset":2,"end_offset":8,"type":"<ALPHANUM>","position":1},
    {"token":"rapos","start_offset":9,"end_offset":15,"type":"<ALPHANUM>","position":2},
    {"token":"marrom","start_offset":16,"end_offset":22,"type":"<ALPHANUM>","position":3},
    {"token":"pul","start_offset":23,"end_offset":28,"type":"<ALPHANUM>","position":4},
    {"token":"sobr","start_offset":29,"end_offset":34,"type":"<ALPHANUM>","position":5},
    {"token":"cerc","start_offset":37,"end_offset":42,"type":"<ALPHANUM>","position":7}
  ]
}
```

---

## 2.8 SÍNTESE DO CAPÍTULO

Neste capítulo, você aprendeu os fundamentos essenciais do OpenSearch:

**Estrutura de dados:**
- Índices são contineres de documentos
- Documentos são objetos JSON com metadados
- OpenSearch suporta diversos tipos de dados para diferentes necessidades

**Mapeamento:**
- Mapping dinâmico oferece flexibilidade mas com riscos
- Mapping explícito é recomendado para produção
- Multi-campos permitem diferentes tipos de busca no mesmo dado

**Análise e tokenização:**
- Analyzers processam texto em tokens para indexação
- Escolher o analyzer correto impacta qualidade de busca
- Language analyzers específicos melhoram resultados em português

**Inverted Index:**
- Mapeia termos → documentos para busca rápida
- TF-IDF calcula relevância dos resultados
- Shards distribuem dados para escalabilidade

**Operações CRUD:**
- CREATE: Inserir novos documentos
- READ: Recuperar por ID
- UPDATE: Modificar campos existentes
- DELETE: Remover documentos
- Bulk: Operações em massa eficientemente

Você agora possui os conhecimentos necessários para estruturar dados, criar índices apropriados e realizar operações básicas de manipulação de dados no OpenSearch. No próximo capítulo, exploraremos como buscar e analisar dados com queries avançadas.

---

## REFERÊNCIAS

OPENSEARCH PROJECT. OpenSearch Documentation: Data Types. Disponível em: https://docs.opensearch.org/latest/clients/data/. Acesso em: 15 jan. 2025.

OPENSEARCH PROJECT. OpenSearch Documentation: Mapping. Disponível em: https://docs.opensearch.org/latest/field-types/index/. Acesso em: 15 jan. 2025.

OPENSEARCH PROJECT. OpenSearch Documentation: Analyzers. Disponível em: https://docs.opensearch.org/latest/analyzers/token-analyzers/. Acesso em: 15 jan. 2025.

OPENSEARCH PROJECT. OpenSearch Documentation: Document API. Disponível em: https://docs.opensearch.org/latest/api-reference/document-apis/index/. Acesso em: 15 jan. 2025.

---

**Fim do Capítulo 2**