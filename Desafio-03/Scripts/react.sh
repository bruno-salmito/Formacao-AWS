#!/bin/bash
#------------------------------------------------------------
# Script: react.sh
# Descrição: Script para construir a aplicação React
# Autor: Bruno Salmito
# Data: 22/08/2025
# Versão: 1.0
#------------------------------------------------------------   


function build_react {

    printf "Verificando o diretório da aplicação..."
    log_message "Verificando o diretório da aplicação..."
    
    if [ -d "bia" ]; then
        echo -e "${GREEN}[OK]"
        cd bia/client
        log_message "[OK] - Diretório da aplicação encontrado: ${PWD}"
    else
        echo -e "${RED}[ERRO]"
        echo "  Diretório da aplicação não encontrado!"
        log_message "[ERRO] - Diretório da aplicação não encontrado"
        exit 1
    fi

    printf "Instalando dependências do React..."
    log_message "Instalando dependências do React..."

    if npm install; then
        echo -e "${GREEN}[OK]"
        echo -e "   Dependências instaladas com sucesso!"
        echo -e "${RESET}"
        log_message "[OK] - Dependências instaladas com sucesso"
    else
        echo -e "${RED}[ERRO]"
        echo "   Falha ao instalar dependências do React!"
        echo -e "${RESET}"
        log_message "[ERRO] - Falha ao instalar dependências do React"
        exit 1
    fi

    printf "Construindo aplicação React..."
    log_message "Construindo aplicação React..."

    VITE_API_URL="$1" npm run build --silent > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]"
        echo -e "   Aplicação React construída com sucesso!"
        echo -e "${RESET}"
        log_message "[OK] - Aplicação React construída com sucesso: ${BUILD_PATH}"
        cd ../../
    else
        echo -e "${RED}[ERRO]"
        echo "   Falha ao construir a aplicação React!"
        echo -e "${RESET}"
        log_message "[ERRO] - Falha ao construir a aplicação React"
        exit 1
    fi

    log_message "[Success] - Build do React finalizado com sucesso"
    log_message "-------------------------------------"
    sleep 2
}


# Função antiga mantida para fins de documentação

function build_react2 {  
    echo   "Iniciando verificação das configurações..."
    printf "    Verificando o diretório da aplicação..."

    if [ ! -d "bia" ]; then
        echo -e "${RED}[ERRO]"
        echo "      Diretório 'bia' não encontrado!"
        log_message "Diretório 'bia' não encontrado"
        exit 1
    else
        echo -e "${GREEN}[OK]"
        cd bia/client
        printf "    Instalando dependências do React..."
        if ! npm install; then
            echo "${RED}[ERRO]"
            echo "      Falha ao instalar dependências do React!"
            log_message "Falha ao instalar dependências do React"
            exit 1
        else
            printf "Construindo aplicação React..."

            #if VITE_API_URL="${ENDPOINT_URL}" npm run build --silent > /dev/null; then
            VITE_API_URL="$1" npm run build --silent > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[OK]"
                 log_message "Aplicação React construida com sucesso: ${BUILD_PATH}" 
            else
                echo -e "${RED}[ERRO]"
                echo "      Falha ao construir a aplicação React!"
                log_message "Falha ao construir a aplicação React"
                exit 1
            fi
           
        fi  
        echo "Build do React concluído com sucesso!"
        echo -e "${RESET}"
        log_message "Build do React concluído com sucesso"
        cd ../../

    fi
    
}

