#!/bin/bash

# ------------------------------------------------------------
# Script: create-s3-bucket.sh
# Descrição: Cria um bucket S3 na AWS com nome e região especificados.
# Uso: ./create-s3-bucket.sh <nome-do-bucket> [regiao]
# Requisitos: AWS CLI instalado e configurado com credenciais válidas.
# Autor: Bruno Salmito
# Data: 18/08/2025
# Versão: 1.0
# ------------------------------------------------------------

# Definição de corres
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# Variaveis de ambiente
USER=$(whoami)
LOG_FILE="/tmp/create-s3-bucket.log"
TIMESTAMP=$(date '+%d-%m-%Y %H:%M:%S')

# Função para gerar nome único do bucket
generate_unique_bucket_name() {
    local base_name="$1"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local random_suffix=$(openssl rand -hex 4)
    echo "${base_name}-${timestamp}-${random_suffix}"
}

# Função para logging
log_message() {
    echo "[${TIMESTAMP}] [${USER}] $1" >> "${LOG_FILE}"
}

# Função para exibir ajuda
show_help() {
    echo -e "${RED}----------------------------------------------------------"
    echo -e "${GREEN}Uso: $0 <nome-do-bucket> [regiao]"
    echo ""
    echo -e "${YELLOW}Parâmetros:"
    echo "  nome-do-bucket    Nome do bucket S3 (obrigatório)"
    echo "  regiao            Região AWS (opcional, padrão: us-east-1)"
    echo ""
    echo -e "${CYAN}Exemplos:"
    echo "  $0 meu-bucket-exemplo"
    echo "  $0 meu-bucket-exemplo us-west-2"
    echo "  $0 meu-bucket-exemplo sa-east-1"
    echo -e "${RED}----------------------------------------------------------"
    echo -e "${RESET}"
    log_message "Help menu displayed"
}

# Verificar se o nome do bucket foi fornecido
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    log_message "Script executed without parameters or with help flag"
    exit 1
fi

# Definir variáveis
BASE_BUCKET_NAME="$1"
REGION="${2:-us-east-1}"  # Usar us-east-1 como padrão se não especificado

# Gerar nome único para o bucket
BUCKET_NAME=$(generate_unique_bucket_name "$BASE_BUCKET_NAME")

log_message "Script started - Base name: ${BASE_BUCKET_NAME}, Final bucket: ${BUCKET_NAME}, Region: ${REGION}"

# Limpa a tela e exibe a mensagem de boas-vindas
clear
echo -e "${CYAN}"
echo "-------------------------------------------------"
echo "Olá $USER, Você está executando [$0] - $(date +%d/%m/%Y)"
echo "Criando Bucket S3"
echo "Nome do bucket: $BUCKET_NAME"
echo "Região: $REGION"
echo "-------------------------------------------------"
echo -e "${RESET}" 


# Validar nome do bucket base (básico)
if [[ ! "$BASE_BUCKET_NAME" =~ ^[a-z0-9][a-z0-9.-]*[a-z0-9]$ ]] || [ ${#BASE_BUCKET_NAME} -lt 3 ] || [ ${#BASE_BUCKET_NAME} -gt 40 ]; then
    log_message "ERROR: Invalid base bucket name: ${BASE_BUCKET_NAME}"
    echo -e "${RED}Erro: Nome base do bucket inválido."
    echo -e "${RESET}"
    echo "O nome base deve:"
    echo "- Ter entre 3 e 40 caracteres (será expandido automaticamente)"
    echo "- Conter apenas letras minúsculas, números, pontos e hífens"
    echo "- Começar e terminar com letra ou número"
    exit 1
fi

# Exibir mensagem de criação do bucket
echo "Criando bucket S3..."
echo "Nome base: $BASE_BUCKET_NAME"
echo "Nome final do bucket: $BUCKET_NAME"
echo "Região: $REGION"
echo ""
log_message "Attempting to create bucket ${BUCKET_NAME} in region ${REGION}"

# Verificar se AWS CLI está instalado
if ! command -v aws &> /dev/null; then
    log_message "ERROR: AWS CLI not installed"
    echo -e "${RED}Erro: AWS CLI não está instalado."
    echo -e "${RESET}"
    echo "Instale o AWS CLI antes de executar este script."
    exit 1
fi

# Verificar se as credenciais AWS estão configuradas
if ! aws sts get-caller-identity &> /dev/null; then
    log_message "ERROR: AWS credentials not configured"
    echo "${RED}Erro: Credenciais AWS não configuradas."
    echo -e "${RESET}"
    echo "Execute 'aws configure' para configurar suas credenciais."
    exit 1
fi

# Criar o bucket
if [ "$REGION" = "us-east-1" ]; then
    # Para us-east-1, não precisamos especificar LocationConstraint
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
    RESULT=$?
else
    # Para outras regiões, precisamos especificar LocationConstraint
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
    RESULT=$?
fi

# Verificar se o bucket foi criado com sucesso
if [ $RESULT -eq 0 ]; then
    log_message "SUCCESS: Bucket ${BUCKET_NAME} created successfully in region ${REGION}"
    echo ""
    echo -e "${GREEN}Bucket '$BUCKET_NAME' criado com sucesso na região '$REGION'!"
    echo ""
    echo -e "${RESET}"
    echo "Você pode verificar o bucket com:"
    echo "  aws s3 ls s3://$BUCKET_NAME"
else
    log_message "ERROR: Failed to create bucket ${BUCKET_NAME} in region ${REGION}"
    echo ""
    echo -e "${RED}Erro ao criar o bucket. Verifique:"
    echo -e "${RESET}"
    echo "- Se o nome do bucket já existe (nomes são únicos globalmente)"
    echo "- Se você tem permissões adequadas"
    echo "- Se a região especificada é válida"
    exit 1
fi
