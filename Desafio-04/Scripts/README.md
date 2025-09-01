# Scripts AWS - Desafio 04

Este diretório contém scripts para automação e gerenciamento de recursos AWS, incluindo EC2, RDS, Route 53 e S3.

## Scripts Principais

### `main.sh`
Script principal que orquestra a execução dos demais scripts. Verifica a existência dos arquivos necessários e coordena as operações.

**Dependências:**
- `log.sh`
- `variables.sh`
- `create_tunnel.sh`
- `ec2.sh`

### `ec2.sh`
Script completo para gerenciamento de instâncias EC2.

**Funcionalidades:**
- Validação de instâncias
- Verificação de status
- Start/stop de instâncias
- Criação e gerenciamento de instâncias EC2

**Autor:** Bruno Salmito  
**Versão:** 0.3

### `manage_ec2.sh`
Script para gerenciamento automatizado de instâncias EC2 baseado no status atual.

**Uso:**
```bash
./manage_ec2.sh <instance-id>
```

**Exemplo:**
```bash
./manage_ec2.sh i-1234567890abcdef0
```

### `create_ec2_instance.sh`
Script interativo para criação de instâncias EC2 com seleção de VPC e subnet.

**Funcionalidades:**
- Verificação de configuração AWS CLI
- Seleção interativa de VPC e subnet
- Criação de instâncias EC2 personalizadas

**Região padrão:** us-east-1

### `create_tunnel.sh`
Script para criação de túneis SSH para instâncias EC2 e RDS.

**Funcionalidades:**
- Validação de endpoints RDS
- Criação de túneis SSH diretos para EC2
- Criação de túneis RDS via bastion-host
- Criação de túneis genéricos via bastion-host para qualquer destino
- Conexão segura com recursos AWS

**Funções principais:**
- `create_simple_tunnel()` - Túnel direto para EC2
- `create_rds_tunnel()` - Túnel para RDS via bastion
- `create_bastion_tunnel()` - Túnel genérico via bastion-host

**Autor:** Bruno Salmito  
**Versão:** 1.0

### `setup_route53_s3.sh`
Script para configuração do Route 53 apontando para sites estáticos no S3.

**Funcionalidades:**
- Configuração de DNS no Route 53
- Integração com buckets S3 para sites estáticos
- Gerenciamento de registros DNS

**Autor:** Bruno Salmito  
**Versão:** 1.0

## Scripts de Suporte

### `log.sh`
Biblioteca de funções para logging dos scripts.

**Funcionalidades:**
- Sistema de logging centralizado
- Arquivo de log: `/tmp/desafio-04.log`
- Timestamps automáticos
- Identificação de usuário

**Autor:** Bruno Salmito  
**Versão:** 1.0

### `variables.sh`
Arquivo de variáveis globais compartilhadas entre os scripts.

**Conteúdo:**
- Definições de cores para output
- Variáveis de configuração global

**Autor:** Bruno Salmito  
**Versão:** 1.0

## Diretórios

### `UserData/`
Contém scripts de inicialização para instâncias EC2.

**Arquivos:**
- `user_data.sh` - Script de user data para configuração inicial de instâncias

### `old/`
Diretório com versões antigas dos scripts (backup).

## Pré-requisitos

- AWS CLI configurado
- Bash shell
- Permissões adequadas para recursos AWS
- Chaves SSH configuradas (para túneis)

## Uso Geral

1. Configure o AWS CLI: `aws configure`
2. Torne os scripts executáveis: `chmod +x *.sh`
3. Execute o script principal: `./main.sh`

## Estrutura de Dependências

```
main.sh
├── log.sh
├── variables.sh
├── create_tunnel.sh
└── ec2.sh
    └── manage_ec2.sh
```

## Logs

Todos os scripts utilizam o sistema de logging centralizado que grava em `/tmp/desafio-04.log`.
