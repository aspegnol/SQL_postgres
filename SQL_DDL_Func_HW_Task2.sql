---2---
/*
Create a function that will return a list of films by part of the title in stock (for example, films with the word 'love' in the title).
• So, the title of films consists of ‘%...%’, and if a film with the title is out of stock, please return a message: a movie with that title was not found
• The function should return the result set in the following view (notice: row_num field is generated counter field (1,2, …, 100, 101, …))
Query (example):select * from core.films_in_stock_by_title('%love%’);
*/


--Ver.1
--A function finds all items in inventory with the given word in a title (film titles might be duplicated)
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
-- 'external' SELECT statement to order the results
SELECT row_number() OVER() AS Row_num, f_results.Film_title, f_results."Language", f_results.Customer_name, f_results.Rental_date
FROM
--'internal' SELECT statement to find the movies
-- Table with items rented but returned
(SELECT f.title as Film_title, l."name" as "Language" , CONCAT(c.first_name ,' ',c.last_name) as Customer_name, r.rental_date as Rental_date
FROM public.rental r  
JOIN public.inventory i ON r.inventory_id =i.inventory_id 
JOIN public.film f ON f.film_id = i.film_id  
JOIN public.language l ON f.language_id =l.language_id 
JOIN public.customer c ON r.customer_id =c.customer_id 
WHERE LOWER(f.title)  like  LOWER($1)
AND r.return_date IS  NOT NULL -- if return_date would be NULL, it means the movie is not available
AND r.return_date < now() -- maybe we know when the item will be returned and there are return_date's from the future?
AND rental_id IN
-- rental table grouped by the items in inventory, max(rental_id) are the newest rental records  
(select max(rental_id) FROM public.rental GROUP BY inventory_id) 
UNION ALL
-- Table with items from inventory never rented
SELECT f2.title  as Film_title, l2."name" as "Language", 'never rented' as  Customer_name, null as Rental_date
FROM public.inventory i2 
JOIN  public.film f2 ON f2.film_id = i2.film_id  
JOIN public.language l2 ON f2.language_id =l2.language_id 
WHERE LOWER(f2.title)  like  LOWER($1)
AND i2.inventory_id NOT IN (SELECT inventory_id from public.rental)
order by  Film_title, Rental_date desc) as f_results;
 IF NOT FOUND THEN
    RAISE NOTICE 'A movie with a title % has not been found',$1;
 END IF;
    RETURN;
END;
$function$
;


--Ver.2
--A function finds all movies with the given word in a title (without duplicates between titles of movies)
-- If there's an inventory item never rented, and second one with the same movie, but rented already,
-- only the one never rented will be displayed (because it's available and less popular it seems :) )
CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(IN f_title text)
RETURNS TABLE ("Row_num" BIGINT,
				"Film_title" text,
				"Language" CHAR(50),
				"Customer_name" text,
				"Rental_date" timestamp with time zone
				)
LANGUAGE PLPGsql
AS $function$
BEGIN 
RETURN query
-- 'external' SELECT to order the results
SELECT row_number() OVER() AS Row_num, f_results.Film_title, f_results."Language", f_results.Customer_name, f_results.Rental_date
FROM
(WITH f_nulls AS
-- movies never rented
(SELECT i1.film_id
FROM public.inventory i1 
WHERE i1.inventory_id NOT IN (SELECT inventory_id from public.rental))
-- newest rows of movies which were rented in the past
SELECT f.title as Film_title, l."name" as "Language" , CONCAT(c.first_name ,' ',c.last_name) as Customer_name, r.rental_date as Rental_date
FROM public.rental r  
JOIN public.inventory i ON r.inventory_id =i.inventory_id 
JOIN public.film f ON f.film_id = i.film_id  
JOIN public.language l ON f.language_id =l.language_id 
JOIN public.customer c ON r.customer_id =c.customer_id 
WHERE LOWER(f.title)  like  LOWER($1)
AND i.film_id not in (SELECT * from f_nulls) --  there are not movies never rented
AND r.return_date IS  NOT NULL -- if return_date would be NULL, it means the movie is not available
AND r.return_date < now() -- maybe we know when the item will be returned and there are return_date's from the future?
AND rental_id IN
	(select max(rental_id) 
	FROM public.rental r 
	JOIN public.inventory i ON i.inventory_id =r.inventory_id 
	GROUP BY film_id order by 1 desc) -- the newest records for all inventory items in 'rental' table
UNION ALL
-- details of movies never rented; they have higher priority (if such movies exist)
SELECT f2.title  as Film_title, l2."name" as "Language", 'never rented' as  Customer_name, null as Rental_date
FROM public.inventory i2 
JOIN  public.film f2 ON f2.film_id = i2.film_id  
JOIN public.language l2 ON f2.language_id =l2.language_id 
WHERE LOWER(f2.title)  like  LOWER($1)
AND i2.inventory_id NOT IN (SELECT inventory_id from public.rental)
order by  Film_title, Rental_date desc) as f_results;
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
-------------------------------------------
