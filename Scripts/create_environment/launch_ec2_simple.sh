#!/bin/bash

# Script para lançar uma instância EC2 (versão sem jq)
# Baseado no script ec2.sh original

set -e  # Sair em caso de erro

# Verificar se AWS CLI está instalado
if ! command -v aws &> /dev/null; then
    echo ">[ERRO] AWS CLI não está instalado"
    exit 1
fi

# Configurações padrão (podem ser modificadas)
INSTANCE_NAME="${INSTANCE_NAME:-my-ec2-instance}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
SECURITY_GROUP_NAME="${SECURITY_GROUP_NAME:-default}"
#SECURITY_GROUP_NAME="${SECURITY_GROUP_NAME:"bia-dev"}"
AVAILABILITY_ZONE="${AVAILABILITY_ZONE:-us-east-1a}"
VOLUME_SIZE="${VOLUME_SIZE:-15}"
AMI_ID="${AMI_ID:-ami-02f3f602d23f1659d}"  # Amazon Linux 2023
IAM_INSTANCE_PROFILE="${IAM_INSTANCE_PROFILE:-}"
USER_DATA_FILE="${USER_DATA_FILE:-}"

echo "=== Iniciando criação da instância EC2 ==="
echo "Nome da instância: $INSTANCE_NAME"
echo "Tipo da instância: $INSTANCE_TYPE"
echo "Security Group: $SECURITY_GROUP_NAME"
echo "Zona de disponibilidade: $AVAILABILITY_ZONE"

# Obter VPC padrão
echo "Obtendo VPC padrão..."
vpc_id=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[0].VpcId" --output text)

if [ "$vpc_id" = "None" ] || [ -z "$vpc_id" ]; then
    echo ">[ERRO] VPC padrão não encontrada"
    exit 1
fi

echo "VPC encontrada: $vpc_id"

# Obter subnet na zona de disponibilidade especificada
echo "Obtendo subnet na zona $AVAILABILITY_ZONE..."
subnet_id=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id Name=availabilityZone,Values=$AVAILABILITY_ZONE --query "Subnets[0].SubnetId" --output text)

if [ "$subnet_id" = "None" ] || [ -z "$subnet_id" ]; then
    echo ">[ERRO] Subnet não encontrada na zona $AVAILABILITY_ZONE"
    exit 1
fi

echo "Subnet encontrada: $subnet_id"

# Obter security group
echo "Verificando security group $SECURITY_GROUP_NAME..."
security_group_id=$(aws ec2 describe-security-groups --group-names "$SECURITY_GROUP_NAME" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [ "$security_group_id" = "None" ] || [ -z "$security_group_id" ]; then
    echo ">[ERRO] Security group $SECURITY_GROUP_NAME não foi encontrado na VPC $vpc_id"
    exit 1
fi

echo "Security Group encontrado: $security_group_id"

# Criar instância EC2
echo "Criando instância EC2..."

# Construir argumentos base
aws_args=(
    "ec2" "run-instances"
    "--image-id" "$AMI_ID"
    "--count" "1"
    "--instance-type" "$INSTANCE_TYPE"
    "--security-group-ids" "$security_group_id"
    "--subnet-id" "$subnet_id"
    "--associate-public-ip-address"
    "--block-device-mappings" "[{\"DeviceName\":\"/dev/xvda\",\"Ebs\":{\"VolumeSize\":$VOLUME_SIZE,\"VolumeType\":\"gp2\"}}]"
    "--tag-specifications" "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]"
    "--query" "Instances[0].InstanceId"
    "--output" "text"
)

# Adicionar IAM instance profile se especificado
if [ -n "$IAM_INSTANCE_PROFILE" ]; then
    # Remover os últimos dois argumentos (query e output) temporariamente
    unset aws_args[-1]
    unset aws_args[-1]
    aws_args+=("--iam-instance-profile" "Name=$IAM_INSTANCE_PROFILE")
    aws_args+=("--query" "Instances[0].InstanceId")
    aws_args+=("--output" "text")
    echo "IAM Instance Profile: $IAM_INSTANCE_PROFILE"
fi

# Adicionar user data se especificado
if [ -n "$USER_DATA_FILE" ] && [ -f "$USER_DATA_FILE" ]; then
    # Remover os últimos dois argumentos (query e output) temporariamente
    unset aws_args[-1]
    unset aws_args[-1]
    aws_args+=("--user-data" "file://$USER_DATA_FILE")
    aws_args+=("--query" "Instances[0].InstanceId")
    aws_args+=("--output" "text")
    echo "User Data File: $USER_DATA_FILE"
fi

# Executar comando
echo "Executando comando AWS CLI..."
instance_id=$(aws "${aws_args[@]}")

# Verificar se o comando foi executado com sucesso
if [ $? -ne 0 ] || [ -z "$instance_id" ] || [ "$instance_id" = "None" ]; then
    echo ">[ERRO] Falha ao criar a instância"
    exit 1
fi

echo "=== Instância criada com sucesso! ==="
echo "Instance ID: $instance_id"
echo "Nome: $INSTANCE_NAME"
echo "Tipo: $INSTANCE_TYPE"
echo "VPC: $vpc_id"
echo "Subnet: $subnet_id"
echo "Security Group: $security_group_id"

echo ""
echo "Aguardando instância ficar em estado 'running'..."
aws ec2 wait instance-running --instance-ids $instance_id

# Obter IP público
public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

if [ "$public_ip" != "None" ] && [ -n "$public_ip" ]; then
    echo "IP Público: $public_ip"
fi

echo ""
echo "Instância $instance_id está agora em execução!"
