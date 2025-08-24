# Formação AWS - Curso com Henrylle Maia

Este repositório contém os materiais e registros dos desafios práticos realizados durante o curso **Formação AWS** ministrado por **Henrylle Maia**.  
O objetivo é documentar de forma clara e organizada cada passo executado, desde a preparação do ambiente local até a implementação de soluções completas na AWS.

## Sobre o curso
O curso **Formação AWS** é focado em criar uma base sólida em serviços da **Amazon Web Services**, combinando teoria e prática.  
Ao longo das aulas, são realizados diversos **desafios práticos** que simulam cenários reais de mercado, envolvendo:

- Criação e configuração de ambientes locais e na nuvem.
- Utilização de serviços AWS como EC2, IAM, VPC e SSM.
- Integração com ferramentas DevOps como Docker, Git, VSCode, Amazon Q e DBeaver.
- Deploy e testes de aplicações web.

## Desafios Realizados

### [Desafio 01 - Preparação do ambiente e implantação inicial na AWS](Desafio-01/README.md)
Neste desafio foi feita a instalação e configuração do ambiente local com Docker, Git, Amazon Q, VSCode e DBeaver.  
Também foi realizado o **build** e teste de uma aplicação React chamada **Bia** localmente na porta 3001, além do provisionamento de uma instância EC2 na AWS com Security Group, Role IAM e acesso via SSM.

### [Desafio 02 - Preparação do ambiente e conexão com AWS via cli e publicação no ECR](Desafio-02/README.md)
O objetivo deste desafio foi configurar o acesso à AWS a partir do meu computador rodando Linux, testar diferentes formas de conexão com instâncias EC2 (SSH e SSM), trabalhar com imagens Docker e publicá-las no Amazon ECR. 

### [Desafio 03 - Deploy da BIA no ECS + Assets no S3](Desafio-03/README.md)
O objetivo deste desafio foi colocar a aplicação **BIA** rodando em um **Cluster ECS (bia-web)**, com os **assets estáticos** sendo entregues a partir de um bucket S3 configurado como **site estático**.  
Além disso, construímos nossa primeira rotina de deploy utilizando **Shell Script**, garantindo a separação entre a entrega do frontend e backend do projeto.


<<<<<<< HEAD
### [Desafio 04 - Automação com Shell Script + EC2 Porteiro + Túnel SSM](Desafio-04/README.md)
Neste desafio, o foco foi criar **scripts em Shell Script** para automatizar o processo de lançar e gerenciar uma instância EC2 utilizada como “porteiro”.  
A instância foi configurada para permitir o acesso seguro ao banco de dados RDS e à aplicação BIA via túneis SSM.

<hr>
=======
### [Desafio 04 - Deploy da BIA no ECS + Assets no S3](Desafio-04/README.md)
Neste desafio, o foco foi criar **scripts em Shell Script** para automatizar o processo de lançar e gerenciar uma instância EC2 utilizada como “porteiro”.  
A instância foi configurada para permitir o acesso seguro ao banco de dados RDS e à aplicação BIA via túneis SSM.
---
>>>>>>> 3cc91f7710b9ba2ae9d47586d9829ebcca10bc0a



*(Os próximos desafios serão adicionados conforme avançamos no curso.)*

### Estrutura do Repositório

```plaintext
Formacao-AWS
 ├── README.md             # Visão geral do curso e índice de desafios
 ├── Desafio-01
 │    └── README.md         # Documentação completa do desafio 01
 ├── Desafio-02
 │    └── README.md         # Documentação completa do desafio 02
 ├── Desafio-03
 │    └── README.md         # Documentação completa do desafio 03
 ├── Desafio-04
 │    └── README.md         # Documentação completa do desafio 04
