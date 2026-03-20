#!/usr/bin/env python3
"""
Gerador de Logs Apache em formato JSON para OpenSearch.

Simula logs de acesso Apache (Combined Format) com variações realistas:
- Taxa de sucessos (2xx): 80-90%
- Taxa de erros (4xx): 5-10% (400, 401, 403)
- Taxa de latência alta: 0-30% (configurável)
- 10 IPs distintos fixos (sempre os mesmos)
- URLs simuladas: login, busca, exploração
- Envia direto para OpenSearch em JSON via Bulk API

Uso:
    # Básico
    python apache_log_generator.py \
        --opensearch-url https://localhost:9200 \
        --opensearch-user admin \
        --opensearch-password Admin@123456 \
        --verify-cert false \
        --count 100 \
        --index apache-logs

    # Com latência alta (20% dos logs acima de 2000ms)
    python apache_log_generator.py \
        --opensearch-url https://localhost:9200 \
        --opensearch-user admin \
        --opensearch-password Admin@123456 \
        --latency-rate 20 \
        --latency-threshold 2000 \
        --count 500
"""

import argparse
import json
import random
import time
from datetime import datetime, timedelta
from typing import Dict, List, Tuple
import sys

try:
    from urllib3.exceptions import InsecureRequestWarning
    import urllib3
    urllib3.disable_warnings(InsecureRequestWarning)
except ImportError:
    pass

try:
    import requests
except ImportError:
    print("❌ Erro: requests não está instalado.")
    print("   Instale com: pip install requests")
    sys.exit(1)


class ApacheLogGenerator:
    """Gerador de logs Apache simulados com envio para OpenSearch."""

    # 10 IPs fixos para manter consistência
    FIXED_IPS = [
        "192.168.1.10",
        "10.0.0.15",
        "172.16.0.50",
        "203.45.67.89",
        "198.51.100.25",
        "192.0.2.100",
        "198.0.200.1",
        "205.244.80.1",
        "189.203.45.67",
        "187.120.90.40",
    ]

    # User agents realistas
    USER_AGENTS = [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
        "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15",
        "curl/7.68.0",
        "python-requests/2.28.0",
        "PostmanRuntime/7.28.0",
    ]

    # URLs simuladas com diferentes padrões
    URLS = {
        "login": ["/login", "/auth/login", "/user/signin", "/api/auth"],
        "search": ["/search", "/api/search", "/query", "/find"],
        "normal": ["/home", "/about", "/contact", "/page", "/api/data"],
        "exploit": [
            "/admin/shell.php",
            "/wp-admin/admin.php",
            "/../../../etc/passwd",
            "/api/v1/../../admin",
            "/shell.jsp",
            "/upload.asp",
        ],
    }

    def __init__(
        self,
        opensearch_url: str,
        opensearch_user: str,
        opensearch_password: str,
        verify_cert: bool = False,
        success_rate: int = 85,
        error_rate: int = 8,
        latency_rate: int = 10,
        latency_threshold: int = 1000,
        index_name: str = "apache-logs",
    ):
        """Inicializa o gerador.

        Args:
            opensearch_url: URL do OpenSearch (ex: https://localhost:9200)
            opensearch_user: Usuário para autenticação
            opensearch_password: Senha para autenticação
            verify_cert: Verificar certificado SSL (False para auto-assinado)
            success_rate: Taxa de sucesso 2xx (80-90)
            error_rate: Taxa de erro 4xx (5-10)
            latency_rate: Percentual de requisições com latência alta (0-30)
            latency_threshold: Latência mínima alta em ms (padrão: 1000)
            index_name: Nome do índice no OpenSearch
        """
        self.opensearch_url = opensearch_url.rstrip("/")
        self.opensearch_user = opensearch_user
        self.opensearch_password = opensearch_password
        self.verify_cert = verify_cert
        self.success_rate = max(80, min(90, success_rate))
        self.error_rate = max(5, min(10, error_rate))
        self.latency_rate = max(0, min(30, latency_rate))
        self.latency_threshold = max(100, latency_threshold)
        self.index_name = index_name

        # Validar rates
        total_rate = self.success_rate + self.error_rate
        if total_rate > 100:
            self.error_rate = 100 - self.success_rate
            print(f"⚠️  Ajustado: success_rate={self.success_rate}, error_rate={self.error_rate}")

        self.session = requests.Session()
        self.session.auth = (opensearch_user, opensearch_password)
        self.session.verify = verify_cert
        self.logs_generated = 0
        self.logs_sent = 0

    def generate_timestamp(self) -> str:
        """Gera timestamp Apache Combined (formato correto).

        Retorna: Exemplo: "20/Mar/2026:14:23:45 +0000"
        """
        now = datetime.now()
        # Formato Apache Combined: [DD/Mon/YYYY:HH:MM:SS +0000]
        return now.strftime("[%d/%b/%Y:%H:%M:%S +0000]")

    def generate_status_code(self) -> int:
        """Gera código HTTP baseado nas taxas configuradas."""
        rand = random.randint(1, 100)

        if rand <= self.success_rate:
            # Sucessos 2xx (200, 201, 204)
            return random.choice([200, 200, 200, 201, 204])
        elif rand <= self.success_rate + self.error_rate:
            # Erros 4xx (400, 401, 403)
            return random.choice([400, 401, 403])
        else:
            # Outros (redirecionamentos, server errors)
            return random.choice([301, 302, 304, 500, 503])

    def generate_request_size(self) -> int:
        """Gera tamanho aleatório da resposta em bytes."""
        return random.randint(100, 50000)

    def generate_response_time(self) -> int:
        """Gera tempo de resposta em ms baseado na taxa de latência."""
        rand = random.randint(1, 100)

        if rand <= self.latency_rate:
            # Latência alta (acima do threshold)
            return random.randint(self.latency_threshold, self.latency_threshold + 5000)
        else:
            # Latência normal
            return random.randint(10, min(self.latency_threshold - 1, 500))

    def select_url(self) -> Tuple[str, str]:
        """Seleciona uma URL baseada na probabilidade de tipo.

        Retorna: (url, tipo)
        """
        rand = random.random()

        if rand < 0.40:  # 40% pesquisas
            url_type = "search"
        elif rand < 0.60:  # 20% login
            url_type = "login"
        elif rand < 0.65:  # 5% tentativas de exploit
            url_type = "exploit"
        else:  # 35% normal
            url_type = "normal"

        url = random.choice(self.URLS[url_type])
        return url, url_type

    def generate_log_entry(self) -> Dict:
        """Gera uma entrada de log Apache Combined em JSON.

        Retorna: Dicionário com campos do log
        """
        ip = random.choice(self.FIXED_IPS)
        timestamp = self.generate_timestamp()
        url, url_type = self.select_url()
        method = random.choice(["GET", "GET", "GET", "POST", "PUT"])
        status = self.generate_status_code()
        size = self.generate_request_size()
        response_time = self.generate_response_time()
        user_agent = random.choice(self.USER_AGENTS)

        # Simular referrer
        referrer = random.choice([
            "-",
            "https://www.google.com/search?q=opensearch",
            "https://example.com/",
            "https://social.example.com/",
        ])

        # Construir log Apache Combined
        apache_log = (
            f'{ip} - - {timestamp} "{method} {url} HTTP/1.1" '
            f'{status} {size} "{referrer}" "{user_agent}"'
        )

        self.logs_generated += 1

        # Converter para JSON estruturado
        return {
            "timestamp": datetime.now().isoformat(),
            "remote_addr": ip,
            "remote_user": "-",
            "request_method": method,
            "request_path": url,
            "request_type": url_type,
            "http_version": "HTTP/1.1",
            "status": status,
            "bytes_sent": size,
            "response_time_ms": response_time,
            "referrer": referrer if referrer != "-" else None,
            "user_agent": user_agent,
            "apache_combined_log": apache_log,
            "is_error": status >= 400,
            "is_exploit_attempt": url_type == "exploit",
            "is_high_latency": response_time >= self.latency_threshold,
        }

    def send_to_opensearch(self, logs: List[Dict]) -> bool:
        """Envia logs para OpenSearch via Bulk API.

        Args:
            logs: Lista de dicionários de log

        Retorna:
            True se sucesso, False caso contrário
        """
        if not logs:
            return True

        bulk_body = ""
        for log in logs:
            # Metadata da ação
            action = {"index": {"_index": self.index_name, "_id": None}}
            bulk_body += json.dumps(action) + "\n"
            # Documento
            bulk_body += json.dumps(log) + "\n"

        try:
            url = f"{self.opensearch_url}/_bulk"
            response = self.session.post(
                url,
                data=bulk_body.encode("utf-8"),
                headers={"Content-Type": "application/x-ndjson"},
                timeout=10,
            )

            if response.status_code in [200, 201]:
                self.logs_sent += len(logs)
                return True
            else:
                print(
                    f"❌ Erro ao enviar (HTTP {response.status_code}): "
                    f"{response.text[:200]}"
                )
                return False

        except requests.exceptions.RequestException as e:
            print(f"❌ Erro de conexão com OpenSearch: {e}")
            return False

    def generate_and_send(
        self,
        count: int = 100,
        batch_size: int = 500,
        interval_seconds: float = 0,
    ):
        """Gera e envia logs para OpenSearch.

        Args:
            count: Número total de logs a gerar
            batch_size: Quantos logs enviar por vez
            interval_seconds: Intervalo entre gerações (0 = sem intervalo)
        """
        print(f"\n🚀 Iniciando geração de {count} logs para {self.opensearch_url}")
        print(f"   Índice: {self.index_name}")
        print(f"   Taxa sucesso: {self.success_rate}% | Taxa erro: {self.error_rate}%")
        print(f"   Taxa latência alta: {self.latency_rate}% (acima de {self.latency_threshold}ms)")
        print(f"   IPs fixos: {len(self.FIXED_IPS)} únicos")
        print()

        batch = []

        for i in range(1, count + 1):
            log = self.generate_log_entry()
            batch.append(log)

            # Enviar em lotes
            if len(batch) >= batch_size or i == count:
                print(f"📤 Enviando lote ({len(batch)} logs)...", end=" ")
                if self.send_to_opensearch(batch):
                    print("✅")
                else:
                    print("⚠️  Falha parcial")
                batch = []

            # Simular intervalo se configurado
            if interval_seconds > 0 and i < count:
                time.sleep(interval_seconds)

            # Progresso
            if i % (count // 10 or 1) == 0:
                print(f"   {i}/{count} logs gerados")

        print(f"\n✅ Concluído!")
        print(f"   Total gerado: {self.logs_generated}")
        print(f"   Total enviado: {self.logs_sent}")
        print(f"   Taxa de sucesso: {(self.logs_sent/self.logs_generated*100):.1f}%")


def main():
    """Função principal com argumentos de linha de comando."""
    parser = argparse.ArgumentParser(
        description="Gerador de Logs Apache em JSON para OpenSearch",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:

  # Gerar 100 logs e enviar para OpenSearch
  python apache_log_generator.py \\
    --opensearch-url https://localhost:9200 \\
    --opensearch-user admin \\
    --opensearch-password Admin@123456 \\
    --verify-cert false \\
    --count 100

  # Gerar 500 logs com taxa de erro customizada
  python apache_log_generator.py \\
    --opensearch-url https://localhost:9200 \\
    --opensearch-user admin \\
    --opensearch-password Admin@123456 \\
    --success-rate 88 \\
    --error-rate 7 \\
    --count 500

  # Gerar com 20% de requisições com latência alta (>2000ms)
  python apache_log_generator.py \\
    --opensearch-url https://localhost:9200 \\
    --opensearch-user admin \\
    --opensearch-password Admin@123456 \\
    --latency-rate 20 \\
    --latency-threshold 2000 \\
    --count 500

  # Gerar com intervalo de 0.5 segundos entre logs
  python apache_log_generator.py \\
    --opensearch-url https://localhost:9200 \\
    --opensearch-user admin \\
    --opensearch-password Admin@123456 \\
    --count 1000 \\
    --interval 0.5
        """,
    )

    # Parâmetros OpenSearch
    parser.add_argument(
        "--opensearch-url",
        default="https://localhost:9200",
        help="URL do OpenSearch (padrão: https://localhost:9200)",
    )
    parser.add_argument(
        "--opensearch-user",
        default="admin",
        help="Usuário OpenSearch (padrão: admin)",
    )
    parser.add_argument(
        "--opensearch-password",
        default="Admin@123456",
        help="Senha OpenSearch (padrão: Admin@123456)",
    )
    parser.add_argument(
        "--verify-cert",
        type=lambda x: x.lower() in ["true", "1", "yes"],
        default=False,
        help="Verificar certificado SSL (padrão: false)",
    )

    # Parâmetros de taxa e geração
    parser.add_argument(
        "--success-rate",
        type=int,
        default=85,
        help="Taxa de sucessos 2xx em %% (80-90, padrão: 85)",
    )
    parser.add_argument(
        "--error-rate",
        type=int,
        default=8,
        help="Taxa de erros 4xx em %% (5-10, padrão: 8)",
    )
    parser.add_argument(
        "--latency-rate",
        type=int,
        default=10,
        help="Percentual de requisições com latência alta em %% (0-30, padrão: 10)",
    )
    parser.add_argument(
        "--latency-threshold",
        type=int,
        default=1000,
        help="Limiar de latência alta em ms (padrão: 1000)",
    )
    parser.add_argument(
        "--count",
        type=int,
        default=100,
        help="Número de logs a gerar (padrão: 100)",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=0,
        help="Intervalo entre gerações em segundos (padrão: 0)",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=50,
        help="Tamanho do lote para envio (padrão: 50)",
    )
    parser.add_argument(
        "--index",
        default="apache-logs",
        help="Nome do índice OpenSearch (padrão: apache-logs)",
    )

    args = parser.parse_args()

    # Validar rates
    if not (80 <= args.success_rate <= 90):
        parser.error("success-rate deve estar entre 80 e 90")
    if not (5 <= args.error_rate <= 10):
        parser.error("error-rate deve estar entre 5 e 10")
    if not (0 <= args.latency_rate <= 30):
        parser.error("latency-rate deve estar entre 0 e 30")
    if args.success_rate + args.error_rate > 100:
        parser.error("success-rate + error-rate não pode exceder 100")

    # Criar e executar gerador
    generator = ApacheLogGenerator(
        opensearch_url=args.opensearch_url,
        opensearch_user=args.opensearch_user,
        opensearch_password=args.opensearch_password,
        verify_cert=args.verify_cert,
        success_rate=args.success_rate,
        error_rate=args.error_rate,
        latency_rate=args.latency_rate,
        latency_threshold=args.latency_threshold,
        index_name=args.index,
    )

    generator.generate_and_send(
        count=args.count,
        batch_size=args.batch_size,
        interval_seconds=args.interval,
    )


if __name__ == "__main__":
    main()
