# Relatório de Tunning de Banco de Dados - AP1
**Aluno:** Matheus Diirr Aguiar Veiga de Souza  
**Disciplina:** Data Base Tunning  

## 1. Caracterização do Ambiente
- **SGBD:** PostgreSQL 15 (executado via contêiner Docker isolado).
- **Base de Dados Objeto de Estudo:** AdventureWorks (Cenário OLTP).
- **Volume e Modelo de Dados:** 68 tabelas ativas distribuídas em múltiplos esquemas organizacionais (`sales`, `production`, `person`, `purchasing`, `humanresources`).
- **Hardware de Experimentação:** Processador AMD Ryzen 5 5600G, 16 GB de RAM, SSD NVMe 2.0 e GPU RTX 4060.
*Nota de Contexto:* Embora o hardware local possua alta taxa de transferência (I/O) e processamento rápido, os gargalos lógicos de varredura sequencial e ordenação em memória permanecem presentes nas operações complexas e serão o foco da otimização algorítmica.

## 2. Carga de Trabalho Analisada (Workload)
Para o diagnóstico de desempenho, foram arquitetadas 3 consultas complexas simulando gargalos reais de análise de dados:
1. **Desempenho de Vendas por Categoria:** Múltiplas junções estruturais (`JOIN`) e agregações de totalização.
2. **Ranking de Clientes VIPs:** Uso intenso de funções de janela (`RANK() OVER`) e subconsultas em memória (`CTE`).
3. **Análise de Prejuízo na Produção:** Junções e agregações com cálculos matemáticos aplicados a linhas filtradas.

## 3. Linha de Base de Desempenho (Baseline)
O comportamento do otimizador de consultas (sem a aplicação de índices adicionais ou reescrita) foi mapeado via `EXPLAIN ANALYZE`, obtendo os seguintes indicadores iniciais:
- **Consulta 1:** Custo total estimado de 0.13. Tempo de execução de 0.322 ms. Estruturas utilizadas: `Nested Loops`, `GroupAggregate` e múltiplas varreduras sequenciais (`Seq Scan`).
- **Consulta 2:** Custo total estimado de 0.11. Tempo de execução de 0.197 ms. Estruturas utilizadas: Agrupamento em hash (`HashAggregate`) e função de agregação de janela (`WindowAgg`) com ordenação na memória (`quicksort`).
- **Consulta 3:** Custo total estimado de 0.07. Tempo de execução de 0.138 ms. Estruturas utilizadas: `HashAggregate` combinado com `Nested Loop` para varredura física sequencial das tabelas de produção.

## 4. Diagnóstico e Análise de Planos de Execução
Com base nas coletas do `EXPLAIN ANALYZE`, identificamos três grandes ofensores de desempenho que explicam o custo elevado das consultas atuais:

1. **Gargalo de Filtragem (Seq Scan):** 
   - **Diagnóstico:** O SGBD realizou varreduras sequenciais completas nas tabelas (ex: `salesorderheader`), lendo todos os blocos de dados para encontrar registros específicos, resultando em alto custo de Entrada e Saída (I/O) e complexidade de tempo $O(N)$.
   - **Solução Proposta:** Criação de índices B-Tree nas colunas utilizadas nas cláusulas `WHERE` (ex: `status`, `scrappedqty`) para viabilizar o *Index Scan*.

2. **Gargalo de Junção (Nested Loops em cascata):** 
   - **Diagnóstico:** A ausência de índices nas chaves estrangeiras forçou o otimizador a utilizar laços aninhados cegos para resolver os `JOINs`. Em consultas com 5 a 6 tabelas transacionais conectadas, isso gera uma degradação severa devido ao produto cartesiano lógico das comparações iterativas.
   - **Solução Proposta:** Indexação das colunas de ligação (Foreign Keys) para permitir que o otimizador escolha algoritmos mais eficientes, como `Hash Join` ou `Merge Join`.

3. **Gargalo de Ordenação e Agregação (Quicksort / HashAggregate):**
   - **Diagnóstico:** As operações de agregação (`SUM`, `GROUP BY`) e as funções de janela (`RANK() OVER`) foram resolvidas em memória (via `quicksort` e agrupamentos de hash). Em cenários de crescimento de volume de dados, isso causará transbordamento de memória para o disco (*temp files*).
   - **Solução Proposta:** Uso estratégico de índices, visto que estruturas em árvore B+ armazenam os dados de forma pré-ordenada, isentando a CPU de alocar espaço de trabalho (`work_mem`) para executar ordenações no momento da consulta.