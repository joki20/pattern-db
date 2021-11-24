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

INSERT INTO
    customer (username, funds, payment_terms)
VALUES
    ('jannikarlsson', 200.0, 'prepaid'),
    ('fahlstrm', 1000.0, 'invoice'),
    ('datalowe', 300.0, 'prepaid'),
    ('joki20', 450.0, 'invoice'),
    ('mosbth', 600.0, 'prepaid')
;


-- ------------------
-- CITY TABLE -------
-- ------------------

INSERT INTO
    city (name, lat_center, lon_center, radius)
VALUES
    ('Skövde', 58.3941248, 13.85349067, 5),
    ('Lund', 55.7106955, 13.2013123, 2),
    ('Uppsala', 59.8615337, 17.6543391, 5);


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

--
-- -- INSERT INTO
-- --     scooter (city_id, battery_level, speed_kph, lat_pos,
-- --     lon_pos)
-- -- VALUES
-- --     (1, 90, 0, 55.6004584, 13.0083306);
