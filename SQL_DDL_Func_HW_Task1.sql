-- 1 ---
/* Create a function that will return the most popular film for each country (where country is an input paramenter).
 The function should return the result set in the following view:
 Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);
*/


--The function might return more than 1 row for a particular country because there might be more than 1 movie with the same
--number of rentals
CREATE OR REPLACE FUNCTION public.most_popular_films_by_countries(IN var_country text array)
RETURNS TABLE ("Country" text,
				"Film" text,
				"Rating" text,
				"Language" text,
				"Length" int,
				"Release_year" text				
)
LANGUAGE sql
AS $function$
--a table to count how many times the movies have been rent
WITH count_c AS
(SELECT co.country country,  COUNT(r.rental_id) AS quantity, i.film_id
FROM public.rental r 
JOIN public.inventory i ON i.inventory_id = r.inventory_id 
JOIN public.customer c ON c.customer_id =r.customer_id  
JOIN public.address a ON a.address_id = c.address_id 
JOIN public.city ci ON ci.city_id =a.city_id 
JOIN public.country co ON co.country_id =ci.country_id 
WHERE co.country = ANY (var_country)
GROUP BY co.country, i.film_id),
-- a table with MAX of rentals, using 'count_c' temporary table
max_c AS 
(SELECT max(coc.quantity) as m_quantity, coc.country FROM count_c coc GROUP BY coc.country)
--final SELECT statement
SELECT cc.country "Country", f.title "Film", f.rating "Rating", l.name "Language", f.length "Length", f.release_year "Release_year"
FROM count_c cc 
JOIN max_c mc ON mc.m_quantity = cc.quantity and mc.country = cc.country
JOIN public.film f ON f.film_id = cc.film_id
JOIN public."language" l ON l.language_id =f.language_id
ORDER BY cc.country,f.title;
$function$
;


-- Check how it works
/*
select * from public.most_popular_films_by_countries(array['Afghanistan','Brazil','United States']);
select * from public.most_popular_films_by_countries(array['Afghanistan']);
select * from public.most_popular_films_by_countries(array['Brazil']);
select * from public.most_popular_films_by_countries(array['United States']);
*/


