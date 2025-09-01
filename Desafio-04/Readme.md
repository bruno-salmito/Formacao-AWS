# Desafio 04 - Automação com Shell Script: EC2 Porteiro + Túneis SSM

## 🎯 Objetivo
O objetivo deste desafio foi criar rotinas em **Shell Script** para gerenciar recursos na AWS, com foco em uma instância **EC2 Porteiro**, que funciona como bastion host para acesso seguro ao banco de dados e à aplicação.

**Etapas propostas:**
- Criar um script que lança uma **EC2 Porteiro** na subnet default (zona b).  
- Criar um script que inicia o porteiro e estabelece um túnel SSM para o **RDS**, redirecionando a porta **5432** para a **5433** local, permitindo inserir um registro manual em tabela.  
- Criar um túnel para a aplicação **BIA**, acessando-a pela porta local **3002** para validar o registro no banco.  
- Criar um script que encerra a instância EC2 Porteiro.  

---

## 🛠️ Passos Executados

### 1️⃣ Automação da EC2 Porteiro
- Desenvolvi um **script em shell (ec2.sh)** para criar e gerenciar a EC2 porteiro.  
- O script inclui:
  - Validação de instâncias existentes.  
  - Criação de EC2 na **zona b**.  
  - Execução de **userdata** para configuração inicial.  

**Conceito:**  
- *Bastion Host (Porteiro)*: instância usada como ponto de entrada para acessar recursos privados da VPC de forma controlada.  
- *Userdata*: script executado automaticamente no primeiro boot da EC2.  

---

### 2️⃣ Criação do Túnel para o RDS
- Utilizei o **script create_tunnel.sh** para estabelecer um **túnel seguro via SSM**.  
- Redirecionei a porta **5432** do RDS para a porta **5433** local.  
- Conectei ao banco pelo **DBeaver** e inseri um registro manual na tabela.  

**Comando utilizado:**
```bash
aws ssm start-session \
  --target <INSTANCE_ID_PORTEIRO> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<ENDPOINT_RDS>"],"portNumber":["5432"],"localPortNumber":["5433"]}'
```

3️⃣ Túnel para a Aplicação BIA

Criei outro túnel via SSM para acessar a aplicação BIA na porta 3002.

A aplicação rodou localmente, permitindo validar o registro inserido no banco.

Comando utilizado:

```bash
aws ssm start-session \
  --target <INSTANCE_ID_PORTEIRO> \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["3002"],"localPortNumber":["3002"]}'
```


4️⃣ Encerramento da EC2 Porteiro

Desenvolvi um script para parar/terminar a instância EC2 quando não fosse mais necessária, evitando custos desnecessários.

Comando exemplo:

```bash
aws ec2 terminate-instances --instance-ids <INSTANCE_ID_PORTEIRO>
```

✅ Resultado Final

Ao final do desafio:

- Scripts criados para lançar, gerenciar e encerrar a EC2 Porteiro.
- Túnel seguro para o RDS configurado via porta local 5433.
- Registro manual adicionado no banco via DBeaver.
- Túnel configurado para a aplicação BIA na porta 3002, validando integração entre frontend e banco.
- Processo de automação garantiu maior segurança e praticidade no gerenciamento dos recursos.

📚 Conceitos Abordados

- Shell Script: automação de tarefas e criação de rotinas de deploy.
- EC2: instâncias virtuais na AWS.
- Userdata: configuração inicial automática da EC2.
- AWS CLI: interface para gerenciar recursos AWS via terminal.
- SSM (Systems Manager): acesso seguro a instâncias sem abrir portas na internet.
- Túnel SSM (Port Forwarding): redirecionamento seguro de portas para acessar serviços internos.
- RDS: banco de dados relacional gerenciado.
- DBeaver: ferramenta de gerenciamento de bancos de dados.
- Bastion Host (Porteiro): instância que funciona como intermediária para conexões seguras.
- Segurança e Custos: uso do porteiro apenas quando necessário, evitando exposição e reduzindo gastos.