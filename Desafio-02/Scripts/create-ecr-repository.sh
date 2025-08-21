#!/bin/bash
#-----------------------------------------------
# Script: create-ecr-repository.sh
# Descrição: Criação de um repositório ECR na AWS
# Uso: ./create-ecr-repository.sh
# Autor: Bruno Salmito
# Version: 1.0
# Date: 21-08-2025
#-----------------------------------------------


set -e  # Parar execução em caso de erro

# Variáveis de configuração
REPOSITORY_NAME="prd/bia"
REGION="us-east-1"
IMAGE_TAG_MUTABILITY="MUTABLE"
ENCRYPTION_TYPE="AES256"
SCAN_ON_PUSH="false"

printf "Criando repositório ECR: $REPOSITORY_NAME na região $REGION ...."
#echo "📍 Região: $REGION"

# Verificar se o repositório já existe
if aws ecr describe-repositories --repository-names "$REPOSITORY_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "  [ERRO]"
    echo "      Repositório '$REPOSITORY_NAME' já existe!"
    read -p "   Deseja continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "      Operação cancelada."
        exit 1
    fi
else
    echo "  [OK]"
    echo "      Repositório não existe, prosseguindo com a criação..."
fi

# Criar o repositório ECR
printf "Criando repositório ECR..."
aws ecr create-repository \
    --repository-name "$REPOSITORY_NAME" \
    --region "$REGION" \
    --image-tag-mutability "$IMAGE_TAG_MUTABILITY" \
    --encryption-configuration encryptionType="$ENCRYPTION_TYPE" \
    --image-scanning-configuration scanOnPush="$SCAN_ON_PUSH"

if [ $? -eq 0 ]; then
    echo "  [SUCESSO]"
    echo "      Repositório '$REPOSITORY_NAME' criado com sucesso!"
    
    # Obter informações do repositório criado
    echo "--------------------------------"
    echo "Informações do repositório:"
    REPOSITORY_URI=$(aws ecr describe-repositories --repository-names "$REPOSITORY_NAME" --region "$REGION" --query 'repositories[0].repositoryUri' --output text)
    echo "   URI: $REPOSITORY_URI"
    
    echo ""
    echo "   Comandos úteis para usar o repositório:"
    echo "   # Login no ECR:"
    echo "   aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPOSITORY_URI"
    echo ""
    echo "   # Tag e push de uma imagem:"
    echo "   docker tag <sua-imagem>:latest $REPOSITORY_URI:latest"
    echo "   docker push $REPOSITORY_URI:latest"
    echo "--------------------------------"
    
else
    echo "  [ERRO]"
    echo "      Erro ao criar o repositório '$REPOSITORY_NAME'!"
    echo "      Erro ao criar o repositório!"
    exit 1
fi

echo ""
echo "Script executado com sucesso!"
