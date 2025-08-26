#!/bin/bash
#-----------------------------------------------------
# Script: create-tunel.sh
# Descrição: Cria um tunel para uma instância EC2
# Autor: Bruno Salmito
# Data: 25/06/2025
# Versão: 0.8
#-----------------------------------------------------

# Inclusão dos arquivos base
if [ ! -f ./log.sh ]; then
    echo "[ERRO] - Arquivo base.sh não encontrado"
    exit 1
fi

if [ ! -f ./variables.sh ]; then
    echo "[ERRO] - Arquivo variables.sh não encontrado"
    exit 1
fi

source ./log.sh
source ./variables.sh

# Variáveis globais
EC2_NAME=$1

# Limpa a tela
clear

# Verifica se foi passado o nome da Instância EC2
printf "Iniciando verificação...."

if [ -z "$EC2_NAME" ]; then
    echo -e "${RED}[ERRO]${RESET}"
    echo -e "${RED}[ERRO] - Você precisa informar o nome de uma instância EC2${RESET}"
    log_message "Erro: Nome da Instância EC2 não informado"
    exit 1
else
    INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$EC2_NAME" --query "Reservations[*].Instances[*].InstanceId" --output text)
    echo -e "${GREEN}[OK]${RESET}"
    echo -e "${GREEN}Instance ID:$INSTANCE_ID${RESET}"
    log_message "Nome da Instância EC2: $EC2_NAME"
    log_message "Instance ID: $INSTANCE_ID"
fi

# Verifica se a instância existe
if [ -z "$INSTANCE_ID" ]; then
    echo -e "${RED}[ERRO] - Instância EC2 não encontrada${RESET}"
    log_message "Erro: Instância EC2 não encontrada"
    exit 1
fi

# Função para criar o PortForwarding Tunel

function create_tunel() {
# Criando um portwarding tunel
    AWS_TUNEL=(aws ssm start-session --target "$INSTANCE_ID" \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["80"], "localPortNumber":["3001"]}')

    if "${AWS_TUNEL[@]}"; then
        echo -e "${GREEN}[OK]${RESET}"
        echo "      >Tunel criado com sucesso"
        log_message "Tunel criado com sucesso"
    else
        echo -e "${RED}[ERRO]${RESET}"
        echo -e "       >Erro ao criar tunel${RESET}"
        exit 1
    fi

}

# Função de inicio do script
function start {
    echo -e "${CYAN}Iniciando o script de criação de tunel"
    echo "---------------------------------------"
    echo "Nome da Instância: $EC2_NAME"
    echo "ID da Instância: $INSTANCE_ID"
    echo "---------------------------------------"
    echo -e "${RESET}"
    echo -e "${YELLOW}Criando tunel com a Instância $EC2_NAME:$INSTANCE_ID.....${RESET}"
    log_message "----------------------------------------------------"
    log_message "Criando tunel com a Instância $EC2_NAME:$INSTANCE_ID....."
    create_tunel
}

# Inicia o script
start








