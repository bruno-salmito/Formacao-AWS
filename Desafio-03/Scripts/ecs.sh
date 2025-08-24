#!/bin/bash
#------------------------------------------------------------
# Script: ecs.sh
# Descrição: Script para fazer update service do ECS com force new deployment
# Uso: ./ecs.sh [CLUSTER_NAME] [SERVICE_NAME]
# Autor: Bruno Salmito
# Data: 23/08/2025
# Versão: 1.0
#------------------------------------------------------------

function update_ecs_service {

    echo -e "${CYAN}iniciando o processo de update do Service: $SERVICE_NAME..."
    echo -e "============================================================"
    echo -e "${RESET}"
    log_message "Iniciando o processo de update do Service..."
    log_message "Service: $SERVICE_NAME"
    log_message "Cluster: $CLUSTER_NAME"

    printf "Verificando informações do cluster e serviço..."
    log_message "Verificando informações do cluster e serviço..."
    verify_cluster_and_service

    # Executar o update service com force new deployment
    printf "Executando update service ..."
    log_info "Executando update service com force new deployment..."
    UPDATE_RESULT=$(aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --force-new-deployment \
        --output json)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET}"
        log_message "       >Update service executado com sucesso!"
        log_success "Update service iniciado com sucesso!"
    fi
    
    # Extrair informações do resultado
    #NEW_TASK_DEF=$(echo "$UPDATE_RESULT" | jq -r '.service.taskDefinition')
    #DEPLOYMENT_ID=$(echo "$UPDATE_RESULT" | jq -r '.service.deployments[0].id')
    #log_info "Nova Task Definition: $NEW_TASK_DEF"
    #log_info "ID do Deployment: $DEPLOYMENT_ID"
    
    # Aguardar o deployment completar (opcional)

    aws ecs update-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME"  --force-new-deployment

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET}"
        log_message "       >Update service executado com sucesso!"
        printf "Aguardando o deployment completar...."
        aws ecs wait services-stable --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME"
        echo -e "${GREEN}[OK]${RESET}"
        echo "       >Deployment completado com sucesso!"
        log_message "[SUCCESS] - Deployment completado com sucesso!"

        # Verificar status final
        FINAL_RUNNING_COUNT=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --query 'services[0].runningCount' --output text)
        printf "Verificando status final..."        
        if [ $? -eq 0 ]; then
           echo -e "${GREEN}[OK]${RESET}"
           echo "       >Status final verificado com sucesso!"
           log_message "Status final verificado com sucesso!"
           log_message "Tasks em execução após deployment: $FINAL_RUNNING_COUNT"
        else
            log_message "[ERRO] - Timeout aguardando deployment ou erro ocorreu"
        fi
    else
        log_message "Falha ao executar update service!"
        exit 1  
    fi

    log_message "Update service executado com sucesso!"


}

function verify_cluster_and_service {
# Verificar se o cluster existe
    printf "Verificando se o cluster '$CLUSTER_NAME' esta ativo..."
    if  aws ecs describe-clusters --clusters "$CLUSTER_NAME" --query 'clusters[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
        echo -e "${GREEN}[ATIVO]${RESET}"
        log_message "[ATIVO] - Cluster '$CLUSTER_NAME' encontrado e ativo."
    else   
        echo -e "${RED}[ERRO]${RESET}"
        echo -e "       >Cluster '$CLUSTER_NAME' não encontrado ou não está ativo!"
        log_message "[ERRO] - Cluster '$CLUSTER_NAME' não encontrado ou não está ativo!"
        exit 1
    fi

# Verificar se o serviço existe
    printf "Verificando se o serviço '$SERVICE_NAME' esta ativo..."
    if  aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --query 'services[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
        echo -e "${GREEN}[ATIVO]${RESET}"
        log_message "[ATIVO] - Serviço '$SERVICE_NAME' encontrado e ativo no cluster '$CLUSTER_NAME'."
    else
        echo -e "${RED}[ERRO]${RESET}"
        echo -e "       >Serviço '$SERVICE_NAME' não encontrado ou não está ativo no cluster '$CLUSTER_NAME'!"
        log_message "[ERRO] - Serviço '$SERVICE_NAME' não encontrado ou não está ativo no cluster '$CLUSTER_NAME'!"
        exit 1
    fi
}


function get_cluster_info {
    #log_info "Obtendo informações atuais do serviço..."
    CLUSTER_ARN=$(aws ecs describe-clusters --clusters "$CLUTER_NAME" --query 'clusters[0].clusterArn' --output text)
    CURRENT_TASK_DEF=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --query 'services[0].taskDefinition' --output text)
    CURRENT_RUNNING_COUNT=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --query 'services[0].runningCount' --output text)
    CURRENT_DESIRED_COUNT=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --query 'services[0].desiredCount' --output text)

    #log_info "Task Definition atual: $CURRENT_TASK_DEF"
    #log_info "Tasks em execução: $CURRENT_RUNNING_COUNT"
    #log_info "Tasks desejadas: $CURRENT_DESIRED_COUNT"

}



