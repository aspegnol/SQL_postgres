• What operations do the following functions perform: film_in_stock, film_not_in_stock, inventory_in_stock, get_customer_balance,inventory_held_by_customer, rewards_report, last_day? You can find these functions in dvd_rental database.

1.  inventory_in_stock - If we know inventory_id of the item, the function will return the information if the item is in stock (True/False). Item in stock is an item which is available now (not rented - no related record in RENTAL table OR not rented at this moment – related record in RENTAL table has return_date <> NULL).

2. film_in_stock – If we know and provide the ID of the movie and the store_id, the function will return ID of inventory, which is available at this moment (using function inventory_in_stock()).

3. film_not_in_stock – It’s the function similar to film_in_stock but it gives the information what inventory_id is rented at this moment (also using function inventory_in_stock).

4. get_customer_balance – It counts the financial balance for the particular customer and a date. Variables:
v_rentfees  - the cost of all movies rented until effective date, based on the rental rate of every movie.
v_overfees – the cost of movies returned later than should have been returned (1 Dollar for each day of being late.
v-payments – all payments made by the customer until effective day.
The balance is v_rentfees + v_overfees - v_payments.

5. inventory_held_by_customer – returns ID of a customers who rented the movie but didn’t return it.

6. rewards_report – It finds all the customers deserving a reward. Input parameters: the number of minimum purchases and minimum amount spent. It finds those customer for the month which was 3 months ago (since the first day of the month until the last day of the month).
------------------------------------------------------------






• Why does ‘rewards_report’ function return 0 rows? Correct and recreate the function, so that it's able to return rows properly.

The database has old data and has no records for 3 monts back. To make the function more flexible, we should add another IN variable with the type of DATE to make a possibility to choose the month we want to count the rewards.

Example of such function:
 CREATE OR REPLACE FUNCTION public.rewards_report(min_monthly_purchases integer, min_dollar_amount_purchased numeric, date_reward DATE)
 RETURNS SETOF customer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    last_month_start DATE;
    last_month_end DATE;
    rr RECORD;
    tmpSQL TEXT;
BEGIN
    /* Some sanity checks... */
    IF min_monthly_purchases = 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases parameter must be > 0';
     END IF;
    IF min_dollar_amount_purchased = 0.00 THEN
        RAISE EXCEPTION 'Minimum monthly dollar amount purchased parameter must be > $0.00';
    END IF;

    last_month_start := date_reward;
    last_month_start := to_date((extract(YEAR FROM last_month_start) || '-' || extract(MONTH FROM last_month_start) || '-01'),'YYYY-MM-DD');
    last_month_end := LAST_DAY(last_month_start);
    /*
    Create a temporary storage area for Customer IDs.
    */
    CREATE TEMPORARY TABLE tmpCustomer (customer_id INTEGER NOT NULL PRIMARY KEY);
    /*
    Find all customers meeting the monthly purchase requirements
    */
    tmpSQL := 'INSERT INTO tmpCustomer (customer_id)
        SELECT p.customer_id
        FROM payment AS p
        WHERE DATE(p.payment_date) BETWEEN '||quote_literal(last_month_start) ||' AND '|| quote_literal(last_month_end) || '
        GROUP BY customer_id
        HAVING SUM(p.amount) > '|| min_dollar_amount_purchased || '
        AND COUNT(customer_id) > ' ||min_monthly_purchases ;
    EXECUTE tmpSQL;
    /*
    Output ALL customer information of matching rewardees.
    Customize output as needed.
    */
    FOR rr IN EXECUTE 'SELECT c.* FROM tmpCustomer AS t INNER JOIN customer AS c ON t.customer_id = c.customer_id' LOOP
        RETURN NEXT rr;
    END LOOP;

    /* Clean up */
    tmpSQL := 'DROP TABLE tmpCustomer';
    EXECUTE tmpSQL;

RETURN;
END
$function$
;
------------------------------------------------------------




• Is there any function that can potentially be removed from the dvd_rental codebase? If so, which one and why?

inventory_held_by_customer – all the info the function returns and the variable we provide, is in one table. The same result will give the simple query.

last_day – It provides the last day of the month. It can be reached easier way, i.e.  
date_trunc('month', var_date) + interval '1 month - 1 day'		
------------------------------------------------------------




• * The ‘get_customer_balance’ function describes the business requirements for calculating the client balance. Unfortunately, not all of them are implemented in this function. Try to change function using the requirements from the comments.

CREATE OR REPLACE FUNCTION public.get_customer_balance_v2(p_customer_id integer, p_effective_date timestamp with time zone)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
       --#OK, WE NEED TO CALCULATE THE CURRENT BALANCE GIVEN A CUSTOMER_ID AND A DATE
       --#THAT WE WANT THE BALANCE TO BE EFFECTIVE FOR. THE BALANCE IS:
       --#   1) RENTAL FEES FOR ALL PREVIOUS RENTALS
       --#   2) ONE DOLLAR FOR EVERY DAY THE PREVIOUS RENTALS ARE OVERDUE
       --#   3) IF A FILM IS MORE THAN RENTAL_DURATION * 2 OVERDUE, CHARGE THE REPLACEMENT_COST
       --#   4) SUBTRACT ALL PAYMENTS MADE BEFORE THE DATE SPECIFIED
DECLARE
    v_rentfees DECIMAL(5,2); --#FEES PAID TO RENT THE VIDEOS INITIALLY
    v_overfees INTEGER;      --#LATE FEES FOR PRIOR RENTALS
    v_repl_costs DECIMAL(5,2);--#FEES FOR LONG OVERDUE
    v_payments DECIMAL(5,2); --#SUM OF PAYMENTS MADE PREVIOUSLY
BEGIN
    SELECT COALESCE(SUM(film.rental_rate),0) INTO v_rentfees
    FROM film, inventory, rental
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(CASE 
          WHEN (rental.return_date - rental.rental_date) > (film.rental_duration * '1 day'::interval)
          THEN EXTRACT(epoch FROM ((rental.return_date - rental.rental_date) - (film.rental_duration * '1 day'::interval)))::INTEGER / 86400 -- * 1 dollar
                           ELSE 0
                        END),0) 
    INTO v_overfees
    FROM rental, inventory, film
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;
     
    SELECT COALESCE(SUM(CASE 
                           WHEN (rental.return_date - rental.rental_date) > (2 * film.rental_duration * '1 day'::interval)
                           THEN COALESCE(film.replacement_cost,0)
                           ELSE 0
                        END),0) 
    INTO v_repl_costs
    FROM rental, inventory, film
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(payment.amount),0) INTO v_payments
    FROM payment
    WHERE payment.payment_date <= p_effective_date
    AND payment.customer_id = p_customer_id;

    RETURN v_rentfees + v_overfees + v_repl_costs - v_payments;
END
$function$
;
------------------------------------------------------------



• * How do ‘group_concat’ and ‘_group_concat’ functions work? (database creation script might help) Where are they used?

_group_concat is a function which returns concatenation of 2 strings separated by comma. If one of the strings is null, the function will return the second one (without comma)
group_concat is the function which creates aggregated function group_concat which is used in few views.
------------------------------------------------------------




• * What does ‘last_updated’ function do? Where is it used?. 

last_updated creates a trigger, which is used in every table of db. It’s used when new row is inserted to the table. It updates the column ‘last_updated’ of that record and adds the date when it was inserted.
------------------------------------------------------------




• * What is tmpSQL variable for in ‘rewards_report’ function? Can this function be recreated without EXECUTE statement and dynamic SQL?
tmpSQL is a string with SQL statement which becomes that statement when command’ EXECUTE tmpSQL;’ is executed.
The same result we’ll have when we write: RETURN query ‘INSERT INTO ....;’.
------------------------------------------------------------
