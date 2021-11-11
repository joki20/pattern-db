USE sctr; -- choose database (needed for MySQL Docker containers)
-- -----------------------------
-- SCOOTER UPDATE, TEST LOG  --
-- -----------------------------

-- Rent scooter (user with 'prepaid' payment form)
UPDATE
	scooter
SET
	customer_id=1,
    rented=1,
    speed_kph=25
WHERE
	id=1;

-- Return scooter far outside of home city radius (user with 'prepaid' payment form)
UPDATE
	scooter
SET
	customer_id = NULL,
    rented=0,
    speed_kph=0,
    lat_pos=55.608061,
    lon_pos=12.996175
WHERE
	id=1;


-- Rent scooter far outside of home city radius (user with 'invoice' payment form)
UPDATE
	scooter
SET
	customer_id=2,
    rented=1,
    speed_kph=25
WHERE
	id=1;

-- Return scooter far outside of home city radius  (user with 'invoice' payment form)
-- should lead to 'penalty cost' being added because user parked outside of home city
UPDATE
	scooter
SET
	customer_id = NULL,
    rented=0,
    speed_kph=0,
    lat_pos=55.608065,
    lon_pos=12.996179
WHERE
	id=1;

-- Rent scooter far outside of home city radius (user with 'invoice' payment form)
UPDATE
	scooter
SET
	customer_id=2,
    rented=1,
    speed_kph=25
WHERE
	id=1;

-- Return scooter inside of home city radius, but not within a station's radius  (user with 'invoice' payment form)
-- should lead to 'discount'/lowered start cost being applied because user parked outside of home city
-- and 'parking within city' cost being added.
UPDATE
	scooter
SET
	customer_id = NULL,
    rented=0,
    speed_kph=0,
    lat_pos=58.1815656,
    lon_pos=13.9546127
WHERE
	id=1;



-- Rent scooter placed within home city radius (user with 'invoice' payment form)
UPDATE
	scooter
SET
	customer_id=2,
    rented=1,
    speed_kph=25
WHERE
	id=1;

-- Return scooter inside of station (user with 'invoice' payment form)
-- should lead to 'parking within station' cost being added.
UPDATE
	scooter
SET
	customer_id = NULL,
    rented=0,
    speed_kph=0,
    lat_pos=58.1815656,
    lon_pos=13.9546027
WHERE
	id=1;

SELECT * FROM logg;
