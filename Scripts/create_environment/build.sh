#!/bin/bash
# --------------------------------------------------------------------------
# Script: create_environment/build.sh
# Descrição: Cria meu ambiente de estudos na AWS
# Uso: ./build.sh
# Autor: Bruno Salmito
# Data: 18-08-2025
# Versão: 1.2
# --------------------------------------------------------------------------

# Verificar se os arquivos necessários existem
if [ ! -f "variables.sh" ]; then
    echo ">[ERRO] Arquivo variables.sh não encontrado"
    exit 1
fi

if [ ! -f "log.sh" ]; then
    echo ">[ERRO] Arquivo log.sh não encontrado"
    exit 1
fi

if [ ! -f "role.sh" ]; then
    echo ">[ERRO] Arquivo role.sh não encontrado"
    exit 1
fi

if [ ! -f "launch_ec2.sh" ]; then
    echo ">[ERRO] Arquivo launch_ec2.sh não encontrado"
    exit 1
fi

source variables.sh
source log.sh
source role.sh
source launch_ec2.sh

# Variáveis globais de configuração
AMI_ID=""
REGION="us-east-1"
EC2_NAME="bia-dev"
IAM_ROLE="role-acesso-ssm"
SECURITY_GROUP="bia-dev"
INSTANCE_TYPE="t3.micro"
AVAILABILITY_ZONE="us-east-1a"
VOLUME_SIZE="15"

# Função para exibir menu principal
show_menu() {
    echo ""
    echo "=== MENU PRINCIPAL ==="
    echo "1) Selecionar Distribuição Linux"
    echo "2) Informar valores de configuração"
    echo "3) Criar IAM Role"
    echo "4) Criar Security Group"
    echo "5) Criar Ambiente Completo"
    echo "6) Mostrar Configurações Atuais"
    echo "7) Sair"
    echo ""
}

# Função para mostrar configurações atuais
show_current_config() {
    echo ""
    echo "=== CONFIGURAÇÕES ATUAIS ==="
    echo "Região: $REGION"
    echo "Nome da Instância: $EC2_NAME"
    echo "Tipo da Instância: $INSTANCE_TYPE"
    echo "AMI ID: ${AMI_ID:-'Não selecionada'}"
    echo "Security Group: $SECURITY_GROUP"
    echo "IAM Role: $IAM_ROLE"
    echo "Zona de Disponibilidade: $AVAILABILITY_ZONE"
    echo "Tamanho do Volume: ${VOLUME_SIZE}GB"
    echo ""
}

show_dist() {
    echo ""
    echo "=== Seleção da Distribuição Linux ==="
    echo "1) Ubuntu (ami-0e86e20dae9224db8)"
    echo "2) Amazon Linux 2023 (ami-02f3f602d23f1659d)"
    echo "3) Voltar ao menu principal"
    echo ""
}

read_menu_option() {
    read -p "Digite sua opção: " option
    case $option in
        1) show_dist
           read_dist_option
           ;;
        2) read_config_values
           ;;
        3) create_iam_role_menu
           ;;
        4) create_security_group_menu
           ;;
        5) create_complete_environment
           ;;
        6) show_current_config
           show_menu
           read_menu_option
           ;;
        7) echo "Saindo..."
           exit 0
           ;;
        *) echo "Opção inválida"
           show_menu
           read_menu_option
           ;;
    esac
}

read_dist_option() {
    read -p "Digite sua opção: " dist_option
    case $dist_option in
        1) AMI_ID="ami-0e86e20dae9224db8"
           echo "Ubuntu selecionado: $AMI_ID"
           ;;
        2) AMI_ID="ami-02f3f602d23f1659d"
           echo "Amazon Linux 2023 selecionado: $AMI_ID"
           ;;
        3) show_menu
           read_menu_option
           return
           ;;
        *) echo "Opção inválida"
           show_dist
           read_dist_option
           return
           ;;
    esac
    
    show_menu
    read_menu_option
}

read_config_values() {
    echo ""
    echo "=== Configuração de Valores ==="
    
    read -p "Digite a região (atual: $REGION): " REGION_INPUT
    if [ -n "$REGION_INPUT" ]; then
        REGION="$REGION_INPUT"
    fi
    
    read -p "Digite o nome da instância (atual: $EC2_NAME): " EC2_NAME_INPUT
    if [ -n "$EC2_NAME_INPUT" ]; then
        EC2_NAME="$EC2_NAME_INPUT"
    fi
    
    read -p "Digite o tipo da instância (atual: $INSTANCE_TYPE): " INSTANCE_TYPE_INPUT
    if [ -n "$INSTANCE_TYPE_INPUT" ]; then
        INSTANCE_TYPE="$INSTANCE_TYPE_INPUT"
    fi
    
    read -p "Digite o nome da IAM Role (atual: $IAM_ROLE): " IAM_ROLE_INPUT
    if [ -n "$IAM_ROLE_INPUT" ]; then
        IAM_ROLE="$IAM_ROLE_INPUT"
    fi
    
    read -p "Digite o nome do Security Group (atual: $SECURITY_GROUP): " SECURITY_GROUP_INPUT
    if [ -n "$SECURITY_GROUP_INPUT" ]; then
        SECURITY_GROUP="$SECURITY_GROUP_INPUT"
    fi
    
    read -p "Digite a zona de disponibilidade (atual: $AVAILABILITY_ZONE): " AZ_INPUT
    if [ -n "$AZ_INPUT" ]; then
        AVAILABILITY_ZONE="$AZ_INPUT"
    fi
    
    read -p "Digite o tamanho do volume em GB (atual: $VOLUME_SIZE): " VOLUME_INPUT
    if [ -n "$VOLUME_INPUT" ]; then
        VOLUME_SIZE="$VOLUME_INPUT"
    fi
    
    echo ""
    echo "Configurações atualizadas com sucesso!"
    show_current_config
    
    show_menu
    read_menu_option
}

create_iam_role_menu() {
    echo ""
    echo "=== Criação de IAM Role ==="
    echo "Criando IAM Role: $IAM_ROLE"
    
    # Chamar função do role.sh se existir
    if declare -f create_iam_role > /dev/null; then
        verify_role "$IAM_ROLE"
    else
        echo "Função create_iam_role não encontrada no role.sh"
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
    show_menu
    read_menu_option
}

create_security_group_menu() {
    echo ""
    echo "=== Criação de Security Group ==="
    echo "Criando Security Group: $SECURITY_GROUP"
    
    # Chamar função do role.sh se existir
    if declare -f create_security_group > /dev/null; then
        create_security_group "$SECURITY_GROUP"
    else
        echo "Função create_security_group não encontrada"
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
    show_menu
    read_menu_option
}

create_complete_environment() {
    echo ""
    echo "=== Criação do Ambiente Completo ==="
    
    # Verificar se AMI foi selecionada
    if [ -z "$AMI_ID" ]; then
        echo -e "${RED}>[ERRO] Você deve selecionar uma distribuição Linux primeiro (opção 1)${RESET}"
        echo ""
        read -p "Pressione Enter para continuar..."
        show_menu
        read_menu_option
        return
    fi
    
    # Mostrar configurações que serão usadas
    echo "Será criado um ambiente com as seguintes configurações:"
    show_current_config
    
    read -p "Deseja continuar? (s/N): " confirm
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        echo "Operação cancelada"
        show_menu
        read_menu_option
        return
    fi
    
    echo ""
    echo "Iniciando criação do ambiente..."
    
    # Chamar função do launch_ec2.sh
    if create_environment "$EC2_NAME" "$AMI_ID" "$INSTANCE_TYPE" "$SECURITY_GROUP" "$AVAILABILITY_ZONE" "$VOLUME_SIZE" "$IAM_ROLE"; then
        echo ""
        echo "=== Ambiente criado com sucesso! ==="
    else
        echo ""
        echo ">[ERRO] Falha na criação do ambiente"
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
    show_menu
    read_menu_option
}

# Função principal
main() {
    echo "=== Script de Criação de Ambiente AWS ==="
    echo "Versão: 2.0"
    echo ""
    
    show_menu
    read_menu_option
}

# Verificar se o usuário passou os parâmetros corretos
# verify_role "role-acesso-ssm" "AmazonSSMManagedInstanceCore"

# Executar função principal
main