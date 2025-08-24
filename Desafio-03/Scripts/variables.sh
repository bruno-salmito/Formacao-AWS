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


BUILD_PATH="bia/client/build"
APP_PATH="bia"
BUCKET_PATH="s3://app-bia"
BUCKET_NAME="app-bia"
ENDPOINT_URL="http://3.238.57.11"
PROFILE="formacao"
AWS_ACCOUNT=$(aws sts get-caller-identity --profile formacao |grep -i userid |cut -d "|" -f3)

ECR_REGISTRY="874287870279.dkr.ecr.us-east-1.amazonaws.com"
IMAGE_NAME="prd/bia"
IMAGE_TAG="rds1"
ECR_PATH="prd/bia"
ECR_URL="${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
CLUSTER_NAME="bia-web"
SERVICE_NAME="task-def-bia"
TASK_FAMILY="bia-task"
