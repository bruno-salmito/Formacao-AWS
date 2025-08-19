#!/bin/bash

# Exemplos de uso do script launch_ec2_instance.sh

echo "=== Exemplos de uso do script launch_ec2_instance.sh ==="
echo ""

echo "1. Uso básico (com configurações padrão):"
echo "./launch_ec2_instance.sh"
echo ""

echo "2. Especificando nome da instância:"
echo "INSTANCE_NAME=\"minha-instancia\" ./launch_ec2_instance.sh"
echo ""

echo "3. Especificando tipo de instância:"
echo "INSTANCE_TYPE=\"t3.small\" ./launch_ec2_instance.sh"
echo ""

echo "4. Especificando security group personalizado:"
echo "SECURITY_GROUP_NAME=\"meu-security-group\" ./launch_ec2_instance.sh"
echo ""

echo "5. Especificando zona de disponibilidade:"
echo "AVAILABILITY_ZONE=\"us-east-1b\" ./launch_ec2_instance.sh"
echo ""

echo "6. Especificando tamanho do volume:"
echo "VOLUME_SIZE=\"20\" ./launch_ec2_instance.sh"
echo ""

echo "7. Especificando AMI personalizada:"
echo "AMI_ID=\"ami-0abcdef1234567890\" ./launch_ec2_instance.sh"
echo ""

echo "8. Com IAM Instance Profile:"
echo "IAM_INSTANCE_PROFILE=\"role-acesso-ssm\" ./launch_ec2_instance.sh"
echo ""

echo "9. Com arquivo de User Data:"
echo "USER_DATA_FILE=\"user_data_ec2_zona_a.sh\" ./launch_ec2_instance.sh"
echo ""

echo "10. Exemplo completo com múltiplas configurações:"
echo "INSTANCE_NAME=\"web-server\" \\"
echo "INSTANCE_TYPE=\"t3.small\" \\"
echo "SECURITY_GROUP_NAME=\"web-sg\" \\"
echo "AVAILABILITY_ZONE=\"us-east-1a\" \\"
echo "VOLUME_SIZE=\"20\" \\"
echo "IAM_INSTANCE_PROFILE=\"role-acesso-ssm\" \\"
echo "USER_DATA_FILE=\"user_data_ec2_zona_a.sh\" \\"
echo "./launch_ec2_instance.sh"
echo ""

echo "=== Variáveis de ambiente disponíveis ==="
echo "INSTANCE_NAME       - Nome da instância (padrão: my-ec2-instance)"
echo "INSTANCE_TYPE       - Tipo da instância (padrão: t3.micro)"
echo "SECURITY_GROUP_NAME - Nome do security group (padrão: default)"
echo "AVAILABILITY_ZONE   - Zona de disponibilidade (padrão: us-east-1a)"
echo "VOLUME_SIZE         - Tamanho do volume em GB (padrão: 15)"
echo "AMI_ID              - ID da AMI (padrão: ami-02f3f602d23f1659d)"
echo "IAM_INSTANCE_PROFILE - Nome do IAM Instance Profile (opcional)"
echo "USER_DATA_FILE      - Arquivo de user data (opcional)"
