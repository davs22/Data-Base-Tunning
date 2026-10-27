-- =====================================================================
-- Projeto AP1 - Linha de Base (Workload)
-- Alvo: PostgreSQL 15 / Banco: adventureworks
-- =====================================================================

-- Consulta 1: Desempenho de Vendas por Categoria e Território (Múltiplos Joins e Agregação)
SELECT
    t.name AS territory_name,
    c.name AS category_name,
    EXTRACT(YEAR FROM h.orderdate) AS order_year,
    SUM((d.orderqty * d.unitprice) * (1 - d.unitpricediscount)) AS total_sales,
    COUNT(DISTINCT h.salesorderid) AS total_orders
FROM sales.salesorderheader h
JOIN sales.salesorderdetail d ON h.salesorderid = d.salesorderid
JOIN production.product p ON d.productid = p.productid
JOIN production.productsubcategory sc ON p.productsubcategoryid = sc.productsubcategoryid
JOIN production.productcategory c ON sc.productcategoryid = c.productcategoryid
JOIN sales.salesterritory t ON h.territoryid = t.territoryid
WHERE h.status = 5 
GROUP BY t.name, c.name, EXTRACT(YEAR FROM h.orderdate)
ORDER BY total_sales DESC;

-- Consulta 2: Ranking de Clientes VIPs com Base no Histórico (Função de Janela RANK)
WITH CustomerSales AS (
    SELECT
        c.customerid,
        p.firstname || ' ' || p.lastname AS fullname,
        SUM(h.totaldue) AS total_spent,
        MAX(h.orderdate) AS last_purchase_date
    FROM sales.customer c
    JOIN person.person p ON c.personid = p.businessentityid
    JOIN sales.salesorderheader h ON c.customerid = h.customerid
    GROUP BY c.customerid, p.firstname, p.lastname
)
SELECT
    customerid,
    fullname,
    total_spent,
    last_purchase_date,
    RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
FROM CustomerSales
WHERE total_spent > 10000
ORDER BY spend_rank;

-- Consulta 3: Análise de Prejuízo na Produção (Cálculo Matemático e Agrupamento)
SELECT
    p.name AS product_name,
    sr.name AS scrap_reason,
    SUM(wo.scrappedqty) AS total_scrapped,
    SUM(wo.scrappedqty * p.standardcost) AS total_loss_value
FROM production.workorder wo
JOIN production.product p ON wo.productid = p.productid
JOIN production.scrapreason sr ON wo.scrapreasonid = sr.scrapreasonid
WHERE wo.scrappedqty > 0
GROUP BY p.name, sr.name
ORDER BY total_loss_value DESC;