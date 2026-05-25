SELECT 
    category,
    COUNT(*) AS liczba_produktow,
    ROUND(AVG(retail_price)::numeric, 2) AS srednia_cena,
    ROUND(MIN(retail_price)::numeric, 2) AS min_cena,
    ROUND(MAX(retail_price)::numeric, 2) AS max_cena
FROM products
GROUP BY category
ORDER BY liczba_produktow DESC;

SELECT 
    p.category,
    COUNT(oi.id) AS liczba_sprzedazy,
    ROUND(SUM(oi.sale_price)::numeric, 2) AS przychod_total,
    ROUND(AVG(oi.sale_price)::numeric, 2) AS srednia_cena_sprzedazy,
    ROUND(AVG(p.retail_price - p.cost)::numeric, 2) AS srednia_marza
FROM order_items oi
JOIN products p ON oi.product_id = p.id
WHERE oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY p.category
ORDER BY przychod_total DESC;

SELECT 
    p.category,
    COUNT(*) AS wszystkie_zamowienia,
    SUM(CASE WHEN oi.status = 'Returned' THEN 1 ELSE 0 END) AS zwroty,
    ROUND(100.0 * SUM(CASE WHEN oi.status = 'Returned' THEN 1 ELSE 0 END) / COUNT(*), 1) AS procent_zwrotow
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY p.category
ORDER BY procent_zwrotow DESC;

SELECT 
    segment,
    COUNT(*) AS liczba_klientow,
    ROUND(AVG(srednia_ilosc_produktow)::numeric, 1) AS avg_produktow
FROM (
    SELECT 
        o.user_id,
        CASE 
            WHEN COUNT(o.order_id) = 1 THEN 'Nowy'
            WHEN COUNT(o.order_id) BETWEEN 2 AND 5 THEN 'Powracający'
            ELSE 'VIP'
        END AS segment,
        AVG(o.num_of_item) AS srednia_ilosc_produktow
    FROM orders o
    WHERE o.status = 'Complete'
    GROUP BY o.user_id
) sub
GROUP BY segment
ORDER BY liczba_klientow DESC;

SELECT 
    DATE_TRUNC('month', o.created_at::timestamp) AS miesiac,
    COUNT(DISTINCT o.order_id) AS liczba_zamowien,
    ROUND(SUM(oi.sale_price)::numeric, 2) AS przychod,
    ROUND(AVG(oi.sale_price)::numeric, 2) AS avg_wartosc_zamowienia
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY DATE_TRUNC('month', o.created_at::timestamp)
ORDER BY miesiac;

WITH miesięczny_przychod AS (
    SELECT 
        DATE_TRUNC('month', o.created_at::timestamp) AS miesiac,
        ROUND(SUM(oi.sale_price)::numeric, 2) AS przychod
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE oi.status NOT IN ('Cancelled', 'Returned')
    GROUP BY DATE_TRUNC('month', o.created_at::timestamp)
)
SELECT 
    miesiac,
    przychod,
    LAG(przychod) OVER (ORDER BY miesiac) AS przychod_poprzedni_miesiac,
    ROUND(100.0 * (przychod - LAG(przychod) OVER (ORDER BY miesiac)) 
          / LAG(przychod) OVER (ORDER BY miesiac), 1) AS zmiana_procent
FROM miesięczny_przychod
ORDER BY miesiac;