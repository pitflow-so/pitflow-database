# Deploy da infraestrutura de bancos do Pitflow

## Características do ambiente

Este é um ambiente acadêmico, descartável e reconstruído com frequência. A configuração segue práticas próximas de produção — isolamento por usuário, state remoto e credenciais externas — mas aplica automaticamente o plano e não preserva dados quando o laboratório remove os recursos.

## Recursos

- uma instância RDS PostgreSQL 16 `db.t3.micro`, Single-AZ e 20 GiB;
- quatro bancos lógicos com usuários exclusivos: operation, inventory, registry e payment;
- uma tabela DynamoDB on-demand para o orquestrador SAGA;
- um security group para PostgreSQL;
- nenhum recurso IAM ou service-linked role criado por este repositório.

## Pré-requisitos

1. Iniciar o AWS Learner Lab.
2. Atualizar `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN` nos GitHub Secrets.
3. Executar o `pitflow-bootstrap` para garantir que `pitflow/bootstrap` exista com as credenciais padronizadas.
4. Confirmar que o bucket S3 do backend e o Terraform state estão acessíveis.

## Fluxo do workflow

O workflow é executado em pushes na `main` que alterem a infraestrutura ou manualmente por `workflow_dispatch`. Não possui parâmetros.

Em uma única execução ele:

1. configura as credenciais temporárias AWS;
2. executa `terraform init`, `fmt -check` e `validate`;
3. gera e aplica o plano Terraform;
4. executa o bootstrap idempotente dos quatro bancos e usuários PostgreSQL;
5. atualiza os endpoints e dados não sensíveis do DynamoDB no secret.

Se o laboratório tiver removido os recursos, uma nova execução os cria. Se as credenciais temporárias estiverem ausentes ou expiradas, a configuração oficial de credenciais AWS falha e nenhuma etapa Terraform é aplicada.

## Rede e security group

Um security group é o firewall virtual da AWS associado ao RDS. Ele define quais conexões de rede podem entrar ou sair da instância, independentemente do usuário e da senha configurados no PostgreSQL.

O recurso `pitflow-rds-sg` possui atualmente:

- entrada TCP na porta PostgreSQL `5432`;
- origem padrão `0.0.0.0/0`, que representa qualquer endereço IPv4;
- saída liberada para qualquer destino.

A abertura pública permite que o runner hospedado do GitHub Actions, cujo endereço IP pode variar, execute o bootstrap PostgreSQL. `publicly_accessible = true` torna o RDS alcançável pela internet, enquanto o security group permite efetivamente a conexão na porta 5432. Ainda é necessário autenticar com usuário e senha válidos.

Essa regra é aceitável somente para a simplicidade deste laboratório descartável. Em uma arquitetura de produção, o recomendado seria:

- manter o RDS privado;
- permitir entrada apenas a partir do security group dos pods/serviços;
- executar migrations e bootstrap dentro da VPC;
- ou adicionar temporariamente o IP do runner durante o deploy e remover a regra ao final.

A lista de origens é controlada pela variável Terraform `allowed_postgres_cidr_blocks`. Seu valor padrão permanece `0.0.0.0/0` para que o workflow atual consiga conectar sem infraestrutura adicional de rede.

## Propriedade dos campos do secret

O `pitflow-bootstrap` é responsável por nomes, usuários, senhas e demais configurações da aplicação. Depois do deploy, este repositório mescla apenas os valores dinâmicos:

- `PITFLOW_OPERATION_DB_HOST` e `PITFLOW_OPERATION_DB_PORT`;
- `PITFLOW_INVENTORY_DB_HOST` e `PITFLOW_INVENTORY_DB_PORT`;
- `PITFLOW_REGISTRY_DB_HOST` e `PITFLOW_REGISTRY_DB_PORT`;
- `PITFLOW_PAYMENT_DB_HOST` e `PITFLOW_PAYMENT_DB_PORT`;
- `PITFLOW_ORCHESTRATOR_TABLE_NAME`;
- `PITFLOW_ORCHESTRATOR_AWS_REGION`.

Os quatro bancos PostgreSQL compartilham host e porta, mas possuem nomes, usuários e senhas diferentes. O DynamoDB usa IAM e não possui username, password, host ou porta.

## Segurança dos valores

- O workflow não imprime o conteúdo do secret.
- A atualização usa arquivos temporários do runner, removidos ao final do step.
- O script PostgreSQL lê credenciais diretamente do Secrets Manager.
- Nenhuma senha é exposta em outputs Terraform.
- O arquivo de plano não é publicado como artifact.

O password master necessário pelo recurso RDS continua sendo tratado como atributo sensível pelo provider AWS e pode existir de forma sensível no Terraform state. O state remoto deve permanecer restrito.
