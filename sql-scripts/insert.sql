-- choose database (needed for MySQL Docker containers)
USE sctr;

-- Enable LOAD DATA LOCAL INFILE on the server.
--
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';

-- Empty all tables
--
-- DELETE FROM apikeys WHERE key != 0;
DELETE FROM scooter WHERE id > 0;
DELETE FROM customer WHERE id > 0;
DELETE FROM adm WHERE id > 0;
DELETE FROM city WHERE id > 0;
DELETE FROM station WHERE id > 0;
DELETE FROM logg WHERE id > 0;


-- ---------------
-- APIKEYS TABLE  --
-- ---------------

INSERT INTO
    apikeys (client, apikey)
VALUES
    ('customerwebb', '3676397924422645'),
    ('customerapp', '703273357638792F'),
    ('adminwebb', '556A586E32723575'),
    ('scooterclient', '635166546A576E5A'),
    (null, '3272357538782141'),
    (null, '6A576E5A72347537'),
    (null, '51655468576D5A71'),
    (null, '2B4B625065536856'),
    (null, '442A472D4B615064')
;


-- ---------------
-- ADMIN TABLE  --
-- ---------------

INSERT INTO
    adm (username)
VALUES
    ('jannikarlsson'),
    ('fahlstrm'),
    ('datalowe'),
    ('joki20'),
    ('mosbth')
;


-- ------------------
-- CUSTOMER TABLE --
-- ------------------

-- Add SQL to LOAD DATA LOCAL INFILE
LOAD DATA LOCAL INFILE 'customer.csv'
INTO TABLE customer
CHARSET latin1
FIELDS
    TERMINATED BY ',' -- for multiple columns
    ENCLOSED BY '"'
LINES
    TERMINATED BY '\n'
IGNORE 1 LINES -- ignores header
(id, username, token, funds, payment_terms) -- specify insert columns
;


-- ------------------
-- CITY TABLE -------
-- ------------------

INSERT INTO
    city (name, lat_center, lon_center, radius)
VALUES
    ('Skövde', 58.3941248, 13.85349067, 5),
    ('Lund', 55.7106955, 13.2013123, 2),
    ('Uppsala', 59.8615337, 17.6543391, 5)
;


-- ------------------
-- STATION TABLE ----
-- ------------------

-- Add SQL to LOAD DATA LOCAL INFILE
LOAD DATA LOCAL INFILE 'station.csv'
INTO TABLE station
CHARSET latin1
FIELDS
    TERMINATED BY ',' -- for multiple columns
    ENCLOSED BY '"'
LINES
    TERMINATED BY '\n'
IGNORE 1 LINES -- ignores header
(id, city_id, location, lat_center, lon_center, radius, type) -- specify insert columns
;


-- ------------------
-- SCOOTER TABLE  --
-- ------------------

-- Add SQL to LOAD DATA LOCAL INFILE
LOAD DATA LOCAL INFILE 'scooter.csv'
INTO TABLE scooter
CHARSET latin1
FIELDS
    TERMINATED BY ',' -- for multiple columns
    ENCLOSED BY '"'
LINES
    TERMINATED BY '\n'
IGNORE 1 LINES -- ignores header
(id, customer_id, city_id, station_id, lat_pos, lon_pos, speed_kph, battery_level) -- specify insert columns. Column 'status' is default 'active', so don't specify here
;


-- --------------
-- LOGG TABLE  --
-- --------------

-- Add SQL to LOAD DATA LOCAL INFILE
LOAD DATA LOCAL INFILE 'logg.csv'
INTO TABLE logg
CHARSET latin1
FIELDS
    TERMINATED BY ',' -- for multiple columns
    ENCLOSED BY '"'
LINES
    TERMINATED BY '\n'
IGNORE 1 LINES -- ignores header
(id, customer_id, scooter_id, start_time, end_time, start_lat, start_lon, end_lat, end_lon, start_cost, travel_cost, parking_cost, total_cost) -- specify insert columns.
;
