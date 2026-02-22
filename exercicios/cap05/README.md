# Exercícios — Capítulo 5: Fluent Bit

Arquivos de dados e configurações para os exercícios do Capítulo 5.

## Estrutura

```
cap05/
├── README.md (este arquivo)
├── ex1-app-logs.ndjson        (Dados para Ex 1: Pipeline básico)
├── ex2-apache-logs.txt         (Dados para Ex 2: Parser Regex)
├── ex3-malformed-logs.txt      (Dados para Ex 3: Debug Parser)
└── ex4-ecommerce-logs.ndjson   (Dados para Ex 4: Filter Lua)
```

## Exercícios

**Executar:** Veja `exemplos/cap05/docker-compose.yml` para setup e instruções.

- **Ex 1:** Pipeline Básico — Input Dummy → Parser JSON → Filter → OpenSearch
- **Ex 2:** Parser Regex — Apache Combined Log Format
- **Ex 3:** Debugar Parser — Identificar e corrigir erros
- **Ex 4:** Filter Lua — Enriquecimento e normalização

Cada arquivo `.ndjson` contém dados para teste.
