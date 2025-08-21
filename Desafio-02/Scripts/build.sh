#!/bin/bash
#-----------------------------------------------
# Script: build.sh
# Descrição: Build, tag e push de uma imagem docker para o AWS ECR
# Uso: ./build.sh [ECR_REGISTRY] [NOME-IMAGEM] [REGIÃO-AWS] 
# Autor: Bruno Salmito
# Version: 1.0
# Date: 2023-10-01
#-----------------------------------------------

#-------------------------------
# Configurações iniciais
#-------------------------------
# Valor padrão do ECR_REGISTRY
DEFAULT_ECR_REGISTRY="874287870279.dkr.ecr.us-east-1.amazonaws.com"

# Valor padrão do nome da imagem Docker
DEFAULT_IMAGE_NAME="prd/bia"

# Valor padrão da região AWS
AWS_REGION="us-east-1"

# Se o usuário passar argumentos, usa eles; caso contrário usa os padrões
ECR_REGISTRY="${1:-$DEFAULT_ECR_REGISTRY}"
IMAGE_NAME="${2:-$DEFAULT_IMAGE_NAME}"
AWS_REGION="${3:-$AWS_REGION}"


# Tag da imagem
IMAGE_TAG="latest"

echo "Usando ECR Registry: $ECR_REGISTRY"
echo "Imagem Docker: $IMAGE_NAME:$IMAGE_TAG"
echo "Região AWS: $AWS_REGION"

#-------------------------------
# Login no ECR
#-------------------------------
echo "Fazendo login no AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
if [ $? -ne 0 ]; then
    echo "Erro ao logar no ECR!"
    exit 1
fi

#-------------------------------
# Build da imagem Docker
#-------------------------------
echo "Construindo a imagem Docker..."
docker build -t $IMAGE_NAME .
if [ $? -ne 0 ]; then
    echo "Erro ao construir a imagem!"
    exit 1
fi

#-------------------------------
# Tag da imagem Docker
#-------------------------------
echo "Tagging da imagem Docker..."
docker tag $IMAGE_NAME:$IMAGE_TAG $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
if [ $? -ne 0 ]; then
    echo "Erro ao criar a tag da imagem!"
    exit 1
fi

#-------------------------------
# Push da imagem para o ECR
#-------------------------------
echo "Enviando a imagem para o ECR..."
docker push $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
if [ $? -ne 0 ]; then
    echo "Erro ao enviar a imagem para o ECR!"
    exit 1
fi

echo "Imagem enviada com sucesso para $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
