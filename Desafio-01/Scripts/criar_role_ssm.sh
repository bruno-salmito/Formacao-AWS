#!/bin/bash
#----------------------------------------------
#Script: criar_role_ssm.sh
#Descrição: Cria uma IAM role para acesso ao SSM, esse script deve ser executado no cloud shell da AWS.
#Data: versão 1.0
#Uso: ./criar_role_ssm.sh
#----------------------------------------------


role_name="role-acesso-ssm"
policy_name="AmazonSSMManagedInstanceCore"

# Verifica se a role já existe
if aws iam get-role --role-name "$role_name" &> /dev/null; then
    echo "A IAM role $role_name já existe."
    exit 1
fi

aws iam create-role --role-name $role_name --assume-role-policy-document file://ec2_principal.json
# Cria o perfil de instância
aws iam create-instance-profile --instance-profile-name $role_name

# Adiciona a função IAM ao perfil de instância
aws iam add-role-to-instance-profile --instance-profile-name $role_name --role-name $role_name

aws iam attach-role-policy --role-name $role_name --policy-arn arn:aws:iam::aws:policy/$policy_name