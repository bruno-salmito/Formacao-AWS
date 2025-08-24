#!/bin/bash
#------------------------------------------------------------
# Script: deploy.sh
# Descrição: Script principal para deploy da aplicação BIA
# Autor: Bruno Salmito
# Data: 22/08/2025
# Versão: 1.1
#------------------------------------------------------------   

# Inclusão do arquivo de arquivos base

printf "Verificando arquivos necessários..."

if [ ! -f "variables.sh" ]; then
    echo "[ERRO]"
    echo "      >Arquivo 'variables.sh' não encontrado!"
    exit 1
fi

if [ ! -f "log.sh" ]; then
    echo "[ERRO]"
    echo "      >Arquivo 'log.sh' não encontrado!"
    exit 1
fi

if [ ! -f "react.sh" ]; then
    echo "[ERRO]"
    echo "      >Arquivo 'react.sh' não encontrado!"
    exit 1
fi

if [ ! -f "s3.sh" ]; then
    echo "[ERRO]"
    echo "      >Arquivo 's3.sh' não encontrado!"
    exit 1
fi

source variables.sh
source log.sh
source react.sh
source s3.sh

echo -e "${GREEN}[OK]${RESET}"


# Gravando o log inicial
log_start

# Iniciando o processo de build do react
echo -e "${CYAN}iniciando o processo de build do React..."
echo -e "============================================================"
echo -e "${RESET}"
log_build "Iniciando o build do React...."

# Chamando a função de build do React
build_react ${ENDPOINT_URL}


# Iniciando o processo de sync com o S3
log_build "Iniciando a sincronização com o S3..."
echo -e "${CYAN}iniciando o processo de sync com o S3..."
echo -e "============================================================"
echo -e "${RESET}"
# Chamando a função de sync com o S3
sync_to_s3

# Incluir processo para o ecr e ecs


# Gravando o log final
log_end
