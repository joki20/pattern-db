USE sctr; -- choose database (needed for MySQL Docker containers)

-- Enable LOAD DATA LOCAL INFILE on the server.
--
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';

-- Empty all tables
--
DELETE FROM scooter WHERE id > 0;
DELETE FROM customer WHERE id > 0;
DELETE FROM adm WHERE id > 0;
DELETE FROM city WHERE id > 0;
DELETE FROM station WHERE id > 0;
DELETE FROM logg WHERE id > 0;

-- ---------------
-- ADMIN TABLE  --
-- ---------------

INSERT INTO
    adm (username, password)
VALUES
    ('admin', 'password');


-- ------------------
-- CUSTOMER TABLE --
-- ------------------

INSERT INTO
    customer (username, password, funds, payment_terms)
VALUES
    ('janni', 'janni', 200.0, 'prepaid'),
    ('ahlstrm', 'frida', 1000.0, 'invoice'),
    ('datalowe', 'lowe', 300.0, 'prepaid'),
    ('jokris', 'johan', 450.0, 'invoice');


-- ------------------
-- CITY TABLE -------
-- ------------------

INSERT INTO
    city (name, lat_center, lon_center, radius)
VALUES
    ('Skövde', 58.396830, 13.853019, 5),
    ('Lund', 55.7067815, 13.1279563, 5),
    ('Uppsala', 59.8332051, 17.5183649, 10);


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
LOAD DATA LOCAL INFILE 'scooter_skovde.csv'
INTO TABLE scooter
CHARSET latin1
FIELDS
    TERMINATED BY ',' -- for multiple columns
    ENCLOSED BY '"'
LINES
    TERMINATED BY '\n'
IGNORE 1 LINES -- ignores header
(id, customer_id, city_id, station_id, lat_pos, lon_pos, active, speed_kph, battery_level, status) -- specify insert columns
;
--
-- -- INSERT INTO
-- --     scooter (city_id, battery_level, speed_kph, lat_pos,
-- --     lon_pos)
-- -- VALUES
-- --     (1, 90, 0, 55.6004584, 13.0083306);
