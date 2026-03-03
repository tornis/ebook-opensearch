#!/bin/bash

###############################################################################
# Script: Descompactar e Preparar Logs Apache
# Descrição: Extrai o arquivo de logs Apache compactado e prepara o ambiente
# Uso: bash 01-descompactar-logs.sh
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHIVE_FILE="$SCRIPT_DIR/archive.zip"
LOGS_DIR="$SCRIPT_DIR/apache-logs"
PREPARED_LOGS="$SCRIPT_DIR/apache_logs_prepared.log"

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Preparação de Logs Apache para Ingestão ===${NC}\n"

# Verificar se o arquivo zip existe
if [ ! -f "$ARCHIVE_FILE" ]; then
    echo -e "${YELLOW}❌ Arquivo $ARCHIVE_FILE não encontrado${NC}"
    exit 1
fi

# Criar diretório para logs descompactados
mkdir -p "$LOGS_DIR"
cd "$LOGS_DIR"

# Descompactar arquivo
echo -e "${BLUE}📦 Descompactando arquivo...${NC}"
unzip -o "$ARCHIVE_FILE" > /dev/null 2>&1
echo -e "${GREEN}✅ Arquivo descompactado com sucesso${NC}\n"

# Contar linhas de log
TOTAL_LINES=$(wc -l < apache_logs.txt)
echo -e "${BLUE}📊 Informações dos Logs:${NC}"
echo "   Total de linhas: $TOTAL_LINES"

# Copiar para arquivo preparado no diretório pai
cp apache_logs.txt "$PREPARED_LOGS"

echo -e "\n${GREEN}✅ Logs descompactados e prontos em:${NC}"
echo "   $PREPARED_LOGS"
echo -e "\n${BLUE}📁 Arquivos gerados:${NC}"
ls -lh "$LOGS_DIR/" | grep -E "apache_logs"

echo -e "\n${GREEN}✅ Próximo passo: Execute o Fluent Bit${NC}"
echo "   Certifique-se de que OpenSearch está rodando em https://localhost:9200"
echo "   Credenciais: admin / <SENHA_ADMIN>"
