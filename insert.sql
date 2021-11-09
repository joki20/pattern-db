DELETE FROM scooter WHERE id > 0;
DELETE FROM customer WHERE id > 0;
DELETE FROM adm WHERE id > 0;
DELETE FROM city WHERE id > 0;

--------------------
-- ADMIN TABLE  ----
--------------------

INSERT INTO
    adm (username, password)
VALUES
    ('admin', 'password');


--------------------
-- CUSTOMER TABLE --
--------------------


INSERT INTO 
    customer (username, password, funds, payment_terms)
VALUES 
    ('janni', 'janni', 200.0, 'prepaid'), 
    ('ahlstrm', 'frida', 1000.0, 'credit'),
    ('datalowe', 'lowe', 300.0, 'prepaid'),
    ('jokris', 'johan', 450.0, 'credit');


--------------------
-- CITY TABLE ------
--------------------

INSERT INTO
    city (name, lat_center, lon_center, radius)
VALUES
    ('Tidaholm', 58.1815656, 13.9546027, 0),
    ('Bjästa', 63.2012144, 18.4735663, 0),
    ('Klågerup', 55.5955693, 13.2308113, 0);

select * from city;
--------------------
-- SCOOTER TABLE  --
--------------------

INSERT INTO
    scooter (city_id, battery_level, speed)
VALUES
    (1, 90, 0);

-------------------------------
-- SCOOTER UPDATE, TEST LOG  --
-------------------------------

-- UPDATE
-- 	scooter
-- SET
-- 	customer_id=2,
--     rented=1,
--     speed=25
-- WHERE
-- 	id=1;
-- select * from logg;

-- UPDATE
-- 	scooter
-- SET
-- 	customer_id=NULL,
--     rented=0,
--     speed=0
-- WHERE
-- 	id=1;
-- select * from logg;