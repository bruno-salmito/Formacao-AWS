# Integração build.sh e launch_ec2.sh

## Visão Geral

O sistema agora funciona com dois scripts integrados:

- **`build.sh`**: Menu principal para configuração e orquestração
- **`launch_ec2.sh`**: Funções modulares para criação de instâncias EC2

## Arquitetura

### build.sh (Orquestrador)
- Menu interativo para configuração
- Gerencia variáveis globais
- Chama funções do launch_ec2.sh
- Integra com role.sh para criação de IAM roles e security groups

### launch_ec2.sh (Executor)
- Funções modulares para cada etapa da criação
- Pode ser usado standalone ou chamado por build.sh
- Validações e tratamento de erros
- Criação completa da instância EC2

## Fluxo de Uso

### 1. Configuração via Menu

```bash
./build.sh
```

**Menu Principal:**
```
=== MENU PRINCIPAL ===
1) Selecionar Distribuição Linux
2) Informar valores de configuração  
3) Criar IAM Role
4) Criar Security Group
5) Criar Ambiente Completo
6) Mostrar Configurações Atuais
7) Sair
```

### 2. Configuração Passo a Passo

#### Opção 1: Selecionar Distribuição
- Ubuntu (ami-0e86e20dae9224db8)
- Amazon Linux 2023 (ami-02f3f602d23f1659d)

#### Opção 2: Configurar Valores
- Região AWS
- Nome da instância
- Tipo da instância
- IAM Role
- Security Group
- Zona de disponibilidade
- Tamanho do volume

#### Opção 3: Criar IAM Role
- Chama função do role.sh
- Cria role com políticas necessárias

#### Opção 4: Criar Security Group
- Chama função do role.sh
- Configura regras de segurança

#### Opção 5: Criar Ambiente Completo
- **PRINCIPAL FUNCIONALIDADE**
- Valida todas as configurações
- Chama `create_environment()` do launch_ec2.sh
- Cria instância EC2 completa

#### Opção 6: Mostrar Configurações
- Exibe todas as configurações atuais
- Útil para verificar antes de criar

## Funções do launch_ec2.sh

### Funções de Validação
- `check_prerequisites()`: Verifica AWS CLI e arquivos
- `validate_ami_and_userdata()`: Valida AMI e define user data
- `validate_security_group()`: Verifica se security group existe
- `validate_iam_profile()`: Verifica IAM instance profile

### Funções de Infraestrutura
- `get_default_vpc()`: Obtém VPC padrão
- `get_subnet()`: Obtém subnet na zona especificada

### Funções de Criação
- `create_ec2_instance()`: Cria a instância EC2
- `wait_instance_ready()`: Aguarda instância ficar pronta
- `get_instance_info()`: Obtém informações da instância

### Função Principal
- `create_environment()`: Orquestra todo o processo de criação

## Exemplo de Uso Completo

```bash
# 1. Executar build.sh
./build.sh

# 2. Selecionar distribuição (opção 1)
# Escolher Ubuntu ou Amazon Linux

# 3. Configurar valores (opção 2)
# Definir nome, tipo, etc.

# 4. Criar ambiente (opção 5)
# Confirmar e executar criação
```

## Configurações Padrão

```bash
REGION="us-east-1"
EC2_NAME="bia-dev"
IAM_ROLE="role-acesso-ssm"
SECURITY_GROUP="bia-dev"
INSTANCE_TYPE="t3.micro"
AVAILABILITY_ZONE="us-east-1a"
VOLUME_SIZE="15"
```

## Uso Standalone do launch_ec2.sh

O launch_ec2.sh também pode ser usado independentemente:

```bash
# Modo interativo
./launch_ec2.sh

# Chamada programática (exemplo)
source launch_ec2.sh
create_environment "minha-instancia" "ami-0e86e20dae9224db8" "t3.micro" "meu-sg" "us-east-1a" "20" "role-acesso-ssm"
```

## Validações Implementadas

### Pré-requisitos
- ✅ AWS CLI instalado
- ✅ Diretório conf_files existe
- ✅ Arquivos de user data existem

### Recursos AWS
- ✅ VPC padrão existe
- ✅ Subnet na zona especificada
- ✅ Security Group existe
- ✅ IAM Instance Profile existe
- ✅ AMI ID válida

### Configuração
- ✅ Distribuição selecionada antes de criar ambiente
- ✅ Confirmação antes de criar recursos
- ✅ Feedback detalhado de cada etapa

## Tratamento de Erros

- **Arquivos ausentes**: Verifica dependências antes de executar
- **Recursos inexistentes**: Valida todos os recursos AWS
- **Falhas de criação**: Retorna códigos de erro apropriados
- **Configuração incompleta**: Impede criação sem configuração adequada

## Logs e Monitoramento

- **Feedback em tempo real**: Cada etapa é reportada
- **Informações detalhadas**: IPs, IDs, comandos de conexão
- **Instruções pós-criação**: Como conectar e monitorar

## Benefícios da Integração

1. **Flexibilidade**: Uso via menu ou programático
2. **Modularidade**: Funções reutilizáveis
3. **Validação**: Verificações em cada etapa
4. **Usabilidade**: Menu intuitivo e feedback claro
5. **Manutenibilidade**: Código organizado e documentado
