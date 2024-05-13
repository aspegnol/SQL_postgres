CREATE DATABASE Campaign;

CREATE SCHEMA IF NOT EXISTS campaign;

SET search_path = campaign;




		---1--- Create tables with NOT NULL constraints, default values and generated columns.

--1 Create table 'topic' to record topics of the polls 
CREATE TABLE IF NOT EXISTS campaign.topics (
    topic_id SERIAL,
    tname CHAR(30) NOT NULL,		-- short name of the poll
    description CHAR(50)		-- More detailed description (if needed)
    );
   --2 create table 'ad_types' 
CREATE TABLE IF NOT EXISTS campaign.ad_types (
    ad_type_id SERIAL, 
    atname CHAR(30) NOT NULL		-- type of the ad (name)
    );
--3 table with names of donors and contact informations about them
CREATE TABLE IF NOT EXISTS campaign.donors (
	donor_id SERIAL, 
	dname CHAR(20) NOT NULL, --name of donor. NOT NULL to avoid rows without basic info
	dlast_name CHAR(20),	-- second name of a donor
	contact_info CHAR(50)  -- email, phone number
    );
--4 Create table with list of distrincts where people can vote for the particular candidates  
CREATE TABLE IF NOT EXISTS campaign.distrincts (
	distrinct_id SERIAL,
	diname CHAR(30) UNIQUE NOT NULL -- not null to avoid empty entries, must be unique
	); 
--5 Create table for the positions the candidates might have in the party
CREATE TABLE IF NOT EXISTS campaign.positions (
	position_id SERIAL, 
	short_name CHAR(20) UNIQUE NOT NULL, 
	long_name CHAR(50) -- longer version of the position used in official documents
	);
--6 Create table with list of candidates
CREATE TABLE IF NOT EXISTS campaign.candidates (
	candidate_id SERIAL,
	cname CHAR(20) NOT NULL, -- first name of the candidate
	clast_name CHAR(20),  -- last name of the candidate
	position_id INT ,  -- what position the candidate has in the party
	distrinct_id INT -- where the member is going to candidate
	);
--7 Create table to record the donations (amount, donor, date, for who)
CREATE TABLE IF NOT EXISTS campaign.donations (
	donation_id SERIAL,
	donor_id INT,  -- for unknown donators, there will be a record in donors table 'anonymous'
	candidate_id INT,
	donation_amount DECIMAL(10,2), 
	donation_date DATE
); 
--8 Table for saving data about the events organised by a party
CREATE TABLE IF NOT EXISTS campaign.events (
	event_id SERIAL,
	ename CHAR(50), -- name of the event
	town CHAR(20),
	candidate_id INT,
	start_date DATE,
	end_date DATE 
);
--9 Table to store the names and contact info of volunteers
CREATE TABLE IF NOT EXISTS campaign.volunteers (
	volunteer_id SERIAL,
	vname CHAR(20) NOT NULL, -- first name of a volunteer
	vlast_name CHAR(20),  -- last name of a volunteer
	distrinct_id INT,
	contact_info CHAR(50),
	availability CHAR(30),
	additional_info CHAR(30)
);
--10 A table to store the info about ads (cost, target etc)
CREATE TABLE IF NOT EXISTS campaign.ads (
	ad_id SERIAL,
	aname CHAR(30) NOT NULL, -- name of the ad
	ad_type_id INT,
	target CHAR(30),
	amount DECIMAL(10,2),
	candidate_id INT ,
	start_date DATE,
	end_date DATE 
);
--11 social media accounts and who is responsible for them
CREATE TABLE IF NOT EXISTS campaign.social_media (
	social_media_id SERIAL,
	smname CHAR(30) NOT NULL,  -- name of the social media
	candidate_id INT,
	smadmin CHAR(30) -- admin of the account
);
--12 table to store the polls
CREATE TABLE IF NOT EXISTS campaign.polls (
	poll_id SERIAL,
	pname CHAR(30) NOT NULL, -- name of the poll
	description CHAR(50),
	candidate_id INT,
	quantity INT , 
	results CHAR(50),
	start_date DATE,
	end_date DATE,
	topic_id INT
);
--13 A table with the info where volunteers were involved
CREATE TABLE IF NOT EXISTS campaign.volunteers_involvement (
	v_involvement_id SERIAL,
	volunteer_id INT,
	event_id INT,
	poll_id INT
);




		---2---Create primary and foreign keys.
--PK
--1 
ALTER TABLE campaign.topics DROP CONSTRAINT IF EXISTS topics_pkey CASCADE;
ALTER TABLE campaign.topics ADD PRIMARY KEY (topic_id);
--2
ALTER TABLE campaign.ad_types DROP CONSTRAINT IF EXISTS ad_types_pkey CASCADE;
ALTER TABLE campaign.ad_types ADD PRIMARY KEY (ad_type_id);
--3
ALTER TABLE campaign.donors DROP CONSTRAINT IF EXISTS donors_pkey CASCADE;
ALTER TABLE campaign.donors ADD PRIMARY KEY (donor_id);
--4
ALTER TABLE campaign.distrincts DROP CONSTRAINT IF EXISTS distrincts_pkey CASCADE;
ALTER TABLE campaign.distrincts ADD PRIMARY KEY (distrinct_id);
--5
ALTER TABLE campaign.positions DROP CONSTRAINT IF EXISTS positions_pkey CASCADE;
ALTER TABLE campaign.positions ADD PRIMARY KEY (position_id);
--6
ALTER TABLE campaign.candidates DROP CONSTRAINT IF EXISTS candidates_pkey CASCADE;
ALTER TABLE campaign.candidates ADD PRIMARY KEY (candidate_id);
--7
ALTER TABLE campaign.donations DROP CONSTRAINT IF EXISTS donations_pkey;
ALTER TABLE campaign.donations ADD PRIMARY KEY (donation_id);
--8
ALTER TABLE campaign.events DROP CONSTRAINT IF EXISTS events_pkey CASCADE;
ALTER TABLE campaign.events ADD PRIMARY KEY (event_id);
--9
ALTER TABLE campaign.volunteers DROP CONSTRAINT IF EXISTS volunteers_pkey CASCADE;
ALTER TABLE campaign.volunteers ADD PRIMARY KEY (volunteer_id);
--10
ALTER TABLE campaign.ads DROP CONSTRAINT IF EXISTS ads_pkey;
ALTER TABLE campaign.ads ADD PRIMARY KEY (ad_id);
--11
ALTER TABLE campaign.social_media DROP CONSTRAINT IF EXISTS social_media_pkey;
ALTER TABLE campaign.social_media ADD PRIMARY KEY (social_media_id);
--12
ALTER TABLE campaign.polls DROP CONSTRAINT IF EXISTS polls_pkey CASCADE;
ALTER TABLE campaign.polls ADD PRIMARY KEY (poll_id);
--13
ALTER TABLE campaign.volunteers_involvement DROP CONSTRAINT IF EXISTS volunteers_involvement_pkey;
ALTER TABLE campaign.volunteers_involvement ADD PRIMARY KEY (v_involvement_id);



--FK
--1
ALTER TABLE campaign.candidates DROP CONSTRAINT IF EXISTS candidates_position_id_fkey;
ALTER TABLE campaign.candidates	ADD CONSTRAINT candidates_position_id_fkey
	FOREIGN KEY (position_id) REFERENCES campaign.positions(position_id);

ALTER TABLE campaign.candidates DROP CONSTRAINT IF EXISTS candidates_distrinct_id_fkey;
ALTER TABLE campaign.candidates	ADD CONSTRAINT candidates_distrinct_id_fkey
	FOREIGN KEY (distrinct_id) REFERENCES campaign.distrincts(distrinct_id);
--2
ALTER TABLE campaign.donations DROP CONSTRAINT IF EXISTS donations_donor_id_fkey;
ALTER TABLE campaign.donations	ADD CONSTRAINT donations_donor_id_fkey
	FOREIGN KEY (donor_id) REFERENCES campaign.donors(donor_id);

ALTER TABLE campaign.donations DROP CONSTRAINT IF EXISTS donations_candidate_id_fkey;
ALTER TABLE campaign.donations	ADD CONSTRAINT donations_candidate_id_fkey
	FOREIGN KEY (candidate_id) REFERENCES campaign.candidates(candidate_id);
--3
ALTER TABLE campaign.events DROP CONSTRAINT IF EXISTS events_candidate_id_fkey;
ALTER TABLE campaign.events	ADD CONSTRAINT events_candidate_id_fkey
	FOREIGN KEY (candidate_id) REFERENCES campaign.candidates(candidate_id);
--4
ALTER TABLE campaign.volunteers DROP CONSTRAINT IF EXISTS volunteers_distrinct_id_fkey;
ALTER TABLE campaign.volunteers	ADD CONSTRAINT volunteers_distrinct_id_fkey
	FOREIGN KEY (distrinct_id) REFERENCES campaign.distrincts(distrinct_id);
--5
ALTER TABLE campaign.ads DROP CONSTRAINT IF EXISTS ads_ad_type_id_fkey;
ALTER TABLE campaign.ads ADD CONSTRAINT ads_ad_type_id_fkey
	FOREIGN KEY (ad_type_id)  REFERENCES campaign.ad_types(ad_type_id);

ALTER TABLE campaign.ads DROP CONSTRAINT IF EXISTS ads_candidate_id_fkey;
ALTER TABLE campaign.ads ADD CONSTRAINT ads_candidate_id_fkey
	FOREIGN KEY (candidate_id) REFERENCES campaign.candidates(candidate_id);
--6
ALTER TABLE campaign.social_media DROP CONSTRAINT IF EXISTS social_media_candidate_id_fkey;
ALTER TABLE campaign.social_media ADD CONSTRAINT social_media_candidate_id_fkey
	FOREIGN KEY (candidate_id) REFERENCES campaign.candidates(candidate_id);
--7
ALTER TABLE campaign.polls DROP CONSTRAINT IF EXISTS polls_candidate_id_fkey;
ALTER TABLE campaign.polls	ADD CONSTRAINT polls_candidate_id_fkey
	FOREIGN KEY (candidate_id)  REFERENCES campaign.candidates(candidate_id);
--8
ALTER TABLE campaign.polls DROP CONSTRAINT IF EXISTS polls_topic_id_fkey ;
ALTER TABLE campaign.polls	ADD CONSTRAINT polls_topic_id_fkey
	FOREIGN KEY (topic_id) REFERENCES campaign.topics(topic_id);
--9
ALTER TABLE campaign.volunteers_involvement DROP CONSTRAINT IF EXISTS volunteers_involvement_volunteer_id_fkey;
ALTER TABLE campaign.volunteers_involvement	ADD CONSTRAINT volunteers_involvement_volunteer_id_fkey
	FOREIGN KEY (volunteer_id) REFERENCES campaign.volunteers(volunteer_id);

ALTER TABLE campaign.volunteers_involvement DROP CONSTRAINT IF EXISTS volunteers_involvement_event_id_fkey;
ALTER TABLE campaign.volunteers_involvement	ADD CONSTRAINT volunteers_involvement_event_id_fkey
	FOREIGN KEY (event_id) REFERENCES campaign.events(event_id);

ALTER TABLE campaign.volunteers_involvement DROP CONSTRAINT IF EXISTS volunteers_involvement_poll_id_fkey;
ALTER TABLE campaign.volunteers_involvement	ADD CONSTRAINT volunteers_involvement_poll_id_fkey
	FOREIGN KEY (poll_id)  REFERENCES campaign.polls(poll_id);




		---3--- Create check constraints
ALTER TABLE campaign.donations DROP CONSTRAINT IF EXISTS donations_donation_amount_check;
ALTER TABLE campaign.donations ADD CONSTRAINT donations_donation_amount_check
	CHECK (donation_amount > 0);
 -- check if the event ended later than started 
ALTER TABLE campaign.events DROP CONSTRAINT IF EXISTS events_check;
ALTER TABLE campaign.events ADD CONSTRAINT events_check CHECK (end_date >= start_date);
 -- check if the amount is greater than 0
ALTER TABLE campaign.ads DROP CONSTRAINT IF EXISTS ads_amount_check;
ALTER TABLE campaign.ads ADD CONSTRAINT ads_amount_check CHECK (amount > 0);
-- check if end date is later than start date
ALTER TABLE campaign.ads DROP CONSTRAINT IF EXISTS ads_check;
ALTER TABLE campaign.ads ADD CONSTRAINT ads_check CHECK (end_date >= start_date);
-- quantity can't be lower than 0
ALTER TABLE campaign.polls DROP CONSTRAINT IF EXISTS polls_quantity_check;
ALTER TABLE campaign.polls ADD CONSTRAINT polls_quantity_check CHECK (quantity > 0);
 -- start_date can't be later than end_date
ALTER TABLE campaign.polls DROP CONSTRAINT IF EXISTS polls_check;
ALTER TABLE campaign.polls ADD CONSTRAINT polls_check CHECK (end_date >= start_date);


--OTHER CONSTRAINTS
-- Create constraint to make sure that the combination of the name + last name is unique
ALTER TABLE campaign.candidates DROP CONSTRAINT IF EXISTS uq_candidate;
ALTER TABLE campaign.candidates 
  ADD CONSTRAINT uq_candidate UNIQUE(cname, clast_name);
--The constraint making sure that there wasn't more than 1 donations made by the same donator
 -- at the same time
ALTER TABLE campaign.donations DROP CONSTRAINT IF EXISTS uq_donation;
ALTER TABLE campaign.donations  
  ADD CONSTRAINT uq_donation UNIQUE(donor_id, donation_date);
--The constraint making sure that there are no the same records related to volunteers 
-- in the same area
ALTER TABLE campaign.volunteers DROP CONSTRAINT IF EXISTS uq_volunteer;
ALTER TABLE campaign.volunteers  
  ADD CONSTRAINT uq_volunteer UNIQUE(vname, vlast_name, distrinct_id);
-- make sure only one kind of ad will run for the particular candidate
ALTER TABLE campaign.ads DROP CONSTRAINT IF EXISTS uq_ad;
ALTER TABLE campaign.ads  
  ADD CONSTRAINT uq_ad UNIQUE(aname, ad_type_id, candidate_id);
 -- One candidate should have only one account in a particular social media
ALTER TABLE campaign.social_media DROP CONSTRAINT IF EXISTS uq_social_media;
ALTER TABLE campaign.social_media  
  ADD CONSTRAINT uq_social_media UNIQUE(smname, candidate_id);
-- Make sure that the volunteer didn't take part in the same event/poll twice
ALTER TABLE campaign.volunteers_involvement DROP CONSTRAINT IF EXISTS uq_volunteers_involvement;
ALTER TABLE campaign.volunteers_involvement 
  ADD CONSTRAINT uq_volunteers_involvement UNIQUE(volunteer_id, event_id, poll_id);



		---4---Fill the tables
--1 Insert into 'topics' 3 records with the check if there's already similar entries   
INSERT INTO campaign.topics (tname, description)
	SELECT 'Support for government' as tname, 'How people are satisfied with current government' as description 
	WHERE NOT EXISTS (SELECT * FROM campaign.topics WHERE LOWER(tname) like 'support for government%'); -- don't insert if already inserted
INSERT INTO campaign.topics (tname, description)
	SELECT 'Eurozone' as tname, 'Should Poland join euro area'  as description 
	WHERE NOT EXISTS (SELECT * FROM campaign.topics WHERE LOWER(tname) like 'eurozone%');-- don't insert if already inserted
INSERT INTO campaign.topics (tname, description)
	SELECT 'Pollution cost' as tname, 'Who should pay for reduction of pollution'  as description 
	WHERE NOT EXISTS (SELECT * FROM campaign.topics WHERE LOWER(tname) like '%pollution%' and LOWER(tname) like '%cost%');-- don't insert if already inserted
--2 Inserting data into campaign.ad_types
INSERT INTO campaign.ad_types (atname)
	SELECT 'bilboard' WHERE NOT EXISTS (SELECT * FROM campaign.ad_types WHERE LOWER(atname) like 'bilboard%');-- don't insert if already inserted
INSERT INTO campaign.ad_types (atname)
	SELECT 'TV advertising' WHERE NOT EXISTS (SELECT * FROM campaign.ad_types WHERE LOWER(atname) like 'tv advertising%');-- don't insert if already inserted
INSERT INTO campaign.ad_types (atname)
	SELECT 'direct mailing' WHERE NOT EXISTS (SELECT * FROM campaign.ad_types WHERE LOWER(atname) like 'direct mailing%');-- don't insert if already inserted
INSERT INTO campaign.ad_types (atname)
	SELECT 'podcast' WHERE NOT EXISTS (SELECT * FROM campaign.ad_types WHERE LOWER(atname) like 'podcast%');-- don't insert if already inserted
INSERT INTO campaign.ad_types (atname)
	SELECT 'Radio' WHERE NOT EXISTS (SELECT * FROM campaign.ad_types WHERE LOWER(atname) like 'radio%');-- don't insert if already inserted
--3 Inserting data into campaign.donors table
INSERT INTO campaign.donors (dname,dlast_name,contact_info)
	SELECT 'Bruce','Willis','bruce@willis.com' 
	WHERE NOT EXISTS
	(SELECT * FROM campaign.donors WHERE LOWER(dname) like 'bruce%' and LOWER(dlast_name) like 'willis');-- don't insert if already inserted
INSERT INTO campaign.donors (dname,contact_info)
	SELECT 'anonymous','no data' 
	WHERE NOT EXISTS
	(SELECT * FROM campaign.donors WHERE LOWER(dname) like 'anonymous%');-- don't insert if already inserted
INSERT INTO campaign.donors (dname,contact_info)
	SELECT 'Rihanna','+1246 623 9886' 
	WHERE NOT EXISTS
	(SELECT * FROM campaign.donors WHERE LOWER(dname) like 'rihanna%');-- don't insert if already inserted
--4 Inserting data to the table 'positions'
INSERT INTO campaign.positions (short_name, long_name)
VALUES 
	('member', 'member of the party'),
	('leader','party leader'),
	('secretary','secretary of the party')
ON CONFLICT (short_name) DO NOTHING;
--5 Inserting data into 'campaign.distrincts' table
INSERT INTO campaign.distrincts (diname) 
VALUES 
	('Pomerania'),
	('Mazovia')
ON CONFLICT (diname) DO NOTHING; -- checking unique names and not inserting if already exists entry
--6 insert data of 2 candidates
INSERT INTO campaign.candidates (cname, clast_name, position_id, distrinct_id)
	SELECT 
		'Jacek' as cname,
		'Placek' as class_name,
		(SELECT position_ID FROM campaign.positions WHERE LOWER(short_name) = 'member') as position_id,
		(SELECT distrinct_id FROM campaign.distrincts WHERE LOWER(diname) = 'pomerania') as distrinct_id
	UNION ALL
	SELECT 
		'Zosia' as cname,
		'Samosia' as class_name,
		(SELECT position_ID FROM campaign.positions WHERE LOWER(short_name) = 'leader') as position_id, -- ID of leader from 'positions' table
		(SELECT distrinct_id FROM campaign.distrincts WHERE LOWER(diname) = 'mazovia') as distrinct_id -- ID from 'distrincts' table
ON CONFLICT (cname, clast_name) DO NOTHING;  -- checking the combination of first name and last name if exist in table
--7 insert some donations to 'donations' table
INSERT INTO campaign.donations (donor_id, candidate_id,donation_amount,donation_date)
-- one donation made by Rihanna for one candidate Jacek
	(SELECT cd.donor_id, MAX(cc.candidate_id) as candidate_id, 500 as donation_amount, CAST('2023-01-01' AS DATE) as donation_date
	FROM campaign.donors cd
	JOIN campaign.candidates cc ON cc.cname ='Jacek'
	WHERE LOWER(cd.dname) = 'rihanna' 
	GROUP BY cd.donor_id
	UNION ALL
-- cross join of donors who are not Rihanna and the candidates who are not Jacek
	SELECT cd.donor_id, cc.candidate_id as candidate_id, 1000 as donation_amount, CAST('2023-03-06' AS DATE) as donation_date
	FROM campaign.donors cd
	JOIN campaign.candidates cc ON cc.cname <>'Jacek'
	WHERE LOWER(cd.dname) <> 'rihanna'
)
ON CONFLICT (donor_id, donation_date) DO NOTHING -- if the donor made a donation during particular time, 0 rows will be added
RETURNING * ;
--8 Inserting data about 2 events 
INSERT INTO campaign.events (ename, town, candidate_id, start_date, end_date)
	SELECT 
		'Debate about future of EU' as ename, 
		'Warsaw' as town, 
		(SELECT MAX(cc.candidate_id) FROM campaign.candidates cc) as candidate_id, 
		CAST('2020-12-20' AS DATE) as start_date, 
		NULL as end_date -- at this moment, we don't know when the event will end
	WHERE 'Debate about future of EU' NOT IN (SELECT ename FROM campaign.events) -- if such event exists in a table, do nothing 
	UNION ALL
	SELECT 
		'Protest of nurses - the support' as ename, 
		'Krakow' as town, 
		NULL as candidate_id, -- the candidate is not specified
		CAST('2023-01-11' AS DATE) as start_date, 
		CAST('2023-01-11' AS DATE) as end_date
	WHERE 'Protest of nurses - the support' NOT IN (SELECT ename FROM campaign.events) -- if such event exists in a table, do nothing 
RETURNING * ;
--9 Inserting data about volunteers
INSERT INTO campaign.volunteers (vname, vlast_name, distrinct_id, contact_info, availability, additional_info)
	SELECT 
		'John' as vname,
		'Smith' as last_name,
		MAX(distrinct_id) as distrinct_id,
		'+1 23 456 89 90' as contact_info,
		'weekends, holidays' as availability,
		'' as additional_info
	FROM campaign.distrincts
	UNION ALL
	SELECT 
		'Paul' as vname,
		'Christian' as last_name,
		MIN(distrinct_id) as distrinct_id,
		'paul@christian.com, =58 332 667 36' as contact_info,
		'March' as availability,
		'don''t call him at night' as additional_info
	FROM campaign.distrincts
ON CONFLICT (vname, vlast_name, distrinct_id) DO NOTHING
RETURNING *;
--10 insert data about 2 ads
INSERT INTO  campaign.ads (aname, ad_type_id, target, amount, candidate_id, start_date, end_date)
	SELECT 
		'How to vote - TV commercial' as aname,
		cat.ad_type_id as ad_type_id,
		'60+' as target, -- for older people
		50000 as amount,
		cc.candidate_id as candidate_id,
		CAST('2023-01-10' AS DATE) as start_date,
		CAST('2023-02-10' AS DATE) as end_date
	FROM campaign.ad_types as cat
	JOIN campaign.positions cp ON cp.short_name = 'member'
	JOIN campaign.candidates cc ON cc.position_id =cp.position_id
	WHERE cat.atname like  'TV%'
	UNION ALL
	SELECT 
		'Our prime minister' as aname,
		cat.ad_type_id as ad_type_id,
		'East Poland' as target, -- for older people
		300000 as amount,
		cc.candidate_id as candidate_id,
		CAST('2023-02-01' AS DATE) as start_date,
		CAST('2023-04-30' AS DATE) as end_date
	FROM campaign.ad_types as cat
	JOIN campaign.positions cp ON cp.short_name = 'leader'
	JOIN campaign.candidates cc ON cc.position_id =cp.position_id 
	WHERE cat.atname like  'bilboard%'
ON CONFLICT(aname, ad_type_id, candidate_id) DO nothing 
RETURNING *;
--11 insert data about the social media accounts
INSERT INTO  campaign.social_media (smname, candidate_id, smadmin)
	SELECT 
		'facebook' as smname,
		MAX(cc.candidate_id) as candidate_id,
		'DJ hacker' as amadmin
	FROM campaign.candidates cc 
	UNION ALL
	SELECT 
		'instagram' as smname,
		MAX(cc.candidate_id) as candidate_id,
		'' as amadmin
	FROM campaign.candidates cc 
	UNION ALL
	SELECT 
		'facebook' as smname,
		MIN(cc.candidate_id) as candidate_id,
		'DJ hacker' as amadmin
	FROM campaign.candidates cc 
ON CONFLICT(smname, candidate_id) DO nothing 
RETURNING *;
--12 insert data to polls table
INSERT INTO campaign.polls (pname, description, candidate_id, quantity, results, start_date, end_date, topic_id)
SELECT pname, description, candidate_id, quantity, results, start_date, end_date, topic_id
FROM 
(SELECT distinct
	'Currency' as pname,
	'Eurozone - east Poland' as description,
	max(candidate_id) as candidate_id,
	50 as quantity,
	'33% agree, 40% disagree, 27% no opinion' as results,
	CAST('2023-01-01' as DATE) as start_date,
	CAST('2023-01-01' as DATE) as end_date,
	ct.topic_id as topic_id
FROM campaign.candidates cc 
JOIN campaign.topics ct ON LOWER(ct.tname)='eurozone' 
GROUP BY ct.topic_id
UNION ALL 
SELECT distinct
	'Currency' as pname,
	'Eurozone - west  Poland' as desription,
	min(candidate_id) as candidate_id,
	83 as quantity,
	'63% agree, 10% disagree, 27% no opinion' as results,
	CAST('2023-01-05' as DATE) as start_date,
	CAST('2023-01-08' as DATE) as end_date,
	ct.topic_id as topic_id
FROM campaign.candidates cc 
JOIN campaign.topics ct ON LOWER(ct.tname)='eurozone'
GROUP BY ct.topic_id
) as temp_polls
WHERE pname NOT IN (SELECT pname FROM campaign.polls)
RETURNING *;
--13 Insert records avout volunteers' involvement
INSERT INTO campaign.volunteers_involvement (volunteer_id, event_id, poll_id)
SELECT * FROM
	(SELECT 
		MAX(volunteer_id) as volunteer_id,
		ce.event_id,
		null as poll_id
	FROM campaign.volunteers cv 
	JOIN campaign.events ce ON ce.town ='Warsaw' 
	GROUP BY ce.event_id 
	UNION ALL 
	SELECT 
		MIN(volunteer_id) as volunteer_id,
		NULL as event_id,
		cp.poll_id
	FROM campaign.volunteers cv 
	JOIN campaign.polls cp ON cp.quantity =50 
	GROUP BY cp.poll_id) as to_insert
	WHERE to_insert.volunteer_id NOT IN (SELECT volunteer_id FROM campaign.volunteers_involvement)
RETURNING *; 

		---5--- Add a column record_ts to each table
ALTER TABLE campaign.topics ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--1
ALTER TABLE campaign.ad_types ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--2
ALTER TABLE campaign.donors ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--3
ALTER TABLE campaign.distrincts ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--4
ALTER TABLE campaign.positions ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--5
ALTER TABLE campaign.candidates ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--6
ALTER TABLE campaign.donations ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--7
ALTER TABLE campaign.events ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--8
ALTER TABLE campaign.volunteers ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--9
ALTER TABLE campaign.ads ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--10
ALTER TABLE campaign.social_media ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--11
ALTER TABLE campaign.polls ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--12
ALTER TABLE campaign.volunteers_involvement ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date NOT NULL;--13

