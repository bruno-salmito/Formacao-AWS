# Scripts de Deploy - Aplicação BIA

Este diretório contém scripts para automatizar o processo de deploy da aplicação BIA na AWS, incluindo build do React, sincronização com S3, push para ECR e atualização do serviço ECS.

## Estrutura dos Scripts

### 📋 deploy.sh
**Script principal de orquestração**

- **Descrição**: Script principal que coordena todo o processo de deploy da aplicação BIA
- **Autor**: Bruno Salmito
- **Versão**: 1.1
- **Funcionalidades**:
  - Verifica a existência de todos os arquivos necessários
  - Carrega variáveis e funções dos outros scripts
  - Executa o processo completo de deploy em sequência:
    1. Build da aplicação React
    2. Sincronização com S3
    3. Push da imagem Docker para ECR
    4. Atualização do serviço ECS
  - Gera logs detalhados de todo o processo

**Uso**: `./deploy.sh`

### 🔧 variables.sh
**Arquivo de configuração global**

- **Descrição**: Define todas as variáveis globais utilizadas pelos scripts
- **Autor**: Bruno Salmito
- **Versão**: 1.0
- **Conteúdo**:
  - Definições de cores para output colorido
  - Configurações AWS (região, conta, perfil)
  - Caminhos de diretórios e arquivos
  - Configurações do ECR (registry, imagem, tag)
  - Configurações do ECS (cluster, serviço, task)
  - URL do endpoint da aplicação

### 📝 log.sh
**Sistema de logging**

- **Descrição**: Fornece funções de logging para todos os scripts
- **Autor**: Bruno Salmito
- **Versão**: 1.0
- **Funcionalidades**:
  - `log_message()`: Registra mensagens com timestamp
  - `log_start()`: Inicia o log com informações do ambiente
  - `log_error()`: Registra erros
  - `log_build()`: Registra mensagens de build
  - `log_end()`: Finaliza o log
- **Arquivo de log**: `/tmp/deploy-app.log`

### ⚛️ react.sh
**Build da aplicação React**

- **Descrição**: Gerencia o processo de build da aplicação React
- **Autor**: Bruno Salmito
- **Versão**: 1.0
- **Funcionalidades**:
  - `build_react()`: Função principal de build
    - Verifica diretório da aplicação
    - Instala dependências npm
    - Executa build com variável de ambiente VITE_API_URL
  - `build_react2()`: Função alternativa (mantida para documentação)
- **Diretório de trabalho**: `bia/client`

### 🪣 s3.sh
**Sincronização com Amazon S3**

- **Descrição**: Gerencia a sincronização dos arquivos buildados com o bucket S3
- **Autor**: Bruno Salmito
- **Versão**: 1.0
- **Funcionalidades**:
  - `sync_to_s3()`: Sincroniza arquivos do build com S3
    - Verifica existência da pasta build
    - Executa sincronização usando AWS CLI
    - Trata erros e gera logs
- **Bucket destino**: Definido na variável `BUCKET_PATH`

### 🐳 ecr.sh
**Gerenciamento do Amazon ECR**

- **Descrição**: Funções para manipulação do ECR (Elastic Container Registry)
- **Autor**: Bruno Salmito
- **Versão**: 1.0
- **Funcionalidades**:
  - `create_ecr_repository()`: Cria repositório ECR (em desenvolvimento)
  - `push_to_ecr()`: Processo completo de push para ECR
  - `login_to_ecr()`: Autentica no ECR
  - `create_image()`: Constrói e tageia imagem Docker
- **Fluxo**: Login → Build → Tag → Push

### 🚀 ecs.sh
**Gerenciamento do Amazon ECS**

- **Descrição**: Atualiza serviços no ECS com force new deployment
- **Autor**: Bruno Salmito
- **Versão**: 1.0
- **Funcionalidades**:
  - `update_ecs_service()`: Atualiza serviço ECS
    - Verifica cluster e serviço
    - Executa update com force new deployment
    - Aguarda estabilização do deployment
  - `verify_cluster_and_service()`: Valida existência e status
  - `get_cluster_info()`: Obtém informações do cluster
- **Aguarda**: Deployment completar antes de finalizar

## Dependências

### Ferramentas Necessárias
- **AWS CLI**: Configurado com perfil adequado
- **Docker**: Para build e push de imagens
- **Node.js/npm**: Para build da aplicação React
- **jq**: Para parsing de JSON (opcional)

### Arquivos Obrigatórios
- `variables.sh`: Configurações globais
- `log.sh`: Sistema de logging
- `react.sh`: Build do React
- `s3.sh`: Sincronização S3
- `ecr.sh`: Gerenciamento ECR
- `ecs.sh`: Gerenciamento ECS

## Fluxo de Execução

1. **Verificação**: Valida existência de todos os scripts necessários
2. **Inicialização**: Carrega variáveis e funções
3. **Build React**: Compila aplicação frontend
4. **Sync S3**: Envia arquivos estáticos para bucket
5. **Docker Build**: Constrói imagem da aplicação
6. **ECR Push**: Envia imagem para repositório
7. **ECS Update**: Atualiza serviço com nova imagem
8. **Finalização**: Registra conclusão nos logs

## Logs

Todos os scripts geram logs detalhados em `/tmp/deploy-app.log` incluindo:
- Timestamps de todas as operações
- Informações do usuário e ambiente
- Status de sucesso/erro de cada etapa
- Detalhes de configuração utilizados

## Configuração

Antes de executar, verifique e ajuste as variáveis em `variables.sh`:
- Credenciais e perfil AWS
- URLs e endpoints
- Nomes de recursos AWS (buckets, repositórios, clusters)
- Caminhos de diretórios

---

**Nota**: O script `build-website-s3.sh` não está documentado conforme solicitado.
