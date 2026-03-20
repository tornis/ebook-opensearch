#!/usr/bin/env python3
"""
Gerador de Dataset de Textos para Vetorização no OpenSearch.

Cria 50 textos distribuídos em 3 temas:
- OpenSearch: ~17 textos
- Elasticsearch: ~17 textos
- RAG (Retrieval-Augmented Generation): ~16 textos

Cada texto tem aproximadamente 20 linhas.
Formato: NDJSON (newline-delimited JSON) compatível com Bulk API.
Índice: temas-ti
"""

import json
import random
from datetime import datetime

OPENSEARCH_TEXTS = [
    """OpenSearch é uma distribuição de código aberto do Elasticsearch mantida pela comunidade.
Ela oferece recursos avançados de busca e análise de dados em tempo real.
O projeto começou em 2021 como um fork do Elasticsearch 7.10.
OpenSearch é totalmente compatível com as APIs do Elasticsearch.
A plataforma suporta buscas complexas usando Query DSL.
Inclui capacidades de análise de dados com agregações poderosas.
OpenSearch permite indexação e busca de grandes volumes de dados.
O sistema é altamente escalável e pode ser distribuído em clusters.
Suporta múltiplos índices e sharding para performance.
OpenSearch inclui plugins de segurança e autenticação.
A plataforma oferece interfaces de administração via API REST.
Suporta parsing e transformação de dados com ingestão.
OpenSearch é usado para log analytics e monitoramento.
Oferece ferramentas de visualização e kibana compatível.
A comunidade mantém documentação abrangente e exemplos.
OpenSearch pode ser deployado em Kubernetes e Docker.
Suporta APIs de busca semântica e vetorial.""",

    """OpenSearch Dashboard é a interface de visualização oficial para OpenSearch.
Permite criar dashboards interativos e relatórios customizados.
Oferece ferramentas para explorar e analisar dados visualmente.
Suporta múltiplos tipos de visualizações: gráficos, tabelas, mapas.
Dashboard integra-se perfeitamente com OpenSearch.
Permite criar alertas baseados em condições de dados.
Oferece capacidades de segurança e controle de acesso.
Dashboard suporta salvamento de buscas e consultas.
Inclui ferramentas para devOps e monitoramento.
Suporta importação e exportação de dashboards.
Dashboard oferece API para automação de tarefas.
Permite compartilhamento de dashboards entre usuários.
Dashboard é responsivo e funciona em diferentes dispositivos.
Oferece filtros dinâmicos para exploração de dados.
Suporta integração com ferramentas externas.
Dashboard inclui templates prontos para casos de uso comuns.
Oferece features avançadas de análise preditiva.""",

    """Ingestão de dados é um componente crítico do OpenSearch.
Pipeline de ingestão processa documentos antes da indexação.
Permite transformação, filtragem e enriquecimento de dados.
Suporta múltiplos processadores: split, lowercase, remove, etc.
Ingestão oferece validação de dados antes do armazenamento.
Permite adicionar campos computados aos documentos.
Ingestão suporta tratamento de erros e fallbacks.
Oferece performance otimizada para processamento em lote.
Suporta formatação de datas e conversão de tipos.
Permite análise de logs estruturados e não estruturados.
Ingestão oferece parsing de formatos complexos.
Suporta integração com sistemas externos via pipelines.
Permite remoção de campos sensíveis durante ingestão.
Oferece métricas de monitoramento para pipelines.
Suporta conditions para lógica condicional.
Ingestão é essencial para data quality.
Permite preprocessamento inteligente de dados.""",

    """Clustering no OpenSearch é fundamental para alta disponibilidade.
Múltiplos nós podem ser agrupados em um cluster.
Suporta replicação automática de dados entre nós.
Oferece failover automático para recuperação de falhas.
Clustering permite distribuição de carga de trabalho.
Cada shard pode ter múltiplas réplicas.
OpenSearch gerencia automaticamente a distribuição de dados.
Suporta discovery automático de nós novos no cluster.
Oferece APIs para monitoramento de saúde do cluster.
Permite configuração de políticas de alocação.
Clustering suporta rolling upgrades sem downtime.
Oferece rebalanceamento automático de shards.
Suporta diferentes tipos de nós: dados, master, ingest.
Permite isolamento de carga de trabalho em nós específicos.
Oferece métricas detalhadas de performance.
Clustering é escalável para milhares de nós.
Suporta cross-cluster replication para DR.""",

    """Segurança no OpenSearch é multifacetado e robusta.
Oferece autenticação baseada em LDAP e SAML.
Suporta controle de acesso baseado em roles (RBAC).
Permite criptografia de dados em trânsito e em repouso.
Oferece auditoria detalhada de todas as operações.
Suporta SSO para integração com provedores corporativos.
Segurança oferece mascaramento de campos sensíveis.
Permite definição granular de permissões por índice.
Suporta rate limiting para proteção contra abuso.
Oferece detecção de anomalias em padrões de acesso.
Permite integração com sistemas de autenticação.
Suporta multi-tenancy com isolamento de dados.
Oferece compliance com regulações como GDPR.
Permite revogação de tokens de acesso.
Suporta encryption de backups e snapshots.
Oferece alertas para violações de segurança.
Segurança é essencial para dados sensíveis.""",

    """Performa no OpenSearch depende de várias otimizações.
Indexação é otimizada para escritas rápidas.
Suporta refresh_interval configurável para controle de latência.
Oferece compressão de índices para economia de espaço.
Tuning de JVM é crucial para performance.
Permite otimização de queries com índices de inversão.
Suporta caching de resultados de filtros.
Oferece análise de slow query logs.
Permite configuração de threadpools específicos.
Suporta merging automático de segmentos.
Oferece métricas de jstat e profiling.
Permite otimização de bulk imports.
Suporta lazy loading de dados em busca.
Oferece índices read-only para melhor performance.
Permite desativação de features desnecessárias.
Suporta force merge para otimização final.
Performance é alcançada através de tunning cuidadoso.""",

    """Vector search no OpenSearch é recurso emergente.
Permite busca semântica baseada em embeddings.
Suporta k-NN (k-nearest neighbors) search.
Oferece busca aproximada para performance em escala.
Vector search é essencial para aplicações de IA.
Permite indexação de embeddings de texto.
Suporta diferentes algoritmos de busca vetorial.
Oferece integração com modelos de machine learning.
Permite busca combinada (léxica + semântica).
Suporta tipos de dados específicos para vetores.
Oferece análise de similaridade entre documentos.
Permite aplicações de recomendação.
Suporta clusters de centroides para eficiência.
Oferece tuning de parâmetros de busca.
Permite uso em sistemas de RAG.
Vector search abre novas possibilidades.
Suporta embeddings pré-computados.""",

    """Observabilidade no OpenSearch oferece visibilidade completa.
Permite rastreamento de traces distribuído.
Suporta coleta de métricas em tempo real.
Oferece agregação de logs de múltiplas fontes.
Observabilidade inclui dashboards pré-construídos.
Permite alertas baseados em métricas.
Suporta correlação entre logs e métricas.
Oferece análise de causa raiz de problemas.
Permite visualização de topologia de aplicações.
Suporta integration com OpenTelemetry.
Oferece APIs para consulta de dados de observabilidade.
Permite rastreamento de performance de aplicações.
Suporta análise histórica de dados operacionais.
Oferece detecção automática de anomalias.
Permite alertas inteligentes e agrupamento.
Observabilidade é crítica para SRE.
Oferece insights operacionais valiosos.""",

    """Migrações para OpenSearch requerem planejamento cuidadoso.
Ferramentas facilitam migração do Elasticsearch.
Oferece compatibilidade com backups do Elasticsearch.
Suporta migração sem downtime com logstash.
Permite reindexação de dados.
Suporta migração incremental em fases.
Oferece validação de dados pós-migração.
Permite testes A/B antes da migração completa.
Suporta rollback em caso de problemas.
Oferece ferramentas de comparação de índices.
Permite migração de configurações e templates.
Suporta snapshot e restore entre versões.
Oferece documentação detalhada do processo.
Permite script de migração customizado.
Suporta paralelização de migração.
Migração deve ser testada em staging.
Oferece suporte comunitário para migração.""",

    """Machine Learning no OpenSearch oferece capabilities avançadas.
Permite detecção de anomalias automática.
Suporta análise de série temporal.
Oferece modelos de forecasting preditivo.
Permite análise de sentimento em textos.
Suporta classificação automática de documentos.
Oferece clustering não supervisionado.
Permite integração com modelos externos.
Suporta processamento de linguagem natural.
Oferece feature engineering automático.
Permite explicabilidade de decisões de ML.
Suporta treino de modelos offline.
Oferece avaliação de modelos em tempo real.
Permite A/B testing de modelos.
Suporta ensemble de múltiplos modelos.
ML abre possibilidades de análise inteligente.
Oferece APIs para integração de modelos.""",
]

ELASTICSEARCH_TEXTS = [
    """Elasticsearch é o mecanismo de busca mais popular do mundo.
Fundado em 2010 por Shay Banon.
Oferece busca e análise em tempo real de qualquer escala.
Elasticsearch é desenvolvido e mantido pela Elastic.
Baseado no Apache Lucene para funcionalidades principais.
Oferece APIs RESTful para fácil integração.
Suporta buscas complexas com Query DSL.
Elasticsearch pode processar petabytes de dados.
Oferece capacidades de análise com agregações.
Elasticsearch é usado por empresas Fortune 500.
Permite busca full-text avançada e relevância.
Oferece linguagem de query poderosa e flexível.
Elasticsearch suporta múltiplos tipos de análise.
Oferece integração com Stack Elastic completo.
Elasticsearch é confiável e altamente disponível.
Permite escalabilidade horizontal em clusters.
Elasticsearch oferece busca praticamente instantânea.""",

    """Kibana é plataforma de visualização para Elasticsearch.
Oferece dashboards interativos e análise visual.
Permite criar visualizações customizadas.
Kibana suporta múltiplos tipos de gráficos.
Oferece ferramentas de exploração de dados.
Permite salvamento e compartilhamento de buscas.
Kibana integra-se perfeitamente com Elasticsearch.
Oferece alertas baseados em condições.
Suporta automação com regras de ação.
Kibana oferece Canvas para visualizações avançadas.
Permite criação de relatórios agendados.
Suporta integração com sistemas de BI.
Kibana oferece análise de impacto de mudanças.
Permite investigação de problemas operacionais.
Oferece métricas de negócio e KPIs.
Kibana é essencial para insights de dados.
Oferece interface intuitiva e responsiva.""",

    """Logstash é ferramenta de processamento de dados pipeline.
Coleta, parseia e enriquece dados.
Oferece múltiplos inputs: arquivos, TCP, HTTP.
Suporta processamento complexo com filtros.
Logstash oferece múltiplos outputs: Elasticsearch, arquivos.
Permite transformação de dados estruturados e não estruturados.
Suporta dissecação de logs complexos.
Logstash oferece performance otimizada para streaming.
Permite adicionar contexto aos dados.
Suporta enriquecimento com dados externos.
Logstash oferece confiabilidade com persistência.
Permite remoção de dados sensíveis.
Suporta compressão de dados em trânsito.
Logstash oferece monitoramento de pipelines.
Permite debugging de pipelines.
Suporta múltiplas instâncias para alta disponibilidade.
Logstash é backbone da ingestão de dados.""",

    """Beats são agentes leves para coleta de dados.
Filebeat coleta logs de arquivos.
Metricbeat coleta métricas do sistema.
Packetbeat captura dados de rede.
Heartbeat monitora disponibilidade de serviços.
Auditbeat coleta dados de auditoria.
Functionbeat coleta dados de cloud functions.
Beats oferecem overhead mínimo.
Suportam múltiplas configurações de output.
Beats podem coletar diferentes tipos de dados.
Oferecem parsing integrado para formatos comuns.
Suportam filtros de dados antes do envio.
Beats oferecem HA com failover automático.
Permittem metadata customizado.
Suportam compressão de dados.
Beats são essenciais para monitoramento.
Oferecem monitoramento de infraestrutura completo.""",

    """Stack Elastic oferece suite completa de ferramentas.
Inclui Elasticsearch, Kibana, Beats e Logstash.
Oferece observabilidade completa de sistemas.
Suite fornece segurança integrada.
Elasticsearch para busca e análise.
Kibana para visualização e exploração.
Beats para coleta de dados leve.
Logstash para processamento de pipeline.
Oferece integração perfeita entre componentes.
Suite suporta casos de uso diversos.
Oferece funcionalidades empresariais avançadas.
Suite é escalável para qualquer volume.
Oferece suporte profissional da Elastic.
Suite inclui ferramentas de segurança.
Oferece conformidade com regulações.
Stack Elastic é solução completa.
Oferece ROI comprovado em produção.""",

    """Query DSL é linguagem poderosa de Elasticsearch.
Oferece buscas estruturadas complexas.
Suporta múltiplos tipos de query.
Match query para busca full-text.
Term query para busca exata.
Range query para buscas de intervalo.
Bool query para combinação lógica.
Wildcard query para buscas com padrão.
Regex query para buscas com expressão regular.
Prefix query para buscas com prefixo.
Fuzzy query para busca tolerante a erros.
Script query para queries customizadas.
Filter context para busca rápida.
Query context para busca com relevância.
DSL oferece precisão e flexibilidade.
Suporta aggregações aninhadas.
Query DSL é foundation do Elasticsearch.""",

    """Agregações no Elasticsearch oferecem análise poderosa.
Metrics aggregations para estatísticas.
Bucket aggregations para agrupamento.
Terms aggregation agrupa por valor único.
Date histogram para análise temporal.
Range aggregation para agrupamento de intervalo.
Cardinality para contar valores únicos.
Avg para média de valores.
Sum para somatório.
Min/Max para valores extremos.
Percentiles para análise de distribuição.
Nested aggregations para análise multinível.
Pipeline aggregations para análise derivada.
Suporta múltiplas agregações simultâneas.
Oferece análise rápida de grandes volumes.
Agregações são essenciais para BI.
Suportam profundidade ilimitada de nesting.""",

    """Segurança no Elasticsearch é comprehensive.
Oferece autenticação e autorização.
Suporta LDAP e SAML.
Oferece RBAC (Role-Based Access Control).
Permite criptografia em trânsito e em repouso.
Oferece auditoria completa de operações.
Suporta multi-tenancy seguro.
Oferece field level security.
Permite mascaramento de dados sensíveis.
Suporta SSO corporativo.
Oferece token management avançado.
Permite API key para automação.
Suporta detecção de anomalias.
Oferece compliance com GDPR.
Permite revogação de acesso.
Segurança é essencial em produção.
Oferece proteção contra ataques conhecidos.""",

    """Performance em Elasticsearch é crítica.
Tuning de JVM para otimização.
Configuração de threadpools adequados.
Otimização de bulk indexing.
Refresh interval configurável.
Merge policies otimizadas.
Compressão de índices.
Caching de resultados.
Análise de slow query logs.
Índices read-only para economia.
Force merge para otimização final.
Sharding estratégico.
Replicação apropriada.
Máquinas com recursos adequados.
Monitoramento contínuo.
Performance depende de múltiplos fatores.
Requer otimização contínua.""",

    """Monitoramento no Elasticsearch é importante.
Ferramentas nativas de monitoramento.
Kibana para visualização de métricas.
Alertas baseados em condições.
Monitoramento de saúde do cluster.
Monitoramento de índices.
Monitoramento de nós.
Monitoramento de shards.
Métricas de JVM.
Métricas de sistema operacional.
Monitoramento de latência de queries.
Detecção de hot shards.
Análise de recursos consumidos.
Alertas automáticos.
Dashboards pré-construídos.
Monitoramento é fundamental.
Oferece visibilidade operacional.""",
]

RAG_TEXTS = [
    """RAG significa Retrieval-Augmented Generation.
Combina busca de informação com geração de texto.
Permite que modelos de IA acessem conhecimento externo.
RAG melhora qualidade de respostas geradas.
Reduz alucinações em modelos de linguagem.
Oferece respostas mais precisas e contextualizadas.
RAG é fundamental para sistemas de IA confiáveis.
Utiliza base de conhecimento para augmentação.
Permite atualização de conhecimento sem retreinar modelo.
RAG combina vantagens de busca e geração.
Oferece escalabilidade para grandes volumes.
Permite customização de respostas.
RAG é usado em chatbots inteligentes.
Oferece explainabilidade de respostas.
Permite citação de fontes nas respostas.
RAG melhora confiança em sistemas de IA.
Oferece abordagem prática para IA generativa.""",

    """Arquitetura de RAG tem componentes principais.
Retriever busca documentos relevantes.
Generator gera respostas baseadas em documentos.
Ranker ordena documentos por relevância.
Query processor prepara perguntas.
Knowledge base armazena informações.
Cache para otimização de performance.
Feedback loop para melhoria contínua.
Componentes trabalham em conjunto.
Permite customização de cada etapa.
Oferece modularidade e flexibilidade.
Arquitetura deve ser escalável.
Permite integração com diferentes modelos.
Oferece configurabilidade.
Componentes podem ser trocados.
Arquitetura é foundation do RAG.
Oferece separação de responsabilidades.""",

    """Retrieval em RAG é etapa crítica.
Busca documentos relevantes à pergunta.
Usa índice de busca como OpenSearch.
Oferece múltiplas estratégias de retrieval.
BM25 para busca léxica.
Vector search para busca semântica.
Hybrid search combinando ambas.
Retrieval deve ser rápido.
Relevância é crucial para qualidade.
Oferece ranking inicial de documentos.
Permite filtragem de resultados.
Suporta busca em múltiplos índices.
Oferece caching de resultados populares.
Permite feedback do usuário.
Retrieval é optimizado para latência.
Oferece recall alto.
Retrieval é bottleneck comum.""",

    """Generation em RAG gera respostas.
Usa modelos de linguagem grandes.
Recebe documentos do retriever.
Gera texto baseado em contexto.
LLM gera resposta fluida e natural.
Permite controle de comprimento de resposta.
Oferece ajuste de temperatura para criatividade.
Permite customização de prompts.
Generation combina múltiplas fontes.
Oferece respostas contextualmente relevantes.
Permite citação de fontes usadas.
Generation é rápida em GPUs.
Oferece qualidade de resposta alta.
Permite múltiplos idiomas.
Generation depende de qualidade de retrieval.
Oferece flexibilidade de modelos.
Generation é onde IA brilha.""",

    """Integração com OpenSearch para RAG.
Vector search para embeddings.
Busca semântica de documentos.
Armazenamento eficiente de textos.
Indexação rápida de novos documentos.
Busca aproximada com k-NN.
Combinação com busca léxica.
Agregações para análise de resultados.
Métricas para monitoramento.
Escalabilidade para milhões de documentos.
Latência baixa para queries em tempo real.
Suporte para multilingue.
Ingestão de dados com pipelines.
Preprocessing automático de textos.
Tokenização e análise de texto.
OpenSearch é backend perfeito.
Oferece performance e confiabilidade.""",

    """Embeddings são fundamentais em RAG.
Representam texto como vetores.
Capturam significado semântico.
Modelos como BERT geram embeddings.
OpenAI embeddings oferecem alta qualidade.
Modelos open-source disponíveis.
Dimensionalidade típica entre 768 e 1536.
Similaridade de cosseno mede relevância.
Embeddings são pré-computados.
Armazenados em índices vetoriais.
Permitem busca semântica rápida.
Múltiplos modelos oferecem diferentes abordagens.
Embeddings multilíngues disponíveis.
Domain-specific embeddings melhoram performance.
Fine-tuning de embeddings possível.
Embeddings são coração de RAG semântico.
Oferecem compreensão profunda de texto.""",

    """Datasets para RAG devem ser qualidade.
Textos bem estruturados melhoram resultados.
Documentos devem cobrir domínio.
Relevância é crucial.
Dados devem ser atualizados.
Sem informações desatualizadas.
Textos devem ser claros.
Evitar redundância excessiva.
Metadata ajuda filtragem.
Versionamento de documentos.
Rastreabilidade de fontes.
Limpeza de dados importante.
Remover duplicatas.
Normalizar formatação.
Dividir textos longos.
Datasets são foundation de qualidade.
Investimento em dados compensa.""",

    """Avaliação de RAG é importante.
Métricas de retrieval: precision, recall.
Métricas de geração: BLEU, ROUGE.
Human evaluation para qualidade.
Relevância de documentos recuperados.
Corretude de respostas geradas.
Comparação com baselines.
A/B testing de configurações.
Análise de falhas.
User feedback loops.
Métricas de latência.
Custo de operação.
Escalabilidade medida.
Robustez contra queries adversariais.
Consistência de respostas.
Avaliação contínua necessária.
Oferece insights para melhoria.""",

    """Desafios em RAG incluem vários.
Hallucination mesmo com retrieval.
Contexto muito longo pode confundir.
Conflito entre múltiplos documentos.
Relevância não garante qualidade.
Latência deve ser minimizada.
Custos de modelos grandes.
Escalabilidade para dados massivos.
Manutenção de índices.
Desempenho em domínios especializados.
Multilingualidade complexa.
Gerenciamento de conhecimento versionado.
Atualização de conhecimento em tempo real.
Privacidade de dados sensíveis.
Integração com sistemas legados.
Desafios motivam pesquisa.
Soluções emergem continuamente.""",

    """Futuro de RAG é promissor.
Modelos cada vez mais poderosos.
Busca cada vez mais precisa.
Latência cada vez menor.
Custos reduzindo.
Novos paradigmas emergindo.
Multi-modal RAG com imagens.
Retrieval adaptativo inteligente.
Reasoning multi-hop avançado.
Integração com memory systems.
Personalização per usuário.
Chains of thought RAG.
Continual learning em RAG.
RAG federado em múltiplas sources.
Segurança e privacidade melhorada.
RAG abre possibilidades infinitas.
Futuro é muito interessante.""",
]

def create_bulk_dataset():
    """Cria dataset em formato Bulk API do OpenSearch."""

    # Distribuir textos entre temas
    all_texts = [
        ("opensearch", text) for text in OPENSEARCH_TEXTS
    ] + [
        ("elasticsearch", text) for text in ELASTICSEARCH_TEXTS
    ] + [
        ("rag", text) for text in RAG_TEXTS
    ]

    # Embaralhar para variação
    random.shuffle(all_texts)

    # Gerar formato NDJSON para Bulk API
    bulk_data = ""

    for idx, (tema, texto) in enumerate(all_texts, 1):
        # Metadata da ação (index)
        action_metadata = {
            "index": {
                "_index": "temas-ti",
                "_id": f"doc_{idx:03d}"
            }
        }

        # Documento com conteúdo
        documento = {
            "id": f"doc_{idx:03d}",
            "tema": tema,
            "conteudo": texto,
            "linhas": len(texto.split('\n')),
            "tamanho_bytes": len(texto.encode('utf-8')),
            "data_criacao": datetime.now().isoformat(),
            "timestamp": int(datetime.now().timestamp() * 1000),  # milliseconds
        }

        # Formato NDJSON (uma linha por linha)
        bulk_data += json.dumps(action_metadata, ensure_ascii=False) + "\n"
        bulk_data += json.dumps(documento, ensure_ascii=False) + "\n"

    return bulk_data, len(all_texts)


def save_dataset(filename, bulk_data):
    """Salva dataset em arquivo."""
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(bulk_data)
    print(f"✅ Dataset salvo em: {filename}")


def print_stats(bulk_data, total_docs):
    """Imprime estatísticas do dataset."""
    lines = bulk_data.strip().split('\n')

    print("\n📊 Estatísticas do Dataset:")
    print(f"   Total de documentos: {total_docs}")
    print(f"   Total de linhas (NDJSON): {len(lines)}")
    print(f"   Tamanho (bytes): {len(bulk_data.encode('utf-8'))}")
    print(f"   Tamanho (KB): {len(bulk_data.encode('utf-8')) / 1024:.2f}")
    print(f"   Índice: temas-ti")
    print(f"   Formato: Bulk API NDJSON")

    # Contar por tema
    opensearch_count = sum(1 for line in lines if '"tema":"opensearch"' in line)
    elasticsearch_count = sum(1 for line in lines if '"tema":"elasticsearch"' in line)
    rag_count = sum(1 for line in lines if '"tema":"rag"' in line)

    print(f"\n📚 Distribuição por Tema:")
    print(f"   OpenSearch: {opensearch_count // 2} textos ({opensearch_count // 2 / total_docs * 100:.1f}%)")
    print(f"   Elasticsearch: {elasticsearch_count // 2} textos ({elasticsearch_count // 2 / total_docs * 100:.1f}%)")
    print(f"   RAG: {rag_count // 2} textos ({rag_count // 2 / total_docs * 100:.1f}%)")


def print_sample(bulk_data):
    """Imprime amostra do dataset."""
    print("\n📝 Amostra do Dataset (primeiro documento):")
    print("-" * 60)

    lines = bulk_data.strip().split('\n')
    action_line = lines[0]
    doc_line = lines[1]

    print("Metadata da Ação:")
    print(action_line)
    print("\nDocumento:")
    doc = json.loads(doc_line)
    print(json.dumps(doc, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    print("\n" + "="*60)
    print("🚀 Gerador de Dataset para RAG/Vetorização")
    print("="*60 + "\n")

    print("🔨 Gerando dataset com 50 textos...")
    bulk_data, total_docs = create_bulk_dataset()

    # Salvar em arquivo
    filename = "dataset-temas-ti.ndjson"
    save_dataset(filename, bulk_data)

    # Imprimir estatísticas
    print_stats(bulk_data, total_docs)

    # Imprimir amostra
    print_sample(bulk_data)

    print("\n" + "="*60)
    print("✅ Dataset Gerado com Sucesso!")
    print("="*60)
    print("\n📌 Próximos Passos:")
    print(f"   1. Preparar OpenSearch:")
    print(f"      docker compose -f exemplos/docker-compose.single-node.yml up -d")
    print(f"   2. Enviar dataset via Bulk API:")
    print(f"      curl -k -u admin:Admin@123456 -X POST \\")
    print(f"        https://localhost:9200/_bulk \\")
    print(f"        -H 'Content-Type: application/x-ndjson' \\")
    print(f"        --data-binary @{filename}")
    print(f"   3. Verificar indexação:")
    print(f"      curl -k -u admin:Admin@123456 https://localhost:9200/temas-ti/_count")
    print()
