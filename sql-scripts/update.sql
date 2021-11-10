USE sctr; -- choose database (needed for MySQL Docker containers)
-- -----------------------------
-- SCOOTER UPDATE, TEST LOG  --
-- -----------------------------

-- Rent scooter
UPDATE
	scooter
SET
	customer_id=2,
    rented=1,
    speed_kph=25
WHERE
	id=1;
select * from logg;

-- Return scooter
UPDATE
	scooter
SET
	customer_id = NULL,
    rented=0,
    speed_kph=0,
    lat_pos=55.6080612,
    lon_pos=12.996175
WHERE
	id=1;
select * from logg;