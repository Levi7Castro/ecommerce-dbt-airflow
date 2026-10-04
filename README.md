# Projeto dbt: E-commerce

Pipeline de dados de e-commerce em PostgreSQL, com transformações em dbt e orquestração diária pelo Apache Airflow. Os dados de exemplo estão em arquivos CSV e passam pelas camadas bronze, silver e gold até a tabela de vendas por item.

## Arquitetura

```text
CSV (seeds)
    -> bronze_raw: tabelas de origem
    -> bronze: views sobre as origens
    -> silver: tabelas com campos padronizados e tipos ajustados
    -> gold: fct_pedidos_vendidos
```

| Camada | Materialização | Conteúdo |
| --- | --- | --- |
| `bronze_raw` | Seeds (tabelas) | Avaliações, carrinho, categorias, clientes, itens de pedidos, pagamentos, pedidos e produtos |
| `bronze` | Views | Oito modelos que consultam a source `ecomerce` |
| `silver` | Tabelas | Oito modelos com renomeação de colunas, limpeza de espaços, normalização de textos e conversão de valores monetários |
| `gold` | Tabela | Fato de itens vendidos, enriquecida com cliente, produto, categoria e pagamento |

A macro `generate_schema_name` usa os nomes de schemas configurados diretamente, sem adicionar o prefixo do schema do target.

### Regra de vendas

O modelo `gold.fct_pedidos_vendidos` considera pedidos com status `concluído` e pagamento com status `pago`. O grão é uma linha por combinação de pedido e produto, identificada por `item_pedido_id`.

A receita fica em `valor_venda`, que usa o subtotal do item. O valor total do pagamento não é repetido nos itens. O modelo pressupõe um pagamento por pedido; essa condição é verificada por um teste de unicidade em `silver_pagamentos.pedido_id`.

## Tecnologias

- Python 3.12 ou superior e `uv` para o ambiente local.
- `dbt-core >= 1.12.5` e `dbt-postgres >= 1.11.0` nas dependências locais.
- Apache Airflow 3.3.0 com `LocalExecutor` no Docker Compose.
- Ambiente dbt separado dentro da imagem Airflow, com `dbt-core==1.12.5` e `dbt-postgres==1.11.0`.
- PostgreSQL para o data warehouse e PostgreSQL 16 para os metadados do Airflow.

## Estrutura

```text
.
├── README.md
├── .env.example                 # Exemplo de configuração
├── pyproject.toml               # Dependências Python
├── uv.lock
├── docker-compose.yml           # Serviços Airflow e banco de metadados
├── airflow/
│   ├── Dockerfile               # Airflow com ambiente dbt separado
│   ├── dags/dbt_build_projeto_01.py
│   └── dbt_profiles/profiles.yml
└── projeto_01/
    ├── dbt_project.yml
    ├── models/
    │   ├── bronze/
    │   ├── silver/
    │   └── gold/
    ├── seeds/                   # Oito arquivos CSV
    ├── macros/generate_schema_name.sql
    └── tests/generic/valid_email.sql
```

## Configuração

É necessário ter Docker com Compose para executar o Airflow e um PostgreSQL acessível para o data warehouse. Para executar dbt pelo terminal, instale também Python e `uv`.

Na raiz do repositório, crie o arquivo de configuração caso ele ainda não exista:

```bash
cp -n .env.example .env
```

Edite `.env` com os valores do seu ambiente:

| Variável | Uso |
| --- | --- |
| `AIRFLOW_UID` | UID do usuário usado pelos containers; consulte com `id -u` |
| `DBT_HOST` | Host do PostgreSQL do data warehouse |
| `DBT_PORT` | Porta do PostgreSQL, normalmente `5432` |
| `DBT_USER` | Usuário do data warehouse |
| `DBT_PASSWORD` | Senha do usuário |
| `DBT_DBNAME` | Banco do data warehouse |
| `AIRFLOW_JWT_SECRET` | Chave compartilhada pelos serviços Airflow |

Gere uma chave para `AIRFLOW_JWT_SECRET`:

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

O banco indicado por `DBT_DBNAME` deve existir, e o usuário precisa de permissão para criar schemas, tabelas e views. O serviço `postgres` do Compose armazena apenas os metadados do Airflow; ele não provisiona o data warehouse.

Se o data warehouse estiver no WSL e os containers forem executados pelo Docker Desktop, configure `DBT_HOST` com o IP do WSL acessível aos containers. Consulte os endereços com `hostname -I`; o IP pode mudar após reiniciar o WSL. Nesse cenário, `host.docker.internal` aponta para o Windows, conforme a configuração descrita em `.env.example`.

O arquivo `.env` está no `.gitignore`. Não publique credenciais no repositório.

## Executar dbt Localmente

Os comandos abaixo são executados na raiz do repositório e usam o profile versionado em `airflow/dbt_profiles`:

```bash
uv sync --locked

set -a
source .env
set +a

uv run dbt debug --project-dir projeto_01 --profiles-dir airflow/dbt_profiles
uv run dbt build --project-dir projeto_01 --profiles-dir airflow/dbt_profiles
```

`dbt debug` verifica a configuração e a conexão. `dbt build` carrega os seeds, materializa os modelos e executa os testes respeitando as dependências do projeto.

Para executar etapas separadamente:

```bash
uv run dbt seed --project-dir projeto_01 --profiles-dir airflow/dbt_profiles
uv run dbt run --project-dir projeto_01 --profiles-dir airflow/dbt_profiles
uv run dbt test --project-dir projeto_01 --profiles-dir airflow/dbt_profiles
```

Após a carga inicial, é possível reconstruir apenas a camada gold:

```bash
uv run dbt build --select tag:gold --project-dir projeto_01 --profiles-dir airflow/dbt_profiles
```

## Executar com Airflow

Com `.env` configurado, execute na raiz:

```bash
docker compose up airflow-init --build
docker compose up -d airflow-apiserver airflow-scheduler airflow-dag-processor
docker compose ps
```

Acesse [http://localhost:8091](http://localhost:8091). A configuração local permite acesso direto como administrador, sem tela de login.

A DAG `dbt_build_projeto_01` é criada pausada. Ative-a para habilitar o agendamento diário ou dispare uma execução manual pela interface.

```text
dbt_debug -> dbt_build
```

- Agendamento: `@daily`, com início configurado em 1 de outubro de 2026.
- `catchup=False`: não executa automaticamente todos os intervalos passados.
- Cada tarefa tem uma nova tentativa após dois minutos em caso de falha.
- O projeto dbt é montado em `/opt/airflow/dbt/projeto_01`.
- Os artefatos dbt ficam em `/tmp/dbt_target` e `/tmp/dbt_logs` dentro do container, separados dos artefatos locais.

Para acompanhar os serviços ou encerrá-los:

```bash
docker compose logs -f airflow-scheduler airflow-dag-processor airflow-apiserver
docker compose down
```

`docker compose down` preserva o volume do banco de metadados.

## Qualidade dos Dados

Os testes estão definidos nas sources e nos modelos silver e gold:

- `not_null` e `unique` para campos obrigatórios e chaves.
- `relationships` para referências entre clientes, pedidos, produtos e categorias.
- `accepted_values` para status de pedidos, status de pagamentos e notas de avaliações.
- `valid_email`, teste genérico que valida o formato dos e-mails com expressão regular no PostgreSQL. Valores nulos são ignorados por esse teste.

As transformações silver padronizam os dados; os testes de unicidade identificam duplicatas, mas não as removem.

## Documentação dbt

Com as variáveis de `.env` carregadas no terminal:

```bash
uv run dbt docs generate --project-dir projeto_01 --profiles-dir airflow/dbt_profiles
uv run dbt docs serve --project-dir projeto_01 --profiles-dir airflow/dbt_profiles --port 8082
```

A documentação fica disponível em [http://localhost:8082](http://localhost:8082), com descrições, colunas, testes e dependências dos modelos.
