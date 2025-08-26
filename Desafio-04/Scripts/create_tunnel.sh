#!/bin/bash
#-----------------------------------------------------
# Script: criar-tunel-refatorado.sh
# Descrição: Cria túneis SSH para instâncias EC2 e RDS
# Autor: Bruno Salmito
# Data: 25/08/2025
# Versão: 1.0
#-----------------------------------------------------

# Função para validar o dns do RDS (endpoint)
function validate_rds_endpoint() {
    local rds_name=$1
    local endpoint

    echo -n "Verificando endpoint do RDS '$rds_name'... " >&2

    # Verifica o endpoint do RDS
    endpoint=$(aws rds describe-db-instances \
        --db-instance-identifier "$rds_name" \
        --query "DBInstances[*].Endpoint.Address" \
        --output text 2>/dev/null)

    if [ -z "$endpoint" ]; then
        echo -e "${RED}[ERRO]${RESET}" >&2
        echo -e "${RED}Endpoint do RDS '$rds_name' não encontrado${RESET}" >&2
        log_message "Erro: Endpoint do RDS '$rds_name' não encontrado" >&2
        return 1
    else
        echo -e "${GREEN}[OK]${RESET}" >&2
        echo -e "${GREEN}Endpoint: $endpoint${RESET}" >&2
        log_message "Endpoint validado: $rds_name ($endpoint)" >&2
        # Retorna o endpoint do RDS
        echo "$endpoint"
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
    log_message "Nome da instância: $ec2_name"
    
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
    log_message "Porta local: $local_port"
    
    echo -n "Digite a porta remota (padrão: 80): "
    read -r remote_port
    remote_port=${remote_port:-80}
    log_message "Porta remota: $remote_port"
    
    echo -n "Digite o profile (padrão: formacao):"
    read -r profile
    profile=${profile:-formacao}
    log_message "Profile: $profile"

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
    log_message "Criando tunel usando o PORTEIRO $ec2_name"
    #log_message "Nome da instância: $ec2_name"

    # Valida a instância bastion
    bastion_id=$(validate_instance "$ec2_name")

    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERRO] Instância bastion '$ec2_name' não disponível${RESET}"
        log_message "Erro: Instância bastion '$ec2_name' não disponível"
        return 1
    fi
    
    # Solicita informações do RDS
    echo -n "Digite o endpoint do RDS: (padrão: endpoint do bia)"
    read -r rds_endpoint
    rds_endpoint=${rds_endpoint:-$ENDPOINT_RDS}
    log_message "Endpoint RDS: $rds_endpoint"
    



    #if [ -z "$rds_endpoint" ]; then
    #    echo -e "${RED}[ERRO] Endpoint do RDS não pode estar vazio${RESET}"
    #    return 1
    #fi
    
    echo -n "Digite a porta do RDS (padrão: 5432 para Postgres): "
    read -r rds_port
    rds_port=${rds_port:-5432}
    log_message "Porta RDS: $rds_port"
    
    echo -n "Digite a porta local (padrão: 5432): "
    read -r local_port
    local_port=${local_port:-5432}
    log_message "Porta local: $local_port" 
    
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



# Verifica dependências do AWS CLI
#if ! command -v aws &> /dev/null; then
#    echo -e "${RED}[ERRO] AWS CLI não encontrado. Instale o AWS CLI primeiro.${RESET}"
#    exit 1
#fi

# Verifica se o perfil AWS existe
if ! aws configure list-profiles | grep -q "^$PROFILE$"; then
    echo -e "${RED}[ERRO] Perfil AWS '$PROFILE' não encontrado.${RESET}"
    echo "Configure o perfil com: aws configure --profile $PROFILE"
    exit 1
fi

# Inicia o script
log_start
#log_message "=== Iniciando script de criação de túneis ==="
#main
