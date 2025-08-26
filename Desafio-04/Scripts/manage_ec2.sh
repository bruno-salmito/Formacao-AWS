#!/bin/bash

# Importa as funções do ec2.sh
source "$(dirname "$0")/ec2.sh"

# Função principal para gerenciar EC2 baseado no status atual
function manage_ec2_instance() {
    local instance_id=$1

    # Validação do parâmetro
    if [ -z "$instance_id" ]; then
        echo "Uso: $0 <instance-id>"
        echo "Exemplo: $0 i-1234567890abcdef0"
        exit 1
    fi

    echo "=== Gerenciamento da Instância EC2: $instance_id ==="
    
    # Verifica o status atual da instância
    local current_status=$(verify_status_ec2 "$instance_id")
    local status_check=$?

    # Se houve erro na verificação, sai do script
    if [ $status_check -ne 0 ]; then
        echo "Não foi possível verificar o status da instância. Abortando."
        exit 1
    fi

    echo "Status atual da instância: $current_status"

    # Lógica condicional baseada no status
    case "$current_status" in
        "running")
            echo "Instância está rodando. Executando parada..."
            stop_ec2 "$instance_id"
            ;;
        "stopped")
            echo "Instância está parada. Executando inicialização..."
            start_ec2 "$instance_id"
            ;;
        "pending")
            echo "Instância está iniciando. Aguarde alguns momentos."
            ;;
        "stopping")
            echo "Instância está parando. Aguarde alguns momentos."
            ;;
        "shutting-down")
            echo "Instância está sendo terminada."
            ;;
        "terminated")
            echo "Instância foi terminada e não pode ser gerenciada."
            ;;
        *)
            echo "Status desconhecido: $current_status"
            echo "Nenhuma ação será executada."
            ;;
    esac

    echo "=== Operação concluída ==="
}

# Executa a função principal se o script for chamado diretamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    manage_ec2_instance "$1"
fi
