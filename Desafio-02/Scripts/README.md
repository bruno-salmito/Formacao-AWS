# Documentação dos Scripts - Desafio 02

Esta documentação descreve os scripts disponíveis neste diretório para automação de tarefas relacionadas ao AWS ECR e deployment de aplicações.

## Scripts Disponíveis

### 1. create-ecr-repository.sh

**Descrição:** Script para criação automatizada de um repositório ECR (Elastic Container Registry) na AWS.

**Funcionalidades:**
- Cria um repositório ECR com configurações pré-definidas
- Verifica se o repositório já existe antes da criação
- Configura criptografia AES256
- Define mutabilidade de tags como MUTABLE
- Desabilita scan automático no push
- Exibe informações úteis após a criação (URI, comandos de exemplo)

**Configurações padrão:**
- Nome do repositório: `prd/bia`
- Região: `us-east-1`
- Mutabilidade de tags: `MUTABLE`
- Criptografia: `AES256`
- Scan no push: `false`

**Como usar:**
```bash
# Tornar o script executável (se necessário)
chmod +x create-ecr-repository.sh

# Executar o script
./create-ecr-repository.sh
```

**Pré-requisitos:**
- AWS CLI instalado e configurado
- Permissões adequadas para criar repositórios ECR
- Credenciais AWS válidas

**Saída esperada:**
- Confirmação da criação do repositório
- URI do repositório criado
- Comandos úteis para login, tag e push de imagens

---

### 2. build.sh

**Descrição:** Script para build, tag e push de imagens Docker para o AWS ECR.

**Funcionalidades:**
- Faz login automático no AWS ECR
- Constrói a imagem Docker a partir do Dockerfile local
- Aplica tag à imagem
- Faz push da imagem para o repositório ECR
- Suporte a parâmetros personalizados ou valores padrão

**Parâmetros:**
1. `ECR_REGISTRY` (opcional): URL do registry ECR
2. `IMAGE_NAME` (opcional): Nome da imagem Docker
3. `AWS_REGION` (opcional): Região AWS

**Valores padrão:**
- ECR Registry: `SEU_REGISTRY` (deve ser alterado)
- Nome da imagem: `minha-imagem-docker`
- Região AWS: `us-east-1`
- Tag da imagem: `latest`

**Como usar:**

```bash
# Usando valores padrão
./build.sh

# Especificando todos os parâmetros
./build.sh 123456789012.dkr.ecr.us-east-1.amazonaws.com minha-app us-east-1

# Especificando apenas alguns parâmetros
./build.sh 123456789012.dkr.ecr.us-east-1.amazonaws.com minha-app
```

**Pré-requisitos:**
- Docker instalado e em execução
- AWS CLI instalado e configurado
- Dockerfile presente no diretório atual
- Permissões para push no repositório ECR
- Credenciais AWS válidas

**Fluxo de execução:**
1. Login no AWS ECR
2. Build da imagem Docker
3. Tag da imagem com o nome do repositório ECR
4. Push da imagem para o ECR

---

### 3. deploy.sh

**Descrição:** Script simples para deployment que combina build e atualização de serviço ECS.

**Funcionalidades:**
- Executa o script de build
- Força um novo deployment no serviço ECS especificado

**Como usar:**

```bash
# Antes de usar, edite o script para especificar:
# - [SEU_CLUSTER]: Nome do seu cluster ECS
# - [SEU_SERVICE]: Nome do seu serviço ECS

# Executar o deployment
./deploy.sh
```

**Pré-requisitos:**
- Script `build.sh` funcional no mesmo diretório
- AWS CLI instalado e configurado
- Cluster e serviço ECS existentes
- Permissões para atualizar serviços ECS

**Configuração necessária:**
Antes de usar, edite o arquivo e substitua:
- `[SEU_CLUSTER]` pelo nome real do seu cluster ECS
- `[SEU_SERVICE]` pelo nome real do seu serviço ECS

Exemplo:
```bash
./build.sh
aws ecs update-service --cluster meu-cluster-producao --service minha-aplicacao --force-new-deployment
```

## Fluxo de Trabalho Recomendado

1. **Primeira vez:**
   ```bash
   # 1. Criar o repositório ECR
   ./create-ecr-repository.sh
   
   # 2. Configurar o build.sh com as informações do repositório criado
   # 3. Configurar o deploy.sh com informações do cluster/serviço ECS
   ```

2. **Deployments subsequentes:**
   ```bash
   # Opção 1: Deploy completo (build + atualização ECS)
   ./deploy.sh
   
   # Opção 2: Apenas build e push
   ./build.sh [ECR_REGISTRY] [IMAGE_NAME] [REGION]
   ```

## Notas Importantes

- **Segurança:** Certifique-se de que as credenciais AWS estão configuradas corretamente
- **Permissões:** Verifique se o usuário/role tem as permissões necessárias para ECR e ECS
- **Customização:** Edite as variáveis padrão nos scripts conforme sua necessidade
- **Logs:** Todos os scripts fornecem feedback detalhado sobre o progresso das operações
- **Tratamento de erros:** Os scripts param a execução em caso de erro (`set -e`)

## Troubleshooting

**Erro de login no ECR:**
- Verifique se o AWS CLI está configurado corretamente
- Confirme se as credenciais têm permissão para acessar o ECR

**Erro no build do Docker:**
- Certifique-se de que existe um Dockerfile no diretório atual
- Verifique se o Docker está em execução

**Erro no push para ECR:**
- Confirme se o repositório ECR existe
- Verifique se as permissões de push estão configuradas

**Erro na atualização do ECS:**
- Confirme se o cluster e serviço existem
- Verifique as permissões para atualizar serviços ECS
