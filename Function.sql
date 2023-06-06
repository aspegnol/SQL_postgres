CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(IN f_title text)
RETURNS TABLE ("Row_num" BIGINT,
				"Film_title" text,
				"Language" CHAR(50),
				"Customer_name" text,
				"Rental_date" timestamp with time zone
				)
LANGUAGE plpgsql
AS $function$
BEGIN 
RETURN query
WITH main_t AS
	(SELECT i.inventory_id ,
		f.title as Film_title, 
		l."name" as "Language" , 
		CONCAT(c.first_name ,' ',c.last_name) as Customer_name, 
		r.rental_date as Rental_date
	FROM public.rental r  
	JOIN public.inventory i ON r.inventory_id =i.inventory_id 
	JOIN public.film f ON f.film_id = i.film_id  
	JOIN public."language" l ON f.language_id =l.language_id 
	JOIN public.customer c ON r.customer_id =c.customer_id 
	WHERE LOWER(f.title)  like  LOWER($1)
	AND r.return_date IS  NOT NULL -- if return_date would be NULL, it means the movie is not available
	AND r.return_date < now() -- maybe we know when the item will be returned and there are return_date's from the future?
	AND r.rental_id IN
-- rental table grouped by the items in inventory, max(rental_id) are the newest rental records  
		(select max(rental_id) FROM public.rental GROUP BY inventory_id) 
	UNION ALL
-- Table with items from inventory never rented
	SELECT 
		i2.inventory_id ,
		f2.title  as Film_title, 
		l2."name" as "Language", 
		'never rented' as  Customer_name, 
		null as Rental_date
	FROM public.inventory i2 
	JOIN public.film f2 ON f2.film_id = i2.film_id  
	JOIN public.language l2 ON f2.language_id =l2.language_id 
	WHERE LOWER(f2.title)  like  LOWER($1)
	AND i2.inventory_id NOT IN 
		(SELECT inventory_id from public.rental)
	order by  Film_title, Rental_date desc)
SELECT 
	count(var_t.inventory_id) as row_num,
	main_t.Film_title, 
	main_t."Language",
	main_t.Customer_name, 
	main_t.Rental_date 
FROM 
-- the same table as main_t but we want to compare inventory_id in both tables
	(SELECT i.inventory_id ,
		f.title as Film_title, 
		l."name" as "Language" , 
		CONCAT(c.first_name ,' ',c.last_name) as Customer_name, 
		r.rental_date as Rental_date
	FROM public.rental r  
	JOIN public.inventory i ON r.inventory_id =i.inventory_id 
	JOIN public.film f ON f.film_id = i.film_id  
	JOIN public."language" l ON f.language_id =l.language_id 
	JOIN public.customer c ON r.customer_id =c.customer_id 
	WHERE LOWER(f.title)  like  LOWER($1)
	AND r.return_date IS  NOT NULL -- if return_date would be NULL, it means the movie is not available
	AND r.return_date < now() -- maybe we know when the item will be returned and there are return_date's from the future?
	AND r.rental_id IN
-- rental table grouped by the items in inventory, max(rental_id) are the newest rental records  
		(select max(rental_id) FROM public.rental GROUP BY inventory_id) 
	UNION ALL
-- Table with items from inventory never rented
	SELECT 
		i2.inventory_id,
		f2.title  as Film_title, 
		l2."name" as "Language", 
		'never rented' as  Customer_name, 
		null as Rental_date
	FROM public.inventory i2 
	JOIN public.film f2 ON f2.film_id = i2.film_id  
	JOIN public.language l2 ON f2.language_id =l2.language_id 
	WHERE LOWER(f2.title)  like  LOWER($1)
	AND i2.inventory_id NOT IN 
		(SELECT inventory_id from public.rental)
	order by  Film_title, Rental_date desc) as var_t
JOIN main_t ON main_t.inventory_id >= var_t.inventory_id -- the main condition to produce row numbers
GROUP BY main_t.Film_title, 	main_t."Language",	main_t.Customer_name, 	main_t.Rental_date 
ORDER BY row_num; 
 IF NOT FOUND THEN
    RAISE NOTICE 'A movie with a title % has not been found',$1;
 END IF;
    RETURN;
END;
$function$
;


-----VERSION 2, using generate_series - doesn't work good :)
CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(IN f_title text)
RETURNS TABLE ("Row_num" BIGINT,
				"Film_title" text,
				"Language" CHAR(50),
				"Customer_name" text,
				"Rental_date" timestamp with time zone
				)
LANGUAGE plpgsql
AS $function$
BEGIN 
RETURN query

WITH main_t AS
	(SELECT 
		f.title as Film_title, 
		l."name" as "Language" , 
		CONCAT(c.first_name ,' ',c.last_name) as Customer_name, 
		r.rental_date as Rental_date
	FROM public.rental r  
	JOIN public.inventory i ON r.inventory_id =i.inventory_id 
	JOIN public.film f ON f.film_id = i.film_id  
	JOIN public."language" l ON f.language_id =l.language_id 
	JOIN public.customer c ON r.customer_id =c.customer_id 
	WHERE LOWER(f.title)  like  LOWER($1)
	AND r.return_date IS  NOT NULL -- if return_date would be NULL, it means the movie is not available
	AND r.return_date < now() -- maybe we know when the item will be returned and there are return_date's from the future?
	AND r.rental_id IN
-- rental table grouped by the items in inventory, max(rental_id) are the newest rental records  
		(select max(rental_id) FROM public.rental GROUP BY inventory_id) 
	UNION ALL
-- Table with items from inventory never rented
	SELECT 
		f2.title  as Film_title, 
		l2."name" as "Language", 
		'never rented' as  Customer_name, 
		null as Rental_date
	FROM public.inventory i2 
	JOIN public.film f2 ON f2.film_id = i2.film_id  
	JOIN public.language l2 ON f2.language_id =l2.language_id 
	WHERE LOWER(f2.title)  like  LOWER($1)
	AND i2.inventory_id NOT IN 
		(SELECT inventory_id from public.rental)
	order by  Film_title, Rental_date desc),
-- we want to know the number of rows in main table and then use it in generate_series
counter AS
	(select count(*) max_f from main_t) 
-- We select all from main table + we add the row number
SELECT 
	generate_series(1,cast(c.max_f as BIGINT)) as row_num, 
	mt.Film_title, 
	mt."Language",
	mt.Customer_name, 
	mt.Rental_date 
FROM 
counter c
CROSS JOIN main_t mt;
 IF NOT FOUND THEN
    RAISE NOTICE 'A movie with a title % has not been found',$1;
 END IF;
    RETURN;
END;
$function$
;

------------------------------------------
--QUERIES FOR TESTS
--drop function public.films_in_stock_by_title(text);
--
--SELECT * from public.films_in_stock_by_title('%LxVE%'); -- Notice message
--SELECT * from public.films_in_stock_by_title('%LoVE%'); -- Should return records
--SELECT * from public.films_in_stock_by_title('%dinos%'); -- One of 'Academy Dinosaur' has never been rented
