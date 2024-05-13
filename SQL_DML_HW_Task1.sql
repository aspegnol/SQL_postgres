-- PART 1
-- Choose your top 3 favorite movies and add them to 'film' table. 
-- Fill rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
-- Add actors who play leading roles in your favorite movies to 'actor' and 'film_actor' tables (6 or more actors in total).


WITH film_new AS -- a table 'film_new' with data to insert into 'film' table
(
SELECT 
	'BIG LEBOWSKI' as title, 
	'A hilariously twisted comedy-triller' as description, 
	1998 as release_year,
	l.language_id as language_id,
	l.language_id as original_language_id,
	1 as rental_duration, 
	4.99 as rental_rate,
	117 as length,
	19.99 as replacement_cost,
	'R'::mpaa_rating as rating,
	now() as last_update,
	CAST('{Trailers}'AS _text) as special_features,
	'bl' as film_mark
FROM public.language l
WHERE LOWEr(l.name) = 'english'
UNION
SELECT 
	'FIGHT CLUB' as title, 
	'An insomniac office worker and a devil-may-care soap maker for an underground fight club' as description, 
	1999 as release_year,
	l.language_id as language_id,
	l.language_id as original_language_id,
	2 as rental_duration, 
	9.99 as rental_rate,
	139 as length,
	19.99 as replacement_cost,
	'R'::mpaa_rating as rating,
	now() as last_update,
	CAST('{Trailers,Deleted Scenes}'AS _text) as special_features,
	'fc' as film_mark
FROM public.language l
WHERE LOWER(l.name) = 'english'
UNION
SELECT 
	'PI' as title, 
	'A study of madness and its partner, genius' as description, 
	1998 as release_year,
	l.language_id as language_id,
	l.language_id as original_language_id,
	3 as rental_duration, 
	19.99 as rental_rate,
	85 as length,
	19.99 as replacement_cost,
	'R'::mpaa_rating as rating,
	now() as last_update,
	CAST('{Behind the Scenes}'AS _text) as special_features,
	'pi' as film_mark
FROM public.language l
WHERE LOWEr(l.name) = 'english'
),
updated_film AS -- inserting data from table 'film_new' to table 'film'
(
INSERT INTO public.film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, 
						length, replacement_cost, rating, last_update, special_features)
SELECT title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, 
						length, replacement_cost, rating, last_update, special_features
FROM film_new fn
WHERE fn.title NOT IN (SELECT title FROM public.film)
RETURNING *
),
actor_new AS -- a table 'actor_new' with data to insert into 'actor' table
(
SELECT 'JEFF' as first_name, 'BRIDGES' as last_name, now() as last_update,'bl' as film_mark
UNION
SELECT 'JOHN' as first_name, 'GOODMAN' as last_name, now() as last_update,'bl' as film_mark
UNION
SELECT 'STEVE' as first_name, 'BUSCEMI' as last_name, now() as last_update,'bl' as film_mark
UNION
SELECT 'JOHN' as first_name, 'TURTURRO' as last_name, now() as last_update,'bl' as film_mark
UNION
SELECT 'EDWARD' as first_name, 'NORTON' as last_name, now() as last_update,'fc' as film_mark
UNION
SELECT 'BRAD' as first_name, 'PITT' as last_name, now() as last_update,'fc' as film_mark
UNION
SELECT 'SEAN' as first_name, 'GULLETTE' as last_name, now() as last_update,'pi' as film_mark
),
--inserting data from 'actor_new' table into 'actor'
updated_actor AS
(
INSERT INTO public.actor (first_name, last_name, last_update)
SELECT first_name, last_name, last_update
FROM actor_new 
WHERE CONCAT(first_name,last_name) NOT IN (SELECT CONCAT(first_name,last_name) FROM public.actor) -- if such actors already in the table, don't insert
RETURNING *
)
-- inserting into 'public.film_actor' data about movies and films
INSERT INTO  public.film_actor	(actor_id, film_id, last_update)
SELECT 	ua.actor_id, uf.film_id, now()
FROM updated_actor ua
JOIN actor_new an ON ua.first_name = an.first_name and ua.last_name =an.last_name
JOIN film_new fn ON fn.film_mark=an.film_mark -- film_mark is to connect actors with movies they played in 
JOIN updated_film uf ON uf.title = fn.title
WHERE uf.title NOT IN (SELECT title FROM public.film)  -- make sure there are no such movies inserted to the table
RETURNING *;








-- PART 2 --
-- Add your favorite movies to any store's inventory.
 
WITH film_store AS -- a table to use for inserting data into 'public.inventory' 
(
SELECT f.film_id as film_id, MIN(s.store_id) as store_id
FROM public.store s 
JOIN public.film f ON f.title ='BIG LEBOWSKI'
GROUP BY f.film_id
UNION
SELECT f.film_id as film_id, MAX(s.store_id) as store_id
FROM public.store s 
JOIN public.film f ON f.title ='BIG LEBOWSKI'
GROUP BY f.film_id
UNION
SELECT f.film_id as film_id, MIN(s.store_id) as store_id
FROM public.store s 
JOIN public.film f ON f.title ='FIGHT CLUB'
GROUP BY f.film_id
UNION
SELECT f.film_id as film_id, MAX(s.store_id) as store_id
FROM public.store s 
JOIN public.film f ON f.title ='PI'
GROUP BY f.film_id
)
INSERT INTO public.inventory (film_id, store_id, last_update) -- insert data into 'inventory' from 'film_store'
SELECT film_id, store_id, now()
FROM film_store
WHERE film_id NOT IN (SELECT film_id FROM public.inventory) -- make sure that there are no such movies already inserted to the table
RETURNING *;





-- PART 3 --
-- Alter any existing customer in the database who has at least 43 rental and 43 payment records. 
-- Change his/her personal data to yours (first name, last name, address, etc.). 
-- Do not perform any updates on 'address' table, as it can impact multiple records with the same address. 
-- Change customer's create_date value to current_date.

WITH payments AS 
(SELECT customer_id ,count(payment_id) as paym FROM public.payment p GROUP BY customer_id HAVING count(payment_id)>=43),
rentals AS 
(SELECT customer_id, COUNT(rental_id) as rent FROM public.rental GROUP BY customer_id HAVING count(rental_id)>=43),
new_customer AS
(SELECT MIN(customer_id) as customer_id
FROM customer c 
WHERE c.customer_id in (select customer_id from public.payment)
AND customer_id IN (SELECT customer_id FROM public.rental))
UPDATE customer
SET first_name='MALGORZATA', last_name='ANDRUSZKIEWICZ', email='GOSIA@ANDRUSZKIEWICZ.PL',create_date='now'::text::date,last_update=now()
WHERE customer_id = (SELECT customer_id FROM new_customer)
AND 'GOSIA@ANDRUSZKIEWICZ.PL' NOT IN (SELECT email FROM public.customer)
RETURNING *;




-- PART 4 --
-- Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
WITH deleted AS
(DELETE FROM payment 
WHERE customer_id = (SELECT customer_id FROM public.customer WHERE first_name='MALGORZATA') 
RETURNING *)
SELECT count(*) FROM deleted; -- return the number of deleted rows

WITH deleted AS
(DELETE FROM rental r  
WHERE customer_id = (SELECT customer_id FROM public.customer WHERE first_name='MALGORZATA')
RETURNING *)
SELECT count(*) FROM deleted; -- return the number of deleted rows




--PART 5 --
-- Rent you favorite movies from the store they are in and pay for them 
-- (add corresponding records to the database to represent this activity)
-- (Note: to insert the payment_date into the table payment, you can create a new partition 
-- (see the scripts to install the training database) or add records for the first half of 2017)


-- I'm creating new partition for the current dates
CREATE TABLE  IF NOT EXISTS payment_p2023_03 PARTITION OF public.payment
    FOR VALUES FROM ('2023-03-01 00:00:00+3:00') TO ('2023-04-01 00:00:00+3:00');

ALTER TABLE public.payment_p2023_03 OWNER TO postgres;



WITH new_rental AS -- data to insert into 'public.rental' table
(SELECT 
	f.film_id as film_id,
	CAST('2023-01-01' AS DATE) as rental_date, 
	i.inventory_id as inventory_id, 
	c.customer_id as customer_id, 
	MAX(s.staff_id) as staff_id -- one of the staff member working in a store where movie is located 
FROM public.inventory i 
JOIN public.film f ON f.film_id =i.film_id 
JOIN public.staff s ON s.store_id = i.store_id
JOIN public.customer c ON c.first_name='MALGORZATA'
WHERE f.title ='BIG LEBOWSKI' -- data related to  'BIG LEBOWSKI' only 
GROUP BY i.inventory_id, c.customer_id, f.film_id
UNION
SELECT 
	f.film_id as film_id,
	CAST('2023-02-02' AS DATE) as rental_date, 
	i.inventory_id as inventory_id, 
	c.customer_id as customer_id, 
	MIN(s.staff_id) as staff_id -- one of the staff member working in a store where movie is located 
FROM public.inventory i 
JOIN public.film f ON f.film_id =i.film_id 
JOIN public.staff s ON s.store_id = i.store_id
JOIN public.customer c ON c.first_name='MALGORZATA'
WHERE f.title ='FIGHT CLUB'
GROUP BY i.inventory_id, c.customer_id, f.film_id
UNION
SELECT 
	f.film_id as film_id,
	CAST('2023-03-03' AS DATE) as rental_date, 
	i.inventory_id as inventory_id, 
	c.customer_id as customer_id, 
	MAX(s.staff_id) as staff_id -- one of the staff member working in a store where movie is located 
FROM public.inventory i 
JOIN public.film f ON f.film_id =i.film_id 
JOIN public.staff s ON s.store_id = i.store_id
JOIN public.customer c ON c.first_name='MALGORZATA'
WHERE f.title ='PI'
GROUP BY i.inventory_id, c.customer_id, f.film_id
),
-- insert data from new_rental into public.rental
insert_rental AS (
INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update) 
SELECT 
nr.rental_date as rental_date, nr.inventory_id as inventory_id, nr.customer_id as customer_id, 
rental_date + interval '10 days' as return_date, 
nr.staff_id as staff_id, now() as last_update
FROM new_rental nr
WHERE nr.inventory_id NOT IN (SELECT inventory_id FROM public.rental)
RETURNING *
) 
-- insert data  newly inserted into public.payment
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT ir.customer_id, ir.staff_id, ir.rental_id, f.rental_rate, now()
FROM insert_rental ir
JOIN new_rental nr ON nr.inventory_id = ir.inventory_id
JOIN public.film f ON f.film_id = nr.film_id
WHERE ir.rental_id NOT IN (SELECT rental_id from public.payment)
RETURNING *;

