-- =====================================================================
-- Aplicação de Índices
-- Alvo: Eliminação de Seq Scan, conversão de Nested Loops e otimização de joins
-- =====================================================================

-- ---------------------------------------------------------------------
-- Otimização da Consulta 1 (Vendas por Categoria e Território)
-- ---------------------------------------------------------------------
-- Justificativa: Cria índice parcial cobrindo apenas pedidos concluídos (status = 5), 
-- reduzindo o tamanho da árvore B+ e otimizando a junção com a tabela de territórios.
CREATE INDEX IF NOT EXISTS idx_soh_status_territory 
ON sales.salesorderheader(territoryid) 
WHERE status = 5;

-- Justificativa: Indexa a chave composta de detalhes de pedidos para agilizar o JOIN com a tabela de produtos.
CREATE INDEX IF NOT EXISTS idx_sod_order_product 
ON sales.salesorderdetail(salesorderid, productid);

-- Justificativa: Indexa a FK de subcategoria na tabela de produtos para acelerar a navegabilidade do JOIN.
CREATE INDEX IF NOT EXISTS idx_product_subcategory 
ON production.product(productsubcategoryid);


-- ---------------------------------------------------------------------
-- Otimização da Consulta 2 (Ranking de Clientes VIPs)
-- ---------------------------------------------------------------------
-- Justificativa: Indexa a FK de cliente na tabela de cabeçalho de vendas, eliminando a varredura sequencial no JOIN.
CREATE INDEX IF NOT EXISTS idx_soh_customer 
ON sales.salesorderheader(customerid);

-- Justificativa: Indexa a FK de pessoa na tabela de clientes.
CREATE INDEX IF NOT EXISTS idx_customer_person 
ON sales.customer(personid);


-- ---------------------------------------------------------------------
-- Otimização da Consulta 3 (Análise de Prejuízo na Produção)
-- ---------------------------------------------------------------------
-- Justificativa: Cria índice parcial focado apenas em ordens com sucata (scrappedqty > 0). 
-- Evita indexar milhões de ordens sem perda, tornando o índice leve e de altíssima seletividade.
CREATE INDEX IF NOT EXISTS idx_workorder_scrapped 
ON production.workorder(productid, scrapreasonid) 
WHERE scrappedqty > 0;