#!/bin/bash
#------------------------------------------------------------------
# Script: Script para lançar uma instância EC2 com funções modulares
#         Pode ser usado standalone ou chamado por outros scripts
# Autor: Bruno Salmito
# Data: 18-08-2025
# Versão: 1.2
# --------------------------------------------------------------------------

set -e  # Sair em caso de erro

# Diretório dos arquivos de configuração
CONF_DIR="./conf_files"

# Verificar se os arquivos necessários existem
if [ ! -f "variables.sh" ]; then
    echo ">[ERRO] Arquivo variables.sh não encontrado"
    exit 1
fi

if [ ! -f "log.sh" ]; then
    echo ">[ERRO] Arquivo log.sh não encontrado"
    exit 1
fi

source variables.sh
source log.sh


# Grava no log de inicio do script
log_message "********************************************************************"
log_message "[START] Criando o seu ambiente"
log_message "USuario: $USER"
log_message "Data/Hora: $TIMESTAMP"
log_message "********************************************************************"

# Função para verificar pré-requisitos
check_prerequisites() {
    # Verificar se AWS CLI está instalado
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}>[ERRO] AWS CLI não está instalado${RESET}"
        log_message "[ERRO] AWS CLI não encontrado " 
        return 1
    fi

    # Verificar se o diretório conf_files existe
    if [ ! -d "$CONF_DIR" ]; then
        echo -e "${RED}>[ERRO] Diretório $CONF_DIR não encontrado${RESET}"
        log_message "[ERRO] Diretório $CONF_DIR não encontrado"
        return 1
    fi

    return 0
}

# Função para validar AMI e definir user data
validate_ami_and_userdata() {
    local ami_id="$1"
    
    case "$ami_id" in
        "ami-0e86e20dae9224db8")
            DISTRIBUTION="ubuntu"
            USER_DATA_FILE="$CONF_DIR/user_data_ec2_ubuntu.sh"
            DEFAULT_USER="ubuntu"
            ;;
        "ami-02f3f602d23f1659d")
            DISTRIBUTION="amazon"
            USER_DATA_FILE="$CONF_DIR/user_data_ec2_amazon.sh"
            DEFAULT_USER="ec2-user"
            ;;
        *)
            echo -e "${RED}>[ERRO] AMI ID não reconhecida: $ami_id${RESET}"
            log_message "[ERRO] AMI ID não reconhecida: $ami_id"
            return 1
            ;;
    esac

    # Verificar se o arquivo de user data existe
    if [ ! -f "$USER_DATA_FILE" ]; then
        echo -e "${RED}>[ERRO] Arquivo de user data não encontrado: $USER_DATA_FILE ${RESET}"
        log_message "[ERRO] Arquivo de user data não encontrado: $USER_DATA_FILE"
        return 1
    fi

    return 0
}

# Função para obter VPC padrão
get_default_vpc() {
    echo "Obtendo VPC padrão..."
    vpc_id=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[0].VpcId" --output text)

    if [ "$vpc_id" = "None" ] || [ -z "$vpc_id" ]; then
        echo -e "${RED}>[ERRO] VPC padrão não encontrada${RESET}"
        log_message "[ERRO] VPC padrão não encontrada"
        return 1
    fi

    echo -e "${GREEN}[OK] VPC encontrada: $vpc_id ${RESET}"
    log_message "[OK] VPC padrão encontrada - $vpc_id"
    return 0
}

# Função para obter subnet
get_subnet() {
    local availability_zone="$1"
    
    echo "Obtendo subnet na zona $availability_zone..."
    subnet_id=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id Name=availabilityZone,Values=$availability_zone --query "Subnets[0].SubnetId" --output text)

    if [ "$subnet_id" = "None" ] || [ -z "$subnet_id" ]; then
        echo -e "${RED}>[ERRO] Subnet não encontrada na zona $availability_zone${RESET}"
        log_message "[ERRO] Subnet não encontrada na zona $availability_zone"
        return 1
    fi

    echo -e "{GREEN}[OK] Subnet encontrada: $subnet_id${RESET}"
    log_message "[OK] ubnet encontrada: $subnet_id"
    return 0
}

# Função para validar security group
validate_security_group() {
    local sg_name="$1"
    
    printf "Verificando security group $sg_name..."
    security_group_id=$(aws ec2 describe-security-groups --group-names "$sg_name" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

    if [ "$security_group_id" = "None" ] || [ -z "$security_group_id" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo -e "       ${RED}>[ERRO] Security group $sg_name não foi encontrado na VPC $vpc_id{RESET}"
        log_message "[ERRO] Security group $sg_name não foi encontrado na VPC $vpc_id"
        return 1
    fi
    echo -e "${GREEN}[OK]${RESET}"
    echo -e "      ${GREEN}Security Group encontrado: $security_group_id${RESET}"
    log_message "[OK] Security Group encontrado: $security_group_id $vpc_id"
    return 0
}

# Função para validar IAM Instance Profile
validate_iam_profile() {
    local profile_name="$1"
    
    printf "Verificando IAM Instance Profile $profile_name..."
    iam_profile_check=$(aws iam get-instance-profile --instance-profile-name "$profile_name" --query "InstanceProfile.InstanceProfileName" --output text 2>/dev/null || echo "None")

    if [ "$iam_profile_check" = "None" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo -e "       ${RED}>[ERRO] IAM Instance Profile $profile_name não encontrado"
        echo "          Certifique-se de que o profile existe e você tem permissões para acessá-lo ${RESET}"
        log_message "[ERRO] IAM Instance Profile $profile_name não encontrado"
        return 1
    fi
    echo -e "${GREEN}[OK]${RESET}"
    echo -e "       ${GREEN}IAM Instance Profile encontrado: $profile_name${RESET}"
    return 0
}

# Função para criar instância EC2
create_ec2_instance() {
    local instance_name="$1"
    local ami_id="$2"
    local instance_type="$3"
    local volume_size="$4"
    local iam_profile="$5"
    
    echo ""
    printf "Criando instância EC2..."

    # Executar comando AWS CLI
    instance_id=$(aws ec2 run-instances \
        --image-id "$ami_id" \
        --count 1 \
        --instance-type "$instance_type" \
        --security-group-ids "$security_group_id" \
        --subnet-id "$subnet_id" \
        --associate-public-ip-address \
        --block-device-mappings "[{\"DeviceName\":\"/dev/xvda\",\"Ebs\":{\"VolumeSize\":$volume_size,\"VolumeType\":\"gp2\"}}]" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name},{Key=Distribution,Value=$DISTRIBUTION}]" \
        --iam-instance-profile "Name=$iam_profile" \
        --user-data "file://$USER_DATA_FILE" \
        --query "Instances[0].InstanceId" \
        --output text)

    # Verificar se o comando foi executado com sucesso
    if [ $? -ne 0 ] || [ -z "$instance_id" ] || [ "$instance_id" = "None" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo -e "       ${RED}>[ERRO] Falha ao criar a instância${RESET}"
        log_message "[ERRO] Falha ao criar a instância"
        return 1
    fi
    echo -e "${GREEN}[OK]${RESET}"
    return 0
}

# Função para aguardar instância ficar pronta
wait_instance_ready() {
    echo ""
    echo "Aguardando instância ficar em estado 'running'..."
    printf "Isso pode levar alguns minutos..."

    aws ec2 wait instance-running --instance-ids $instance_id

    echo -e "${GREEN}[OK]${RESET}"
    echo "      Instância está rodando!"
    return 0
}

# Função para obter informações da instância
get_instance_info() {
    echo ""
    echo "Obtendo informações da instância..."

    public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    private_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)

    return 0
}

# Função para exibir informações finais
show_final_info() {
    local instance_name="$1"
    local ami_id="$2"
    local instance_type="$3"
    
    echo ""
    echo "=== Instância criada com sucesso! ==="
    echo "Instance ID: $instance_id"
    echo "Nome: $instance_name"
    echo "Distribuição: $DISTRIBUTION ($ami_id)"
    echo "Tipo: $instance_type"
    echo "VPC: $vpc_id"
    echo "Subnet: $subnet_id"
    echo "Security Group: $security_group_id"
    echo "IAM Instance Profile: $IAM_INSTANCE_PROFILE"
    echo "Usuário padrão: $DEFAULT_USER"

    echo ""
    echo "=== Informações da Instância ==="
    echo "Instance ID: $instance_id"
    echo "IP Público: $public_ip"
    echo "IP Privado: $private_ip"
    echo "Usuário SSH: $DEFAULT_USER"

    if [ "$public_ip" != "None" ] && [ -n "$public_ip" ]; then
        echo ""
        echo "=== Comandos para Conexão ==="
        echo "SSH: ssh -i <sua-chave.pem> $DEFAULT_USER@$public_ip"
        echo "AWS SSM: aws ssm start-session --target $instance_id"
    fi

    echo ""
    echo "=== User Data Executado ==="
    echo "Os seguintes pacotes estão sendo instalados automaticamente:"
    if [ "$DISTRIBUTION" = "ubuntu" ]; then
        echo "- Docker e Docker Compose"
        echo "- Node.js 14.x e NPM"
        echo "- AWS CLI v2"
        echo "- Configurações de permissão para usuário ubuntu"
    else
        echo "- Docker e Docker Compose v2"
        echo "- Git"
        echo "- Node.js 21.x e NPM"
        echo "- Python 3.11 e UV"
        echo "- Configuração de swap (4GB)"
        echo "- Configurações de permissão para usuários ec2-user e ssm-user"
    fi

    echo ""
    echo "Aguarde alguns minutos para que todos os pacotes sejam instalados."
    echo "Você pode monitorar o progresso conectando via SSH ou SSM e verificando os logs:"
    echo "  sudo tail -f /var/log/cloud-init-output.log"

    echo ""
    echo "Instância $instance_id está pronta para uso!"
}

# Função principal para criar ambiente completo
create_environment() {
    local instance_name="$1"
    local ami_id="$2"
    local instance_type="$3"
    local security_group_name="$4"
    local availability_zone="$5"
    local volume_size="$6"
    local iam_profile="$7"

    # Definir variáveis globais para uso nas funções
    IAM_INSTANCE_PROFILE="$iam_profile"

    echo "=== Iniciando criação da instância EC2 ==="
    echo "Nome da instância: $instance_name"
    echo "AMI ID: $ami_id"
    echo "Tipo da instância: $instance_type"
    echo "Security Group: $security_group_name"
    echo "Zona de disponibilidade: $availability_zone"
    echo "Tamanho do volume: ${volume_size}GB"
    echo "IAM Instance Profile: $iam_profile"
    echo ""

    # Executar validações e criação
    check_prerequisites || return 1
    validate_ami_and_userdata "$ami_id" || return 1
    get_default_vpc || return 1
    get_subnet "$availability_zone" || return 1
    validate_security_group "$security_group_name" || return 1
    validate_iam_profile "$iam_profile" || return 1
    
    echo "User Data: $USER_DATA_FILE"
    echo ""

    create_ec2_instance "$instance_name" "$ami_id" "$instance_type" "$volume_size" "$iam_profile" || return 1
    wait_instance_ready || return 1
    get_instance_info || return 1
    show_final_info "$instance_name" "$ami_id" "$instance_type"

    log_message "[OK] Ambiente criado com sucesso"
    log_message "*********************************************"
    log_message "[Instance ID]: $instance_id"
    log_message "[Nome]: $instance_name"
    log_message "[Distribuição]: $DISTRIBUTION ($ami_id)"
    log_message "[Tipo]: $instance_type"
    log_message "[VPC]: $vpc_id"
    log_message "[Subnet]: $subnet_id"
    log_message "[Security Group]: $security_group_id"
    log_message "[IAM Instance Profile]: $IAM_INSTANCE_PROFILE"
    log_message "[Usuário padrão]: $DEFAULT_USER"
    log_message "[IP Público]: $public_ip"
    log_message "[IP Privado]: $private_ip"
    log_message "*********************************************"
    return 0
}

# Função para uso standalone (menu interativo)
interactive_mode() {
    # Configurações padrão
    local instance_name="${INSTANCE_NAME:-my-ec2-instance}"
    local instance_type="${INSTANCE_TYPE:-t3.micro}"
    local security_group_name="${SECURITY_GROUP_NAME:-default}"
    local availability_zone="${AVAILABILITY_ZONE:-us-east-1a}"
    local volume_size="${VOLUME_SIZE:-15}"
    local iam_profile="role-acesso-ssm"

    # Menu de seleção de distribuição
    echo "=== Seleção da Distribuição Linux ==="
    echo "1) Ubuntu (ami-0e86e20dae9224db8)"
    echo "2) Amazon Linux 2023 (ami-02f3f602d23f1659d)"
    echo "3) Cancelar"
    echo ""

    while true; do
        read -p "Escolha uma opção (1-3): " choice
        
        case $choice in
            1)
                ami_id="ami-0e86e20dae9224db8"
                echo "Selecionado: Ubuntu"
                break
                ;;
            2)
                ami_id="ami-02f3f602d23f1659d"
                echo "Selecionado: Amazon Linux 2023"
                break
                ;;
            3)
                echo "Operação cancelada pelo usuário"
                exit 0
                ;;
            *)
                echo "Opção inválida. Tente novamente."
                ;;
        esac
    done

    # Criar ambiente
    create_environment "$instance_name" "$ami_id" "$instance_type" "$security_group_name" "$availability_zone" "$volume_size" "$iam_profile"
}

# Verificar se o script está sendo executado diretamente ou sendo chamado
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Executado diretamente - modo interativo
    interactive_mode
fi
