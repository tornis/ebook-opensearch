# Gerador de Logs Apache para OpenSearch

Script Python que simula logs de acesso Apache em formato JSON, pronto para serem indexados no OpenSearch.

## 📋 Características

✅ **Taxa de sucessos (2xx):** 80-90% (configurável)
✅ **Taxa de erros (4xx):** 5-10% (400, 401, 403 distribuídos)
✅ **10 IPs fixos:** Sempre os mesmos para simular usuários recorrentes
✅ **URLs realistas:** Login, busca, exploração de vulnerabilidades
✅ **Formato Apache Combined:** Compatível com parsers tradicionais
✅ **JSON estruturado:** Pronto para indexação no OpenSearch
✅ **Envio automático:** Via Bulk API do OpenSearch
✅ **Parâmetros flexíveis:** Customização total pelo CLI

## 🚀 Instalação

### Dependências

```bash
pip install requests
```

### Permissões

```bash
chmod +x apache_log_generator.py
```

## 💻 Uso

### Básico (padrão)

```bash
python apache_log_generator.py \
  --opensearch-url https://localhost:9200 \
  --opensearch-user admin \
  --opensearch-password Admin@123456 \
  --verify-cert false \
  --count 100
```

### Com taxa customizada

```bash
python apache_log_generator.py \
  --opensearch-url https://localhost:9200 \
  --opensearch-user admin \
  --opensearch-password Admin@123456 \
  --success-rate 88 \
  --error-rate 7 \
  --count 500
```

### Com latência alta

```bash
# 20% dos logs com latência acima de 2000ms
python apache_log_generator.py \
  --opensearch-url https://localhost:9200 \
  --opensearch-user admin \
  --opensearch-password Admin@123456 \
  --latency-rate 20 \
  --latency-threshold 2000 \
  --count 500
```

### Com intervalo entre gerações

```bash
# Gerar 1000 logs com 0.5s de intervalo entre eles
python apache_log_generator.py \
  --opensearch-url https://localhost:9200 \
  --opensearch-user admin \
  --opensearch-password Admin@123456 \
  --count 1000 \
  --interval 0.5
```

### Customizar tamanho de lote

```bash
python apache_log_generator.py \
  --opensearch-url https://localhost:9200 \
  --opensearch-user admin \
  --opensearch-password Admin@123456 \
  --count 5000 \
  --batch-size 100
```

## 📊 Parâmetros

| Parâmetro | Padrão | Descrição |
|-----------|--------|-----------|
| `--opensearch-url` | `https://localhost:9200` | URL do OpenSearch |
| `--opensearch-user` | `admin` | Usuário para autenticação |
| `--opensearch-password` | `Admin@123456` | Senha para autenticação |
| `--verify-cert` | `false` | Verificar certificado SSL (true/false) |
| `--success-rate` | `85` | Taxa de sucessos 2xx em % (80-90) |
| `--error-rate` | `8` | Taxa de erros 4xx em % (5-10) |
| `--latency-rate` | `10` | Percentual de requisições com latência alta em % (0-30) |
| `--latency-threshold` | `1000` | Limiar de latência alta em ms |
| `--count` | `100` | Número de logs a gerar |
| `--interval` | `0` | Intervalo entre gerações em segundos |
| `--batch-size` | `50` | Tamanho do lote para envio em massa |
| `--index` | `apache-logs` | Nome do índice no OpenSearch |

## 📝 Exemplo de Log Gerado

```json
{
  "timestamp": "2026-03-20T14:23:45.123456",
  "remote_addr": "192.168.1.10",
  "remote_user": "-",
  "request_method": "GET",
  "request_path": "/search",
  "request_type": "search",
  "http_version": "HTTP/1.1",
  "status": 200,
  "bytes_sent": 4521,
  "response_time_ms": 234,
  "referrer": "https://www.google.com/search?q=opensearch",
  "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
  "apache_combined_log": "192.168.1.10 - - [20/Mar/2026:14:23:45 +0000] \"GET /search HTTP/1.1\" 200 4521 \"https://www.google.com/search?q=opensearch\" \"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36\"",
  "is_error": false,
  "is_exploit_attempt": false,
  "is_high_latency": false
}
```

### Exemplo com Latência Alta

```json
{
  "timestamp": "2026-03-20T14:25:12.456789",
  "remote_addr": "10.0.0.15",
  "remote_user": "-",
  "request_method": "POST",
  "request_path": "/api/search",
  "request_type": "search",
  "http_version": "HTTP/1.1",
  "status": 200,
  "bytes_sent": 8234,
  "response_time_ms": 2847,
  "referrer": "https://example.com/",
  "user_agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
  "apache_combined_log": "10.0.0.15 - - [20/Mar/2026:14:25:12 +0000] \"POST /api/search HTTP/1.1\" 200 8234 \"https://example.com/\" \"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36\"",
  "is_error": false,
  "is_exploit_attempt": false,
  "is_high_latency": true
}
```

## 📋 Campos do Log JSON

- `timestamp`: Data/hora atual ISO 8601
- `remote_addr`: IP (um dos 10 fixos)
- `request_method`: GET/POST/PUT
- `request_path`: URL da requisição
- `request_type`: login/search/exploit/normal
- `status`: HTTP status code
- `bytes_sent`: Tamanho da resposta
- `response_time_ms`: Tempo em ms
- `is_error`: Boolean se é erro (4xx/5xx)
- `is_exploit_attempt`: Boolean se é tentativa de exploit
- `is_high_latency`: Boolean se é latência alta (acima do threshold)
- `apache_combined_log`: Log no formato Apache Combined original

## 🔍 Distribuição de URLs

- **40%** Pesquisas: `/search`, `/api/search`, `/query`, `/find`
- **20%** Login: `/login`, `/auth/login`, `/user/signin`, `/api/auth`
- **5%** Tentativas de exploração: `/admin/shell.php`, `/../../../etc/passwd`, etc.
- **35%** Normal: `/home`, `/about`, `/contact`, `/page`, `/api/data`

## 🌐 IPs Fixos

O script usa sempre os mesmos 10 IPs:

```
192.168.1.10
10.0.0.15
172.16.0.50
203.45.67.89
198.51.100.25
192.0.2.100
198.0.200.1
205.244.80.1
189.203.45.67
187.120.90.40
```

## 🔐 Checagem do OpenSearch

Verificar se os logs foram indexados:

```bash
# Listar índices
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/_cat/indices?v

# Contar documentos
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/apache-logs/_count

# Visualizar um documento
curl -sk -u admin:Admin@123456 \
  https://localhost:9200/apache-logs/_search?size=1 | jq .
```

## 📌 Casos de Uso

### Gerar logs de ataque simulado

```bash
# Alta taxa de erro, tentativas de exploração
python apache_log_generator.py \
  --opensearch-url https://localhost:9200 \
  --opensearch-user admin \
  --opensearch-password Admin@123456 \
  --success-rate 80 \
  --error-rate 10 \
  --count 500 \
  --index apache-logs-attack
```

### Simular tráfego contínuo

```bash
# Gerar logs continuamente com intervalo
python apache_log_generator.py \
  --opensearch-url https://localhost:9200 \
  --opensearch-user admin \
  --opensearch-password Admin@123456 \
  --count 10000 \
  --interval 1.0 \
  --batch-size 100
```

### Teste de performance com problema de latência

```bash
# Simular degradação de performance (25% de requisições lenta)
python apache_log_generator.py \
  --opensearch-url https://localhost:9200 \
  --opensearch-user admin \
  --opensearch-password Admin@123456 \
  --latency-rate 25 \
  --latency-threshold 2500 \
  --count 1000 \
  --index apache-logs-slow
```

### Teste de performance máximo

```bash
# Enviar muitos logs rapidamente
python apache_log_generator.py \
  --opensearch-url https://localhost:9200 \
  --opensearch-user admin \
  --opensearch-password Admin@123456 \
  --count 50000 \
  --batch-size 500
```

## ⚠️ Notas Importantes

- Os timestamps são sempre a **data/hora atual** do sistema
- Certificados auto-assinados: use `--verify-cert false`
- O OpenSearch deve estar rodando e acessível
- O índice é criado automaticamente se não existir
- Para certificados válidos, use `--verify-cert true`
- A **latência alta** é definida pelos parâmetros `--latency-rate` e `--latency-threshold`:
  - `--latency-rate 10` = 10% dos logs terão latência alta
  - `--latency-threshold 1000` = latência alta é qualquer requisição >= 1000ms
  - Requisições com latência alta variam entre threshold e (threshold + 5000)ms

## 🐛 Troubleshooting

**Erro: "requests não está instalado"**
```bash
pip install requests
```

**Erro: "Connection refused"**
- Verificar se OpenSearch está rodando
- Verificar URL, porta e credenciais
- Verificar firewall

**Erro: "Unauthorized"**
- Verificar usuário e senha
- Verificar permissões no OpenSearch

**Certificado SSL inválido**
- Usar `--verify-cert false` para testes locais
- Ou instalar certificado válido no sistema
