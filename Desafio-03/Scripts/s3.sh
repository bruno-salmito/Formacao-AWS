#!/bin/bash
# ------------------------------------------------------------
# Script: s3.sh
# Descrição: Funções para sincronização com Amazon S3
# Autor: Bruno Salmito
# Data: 18/08/2025
# Versão: 1.0
# ------------------------------------------------------------

function sync_to_s3 {
    #cd bia
    printf "Iniciando sincronização com S3..."
    if [ ! -d "$BUILD_PATH" ]; then
        echo -e "${RED}[ERRO]${RESET} Pasta build não encontrada em: $BUILD_PATH"
        echo -e "${YELLOW}Execute o build primeiro antes de sincronizar${RESET}"
        log_message "[ERRO] - Pasta build não encontrada em: $BUILD_PATH"
        exit 1
    fi

    if ! aws s3 sync "$BUILD_PATH" "$BUCKET_PATH" --profile "$PROFILE"; then
        echo -e "${RED}[ERRO]${RESET} Falha ao sincronizar com S3!"
        log_message "[ERRO] - Falha ao sincronizar com S3"
        exit 1
    else
        echo -e "${GREEN}[OK]${RESET} Sincronização concluída com sucesso!"
        log_message "[Success] - Sincronização concluída com sucesso para o bucket: $BUCKET_PATH"
        log_message "-------------------------------------"
    fi
    sleep 2
    #aws s3 sync bia/client/build/ s3://formacao-bia --profile formacao

}

