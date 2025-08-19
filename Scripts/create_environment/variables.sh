# ------------------------------------------------------------
# Arquivo: variables.sh
# Descrição: Variáveis globais para uso nos scripts
# Autor: Bruno Salmito
# Data: 18/08/2025
# Versão: 1.0
# ------------------------------------------------------------

# Definição de cores
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# Variáveis globais
USER=$(whoami)
LOG_FILE="/tmp/build-app.log"
TIMESTAMP=$(date '+%d-%m-%Y %H:%M:%S')
BUILD_PATH="bia/client/build"
BUCKET_PATH="s3://formacao-bia"
PROFILE="formacao"
AWS_ACCOUNT=$(aws sts get-caller-identity --profile formacao |grep -i userid |cut -d "|" -f3)
