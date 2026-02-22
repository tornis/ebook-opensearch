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

**Executar:** Veja `exemplos/cap05/COMO_USAR.md` para setup detalhado e instruções passo-a-passo.

- **Ex 1:** Pipeline Básico — Input Dummy → Parser JSON → Filter → OpenSearch
- **Ex 2:** Parser Regex — Apache Combined Log Format estruturado
- **Ex 3:** Debugar Parser — Identificar e corrigir erros com imagem debug
- **Ex 4:** Filter Lua — Enriquecimento e normalização de logs e-commerce
- **Ex 5:** Monitoramento Docker — Capturar logs e métricas do próprio Docker em tempo real

Cada arquivo `.ndjson`/`.txt` contém dados para teste. Exercício 5 usa volumes montados para acesso ao Docker socket e logs do host.
