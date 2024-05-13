SET search_path = public;

/* PART 1
 */ 

-- 1.1 All comedy movies released between 2000 and 2004, alphabetical
SELECT  fm.title, 
		fm.description, 
		cat.name, 
		fm.release_year  
FROM film fm
JOIN film_category fc 	ON fm.film_id=fc.film_id 
JOIN category cat 		ON fc.category_id = cat.category_id  
WHERE fm.release_year BETWEEN 2000 AND 2004 
		AND cat.name ='Comedy'
ORDER BY fm.title; 






-- 1.2 Revenue of every rental store for year 2017 (columns: address and address2 – as one column, revenue)
SELECT 	CONCAT(a.address,' ',a.address2) AS store,   -- changed || into CONCAT()
    	sum(p.amount) AS revenue
FROM payment p
JOIN rental r		ON p.rental_id = r.rental_id
JOIN inventory i	ON r.inventory_id = i.inventory_id
JOIN store st 		ON i.store_id = st.store_id
JOIN address a 		ON st.address_id = a.address_id
GROUP BY  a.address_id; 







-- 1.3 Top-3 actors by number of movies they took part in (columns: first_name, last_name, number_of_movies, 
--     sorted by number_of_movies in descending order)
SELECT  a.first_name, 
		a.last_name,
		COUNT(fa.film_id) AS number_of_movies
FROM actor a 
JOIN film_actor fa 	ON fa.actor_id = a.actor_id 
GROUP BY a.first_name, a.last_name, a.actor_id  --added actor_id to GROUP BY to have unique actors
ORDER BY number_of_movies DESC, a.last_name 
FETCH FIRST 3 ROWS WITH TIES;






-- 1.4 	Number of comedy, horror and action movies per year (columns: release_year, number_of_action_movies,
-- 	   	number_of_horror_movies, number_of_comedy_movies), sorted by release year in descending order
SELECT f.release_year, 
sum(case when c."name" ='Action' then 1 else 0 end) as number_of_action_movies, 
sum(case when c."name" ='Horror' then 1 else 0 end) as number_of_horror_movies, 
sum(case when c."name" ='Comedy' then 1 else 0 end) as number_of_comedy_movies 
	FROM film_category fc 
	JOIN film f  	ON fc.film_id = f.film_id 
	JOIN category c ON fc.category_id = c.category_id 
	WHERE c.name in ('Action','Horror','Comedy')
	GROUP BY f.release_year;

	
	
	
	
/* PART 2
 */ 

	
	
	
-- 2.1 • Which staff members made the highest revenue for each store and deserve a bonus for 2017 year?

WITH max_rev_table as 
	(SELECT -- maximnum of the revenues for every store (no matter who did it)
	MAX(sum_rev.revenue) as max_rev, 
	sum_rev.store_id
	FROM
		(SELECT 		-- the amount of payments for every staff member and store
		sum(p.amount) revenue, 
		s.staff_id, 
		s.store_id 
		FROM payment p 
		JOIN staff s ON s.staff_id = p.staff_id  
		GROUP BY s.staff_id, s.store_id) AS sum_rev
	GROUP BY sum_rev.store_id)

SELECT -- the amount of payments for every staff member and store (similar to 'sum_rev' table above)
sum(p.amount) revenue, 
CONCAT(s.first_name,' ',s.last_name) as staff_member, 
s.store_id
FROM payment p 
JOIN staff s ON s.staff_id = p.staff_id 
JOIN max_rev_table ON max_rev_table.store_id = s.store_id --I choose the records equivalent to the records from max_rev_table
GROUP BY s.first_name,s.last_name, s.staff_id, s.store_id, max_rev_table.max_rev 
HAVING sum(p.amount) = max_rev_table.max_rev -- I filter the records equal to max revenues from 'max_rev_table'



/* PREVIOUS VERSION, FIXED ABOVE

(SELECT sum(p.amount) revenue, COALESCE(s.first_name,'') ||' ' || COALESCE(s.last_name,'') employee, s.store_id 
FROm payment p 
JOIN staff s ON s.staff_id = p.staff_id  
WHERE s.store_id =1
GROUP BY s.first_name , s.last_name, s.store_id 
ORDER BY revenue DESC
LIMIT 1)
UNION
(SELECT sum(p.amount) revenue, COALESCE(s.first_name,'') || ' ' || COALESCE(s.last_name,'')  employee, s.store_id 
FROm payment p 
JOIN staff s ON s.staff_id = p.staff_id 
WHERE s.store_id =2
GROUP BY s.first_name , s.last_name, s.store_id 
ORDER BY revenue DESC
LIMIT 1);
 */





-- 2.2 Which 5 movies were rented more than others and what's expected audience age for those movies?

-- VER1: We want to know how long the movies were rented
-- Note: not all rows in RATING table has RETURN_DATE filled. I assume that such movies are rented already 
-- and I've counted the time 'until now' in such cases
SELECT f.film_id, f.title, SUM(COALESCE(r.return_date,CURRENT_DATE) - r.rental_date) AS lenth, 
       CASE f.rating
           WHEN 'G' THEN 'General Audiences'
           WHEN 'PG' THEN 'Parental Guidance Suggested'
           WHEN 'PG-13' THEN 'Parents Strongly Cautioned'
           WHEN 'R' THEN 'Restricted'
           WHEN 'NC-17' THEN 'Adults Only'
       END audience
FROM rental r 
JOIN inventory i ON i.inventory_id = r.inventory_id 
JOIN film f ON f.film_id = i.film_id 
GROUP BY f.film_id, f.title
ORDER BY lenth DESC
FETCH FIRST 5 ROWS WITH TIES;


--VER2: We want to calculate how often the movies were rented. In this case, we count the number of rentals
SELECT f.film_id, f.title, COUNT(r.rental_id) AS quantity, 
       CASE f.rating
           WHEN 'G' THEN 'General Audiences'
           WHEN 'PG' THEN 'Parental Guidance Suggested'
           WHEN 'PG-13' THEN 'Parents Strongly Cautioned'
           WHEN 'R' THEN 'Restricted'
           WHEN 'NC-17' THEN 'Adults Only'
       END audience
FROM rental r 
JOIN inventory i ON i.inventory_id = r.inventory_id 
JOIN film f ON f.film_id = i.film_id 
GROUP BY f.film_id, f.title
ORDER BY quantity DESC
FETCH FIRST 5 ROWS WITH TIES;





-- 2.3 Which actors/actresses didn't act for a longer period of time than others?
SELECT  f1.actor_id, 
		a.first_name || ' ' || a.last_name, 
		f1.release_year-max(f2.release_year) length, 
		f1.release_year year_From, 
		max(f2.release_year) year_To 
FROM
	(SELECT fa.actor_id , f.release_year
	FROM film f 
	JOIN film_actor fa ON fa.film_id = f.film_id) AS f1 
	LEFT JOIN 
		(SELECT fa.actor_id , f.release_year
		FROM film f 
		JOIN film_actor fa ON fa.film_id = f.film_id) AS f2 ON  f1.actor_id = f2.actor_id
		and f1.release_year > f2.release_year
	JOIN actor a ON f1.actor_id = a.actor_id
WHERE f2.release_year IS NOT NULL
GROUP BY f1.actor_id, a.first_name, a.last_name, f1.release_year
ORDER BY length DESC
FETCH FIRST 1 ROWS WITH TIES;
/*EXPLANATION:
 * Note: we can't use the window functions.
 * I've created 2 similar tables with columns: actor and release_day. I've joined them the way that for the same actor,
 * the release year from second table is lower than in first table.
 * Max(release_year) gives the oldest release year from second table (but still earlier than in the first table)
 * This way, we have a row with the time periods. 
 * The only thing we can do now, is to count the difference between older release_year and the earlier one.
 * We also need to sort out the results to find the longest period. 
 */



