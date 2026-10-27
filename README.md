# Database Tuning — AdventureWorks

Projeto acadêmico de análise e otimização de consultas no PostgreSQL usando a base AdventureWorks. O trabalho compara planos de execução de um workload analítico antes e depois da criação de índices.

## Objetivos

- Medir consultas com `EXPLAIN ANALYZE`.
- Investigar filtros, junções e agregações nos planos do PostgreSQL.
- Aplicar índices simples, compostos e parciais e observar a escolha do otimizador.

## Tecnologias e dados

- PostgreSQL 15 em contêiner Docker Compose.
- AdventureWorks for Postgres, com tabelas distribuídas pelos esquemas `sales`, `production`, `person`, `purchasing` e `humanresources`.
- Três consultas: vendas por categoria e território, ranking de clientes e perdas por sucata na produção.

## Estrutura do projeto

```text
.
├── docker-compose.yml
├── scripts/
│   ├── workload_consultas.sql   # Consultas usadas na análise
│   └── 02_criacao_indices.sql   # Índices propostos para o workload
├── docs/
│   └── AP1_Relatorio.md
└── AdventureWorks-for-Postgres-master/ # SQL de instalação e arquivos CSV da base
```

## Pré-requisitos

- Docker e Docker Compose (`docker compose`)
- Arquivos CSV da base, presentes em `AdventureWorks-for-Postgres-master/`

## Como executar

Na raiz do repositório, inicie o PostgreSQL:

```bash
docker compose up -d
```

Carregue as tabelas e os dados no banco `adventureworks`:

```bash
docker compose exec -T postgres-tuning psql -U srdiirr -d adventureworks -f /var/lib/postgresql/AdventureWorks/install.sql
```

O carregamento pode levar alguns minutos. O `install.sql` importa os CSVs montados no contêiner e cria a estrutura da base.

## Análise do workload

Execute as consultas de `scripts/workload_consultas.sql` para coletar a linha de base. Para inspecionar o plano e o tempo de cada consulta, prefixe-a com:

```sql
EXPLAIN (ANALYZE, BUFFERS)
```

Em seguida, aplique os índices definidos em `scripts/02_criacao_indices.sql`. Como o arquivo está no host, copie-o para o contêiner e execute-o:

```bash
docker cp scripts/02_criacao_indices.sql db_tuning_unisales:/tmp/02_criacao_indices.sql
docker compose exec -T postgres-tuning psql -U srdiirr -d adventureworks -f /tmp/02_criacao_indices.sql
```

Repita as medições do workload e compare os planos e tempos antes e depois dos índices. Em bases pequenas, o PostgreSQL pode continuar escolhendo `Seq Scan`; isso é uma decisão baseada no custo estimado e não significa que o índice deixou de ser criado.

## Relatório

O relatório com a caracterização do ambiente, a análise dos planos e as limitações observadas está em [`docs/AP1_Relatorio.md`](docs/AP1_Relatorio.md).

## Encerrar o ambiente

```bash
docker compose down
```

Para remover também os dados persistidos do PostgreSQL:

```bash
docker compose down -v
```

O Compose usa credenciais padrão para execução local. Troque a senha antes de expor o serviço à rede.
