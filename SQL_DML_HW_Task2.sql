/*TASK 2 
 * */

/*    RESULTS
 
 
table_to_delete

Size: 575 MB
Size after DELETE of 1/3 rows: 575 MB
Size after DELETE of 1/3 rows AND VACUUM operation: 383 MB 
Size after TRUNCATE of all rows: 8192 bytes
Size after DELETE of all rows: 8192 bytes

Removing 1/3 of table using DELETE took: 49 sec.
Removing all rows using DELETE took: 61 sek.
Removing all rows using TRUNCATE took: 1 sek.

CONCLUSION: 
DELETE operation takes a lot of time, also requires addtional actions to free up the space.
But we can add conditions to the query. 
TRUNCATE removes rows really fast but we can't control what rows will be removed.


*/









----------NOTES-------------------------------------------


SET search_path = public;



-- 1 Create table ‘table_to_delete’ and fill it with the following query:


CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x; 
-- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)




-- 2. Lookup how much space this table consumes with the following query:
SELECT *, pg_size_pretty(total_bytes) AS total,
pg_size_pretty(index_bytes) AS INDEX,
pg_size_pretty(toast_bytes) AS toast,
pg_size_pretty(table_bytes) AS TABLE
FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
FROM (SELECT c.oid,nspname AS table_schema,
relname AS TABLE_NAME,
c.reltuples AS row_estimate,
pg_total_relation_size(c.oid) AS total_bytes,
pg_indexes_size(c.oid) AS index_bytes,
pg_total_relation_size(reltoastrelid) AS toast_bytes
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE relkind = 'r'
) a
) a
WHERE table_name LIKE '%table_to_delete%';

/*ANSWER: TOTAL = 575 MB
 * */





-- 3 Issue the following DELETE operation on ‘table_to_delete’:

DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows


--a. Note how much time it takes to perform this DELETE statement;

/*ANSWER: 
 * Start time	Thu Mar 16 17:45:02 CET 2023
 * Finish time	Thu Mar 16 17:45:51 CET 2023
 * 49 sek
 *  */

--b. Lookup how much space this table consumes after previous DELETE;

/*ANSWER: TOTAL = 575 MB
 * Nothing has changed
 * */


-- c. Perform the following command (if you're using DBeaver, press Ctrl+Shift+O to observe server output (VACUUM results)):

END TRANSACTION;
VACUUM FULL VERBOSE table_to_delete;


-- d. Check space consumption of the table once again and make conclusions;

/*ANSWER: TOTAL = 383 MB
 * */

-- e. Recreate ‘table_to_delete’ table;

DROP TABLE table_to_delete;

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;




-- 4. Issue the following TRUNCATE operation:

TRUNCATE table_to_delete;

-- a. Note how much time it takes to perform this TRUNCATE statement.
/*ANSWER: 
 * Start time	Thu Mar 16 18:53:17 CET 2023
 * Finish time	Thu Mar 16 18:53:18 CET 2023
 * around 1 sek
 */


-- b. Compare with previous results and make conclusion.
/* ANSWER:
 * TRUNCATE statement is much more faster
 */


-- c. Check space consumption of the table once again and make conclusions;

/*ANSWER: TOTAL = 8192 bytes
 * */

--5. Hand over your investigation's results to your trainer. The results must include:
--a. Space consumption of ‘table_to_delete’ table before and after each operation;
--b. Duration of each operation (DELETE, TRUNCATE)

DELETE FROM table_to_delete
/*
Start time	Thu Mar 16 19:22:32 CET 2023
Finish time	Thu Mar 16 19:23:36 CET 2023
1:01
*/

-- Conclusion is on the top of this file




