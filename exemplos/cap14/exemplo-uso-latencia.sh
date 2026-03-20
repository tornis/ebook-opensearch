#!/bin/bash
# Exemplo de uso do gerador de logs com parâmetro de latência

echo "🚀 Exemplos de Geração de Logs Apache com Latência"
echo "=================================================="
echo ""

echo "1️⃣  Gerar 100 logs com 10% de latência alta (padrão)"
echo "   Comando:"
echo "   python apache_log_generator.py \\"
echo "     --opensearch-url https://localhost:9200 \\"
echo "     --opensearch-user admin \\"
echo "     --opensearch-password Admin#123456 \\"
echo "     --verify-cert false \\"
echo "     --count 100"
echo ""
read -p "   Executar? (s/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
  python apache_log_generator.py \
    --opensearch-url https://localhost:9200 \
    --opensearch-user admin \
    --opensearch-password Admin#123456 \
    --verify-cert false \
    --count 100
fi
echo ""

echo "2️⃣  Gerar 500 logs com 20% de latência alta (>2000ms)"
echo "   Comando:"
echo "   python apache_log_generator.py \\"
echo "     --opensearch-url https://localhost:9200 \\"
echo "     --opensearch-user admin \\"
echo "     --opensearch-password Admin#123456 \\"
echo "     --latency-rate 20 \\"
echo "     --latency-threshold 2000 \\"
echo "     --count 500"
echo ""
read -p "   Executar? (s/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
  python apache_log_generator.py \
    --opensearch-url https://localhost:9200 \
    --opensearch-user admin \
    --opensearch-password Admin#123456 \
    --latency-rate 20 \
    --latency-threshold 2000 \
    --count 500
fi
echo ""

echo "3️⃣  Gerar 200 logs com 30% de latência alta (>3000ms)"
echo "   Comando:"
echo "   python apache_log_generator.py \\"
echo "     --opensearch-url https://localhost:9200 \\"
echo "     --opensearch-user admin \\"
echo "     --opensearch-password Admin#123456 \\"
echo "     --latency-rate 30 \\"
echo "     --latency-threshold 3000 \\"
echo "     --count 200 \\"
echo "     --index apache-logs-latency"
echo ""
read -p "   Executar? (s/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
  python apache_log_generator.py \
    --opensearch-url https://localhost:9200 \
    --opensearch-user admin \
    --opensearch-password Admin#123456 \
    --latency-rate 30 \
    --latency-threshold 3000 \
    --count 200 \
    --index apache-logs-latency
fi
echo ""

echo "4️⃣  Gerar 1000 logs com taxa de erro e latência personalizadas"
echo "   Comando:"
echo "   python apache_log_generator.py \\"
echo "     --opensearch-url https://localhost:9200 \\"
echo "     --opensearch-user admin \\"
echo "     --opensearch-password Admin#123456 \\"
echo "     --success-rate 82 \\"
echo "     --error-rate 10 \\"
echo "     --latency-rate 15 \\"
echo "     --latency-threshold 1500 \\"
echo "     --count 1000"
echo ""
read -p "   Executar? (s/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
  python apache_log_generator.py \
    --opensearch-url https://localhost:9200 \
    --opensearch-user admin \
    --opensearch-password Admin#123456 \
    --success-rate 82 \
    --error-rate 10 \
    --latency-rate 15 \
    --latency-threshold 1500 \
    --count 1000
fi
echo ""

echo "✅ Exemplos concluídos!"
echo ""
echo "💡 Dica: Consulte README.md para mais exemplos e documentação"
