#!/bin/bash
#-----------------------------------------------------
# Script: criar-tunel-refatorado.sh
# Descrição: Cria túneis SSH para instâncias EC2 e RDS
# Autor: Bruno Salmito
# Data: 25/08/2025
# Versão: 1.0
#-----------------------------------------------------

# Inclusão dos arquivos base
if [ ! -f ./log.sh ]; then
    echo "[ERRO] - Arquivo log.sh não encontrado"
    exit 1
fi

if [ ! -f ./variables.sh ]; then
    echo "[ERRO] - Arquivo variables.sh não encontrado"
    exit 1
fi

source ./log.sh
source ./variables.sh

# Variáveis globais
#BASTION_INSTANCE="bia-dev"  # Instância porteiro para RDS

# Função para limpar a tela e mostrar cabeçalho
function show_header() {
    clear
    echo -e "${CYAN}"
    echo "=================================================="
    echo "           CRIADOR DE TÚNEIS AWS"
    echo "=================================================="
    echo -e "${RESET}"
}

# Função para mostrar o menu principal
function show_menu() {
    echo -e "${YELLOW}Escolha uma opção:${RESET}"
    echo ""
    echo "1) Criar túnel simples para instância EC2"
    echo "2) Criar túnel para RDS (via instância bia-dev)"
    echo "3) Sair"
    echo ""
    echo -n "Digite sua opção [1-3]: "
}

# Função para validar se a instância existe
function validate_instance() {
    local instance_name=$1
    local instance_id
    
    echo -n "Verificando instância '$instance_name'... " >&2
    
    # Verifica o id da instancia
    instance_id=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance_name" "Name=instance-state-name,Values=running" \
        --query "Reservations[*].Instances[*].InstanceId" \
        --output text 2>/dev/null)    
    
    if [ -z "$instance_id" ]; then
        echo -e "${RED}[ERRO]${RESET}" >&2
        echo -e "${RED}Instância '$instance_name' não encontrada ou não está em execução${RESET}" >&2
        log_message "Erro: Instância '$instance_name' não encontrada ou não está em execução" >&2
        return 1
    else
        echo -e "${GREEN}[OK]${RESET}" >&2
        echo -e "${GREEN}Instance ID: $instance_id${RESET}" >&2
        log_message "Instância validada: $instance_name ($instance_id)" >&2
        # Retorna o ID da Instancia EC2
        echo "$instance_id"
        return 0
    fi
}

# Função para criar túnel simples para EC2
function create_simple_tunnel() {
    local ec2_name
    local instance_id
    local local_port
    local remote_port
    
    echo -e "${CYAN}=== TÚNEL SIMPLES PARA EC2 ===${RESET}"
    echo ""
    
    # Solicita o nome da instância
    echo -n "Digite o nome da instância EC2 (padrão: ECS-bia-web): "
    read -r ec2_name
    ec2_name=${ec2_name:-ECS-bia-web}
    
    #if [ -z "$ec2_name" ]; then
    #    echo -e "${RED}[ERRO] Nome da instância não pode estar vazio${RESET}"
    #    return 1
    #fi
    
    # Valida a instância
    instance_id=$(validate_instance "$ec2_name")
    if [ $? -ne 0 ]; then
        return 1
    fi
  
    # Solicita as portas
    echo -n "Digite a porta local (padrão: 3001): "
    read -r local_port
    local_port=${local_port:-3001}
    
    echo -n "Digite a porta remota (padrão: 80): "
    read -r remote_port
    remote_port=${remote_port:-80}
    
    echo -n "Digite o profile (padrão: formacao):"
    read -r profile
    profile=${profile:-formacao}

    # Cria o túnel
    echo ""
    echo -e "${YELLOW}Criando túnel para $ec2_name...${RESET}"
    echo "Porta local: $local_port -> Porta remota: $remote_port"
    echo ""
    
    log_message "Iniciando túnel simples: $ec2_name ($instance_id) - Local:$local_port -> Remote:$remote_port"
    
    #aws ssm start-session \
    #    --profile "$PROFILE" \
    #    --region "$REGION" \
    #    --target "$instance_id" \
    #    --document-name AWS-StartPortForwardingSession \
    #    --parameters "{\"portNumber\":[\"$remote_port\"], \"localPortNumber\":[\"$local_port\"]}"
    
    aws ssm start-session \
        --profile "$profile" \
        --target "$instance_id" \
        --document-name AWS-StartPortForwardingSession \
        --parameters "{\"portNumber\":[\"$remote_port\"], \"localPortNumber\":[\"$local_port\"]}"

    if [ $? -eq 0 ]; then
        log_message "Túnel simples criado com sucesso"
    else
        echo -e "${RED}[ERRO] Falha ao criar túnel${RESET}"
        log_message "Erro ao criar túnel simples"
    fi
}


# Função para criar túnel para RDS
function create_rds_tunnel() {
    local rds_endpoint
    local rds_port
    local local_port
    local bastion_id
    
    echo -e "${CYAN}=== TÚNEL PARA RDS via Instancia EC2 ===${RESET}"
    echo ""
    
    echo -n "Digite o nome da instância EC2 (padrão: bia-dev): "
    read -r ec2_name
    ec2_name=${ec2_name:-bia-dev}

    # Valida a instância bastion
    bastion_id=$(validate_instance "$ec2_name")

    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERRO] Instância bastion '$ec2_name' não disponível${RESET}"
        return 1
    fi
    
    # Solicita informações do RDS
    echo -n "Digite o endpoint do RDS: (padrão: endpoint do bia)"
    read -r rds_endpoint
    rds_endpoint=${rds_endpoint:-$ENDPOINT_RDS}
    
    #if [ -z "$rds_endpoint" ]; then
    #    echo -e "${RED}[ERRO] Endpoint do RDS não pode estar vazio${RESET}"
    #    return 1
    #fi
    
    echo -n "Digite a porta do RDS (padrão: 3306 para MySQL): "
    read -r rds_port
    rds_port=${rds_port:-3306}
    
    echo -n "Digite a porta local (padrão: 3306): "
    read -r local_port
    local_port=${local_port:-3306}
    
    # Cria o túnel
    echo ""
    echo -e "${YELLOW}Criando túnel para RDS via $ec2_name...${RESET}"
    echo "RDS: $rds_endpoint:$rds_port"
    echo "Porta local: $local_port"
    echo ""
    
    log_message "Iniciando túnel RDS: $rds_endpoint:$rds_port via $ec2_name ($bastion_id) - Local:$local_port"
    
    aws ssm start-session \
        --target "$bastion_id" \
        --document-name AWS-StartPortForwardingSessionToRemoteHost \
        --parameters "{\"host\":[\"$rds_endpoint\"], \"portNumber\":[\"$rds_port\"], \"localPortNumber\":[\"$local_port\"]}"
    
    if [ $? -eq 0 ]; then
        log_message "Túnel RDS criado com sucesso"
    else
        echo -e "${RED}[ERRO] Falha ao criar túnel RDS${RESET}"
        log_message "Erro ao criar túnel RDS"
    fi
}

# Função principal
function main() {
    local option
    
    while true; do
        show_header
        show_menu
        read -r option
        
        case $option in
            1)
                echo ""
                create_simple_tunnel
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${RESET}"
                read -r
                ;;
            2)
                echo ""
                create_rds_tunnel
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${RESET}"
                read -r
                ;;
            3)
                echo ""
                echo -e "${GREEN}Saindo...${RESET}"
                log_message "Script finalizado pelo usuário"
                exit 0
                ;;
            *)
                echo ""
                echo -e "${RED}Opção inválida! Escolha entre 1-3.${RESET}"
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${RESET}"
                read -r
                ;;
        esac
    done
}

# Verifica dependências do AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}[ERRO] AWS CLI não encontrado. Instale o AWS CLI primeiro.${RESET}"
    exit 1
fi

# Verifica se o perfil AWS existe
if ! aws configure list-profiles | grep -q "^$PROFILE$"; then
    echo -e "${RED}[ERRO] Perfil AWS '$PROFILE' não encontrado.${RESET}"
    echo "Configure o perfil com: aws configure --profile $PROFILE"
    exit 1
fi

# Inicia o script
log_message "=== Iniciando script de criação de túneis ==="
main
