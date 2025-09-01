# Inclusão dos arquivos base
if [ ! -f ./log.sh ]; then
    echo "[ERRO] - Arquivo log.sh não encontrado"
    exit 1
fi

if [ ! -f ./variables.sh ]; then
    echo "[ERRO] - Arquivo variables.sh não encontrado"
    exit 1
fi

if [ ! -f ./create_tunnel.sh ]; then
    echo "[ERRO] - Arquivo create_tunnel.sh não encontrado"
    exit 1
fi

if [ ! -f ./ec2.sh ]; then
    echo "[ERRO] - Arquivo ec2.sh não encontrado"
    exit 1
fi

source ./log.sh
source ./variables.sh
source ./create_tunnel.sh
source ./ec2.sh

# Variáveis globais
#BASTION_INSTANCE="bia-dev"  # Instância porteiro para RDS

# Função para limpar a tela e mostrar cabeçalho
function show_header() {
    clear
    echo -e "${CYAN}"
    echo "=================================================="
    echo "     CRIADOR DE TÚNEIS AWS E GERENCIADOR EC2"
    echo "=================================================="
    echo -e "${RESET}"
}

# Função para mostrar o menu principal
function show_menu() {
    echo -e "${YELLOW}Escolha uma opção:${RESET}"
    echo ""
    echo "1) Criar túnel simples para instância EC2"
    echo "2) Criar túnel para RDS (via instância bia-dev)"
    echo "3) Verificar status da instância EC2"
    echo "4) Parar instância EC2"
    echo "5) Iniciar instância EC2"
    echo "6) Criar instância EC2"
    echo "7) Criar instância EC2 Por Subnet" 
    echo "8) Sair"
    echo ""
    echo -n "Digite sua opção [1-8]: "
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
                echo -n "Digite o nome da instância EC2 (padrão: bia-dev): "
                read -r ec2_name
                ec2_name=${ec2_name:-bia-dev}
                ec2_id=$(validate_instance "$ec2_name")
                verify_status_ec2  $ec2_id $ec2_name
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${RESET}"
                read -r
                ;;
            4)
                echo ""
                echo -n "Digite o nome da instância EC2 (padrão: bia-dev): "
                read -r ec2_name
                ec2_name=${ec2_name:-bia-dev}
                stop_ec2 $ec2_name
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${RESET}"
                read -r
                ;;
            5)
                echo ""
                echo -n "Digite o nome da instância EC2 (padrão: bia-dev): "
                read -r ec2_name
                ec2_name=${ec2_name:-bia-dev}
                start_ec2 $ec2_name
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${RESET}"
                read -r
                ;;
            6)
                echo ""
                create_ec2
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${RESET}"
                read -r
                ;;                         
            7)
                echo ""
                create_ec2_new
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${RESET}"
                read -r
                ;;   
            8)
                echo ""
                echo -e "${GREEN}Saindo...${RESET}"
                log_message "Script finalizado pelo usuário"
                exit 0
                ;;
            9)
                echo ""
                create_bastion_tunnel
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${RESET}"
                read -r
                ;;
            *)
                echo ""
                echo -e "${RED}Opção inválida! Escolha entre 1-4.${RESET}"
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${RESET}"
                read -r
                ;;
        esac
    done
}

main