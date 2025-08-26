
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


