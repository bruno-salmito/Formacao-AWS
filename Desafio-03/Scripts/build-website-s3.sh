#!/bin/bash
#------------------------------------------------------------
# Script: build-website-s3.sh
# Descrição: Script para construir e sincronizar o site com o S3
# Autor: Bruno Salmito
# Data: 22/08/2025
# Versão: 1.2
#------------------------------------------------------------

# Inclusão do arquivo de arquivos base
printf "Verificando arquivos necessários..."

if [ ! -f "variables.sh" ]; then
    echo "[ERRO]"
    echo "[ERRO] Arquivo 'variables.sh' não encontrado!"
    exit 1
fi

if [ ! -f "log.sh" ]; then
    echo "[ERRO]"
    echo "[ERRO] Arquivo 'log.sh' não encontrado!"
    exit 1
fi

if [ ! -f "s3.sh" ]; then
    echo "[ERRO]"
    echo "[ERRO] Arquivo 's3.sh' não encontrado!"
    exit 1
fi

if [ ! -f "react.sh" ]; then
    echo "[ERRO]"
    echo "[ERRO] Arquivo 'react.sh' não encontrado!"
    exit 1
fi
echo "[OK]"

source variables.sh
source log.sh
source s3.sh
source react.sh

# Registra no log o início da operação
log_message "Iniciando o processo de build e sincronização com S3" 
log_message "Usuário: $USER"
log_message "Data: $TIMESTAMP"
log_message "AWS Account: $AWS_ACCOUNT"
log_message "Bucket PATH: $BUCKET_PATH"
log_message "Bucket Name: $BUCKET_NAME"
log_message "**********************************"

# Chama a função de build do React
echo -e "${CYAN}iniciando o processo de build..."
echo -e "============================================================"
echo -e "${RESET}"
build_react ${ENDPOINT_URL}

# Chama a função de sincronização com o S3
# Chama a função de build do React
echo -e "${CYAN}iniciando o processo de sync com o S3..."
echo -e "============================================================"
echo -e "${RESET}"
sync_to_s3

# Incluir função para enviar pro ECR




# Incluir registro no log do fim da operação
log_message "Processo de build e sincronização com S3 finalizado"
log_message "**********************************"
echo -e "${GREEN}Processo finalizado com sucesso!${RESET}"
echo -e "${GREEN}Verifique o arquivo de log para mais detalhes: ${LOG_FILE}${RESET}"    