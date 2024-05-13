-- 1. Top-3 most selling movie categories of all time and total dvd rental income for each category. 
-- Only consider dvd rental customers from the USA.

SELECT 
	sum(paym.amount) as income, 
	flmc.category_id category 					-- the category of the movie
FROM public.payment paym
		-- I join tables to get to category of movies and to group by them
JOIN public.rental rent ON rent.rental_id = paym.rental_id
JOIN public.inventory inv ON inv.inventory_id = rent.inventory_id
JOIN public.film flm ON flm.film_id  = inv.film_id 
JOIN public.film_category flmc ON flmc.film_id = flm.film_id 
		-- I join tables to get to the country of the customers
JOIN public.customer cust ON cust.customer_id = rent.customer_id
JOIN public.address adr ON adr.address_id = cust.address_id
JOIN public.city ct ON ct.city_id = adr.city_id
JOIN public.country cnt ON cnt.country_id = ct.country_id
WHERE cnt.country = 'United States' 		-- I filter the results 
GROUP BY  flmc.category_id
ORDER BY income DESC 
FETCH FIRST 3 ROWS WITH TIES  				-- in case we have more than 1 results with the same amount 






-- 2. For each client, display a list of horrors that he had ever rented 
-- (in one column, separated by commas), and the amount of money that he paid for it

SELECT 
	concat(cust.first_name,' ', cust.last_name) as Customer, -- name and surname of the customer
	STRING_AGG(flm.title,', ') as Horrors, 					-- list of all movies in one line
	sum(paym.amount) as Amount 								-- the sum of the amount spent on those movies
FROM public.customer cust
JOIN public.rental rent ON rent.customer_id = cust.customer_id 
JOIN public.payment paym ON paym.rental_id = rent.rental_id 
JOIN public.inventory inv ON inv.inventory_id = rent.inventory_id
JOIN public.film flm ON flm.film_id  = inv.film_id 
JOIN public.film_category flmc ON flmc.film_id = flm.film_id 
JOIN public.category cat ON cat.category_id = flmc.category_id 
WHERE cat.name = 'Horror' 									-- I filter the results
GROUP BY cust.first_name, cust.last_name
ORDER BY Customer


  
   