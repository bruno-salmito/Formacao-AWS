#!/bin/bash
#-----------------------------------------------
# Script: setup_route53_s3.sh
# Descrição: Configura Route 53 para apontar para site estático S3
# Autor: Bruno Salmito
# Data: 27/08/2025
# Versão: 1.0
#-----------------------------------------------------

# Cores para output
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# Hosted Zone IDs do S3 por região
declare -A S3_HOSTED_ZONES=(
    ["us-east-1"]="Z3AQBSTGFYJSTF"
    ["us-west-1"]="Z2F56UZL2M1ACD"
    ["us-west-2"]="Z3BJ6K6RIION7M"
    ["eu-west-1"]="Z1BKCTXD74EZPE"
    ["eu-central-1"]="Z21DNDUVLTQW6Q"
    ["ap-southeast-1"]="Z3O0SRN1WG5H4"
    ["ap-northeast-1"]="Z2M4EHUR26P7ZW"
)

function setup_route53_s3() {
    echo -e "${CYAN}=== CONFIGURANDO ROUTE 53 PARA S3 ===${RESET}"
    echo ""
    
    # Solicitar informações
    echo -n "Digite o nome do bucket S3: "
    read -r bucket_name
    
    echo -n "Digite o nome do domínio (ex: exemplo.com): "
    read -r domain_name
    
    echo -n "Digite a região do bucket (padrão: us-east-1): "
    read -r region
    region=${region:-us-east-1}
    
    # Verificar se o bucket existe
    echo -n "Verificando se o bucket existe... "
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        echo -e "${GREEN}[OK]${RESET}"
    else
        echo -e "${RED}[ERRO]${RESET}"
        echo "Bucket '$bucket_name' não encontrado."
        return 1
    fi
    
    # Verificar se o bucket está configurado para website
    echo -n "Verificando configuração de website... "
    if aws s3api get-bucket-website --bucket "$bucket_name" 2>/dev/null; then
        echo -e "${GREEN}[OK]${RESET}"
    else
        echo -e "${YELLOW}[CONFIGURANDO]${RESET}"
        echo "Configurando bucket para hospedagem de website..."
        
        aws s3api put-bucket-website --bucket "$bucket_name" --website-configuration '{
            "IndexDocument": {
                "Suffix": "index.html"
            },
            "ErrorDocument": {
                "Key": "error.html"
            }
        }'
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Website configurado com sucesso${RESET}"
        else
            echo -e "${RED}Erro ao configurar website${RESET}"
            return 1
        fi
    fi
    
    # Obter o Hosted Zone ID do S3 para a região
    s3_hosted_zone_id=${S3_HOSTED_ZONES[$region]}
    if [ -z "$s3_hosted_zone_id" ]; then
        echo -e "${RED}Região '$region' não suportada${RESET}"
        return 1
    fi
    
    # Construir o endpoint do S3
    s3_endpoint="s3-website-${region}.amazonaws.com"
    
    # Buscar a Hosted Zone do Route 53
    echo -n "Buscando Hosted Zone para '$domain_name'... "
    hosted_zone_id=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='${domain_name}.'].Id" --output text 2>/dev/null | sed 's|/hostedzone/||')
    
    if [ -z "$hosted_zone_id" ] || [ "$hosted_zone_id" == "None" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo "Hosted Zone para '$domain_name' não encontrada."
        echo "Certifique-se de que a Hosted Zone existe no Route 53."
        return 1
    fi
    
    echo -e "${GREEN}[OK]${RESET}"
    echo "Hosted Zone ID: $hosted_zone_id"
    
    # Criar o registro ALIAS
    echo -n "Criando registro ALIAS... "
    
    change_batch=$(cat <<EOF
{
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "$domain_name",
            "Type": "A",
            "AliasTarget": {
                "DNSName": "$s3_endpoint",
                "EvaluateTargetHealth": false,
                "HostedZoneId": "$s3_hosted_zone_id"
            }
        }
    }]
}
EOF
)
    
    result=$(aws route53 change-resource-record-sets --hosted-zone-id "$hosted_zone_id" --change-batch "$change_batch" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET}"
        change_id=$(echo "$result" | grep -o '"Id": "[^"]*"' | cut -d'"' -f4)
        echo "Change ID: $change_id"
        echo ""
        echo -e "${GREEN}Configuração concluída com sucesso!${RESET}"
        echo ""
        echo "Informações da configuração:"
        echo "- Domínio: $domain_name"
        echo "- Bucket S3: $bucket_name"
        echo "- Região: $region"
        echo "- Endpoint S3: $s3_endpoint"
        echo ""
        echo -e "${YELLOW}Nota: A propagação DNS pode levar até 48 horas.${RESET}"
    else
        echo -e "${RED}[ERRO]${RESET}"
        echo "Falha ao criar o registro ALIAS."
        return 1
    fi
}

# Função para criar registro CNAME para www
function setup_www_redirect() {
    echo -e "${CYAN}=== CONFIGURANDO REDIRECIONAMENTO WWW ===${RESET}"
    echo ""
    
    echo -n "Digite o domínio principal (ex: exemplo.com): "
    read -r domain_name
    
    echo -n "Buscando Hosted Zone... "
    hosted_zone_id=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='${domain_name}.'].Id" --output text 2>/dev/null | sed 's|/hostedzone/||')
    
    if [ -z "$hosted_zone_id" ] || [ "$hosted_zone_id" == "None" ]; then
        echo -e "${RED}[ERRO]${RESET}"
        echo "Hosted Zone não encontrada."
        return 1
    fi
    
    echo -e "${GREEN}[OK]${RESET}"
    
    # Criar registro CNAME para www
    change_batch=$(cat <<EOF
{
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "www.$domain_name",
            "Type": "CNAME",
            "TTL": 300,
            "ResourceRecords": [{
                "Value": "$domain_name"
            }]
        }
    }]
}
EOF
)
    
    echo -n "Criando registro CNAME para www... "
    aws route53 change-resource-record-sets --hosted-zone-id "$hosted_zone_id" --change-batch "$change_batch" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET}"
        echo "Registro www.$domain_name criado com sucesso."
    else
        echo -e "${RED}[ERRO]${RESET}"
        echo "Falha ao criar registro www."
        return 1
    fi
}

# Menu principal
function main() {
    echo -e "${CYAN}Route 53 + S3 Setup Tool${RESET}"
    echo ""
    echo "1) Configurar domínio principal (A record ALIAS)"
    echo "2) Configurar redirecionamento www (CNAME)"
    echo "3) Sair"
    echo ""
    echo -n "Escolha uma opção [1-3]: "
    read -r option
    
    case $option in
        1)
            setup_route53_s3
            ;;
        2)
            setup_www_redirect
            ;;
        3)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            ;;
    esac
}

main
