# Datasets e Scripts de Carga — Ebook OpenSearch 3.5

Este diretório contém os datasets e scripts necessários para reproduzir todos os exemplos e exercícios do ebook em sala de aula.

## Pré-requisitos

1. **Docker Desktop** instalado e em execução
2. Subir o ambiente OpenSearch:
   ```bash
   docker compose -f exemplos/docker-compose.single-node.yml up -d
   ```
3. Aguardar ~30 segundos e verificar se está saudável:
   ```bash
   curl -sk -u admin:<SENHA_ADMIN> https://localhost:9200/_cluster/health?pretty
   ```

## Como Carregar os Dados

### Opção 1: Carregar tudo de uma vez (recomendado)
```bash
bash exercicios/carregar-tudo.sh
```

### Opção 2: Carregar por capítulo
```bash
bash exercicios/cap01/carregar.sh   # Capítulo 1 — Introdução e Arquitetura
bash exercicios/cap02/carregar.sh   # Capítulo 2 — Conceitos e CRUD
bash exercicios/cap03/carregar.sh   # Capítulo 3 — Query DSL e PPL
bash exercicios/cap04/carregar.sh   # Capítulo 4 — Agregações
```

> Cada script é **idempotente**: apaga e recria os índices. Pode ser executado quantas vezes for necessário para reiniciar o estado dos dados.

## Verificar Índices Carregados

```bash
curl -sk -u admin:<SENHA_ADMIN> https://localhost:9200/_cat/indices?v&s=index
```

## Índices por Capítulo

| Capítulo | Índices Criados |
|----------|----------------|
| Cap 01 | `livros`, `vendas-2025` |
| Cap 02 | `usuarios`, `produtos`, `produtos-dinamico`, `produtos-explicitamente-mapeado`, `blog-posts`, `logs-api` |
| Cap 03 | `articles`, `users`, `documents`, `products`, `events`, `store`, `news`, `job-listings`, `blog`, `api-logs`, `application-logs`, `orders`, `logs`, `customer-interactions`, `transactions`, `metrics`, `e-commerce`, `sales`, `error-logs` |
| Cap 04 | `ecommerce-products`, `vendas`, `vendas-ecommerce`, `logs-api-2024`, `logs-web`, `sensor-iot`, `dados-financeiros`, `avaliacoes-clientes`, `analytics-website`, `system-health`, `product-reviews`, `abandoned-carts`, `transacoes-financeiras` |

## Credenciais Padrão

| Configuração | Valor |
|-------------|-------|
| URL | `https://localhost:9200` |
| Usuário | `admin` |
| Senha | `<SENHA_ADMIN>` |

> Use sempre `-k` no curl para ignorar a validação do certificado SSL autoassinado.
