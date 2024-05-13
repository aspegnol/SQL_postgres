-- Create DB
--CREATE DATABASE healthcare;

--Create schema
CREATE SCHEMA IF NOT EXISTS healthcare;

-- Create table LOCATION - address where the insitutions are located
CREATE TABLE IF NOT EXISTS healthcare.location (
	location_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	distrinct CHAR(15),
	address CHAR(30) NOT NULL,
	Udate DATE DEFAULT current_date NOT NULL-- date of the update of the record
);
-- create table INSTITUTION - names of the institutions + location
CREATE TABLE IF NOT EXISTS healthcare.institution (
	institution_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	i_name CHAR(50) NOT NULL,
	location_id INT REFERENCES healthcare.location(location_id),
	UDate DATE DEFAULT current_date NOT NULL-- date of the update of the record
);
-- create table SPECIALIST - the name of professions
CREATE TABLE IF NOT EXISTS healthcare.specialist (
	specialist_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	s_name CHAR(50) NOT NULL,
	avg_time_visit INT DEFAULT 15 CHECK(avg_time_visit > 0), CHECK(avg_time_visit < 480), -- average time spent on service of 1 patient, in minutes, can't last more than 8 hours
	UDate DATE DEFAULT current_date NOT NULL-- date of the update of the record 	
);
-- create table CAPACITY - how many specialists work in a particular place + how many of them we want to work
CREATE TABLE IF NOT EXISTS healthcare.capacity(
	capacity_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	institution_id INT REFERENCES healthcare.institution(institution_id),
	specialist_id INT REFERENCES healthcare.specialist(specialist_id),
	hiring_target INT CHECK(hiring_target > 0), -- how many specialistswe could hire
	hiring_current INT CHECK( hiring_target>=hiring_current), -- how many specialists are already hired
	hours_weekly_target INT GENERATED ALWAYS AS (8 * hiring_target) STORED, -- how many hours weekly the specialists we want to be available
	hours_weekly_current INT GENERATED ALWAYS AS (8 * hiring_current) STORED, -- how many hours weekly the specialist is available
	UDate DATE DEFAULT current_date NOT NULL-- date of the update of the record 
);
-- create table STAFF - names of specialists, where they work and what they do
CREATE TABLE IF NOT EXISTS healthcare.staff(
	staff_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	first_name CHAR(30) NOT NULL,
	last_name CHAR(30),
	specialist_id INT REFERENCES healthcare.specialist(specialist_id),
	institution_id INT REFERENCES healthcare.institution(institution_id),
	start_date DATE DEFAULT current_date, -- the date when has been hired
	end_date DATE DEFAULT NULL,
	UDate DATE DEFAULT current_date NOT NULL -- date of the update of the record
);
-- create table VISIT - where and when the visit has happened, who was the doctor and basic detail about patient
CREATE TABLE IF NOT EXISTS healthcare.visit(
	visit_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	institution_id INT REFERENCES healthcare.institution(institution_id),
	staff_id INT REFERENCES healthcare.staff(staff_id),
	patientid CHAR(20), --It's not FK. It's personal ID number; how it looks - depends on the country.
	start_date DATE DEFAULT current_date NOT NULL,
	end_date DATE DEFAULT current_date NOT NULL,
	UDate DATE DEFAULT current_date NOT NULL-- date of the update of the record	
);




-- inserting data related to the location of health institutions
INSERT INTO healthcare."location"  (distrinct, address)
SELECT 'Gdynia Redlowo' as distrinct, 'Legionow 5' as address 
WHERE NOT EXISTS (SELECT 1 FROM healthcare."location" WHERE distrinct like '%Redlowo%');

INSERT INTO healthcare."location"  (distrinct, address)
SELECT 'Gdynia Orlowo' as distrinct, 'Orlowska 13' as address 
WHERE NOT EXISTS (SELECT 1 FROM healthcare."location" WHERE distrinct like '%Orlowo%');

INSERT INTO healthcare."location"  (distrinct, address)
SELECT 'Gdynia Obluze' as distrinct, 'Bosmanska 9' as address 
WHERE NOT EXISTS (SELECT 1 FROM healthcare."location" WHERE distrinct like '%Obluze%');

INSERT INTO healthcare."location"  (distrinct, address)
SELECT 'Gdynia Witomino' as distrinct, 'Konwaliowa 14' as address 
WHERE NOT EXISTS (SELECT 1 FROM healthcare."location" WHERE distrinct like '%Witomino%');

INSERT INTO healthcare."location"  (distrinct, address)
SELECT 'Gdynia Chwarzno' as distrinct, 'Poziomkowa 1' as address 
WHERE NOT EXISTS (SELECT 1 FROM healthcare."location" WHERE distrinct like '%Chwarzno%');

--inserting names of the institutions
INSERT INTO healthcare.institution (i_name, location_id)
SELECT 
CASE WHEN hl.distrinct like '%Redlowo%' THEN 'hospital' 
	WHEN hl.distrinct like '%Orlowo%' THEN 'nursing home'
	WHEN hl.distrinct like '%Obluze%' THEN 'maternity home'
	WHEN hl.distrinct like '%Witomino%' THEN 'health centre' 
	WHEN hl.distrinct like '%Chwarzno%' THEN 'dispensary'
	END i_name,
hl.location_id as location_id
FROM healthcare."location" hl
WHERE NOT EXISTS -- Checking if not already inserted
(SELECT 1 FROM healthcare.institution 
WHERE distrinct like '%Redlowo%' OR distrinct like '%Orlowo%' OR distrinct like '%Obluze%' OR distrinct like '%Witomino%' OR distrinct like '%Chwarzno%')
RETURNING *;


-- inserting names of the professions
-- specialists who spend usually 30 minutes on taking care of 1 patient
INSERT INTO healthcare.specialist (avg_time_visit,s_name)
SELECT 30, temp_sp.* FROM (VALUES ('customer service'), ('neurologist'), ('geriatrician')) temp_sp
WHERE NOT EXISTS (SELECT 1 FROM healthcare.specialist WHERE s_name in ('customer service','neurologist','geriatrician'))
RETURNING *;
-- specialists who spend usually 15 minutes on taking care of 1 patient
INSERT INTO healthcare.specialist (avg_time_visit,s_name)
SELECT 20, temp_sp.* FROM (VALUES ('pediatrist'), ('oculist'), ('nurse'),('laryngologist')) temp_sp
WHERE NOT EXISTS (SELECT 1 FROM healthcare.specialist WHERE s_name in ('pediatrist','oculist','nurse','laryngologist') )
RETURNING *;




-- inserting data about current/target hiring. 
-- CUSTOMER SERVICE: In hospital, nursing home and health centre, there are 12 people hired but 15 required.
WITH instit_to_insert AS
(SELECT institution_id, i_name 
FROM healthcare.institution WHERE LOWER(i_name) IN ('hospital','nursing home','health centre')),
spec_to_insert AS
(SELECT specialist_id, s_name
FROM healthcare.specialist)
INSERT INTO healthcare.capacity (institution_id,specialist_id, hiring_target,hiring_current)
SELECT iti.institution_id, sti.specialist_id, 15,12
FROM instit_to_insert iti
JOIN spec_to_insert sti ON LOWER(sti.s_name)='customer service'
WHERE NOT exists 
(SELECT 1 FROM healthcare.capacity WHERE institution_id=iti.institution_id AND specialist_id=sti.specialist_id)
RETURNING *;
-- CUSTOMER SERVICE: In hospital, nursing home and health centre, there are 5 people hired but 6 required.
WITH instit_to_insert AS
(SELECT institution_id, i_name 
FROM healthcare.institution WHERE LOWER(i_name) IN ('maternity home','dispensary')),
spec_to_insert AS
(SELECT specialist_id, s_name
FROM healthcare.specialist)
INSERT INTO healthcare.capacity (institution_id,specialist_id, hiring_target,hiring_current)
SELECT iti.institution_id, sti.specialist_id, 6,5
FROM instit_to_insert iti
JOIN spec_to_insert sti ON LOWER(sti.s_name)='customer service'
WHERE NOT exists 
(SELECT 1 FROM healthcare.capacity WHERE institution_id=iti.institution_id AND specialist_id=sti.specialist_id)
RETURNING *;
-- NEUROLOGISTS in hospital
WITH instit_to_insert AS
(SELECT institution_id, i_name 
FROM healthcare.institution WHERE LOWER(i_name) IN ('hospital')),
spec_to_insert AS
(SELECT specialist_id, s_name
FROM healthcare.specialist)
INSERT INTO healthcare.capacity (institution_id,specialist_id, hiring_target,hiring_current)
SELECT iti.institution_id, sti.specialist_id, 3,3
FROM instit_to_insert iti
JOIN spec_to_insert sti ON LOWER(sti.s_name)='neurologist'
WHERE NOT exists 
(SELECT 1 FROM healthcare.capacity WHERE institution_id=iti.institution_id AND specialist_id=sti.specialist_id)
RETURNING *;
-- NEUROLOGISTS in health centre
WITH instit_to_insert AS
(SELECT institution_id, i_name 
FROM healthcare.institution WHERE LOWER(i_name) IN ('health centre')),
spec_to_insert AS
(SELECT specialist_id, s_name
FROM healthcare.specialist)
INSERT INTO healthcare.capacity (institution_id,specialist_id, hiring_target,hiring_current)
SELECT iti.institution_id, sti.specialist_id, 3,2
FROM instit_to_insert iti
JOIN spec_to_insert sti ON LOWER(sti.s_name)='neurologist'
WHERE NOT exists 
(SELECT 1 FROM healthcare.capacity WHERE institution_id=iti.institution_id AND specialist_id=sti.specialist_id)
RETURNING *;
-- NEUROLOGISTS in the rest of institutions
WITH instit_to_insert AS
(SELECT institution_id, i_name 
FROM healthcare.institution WHERE LOWER(i_name) IN ('nursing home','maternity home','dispensary')),
spec_to_insert AS
(SELECT specialist_id, s_name
FROM healthcare.specialist)
INSERT INTO healthcare.capacity (institution_id,specialist_id, hiring_target,hiring_current)
SELECT iti.institution_id, sti.specialist_id, 1,1
FROM instit_to_insert iti
JOIN spec_to_insert sti ON LOWER(sti.s_name)='neurologist'
WHERE NOT exists 
(SELECT 1 FROM healthcare.capacity WHERE institution_id=iti.institution_id AND specialist_id=sti.specialist_id)
RETURNING *;
-- PEDIATRISTS in maternity home
WITH instit_to_insert AS
(SELECT institution_id, i_name 
FROM healthcare.institution WHERE LOWER(i_name) IN ('maternity home')),
spec_to_insert AS
(SELECT specialist_id, s_name
FROM healthcare.specialist)
INSERT INTO healthcare.capacity (institution_id,specialist_id, hiring_target,hiring_current)
SELECT iti.institution_id, sti.specialist_id, 6,5
FROM instit_to_insert iti
JOIN spec_to_insert sti ON LOWER(sti.s_name)='pediatrist'
WHERE NOT exists 
(SELECT 1 FROM healthcare.capacity WHERE institution_id=iti.institution_id AND specialist_id=sti.specialist_id)
RETURNING *;
-- PEDIATRISTS  in hospital
WITH instit_to_insert AS
(SELECT institution_id, i_name 
FROM healthcare.institution WHERE LOWER(i_name) IN ('hospital')),
spec_to_insert AS
(SELECT specialist_id, s_name
FROM healthcare.specialist)
INSERT INTO healthcare.capacity (institution_id,specialist_id, hiring_target,hiring_current)
SELECT iti.institution_id, sti.specialist_id, 2,2
FROM instit_to_insert iti
JOIN spec_to_insert sti ON LOWER(sti.s_name)='pediatrist'
WHERE NOT exists 
(SELECT 1 FROM healthcare.capacity WHERE institution_id=iti.institution_id AND specialist_id=sti.specialist_id)
RETURNING *;
--GERIATRICIANS in hospital
WITH instit_to_insert AS
(SELECT institution_id, i_name 
FROM healthcare.institution WHERE LOWER(i_name) IN ('hospital')),
spec_to_insert AS
(SELECT specialist_id, s_name
FROM healthcare.specialist)
INSERT INTO healthcare.capacity (institution_id,specialist_id, hiring_target,hiring_current)
SELECT iti.institution_id, sti.specialist_id, 1,1
FROM instit_to_insert iti
JOIN spec_to_insert sti ON LOWER(sti.s_name)='geriatrician'
WHERE NOT exists 
(SELECT 1 FROM healthcare.capacity WHERE institution_id=iti.institution_id AND specialist_id=sti.specialist_id)
RETURNING *;
--GERIATRICIANS in nursing home
WITH instit_to_insert AS
(SELECT institution_id, i_name 
FROM healthcare.institution WHERE LOWER(i_name) IN ('nursing home')),
spec_to_insert AS
(SELECT specialist_id, s_name
FROM healthcare.specialist)
INSERT INTO healthcare.capacity (institution_id,specialist_id, hiring_target,hiring_current)
SELECT iti.institution_id, sti.specialist_id, 2,2
FROM instit_to_insert iti
JOIN spec_to_insert sti ON LOWER(sti.s_name)='geriatrician'
WHERE NOT exists 
(SELECT 1 FROM healthcare.capacity WHERE institution_id=iti.institution_id AND specialist_id=sti.specialist_id)
RETURNING *;
-- OCULIST and LARYNGOLOGIST in all institutions
WITH instit_to_insert AS
(SELECT institution_id, i_name 
FROM healthcare.institution WHERE LOWER(i_name) IN ('hospital','nursing home','maternity home','health centre','dispensary')),
spec_to_insert AS
(SELECT specialist_id, s_name
FROM healthcare.specialist)
INSERT INTO healthcare.capacity (institution_id,specialist_id, hiring_target,hiring_current)
SELECT iti.institution_id, sti.specialist_id, 1,1
FROM instit_to_insert iti
JOIN spec_to_insert sti ON LOWER(sti.s_name) in ('laryngologist','oculist')
WHERE NOT exists 
(SELECT 1 FROM healthcare.capacity WHERE institution_id=iti.institution_id AND specialist_id=sti.specialist_id)
RETURNING *;
-- NURSES  in all institutions
WITH instit_to_insert AS
(SELECT institution_id, i_name 
FROM healthcare.institution WHERE LOWER(i_name) IN ('hospital','nursing home','maternity home','health centre','dispensary')),
spec_to_insert AS
(SELECT specialist_id, s_name
FROM healthcare.specialist)
INSERT INTO healthcare.capacity (institution_id,specialist_id, hiring_target,hiring_current)
SELECT iti.institution_id, sti.specialist_id, 25,24
FROM instit_to_insert iti
JOIN spec_to_insert sti ON LOWER(sti.s_name) in ('nurse')
WHERE NOT exists 
(SELECT 1 FROM healthcare.capacity WHERE institution_id=iti.institution_id AND specialist_id=sti.specialist_id)
RETURNING *;



-- Insert details about few nurses in all institutions 
INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Malgorzata','Godek', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='nurse'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) = 'hospital'),
CAST('01-01-2000' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Malgorzata' and last_name='Godek') ;

INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Malgorzata','Zabek', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='nurse'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) = 'nursing home'),
CAST('01-01-2000' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Malgorzata' and last_name='Zabek') ;

INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Malgorzata','Bobek', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='nurse'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) = 'maternity home'),
CAST('01-01-2000' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Malgorzata' and last_name='Bobek') ;

INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Malgorzata','Rabek', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='nurse'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) = 'health centre'),
CAST('01-01-2000' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Malgorzata' and last_name='Rabek') ;

INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Malgorzata','Lebek', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='nurse'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) = 'dispensary'),
CAST('01-01-2000' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Malgorzata' and last_name='Lebek') ;

-- Insert details about neurologist in hospital 
INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Zosia','Neuro', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='neurologist'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name)='hospital'),
CAST('01-01-2000' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Zosia' and last_name='Neuro') ;
-- Insert details about neurologist in health centre
INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Basia','Neuro', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='neurologist'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name)='health centre'),
CAST('01-01-2005' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Basia' and last_name='Neuro') ;

-- Insert details about neurologist in maternity home
INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Kasia','Neuro', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='neurologist'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name)='maternity home'),
CAST('01-01-2015' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Kasia' and last_name='Neuro') ;

-- Insert details about neurologist in dispensary
INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Rysia','Neuro', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='neurologist'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name)='dispensary'),
CAST('01-01-2014' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Rysia' and last_name='Neuro') ;

--Insert details about pediatrists in nursing home
INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Robert','Baby', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='pediatrist'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) = 'nursing home'),
CAST('01-01-2000' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Robert' and last_name='Baby') ;

INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Roberta','Babies', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='pediatrist'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) = 'nursing home'),
CAST('01-01-2001' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Roberta' and last_name='Babies') ;

INSERT INTO healthcare.staff (first_name, last_name, specialist_id ,institution_id,start_date )
SELECT 'Renata','Bab', (SELECT specialist_id FROM healthcare.specialist WHERE LOWER(s_name)='pediatrist'),
(SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) = 'nursing home'),
CAST('01-01-2000' AS DATE)
WHERE NOT EXISTS (SELECT 1 FROM healthcare.staff where first_name ='Renata' and last_name='Bab') ;




-- inserting data about visits of patients
-- Doctor BASIA - 6 visits in January
INSERT INTO healthcare.visit (institution_id,staff_id,patientID,start_date, end_date)
SELECT (SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) ='hospital'), 
staff_id,
'ADX1234','2020-01-02', '2020-01-02'
FROM healthcare.staff 
WHERE LOWER(first_name)='basia'
AND NOT EXISTS (SELECT 1 FROM healthcare.visit WHERE patientID='ADX1234' AND start_date = '2020-01-02' );

INSERT INTO healthcare.visit (institution_id,staff_id,patientID,start_date, end_date)
SELECT (SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) ='hospital'), 
staff_id,
'882645','2020-01-03', '2020-01-03'
FROM healthcare.staff 
WHERE LOWER(first_name)='basia'
AND NOT EXISTS (SELECT 1 FROM healthcare.visit WHERE patientID='882645' AND start_date = '2020-01-03' );

INSERT INTO healthcare.visit (institution_id,staff_id,patientID,start_date, end_date)
SELECT (SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) ='hospital'), 
staff_id,
'186','2020-01-04', '2020-01-04'
FROM healthcare.staff 
WHERE LOWER(first_name)='basia'
AND NOT EXISTS (SELECT 1 FROM healthcare.visit WHERE patientID='186' AND start_date = '2020-01-04' );

INSERT INTO healthcare.visit (institution_id,staff_id,patientID,start_date, end_date)
SELECT (SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) ='hospital'), 
staff_id,
'999999999','2020-01-05', '2020-01-05'
FROM healthcare.staff 
WHERE LOWER(first_name)='basia'
AND NOT EXISTS (SELECT 1 FROM healthcare.visit WHERE patientID='999999999' AND start_date = '2020-01-05' );

INSERT INTO healthcare.visit (institution_id,staff_id,patientID,start_date, end_date)
SELECT (SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) ='hospital'), 
staff_id,
'1000000','2020-01-06', '2020-01-06'
FROM healthcare.staff 
WHERE LOWER(first_name)='basia'
AND NOT EXISTS (SELECT 1 FROM healthcare.visit WHERE patientID='1000000' AND start_date = '2020-01-06' );


--Doctor ZOSIA - 4 visits in January
INSERT INTO healthcare.visit (institution_id,staff_id,patientID,start_date, end_date)
SELECT (SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) ='hospital'), 
staff_id,
'89o99p','2020-01-03', '2020-01-03'
FROM healthcare.staff 
WHERE LOWER(first_name)='zosia'
AND NOT EXISTS (SELECT 1 FROM healthcare.visit WHERE patientID='89o99p' AND start_date = '2020-01-03' );

INSERT INTO healthcare.visit (institution_id,staff_id,patientID,start_date, end_date)
SELECT (SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) ='hospital'), 
staff_id,
'0990','2020-01-04', '2020-01-04'
FROM healthcare.staff 
WHERE LOWER(first_name)='zosia'
AND NOT EXISTS (SELECT 1 FROM healthcare.visit WHERE patientID='0990' AND start_date = '2020-01-04' );


INSERT INTO healthcare.visit (institution_id,staff_id,patientID,start_date, end_date)
SELECT (SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) ='hospital'), 
staff_id,
'00001','2020-01-08', '2020-01-08'
FROM healthcare.staff 
WHERE LOWER(first_name)='zosia'
AND NOT EXISTS (SELECT 1 FROM healthcare.visit WHERE patientID='0001' AND start_date = '2020-01-08' );

INSERT INTO healthcare.visit (institution_id,staff_id,patientID,start_date, end_date)
SELECT (SELECT institution_id FROM healthcare.institution WHERE LOWER(i_name) ='hospital'), 
staff_id,
'1001x','2020-01-14', '2020-01-14'
FROM healthcare.staff 
WHERE LOWER(first_name)='zosia'
AND NOT EXISTS (SELECT 1 FROM healthcare.visit WHERE patientID='1001x' AND start_date = '2020-01-14' );




-----------FINAL QUERY----------------

SELECT EXTRACT(MONTH FROM v.start_date) as mn,count(v.visit_id) as visits, CONCAT(s.first_name,' ',s.last_name) as specialist
FROM healthcare.visit v 
JOIN healthcare.staff s ON s.staff_id= v.staff_id 
GROUP BY EXTRACT(MONTH FROM v.start_date), s.first_name,s.last_name
HAVING count(v.visit_id)<5 


