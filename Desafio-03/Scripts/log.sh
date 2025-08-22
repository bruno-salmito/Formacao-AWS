#!/bin/bash
#------------------------------------------------------------
# Script: log.sh
# Descrição: Funções de logging para os scripts
# Autor: Bruno Salmito
# Data: 18/08/2025
# Versão: 1.0
#------------------------------------------------------------   

# Definição de variáveis globais
LOG_FILE="/tmp/create_static_website.log"  # Caminho do arquivo de log
TIMESTAMP=$(date '+%d-%m-%Y %H:%M:%S')
USER=$(whoami)

# Função para logging
log_message() {
    echo "[${TIMESTAMP}] [${USER}] $1" >> "${LOG_FILE}"
}