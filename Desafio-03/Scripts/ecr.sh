#!/bin/bash
#------------------------------------------------------------
# Script: ecr.sh
# Descrição: Funções para manipulação do ECR na AWS
# Autor: Bruno Salmito
# Data: 22/08/2025
# Versão: 1.0
#------------------------------------------------------------   


# Função para criar o repositório ECR se não existir
function create_ecr_repository {

    echo -e "${CYAN}Iniciando a criação do repositório ECR..."
    echo -e "============================================================"
    echo -e "${RESET}"
   

    # Chamando a função de criação do repositório ECR
    # TErminar a implementação
}

# Função para enviar para o ECR
function push_to_ecr {

    echo -e "${CYAN}iniciando o processo de push para o ECR..."
    echo -e "============================================================"
    echo -e "${RESET}"
 
    # Chamando a função de login no ECR
    login_to_ecr ${REGION}
    
    # Chamando a função de build da imagem
    create_image

    docker push $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET}"
        log_message "[OK] - Imagem enviada para o ECR com sucesso: ${ECR_URL}"
    else
        echo -e "${RED}[ERRO]${RESET}"
        log_message "[ERRO] - Falha ao enviar a imagem para o ECR"
        exit 1  

    fi

}

# Função para login no ECR
function login_to_ecr {

    printf "Logando no ECR..."
    log_message "Logando no ECR..."
    aws ecr get-login-password --region "$1" | docker login --username AWS --password-stdin $ECR_REGISTRY

# Verificando se o login foi bem-sucedido
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET}"
        log_message "[OK] - Login no ECR realizado com sucesso"
    else
        echo -e "${RED}[ERRO]${RESET}"
        log_message "[ERRO] - Falha no login no ECR"
        exit 1
    fi
}

# Função para criar a imagem Docker
function create_image {

    printf "Verificando o diretório da aplicação..."
    # Verificar se o diretório da aplicação existe
    if [ -d "${APP_PATH}" ]; then
        cd "${APP_PATH}"
        log_message "[OK] - Diretório da aplicação encontrado: ${APP_PATH}"
    else
        echo -e "${RED}[ERRO]${RESET}"
        log_message "[ERRO] - Diretório da aplicação não encontrado: ${APP_PATH}"
        exit 1
    fi

    printf "Construindo a imagem Docker..."
    log_message "Construindo a imagem Docker..."
    
    # Construir a imagem Docker
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET}"
        log_message "[OK] - Imagem Docker construída com sucesso: ${IMAGE_NAME}:${IMAGE_TAG}"
    else
        echo -e "${RED}[ERRO]${RESET}"
        log_message "[ERRO] - Falha ao construir a imagem Docker"
        exit 1
    fi

    # Criar tag para o ECR
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET}"
        log_message "[OK] - Tag da imagem criada com sucesso para o ECR"
    else
        echo -e "${RED}[ERRO]${RESET}"
        log_message "[ERRO] - Falha ao criar tag da imagem para o ECR"
        exit 1
    fi

}

