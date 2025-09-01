
#!/bin/bash
#-----------------------------------------------
# Script: ec2.sh
# Descrição: Script para gerenciamento de instancias EC2
# Autor: Bruno Salmito
# Data: 25/08/2025
# Versão: 0.3
#-----------------------------------------------------

# Função para validar se a instância existe
function validate_instance() {
    local instance_name=$1
    local instance_id
    
    echo -n "Verificando instância '$instance_name'... " >&2

    #--filters "Name=tag:Name,Values=$instance_name" "Name=instance-state-name,Values=running" \   
    # Verifica o id da instancia
    instance_id=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance_name" \
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


# Função para verificar o status de uma instância EC2
# Retorna apenas o status da instância (running, stopped, pending, etc.)
function verify_status_ec2() {
    local ec2_name=$2
    local id_instance=$1

    # Validação do parâmetro
    if [ -z "$id_instance" ]; then
        echo "ERROR: ID da instância é obrigatório" >&2
        return 1
    fi

    # Consulta o status da instância
    local status=$(aws ec2 describe-instances \
                  --instance-ids "$id_instance" \
                  --query 'Reservations[0].Instances[0].State.Name' \
                  --output text 2>/dev/null)

    # Verifica se a consulta foi bem-sucedida
    if [ $? -ne 0 ] || [ -z "$status" ] || [ "$status" == "None" ]; then
        echo "ERROR: Não foi possível obter o status da instância $id_instance" >&2
        return 1
    fi

    #start_stop_ec2 $status $id_instance
    # Retorna apenas o status
    echo "$status"
    return 0
}

# Função para iniciar uma instância EC2
function start_ec2() {
    local ec2_name=$1
    local id_instance=$(validate_instance "$ec2_name")
    local status=$(verify_status_ec2 "$id_instance")

    # Validação do parâmetro
    if [ -z "$id_instance" ]; then
        echo "ERROR: ID da instância é obrigatório" >&2
        return 1
    fi

    if [ "$status" = "running" ]; then
        echo "ERROR: A instância $id_instance já está em execução" >&2
        return 1
    fi

    echo "Iniciando instância $id_instance..."
    
    # Executa o comando para iniciar a instância
    aws ec2 start-instances --instance-ids "$id_instance" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Comando de inicialização enviado para a instância $id_instance"
        return 0
    else
        echo "ERROR: Falha ao iniciar a instância $id_instance" >&2
        return 1
    fi
}

# Função para parar uma instância EC2
function stop_ec2() {
    local ec2_name=$1
    local id_instance=$(validate_instance "$ec2_name")
    local status=$(verify_status_ec2 "$id_instance")

    # Validação do parâmetro
    if [ -z "$id_instance" ]; then
        echo "ERROR: ID da instância é obrigatório" >&2
        return 1
    fi

    echo "Status atual: $status"
    if [ "$status" = "stopped" ]; then
        echo "ERROR: A instância $id_instance já está parada" >&2
        return 1
    fi

    echo "Parando instância $id_instance..."
    
    # Executa o comando para parar a instância
    aws ec2 stop-instances --instance-ids "$id_instance" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Comando de parada enviado para a instância $id_instance"
        return 0
    else
        echo "ERROR: Falha ao parar a instância $id_instance" >&2
        return 1
    fi
}

# Função de exemplo para demonstrar o uso (pode ser removida)
function start_stop_ec2() {
    local current_status=$1
    local instance_id=$2  


    echo "=== Exemplo de uso das funções ==="
    
    # Verifica o status
    #local current_status=$(verify_status_ec2 "$instance_id")
    echo "Status atual: $current_status"
        
    # Lógica condicional baseada no status
    case "$current_status" in
         "running")
                echo "Instância está rodando. Parando..."
                stop_ec2 "$instance_id"
                ;;
         "stopped")
                echo "Instância está parada. Iniciando..."
                start_ec2 "$instance_id"
                ;;
         *)
                echo "Instância está em estado: $current_status"
                ;;
    esac
    
}

# Função para criar uma instância ec2
function create_ec2() {
    echo -e "${CYAN}=== CRIANDO UMA INSTÂNCIA EC2 ===${RESET}"
    echo ""
    
    echo -n "Digite o nome da instância EC2: "
    read -r ec2_name

    if [ -z "$ec2_name" ]; then
        echo -e "${RED}Nome da instância não pode ser vazio.${RESET}"
        return 1
    fi

    echo -n "Digite a região (padrão: $REGION): "
    read -r AWS_REGION
    region=${AWS_REGION:-$REGION}

    echo -n "Digite o nome da VPC (padrão: Default): "
    read -r VPC
    vpc=${VPC:-Default}

    printf  "Verificando se a VPC existe...."

    vpc_id=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values="$vpc" --query "Vpcs[0].VpcId" --output text)

    if [ -z "$vpc_id" ] || [ "$vpc_id" == "None" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >VPC '$vpc' não encontrada."
        return 1
    fi
    
    echo -e "${GREEN}[OK]${RESET}"
    echo "      >VPC '$vpc' encontrada ID: $vpc_id."

    echo -n "Digite a subnet: (padrão: $DEFAULT_AZ): "
    read -r SUBNET
    subnet=${SUBNET:-$DEFAULT_AZ}

    printf  "Verificando se a subnet existe...."

    subnet_id=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$vpc_id" Name=availabilityZone,Values="$subnet" --query "Subnets[0].SubnetId" --output text)

    if [ -z "$subnet_id" ] || [ "$subnet_id" == "None" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >Subnet '$subnet' não encontrada na VPC '$vpc'."
        return 1
    fi

    echo -e "${GREEN}[OK]${RESET}"
    echo  "   >Subnet: $subnet id: $subnet_id"

    echo -n "Digite o tipo de instância EC2 (padrão: t3.micro):"
    read -r ec2_type
    ec2_type=${ec2_type:-t3.micro}


    echo -n "Digite o Security Group (padrão: bia-dev): "
    read -r ec2_sg
    ec2_sg=${ec2_sg:-bia-dev}

    printf "Verificando se o Security Group existe...."
    sg_id=$(aws ec2 describe-security-groups --group-names "bia-dev" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

    if [ -z "$sg_id" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >Security group '$ec2_sg' não encontrado."
        return 1
    fi

    echo -e "${GREEN}[OK]${RESET}"

    printf "Criando a instância EC2..."

    aws ec2 run-instances \
                --image-id "$AMI" --count 1 \
                --instance-type "$ec2_type" \
                --key-name "formacao" \
                --security-group-ids "$sg_id" --subnet-id "$subnet_id" --associate-public-ip-address \
                --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":15,"VolumeType":"gp2"}}]' \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=\"$ec2_name\"}]" \
                --iam-instance-profile Name=role-acesso-ssm --user-data file://UserData/user_data.sh
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET}"    
        echo "      >Instância EC2 '$ec2_name' criada com sucesso."
        return 0
    else
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >Falha ao criar a instância EC2 '$ec2_name'."
        return 1
    fi

}

function create_ec2_new2() {
    echo -e "${CYAN}=== CRIANDO UMA INSTÂNCIA EC2 (VERSÃO CORRIGIDA) ===${RESET}"
    echo ""
    
    echo -n "Digite o nome da instância EC2: "
    read -r ec2_name

    if [ -z "$ec2_name" ]; then
        echo "Nome da instância não pode ser vazio."
        return 1
    fi

    echo -n "Digite a região (padrão: $REGION):"
    read -r AWS_REGION
    region=${AWS_REGION:-$REGION}

    echo -n "Digite o nome da VPC (padrão: Default): "
    read -r VPC
    vpc=${VPC:-Default}

    printf  "Verificando se a VPC existe...."

    vpc_id=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values="$vpc" --query "Vpcs[0].VpcId" --output text)

    if [ -z "$vpc_id" ] || [ "$vpc_id" == "None" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >VPC '$vpc' não encontrada."
        return 1
    fi
    
    echo -e "${GREEN}[OK]${RESET}"
    echo  "      >VPC '$vpc' encontrada ID: $vpc_id."

    # CORREÇÃO: Mostra as subnets disponíveis e busca pelo nome
    echo ""
    echo "Subnets disponíveis na VPC '$vpc':"
    aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query "Subnets[*].[Tags[?Key=='Name'].Value|[0],AvailabilityZone,SubnetId]" \
        --output table
    echo ""

    echo -n "Digite o nome da subnet (ex: project-subnet-public1-us-east-1a): "
    read -r SUBNET
    
    if [ -z "$SUBNET" ]; then
        echo -e "${RED}[ERRO]Nome da subnet não pode ser vazio.${RESET}"
        return 1
    fi

    printf  "Verificando se a subnet existe...."

    # Busca a subnet pelo nome (tag Name) dentro da VPC especificada
    subnet_id=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Name,Values=$SUBNET" \
        --query "Subnets[0].SubnetId" \
        --output text)

    if [ -z "$subnet_id" ] || [ "$subnet_id" == "None" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >Subnet '$SUBNET' não encontrada na VPC '$vpc'."
        return 1
    fi

    echo -e "${GREEN}[OK]${RESET}"
    echo  "   >Subnet: $SUBNET id: $subnet_id"

    echo -n "Digite o tipo de instância EC2 (padrão: t3.micro):"
    read -r ec2_type
    ec2_type=${ec2_type:-t3.micro}

    echo -n "Digite o Security Group (padrão: bia-dev): "
    read -r ec2_sg
    ec2_sg=${ec2_sg:-bia-dev}

    printf "Verificando se o Security Group existe...."
    sg_id=$(aws ec2 describe-security-groups --group-names "bia-dev" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

    if [ -z "$sg_id" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >Security group '$ec2_sg' não encontrado."
        return 1
    fi

    echo -e "${GREEN}[OK]${RESET}"

    printf "Criando a instância EC2..."

    aws ec2 run-instances \
                --image-id "$AMI" --count 1 \
                --instance-type "$ec2_type" \
                --security-group-ids "$sg_id" --subnet-id "$subnet_id" --associate-public-ip-address \
                --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":15,"VolumeType":"gp2"}}]' \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=\"$ec2_name\"}]" \
                --iam-instance-profile Name=role-acesso-ssm --user-data file://UserData/user_data.sh
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET}"    
        echo "      >Instância EC2 '$ec2_name' criada com sucesso."
        return 0
    else
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >Falha ao criar a instância EC2 '$ec2_name'."
        return 1
    fi
}
function create_ec2_new() {
    echo -e "${CYAN}=== CRIANDO UMA INSTÂNCIA EC2 (VERSÃO CORRIGIDA) ===${RESET}"
    echo ""
    
    echo -n "Digite o nome da instância EC2: "
    read -r ec2_name

    if [ -z "$ec2_name" ]; then
        echo "Nome da instância não pode ser vazio."
        return 1
    fi

    echo -n "Digite a região (padrão: $REGION):"
    read -r AWS_REGION
    region=${AWS_REGION:-$REGION}

    echo -n "Digite o nome da VPC (padrão: Default):"
    read -r VPC
    vpc=${VPC:-Default}

    printf  "Verificando se a VPC existe...."

    vpc_id=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values="$vpc" --query "Vpcs[0].VpcId" --output text)

    if [ -z "$vpc_id" ] || [ "$vpc_id" == "None" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >VPC '$vpc' não encontrada."
        return 1
    fi
    
    echo -e "${GREEN}[OK]${RESET}"
    echo -e "      >VPC '$vpc' encontrada ID: $vpc_id."

    # Mostra as subnets disponíveis
    echo ""
    echo "Subnets disponíveis na VPC '$vpc':"
    aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query "Subnets[*].[Tags[?Key=='Name'].Value|[0],AvailabilityZone,SubnetId]" \
        --output table
    echo ""

    echo -n "Digite o nome da subnet: "
    read -r SUBNET
    
    if [ -z "$SUBNET" ]; then
        echo "Nome da subnet não pode ser vazio."
        return 1
    fi

    printf  "Verificando se a subnet existe...."

    subnet_id=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Name,Values=$SUBNET" \
        --query "Subnets[0].SubnetId" \
        --output text)

    if [ -z "$subnet_id" ] || [ "$subnet_id" == "None" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >Subnet '$SUBNET' não encontrada na VPC '$vpc'."
        return 1
    fi

    echo -e "${GREEN}[OK]${RESET}"
    echo -e "   >Subnet: $SUBNET id: $subnet_id"

    echo -n "Digite o tipo de instância EC2 (padrão: t3.micro):"
    read -r ec2_type
    ec2_type=${ec2_type:-t3.micro}

    echo -n "Digite o Security Group: "
    read -r ec2_sg
    
    if [ -z "$ec2_sg" ]; then
        echo "Nome do Security Group não pode ser vazio."
        return 1
    fi

    printf "Verificando se o Security Group existe...."
    # CORREÇÃO: Busca o security group na VPC específica
    sg_id=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=$ec2_sg" \
        --query "SecurityGroups[0].GroupId" \
        --output text 2>/dev/null)

    if [ -z "$sg_id" ] || [ "$sg_id" == "None" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >Security group '$ec2_sg' não encontrado na VPC '$vpc'."
        return 1
    fi

    echo -e "${GREEN}[OK]${RESET}"
    echo -e "   >Security Group: $ec2_sg id: $sg_id"

    printf "Criando a instância EC2..."

    aws ec2 run-instances \
                --image-id "$AMI" --count 1 \
                --instance-type "$ec2_type" \
                --key-name "formacao" \
                --security-group-ids "$sg_id" --subnet-id "$subnet_id" --associate-public-ip-address \
                --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":15,"VolumeType":"gp2"}}]' \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=\"$ec2_name\"}]" \
                --iam-instance-profile Name=role-acesso-ssm --user-data file://UserData/user_data.sh
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET}"    
        echo "      >Instância EC2 '$ec2_name' criada com sucesso."
        return 0
    else
        echo -e "${RED}[ERRO]${RESET}"
        echo "      >Falha ao criar a instância EC2 '$ec2_name'."
        return 1
    fi
}
