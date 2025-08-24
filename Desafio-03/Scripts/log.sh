#!/bin/bash
#------------------------------------------------------------
# Script: log.sh
# Descrição: Funções de logging para os scripts
# Autor: Bruno Salmito
# Data: 18/08/2025
# Versão: 1.0
#------------------------------------------------------------   

# Definição de variáveis globais
LOG_FILE="/tmp/deploy-app.log"  # Caminho do arquivo de log
TIMESTAMP=$(date '+%d-%m-%Y %H:%M:%S')
USER=$(whoami)

# Função para logging
log_message() {
    echo "[${TIMESTAMP}] [${USER}] $1" >> "${LOG_FILE}"
}


# Função que gera o inicio do log
log_start() {
    log_message "********************************************"
    # Registra no log o início da operação
    log_message "Iniciando o processo de build" 
    log_message "Usuário: $USER"
    log_message "Data: $TIMESTAMP"
    log_message "AWS Account: $AWS_ACCOUNT"
    log_message "AWS Region: $AWS_REGION"
    log_message "Bucket PATH: $BUCKET_PATH"
    log_message "Bucket Name: $BUCKET_NAME"
    log_message "Repository Name: $REPOSITORY_NAME"
    log_message "Repository URL: $REPOSITORY_URL"
    log_message "Image Name: $IMAGE_NAME"
    log_message "Image Tag: $IMAGE_TAG"    
    log_message "********************************************"
}


# função que gera o log de erro
log_error() {
    log_message "ERRO: $1"
    log_message "Processo de build finalizado com erros"
    log_message "********************************************"
}

# Função que gera o log da função
log_build() {
    log_message "$1"
}


# Função que gera o fim do log
log_end() {
    log_message "Processo de build finalizado"
    log_message "********************************************"
}