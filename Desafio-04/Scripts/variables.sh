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
REGION="us-east-1"
DEFAULT_AZ="us-east-1a"

PROFILE="formacao"
AWS_ACCOUNT=$(aws sts get-caller-identity --profile formacao |grep -i userid |cut -d "|" -f3)

ENDPOINT_RDS="bia.ceta0448mm1j.us-east-1.rds.amazonaws.com"

AMI="ami-02f3f602d23f1659d"


