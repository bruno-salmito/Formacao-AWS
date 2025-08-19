#!/bin/bash
# --------------------------------------------------------------------------
# Script: create_environment/role.sh
# Descrição: Cria uma IAM role para acesso via SSM (AWS Systems Manager)
# Uso: ./role.sh [nome_da_role] (opcional, padrão: role-acesso-ssm) [policy_arn] (opcional, padrão: AmazonSSMManagedInstanceCore)
# Autor: Bruno Salmito
# Data: 2023-10-08
# Versão: 1.0
# --------------------------------------------------------------------------

# Inclusão dos arquivos base
if [ ! -f "variables.sh" ] && [ ! -f "log.sh" ]; then    
    echo  "[ERRO] Arquivo(s) base não encontrado(s)!"
    exit 1
else
    source variables.sh
    source log.sh
fi  

# Grava no log de inicio do script
log_message "********************************************************************"
log_message "[START] Iniciando o script de criação da IAM role"
log_message "USuario: $USER"
log_message "Data/Hora: $TIMESTAMP"
log_message "********************************************************************"

function add_role(){
    printf "Criando a role $1..."
    aws iam create-role --role-name "$1" --assume-role-policy-document "file://conf_files/ec2_principal.json"
    aws iam create-instance-profile --instance-profile-name "$1"
    aws iam add-role-to-instance-profile --instance-profile-name "$1" --role-name "$1"
    aws iam attach-role-policy --role-name $1 --policy-arn arn:aws:iam::aws:policy/"$2"
    echo -e "   ${GREEN}[OK]${RESET}"
    echo "      Criado a IAM role $1..."
    log_message "[OK] criado a IAM role $1..." 
}

function verify_role(){
    
    if [ -z "$1" ]; then
        ROLE_NAME="role-acesso-ssm"
        log_message "[INFO] Nenhum nome de role especificado, usando o padrão: $ROLE_NAME"
    else
        ROLE_NAME="$1"
        log_message "[INFO] Nome da role especificado: $ROLE_NAME"
    fi

    if [ -z "$2" ]; then
        POLICY_NAME="AmazonSSMManagedInstanceCore"
        log_message "[INFO] Nenhuma política especificada, usando o padrão: $POLICY_NAME"
    else
        POLICY_NAME="$2"
        log_message "[INFO] Política especificada: $POLICY_NAME"
    fi


    printf "Verificando existência da role $ROLE_NAME..."

    if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
        echo -e "   ${YELLOW}[WARNING]${RESET}"
        echo "      A IAM role $ROLE_NAME já existe. Nenhuma ação foi realizada."
        log_message "[WARNING] A IAM role $ROLE_NAME já existe. Nenhuma ação foi realizada."
        exit 1
    else
        echo -e "   ${GREEN}[OK]${RESET}"
        echo -e "   ${GREEN}Chamando a função para criar a role....${RESET}"
        log_message "[OK] Chamando a função para criar a role $ROLE_NAME com a política $POLICY_NAME"
        add_role $ROLE_NAME $POLICY_NAME
    fi
}
