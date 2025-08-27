#!/bin/bash

# Função para criar instância EC2 com seleção interativa de VPC e subnet
create_ec2_instance() {
    echo "=== Criação de Instância EC2 ==="
    echo
    
    # Verificar se AWS CLI está configurado
    if ! aws sts get-caller-identity &>/dev/null; then
        echo "Erro: AWS CLI não está configurado. Execute 'aws configure' primeiro."
        return 1
    fi
    
    # Definir região (pode ser alterada conforme necessário)
    REGION=${AWS_DEFAULT_REGION:-us-east-1}
    echo "Região selecionada: $REGION"
    echo
    
    # 1. Listar VPCs disponíveis
    echo "📋 Listando VPCs disponíveis..."
    echo
    
    # Obter VPCs e formatá-las
    VPC_DATA=$(aws ec2 describe-vpcs \
        --region "$REGION" \
        --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0],IsDefault]' \
        --output text)
    
    if [ -z "$VPC_DATA" ]; then
        echo "Nenhuma VPC encontrada na região $REGION"
        return 1
    fi
    
    # Criar array para armazenar VPCs
    declare -a VPC_IDS
    declare -a VPC_INFO
    counter=1
    
    echo "VPCs disponíveis:"
    echo "=================="
    
    while IFS=$'\t' read -r vpc_id cidr_block name is_default; do
        # Se name estiver vazio, usar "Sem nome"
        if [ "$name" = "None" ] || [ -z "$name" ]; then
            name="Sem nome"
        fi
        
        # Marcar VPC padrão
        default_marker=""
        if [ "$is_default" = "True" ]; then
            default_marker=" (Padrão)"
        fi
        
        VPC_IDS[$counter]="$vpc_id"
        VPC_INFO[$counter]="$vpc_id - $cidr_block - $name$default_marker"
        
        echo "$counter) $vpc_id - $cidr_block - $name$default_marker"
        ((counter++))
    done <<< "$VPC_DATA"
    
    echo
    
    # Solicitar seleção da VPC
    while true; do
        read -p "Selecione o número da VPC (1-$((counter-1))): " vpc_choice
        
        if [[ "$vpc_choice" =~ ^[0-9]+$ ]] && [ "$vpc_choice" -ge 1 ] && [ "$vpc_choice" -lt "$counter" ]; then
            SELECTED_VPC="${VPC_IDS[$vpc_choice]}"
            echo "VPC selecionada: ${VPC_INFO[$vpc_choice]}"
            break
        else
            echo "Seleção inválida. Digite um número entre 1 e $((counter-1))."
        fi
    done
    
    echo
    
    # 2. Listar subnets da VPC selecionada
    echo "📋 Listando subnets da VPC $SELECTED_VPC..."
    echo
    
    SUBNET_DATA=$(aws ec2 describe-subnets \
        --region "$REGION" \
        --filters "Name=vpc-id,Values=$SELECTED_VPC" \
        --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0],MapPublicIpOnLaunch]' \
        --output text)
    
    if [ -z "$SUBNET_DATA" ]; then
        echo "Nenhuma subnet encontrada na VPC $SELECTED_VPC"
        return 1
    fi
    
    # Criar array para armazenar subnets
    declare -a SUBNET_IDS
    declare -a SUBNET_INFO
    counter=1
    
    echo "Subnets disponíveis:"
    echo "===================="
    
    while IFS=$'\t' read -r subnet_id cidr_block az name public_ip; do
        # Se name estiver vazio, usar "Sem nome"
        if [ "$name" = "None" ] || [ -z "$name" ]; then
            name="Sem nome"
        fi
        
        # Indicar se é pública ou privada
        subnet_type="Privada"
        if [ "$public_ip" = "True" ]; then
            subnet_type="Pública"
        fi
        
        SUBNET_IDS[$counter]="$subnet_id"
        SUBNET_INFO[$counter]="$subnet_id - $cidr_block - $az - $name ($subnet_type)"
        
        echo "$counter) $subnet_id - $cidr_block - $az - $name ($subnet_type)"
        ((counter++))
    done <<< "$SUBNET_DATA"
    
    echo
    
    # Solicitar seleção da subnet
    while true; do
        read -p "Selecione o número da subnet (1-$((counter-1))): " subnet_choice
        
        if [[ "$subnet_choice" =~ ^[0-9]+$ ]] && [ "$subnet_choice" -ge 1 ] && [ "$subnet_choice" -lt "$counter" ]; then
            SELECTED_SUBNET="${SUBNET_IDS[$subnet_choice]}"
            echo "Subnet selecionada: ${SUBNET_INFO[$subnet_choice]}"
            break
        else
            echo "Seleção inválida. Digite um número entre 1 e $((counter-1))."
        fi
    done
    
    echo
    
    # 3. Coletar informações adicionais para a instância
    echo "📝 Configurações da instância:"
    echo
    
    # Tipo de instância
    read -p "Tipo de instância (padrão: t2.micro): " INSTANCE_TYPE
    INSTANCE_TYPE=${INSTANCE_TYPE:-t2.micro}
    
    # AMI ID (Amazon Linux 2 por padrão)
    read -p "AMI ID (padrão: ami-0c02fb55956c7d316 - Amazon Linux 2): " AMI_ID
    AMI_ID=${AMI_ID:-ami-0c02fb55956c7d316}
    
    # Nome da instância
    read -p "Nome da instância: " INSTANCE_NAME
    
    # Key pair
    read -p "Nome do key pair (deixe vazio se não quiser usar): " KEY_PAIR
    
    # Security Group
    read -p "Security Group ID (deixe vazio para usar o padrão da VPC): " SECURITY_GROUP
    
    echo
    echo "🚀 Criando instância EC2..."
    echo "=========================="
    echo "VPC: $SELECTED_VPC"
    echo "Subnet: $SELECTED_SUBNET"
    echo "Tipo: $INSTANCE_TYPE"
    echo "AMI: $AMI_ID"
    echo "Nome: $INSTANCE_NAME"
    echo
    
    # Construir comando AWS CLI
    AWS_CMD="aws ec2 run-instances --region $REGION --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --subnet-id $SELECTED_SUBNET"
    
    # Adicionar key pair se fornecido
    if [ -n "$KEY_PAIR" ]; then
        AWS_CMD="$AWS_CMD --key-name $KEY_PAIR"
    fi
    
    # Adicionar security group se fornecido
    if [ -n "$SECURITY_GROUP" ]; then
        AWS_CMD="$AWS_CMD --security-group-ids $SECURITY_GROUP"
    fi
    
    # Adicionar tag de nome se fornecido
    if [ -n "$INSTANCE_NAME" ]; then
        AWS_CMD="$AWS_CMD --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]'"
    fi
    
    # Executar comando
    echo "Executando: $AWS_CMD"
    echo
    
    RESULT=$(eval $AWS_CMD 2>&1)
    
    if [ $? -eq 0 ]; then
        INSTANCE_ID=$(echo "$RESULT" | grep -o '"InstanceId": "[^"]*"' | cut -d'"' -f4)
        echo "✅ Instância criada com sucesso!"
        echo "Instance ID: $INSTANCE_ID"
        echo
        echo "Para verificar o status da instância:"
        echo "aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text"
    else
        echo "❌ Erro ao criar instância:"
        echo "$RESULT"
        return 1
    fi
}

# Função de ajuda
show_help() {
    echo "Script para criação de instância EC2"
    echo "===================================="
    echo
    echo "Uso:"
    echo "  source create_ec2_instance.sh"
    echo "  create_ec2_instance"
    echo
    echo "Ou execute diretamente:"
    echo "  ./create_ec2_instance.sh"
    echo
    echo "O script irá:"
    echo "1. Listar todas as VPCs disponíveis"
    echo "2. Permitir seleção da VPC desejada"
    echo "3. Listar subnets da VPC selecionada"
    echo "4. Permitir seleção da subnet desejada"
    echo "5. Coletar configurações da instância"
    echo "6. Criar a instância EC2"
}

# Se o script for executado diretamente (não sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_help
    else
        create_ec2_instance
    fi
fi
