
CREATE OR REPLACE FUNCTION public.client_metric(client_id INT, left_boundary DATE, right_boundary DATE)
RETURNS TABLE (metric_name text,
			   metric_value text)
LANGUAGE sql
AS $$
-- customer's name, surname and email address
SELECT 'customer''s info'  metric_name, COALESCE(CONCAT(c.first_name,' ', c.last_name,', ',c.email),'no such customer') as metric_value
FROM public.customer c 
WHERE c.customer_id = client_id
-- number of films rented since left_boundary until right_boundary
union 
SELECT 'num. of films rented' as metric_name, COALESCE(CAST(count(r.rental_id) as text),'no data') as metric_value
FROM public.rental r 
WHERE r.customer_id = client_id
AND r.rental_date >= left_boundary 
AND r.rental_date <= right_boundary
-- comma separated list of rented films at the end since left_boundary until right_boundary
UNION
SELECT 'rented films'' titles' as metric_name, COALESCE(string_agg(distinct f.title,', '),'no data') as metric_value
FROM public.rental r 
JOIN public.inventory i ON i.inventory_id = r.inventory_id 
JOIN public.film f ON f.film_id =i.film_id 
WHERE r.customer_id = client_id
AND r.rental_date >= left_boundary 
AND r.rental_date <= right_boundary
-- total number of payments made since left_boundary until right_boundary
UNION
SELECT 'num. of payments' as metric_name, COALESCE(CAST(count(p.payment_id) as text),'no data') as metric_value
FROM public.rental r 
JOIN public.payment p ON p.rental_id  = r.rental_id 
WHERE r.customer_id = client_id
AND p.payment_date  >= left_boundary 
AND p.payment_date <= right_boundary
-- total amount paid  since left_boundary until right_boundary
UNION
SELECT 'payments'' amount' as metric_name, COALESCE(CAST(sum(p.amount) as text),'no data') as metric_value
FROM public.rental r 
JOIN public.payment p ON p.rental_id  = r.rental_id 
WHERE r.customer_id = client_id
AND p.payment_date >= left_boundary 
AND p.payment_date <= right_boundary
ORDER BY metric_name;
$$
;

--check if works OK
/*
select * from public.client_metric(1,'01-01-2020','01-01-2023'); 
select * from public.client_metric(1,'01-01-2023','01-01-2024');
*?