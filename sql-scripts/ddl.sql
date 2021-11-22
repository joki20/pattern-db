USE sctr; -- choose database (needed for MySQL Docker containers)
-- All code with tables, views, procedures, triggers, and so on.
-- DROP TABLES, START WITH FOREIGN KEYS TO ELIMINATE DEPENDENCIES
DROP TABLE IF EXISTS logg;
DROP TABLE IF EXISTS scooter;
DROP TABLE IF EXISTS station;
DROP TABLE IF EXISTS city;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS adm;

-- drop functions
DROP FUNCTION IF EXISTS calc_geo_dist;

DROP TRIGGER IF EXISTS logg_insert;
DROP TRIGGER IF EXISTS logg_update;

DROP VIEW IF EXISTS v_logg;



CREATE TABLE adm
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `username` VARCHAR(20),
    `password` CHAR(255), -- https://www.php.net/manual/en/function.password-hash.php

    PRIMARY KEY (`id`)
)
ENGINE INNODB
;

CREATE TABLE customer
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `username` VARCHAR(20) UNIQUE,
    `password` CHAR(255),
    `funds` DECIMAL(7, 2) DEFAULT 0,
    `payment_terms` ENUM('invoice','prepaid') DEFAULT 'invoice',

    PRIMARY KEY (`id`)
)
ENGINE INNODB
;

CREATE TABLE city
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(20) NOT NULL UNIQUE,
    `lat_center` DECIMAL(9,6),
    `lon_center` DECIMAL(9,6),
    `radius` DECIMAL(3, 1),

    PRIMARY KEY (`id`)
)
ENGINE INNODB
;

CREATE TABLE station
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `city_id` INT,
    `location` VARCHAR(20),
    `lat_center` DECIMAL(9,6),
    `lon_center` DECIMAL(9,6),
    `radius` DECIMAL(4, 3) DEFAULT 0.002,
    `type` ENUM('charge','park') DEFAULT 'charge',

    PRIMARY KEY (`id`),
    FOREIGN KEY (`city_id`) REFERENCES `city` (`id`)
)
ENGINE INNODB
;

CREATE TABLE scooter
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `customer_id` INT DEFAULT NULL,
    `city_id` INT,
    `station_id` INT,
    `lat_pos` DECIMAL(9,6),
    `lon_pos` DECIMAL(9,6),
    `speed_kph` INT DEFAULT 0,
    `battery_level` INT DEFAULT 100,
    `status` ENUM('active', 'inactive', 'maintenance') DEFAULT 'active',

    PRIMARY KEY (`id`),
    FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
    FOREIGN KEY (`city_id`) REFERENCES `city` (`id`),
    FOREIGN KEY (`station_id`) REFERENCES `station` (`id`)
)
ENGINE INNODB
;

CREATE TABLE logg
(
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `customer_id` INT,
    `scooter_id` INT,
    `start_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `end_time` DATETIME DEFAULT NULL,
    `start_lat` DECIMAL(9,6),
    `start_lon` DECIMAL(9,6),
    `end_lat` DECIMAL(9,6),
    `end_lon` DECIMAL(9,6),
    `start_cost` DECIMAL(7, 2) DEFAULT 0,
    `travel_cost` DECIMAL(7,2) DEFAULT 0,
    `parking_cost` DECIMAL(7, 2) DEFAULT 0,
    `total_cost` DECIMAL(7, 2) DEFAULT 0,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
    FOREIGN KEY (`scooter_id`) REFERENCES `scooter` (`id`)
)
ENGINE INNODB
;


-- SET ALL ID TO START FROM 1
ALTER TABLE scooter AUTO_INCREMENT = 1;
ALTER TABLE customer AUTO_INCREMENT = 1;
ALTER TABLE adm AUTO_INCREMENT = 1;
ALTER TABLE city AUTO_INCREMENT = 1;
ALTER TABLE logg AUTO_INCREMENT = 1;


--
-- functions
-- ----------------
DELIMITER ;;
-- Calculate distance in degrees between
-- two geographical locations, based on their
-- lat-/longitudes (using Pythagora's theorem)
-- Note that this function
-- assumes that the earth is 'flat', ie that
-- one degree in 'latitudinal' direction is the same
-- as one degree in 'longitudinal' direction regardless
-- of where the points are located on Earth, so don't
-- rely on it for calculating longer distances or truly
-- critical calculations.
CREATE FUNCTION calc_geo_dist(
	start_lat DECIMAL(9, 6),
    start_lon DECIMAL(9, 6),
    end_lat DECIMAL(9, 6),
    end_lon DECIMAL(9, 6)
)
RETURNS INT
DETERMINISTIC
BEGIN
	SET @delta_lat = end_lat - start_lat;
    SET @delta_lon = end_lon - start_lon;
    RETURN SQRT(POWER(@delta_lat, 2) + POWER(@delta_lon, 2));
END;;
DELIMITER ;

DROP TRIGGER IF EXISTS logg_insert;
DROP TRIGGER IF EXISTS logg_update;

DELIMITER ;;
CREATE TRIGGER logg_insert
AFTER UPDATE
ON scooter FOR EACH ROW -- chech each table row
BEGIN
    -- if a customer is assigned to scooter
    IF (
        OLD.customer_id IS NULL AND
        NOT NEW.customer_id IS NULL
        ) THEN

        -- insert new entry into logg table user, scooter, start time, lat, lot
        INSERT INTO logg (customer_id, scooter_id, start_time, start_lat, start_lon)
        VALUES (NEW.customer_id, NEW.id, NOW(), OLD.lat_pos, OLD.lon_pos);


    END IF;
END
;;
DELIMITER ;


DELIMITER ;;
CREATE TRIGGER logg_update
AFTER UPDATE
ON scooter FOR EACH ROW -- chech each table row for changes
-- WHERE filters out latest id row with this customer
BEGIN
    -- scooter row where customer is no longer assigned to specific scooter
    IF (
        NOT OLD.customer_id IS NULL AND
        NEW.customer_id IS NULL
        ) THEN
        -- start cost
        SET @start_cost = 20;
        -- travelling cost
        SET @price_per_min = 2.50;
        SET @start_time = (SELECT start_time FROM logg WHERE customer_id = OLD.customer_id ORDER BY id DESC LIMIT 1);
        SET @minutes_traveled = TIMESTAMPDIFF(MINUTE, @start_time, NOW());
        SET @travel_cost = @price_per_min * @minutes_traveled;
        -- parking price at a station
        SET @parking_cost = 20;
        -- discount for bringing scooter parked outside of city inside city
        SET @bring_home_discount = 10;
        -- total cost
        SET @total_cost = 0;
        -- start points
        SET @start_lat = (SELECT start_lat FROM logg WHERE customer_id = OLD.customer_id ORDER BY id DESC LIMIT 1);
        SET @start_lon = (SELECT start_lon FROM logg WHERE customer_id = OLD.customer_id ORDER BY id DESC LIMIT 1);

        -- 0 if started outside of associated city, 1 if started within city
        SET @started_inside_city = (
            SELECT EXISTS (
                SELECT * FROM city
                WHERE
                    id = OLD.city_id
                    AND calc_geo_dist(@start_lat, @start_lon, lat_center, lon_center) <= radius
            )
        );

        -- PARKING AT STATION AND/OR IN CITY ZONE
        --
        -- 0 if ended/parked outside of 'station/parking zone', 1 if ended/parked within
        SET @ended_at_station = (
            SELECT EXISTS (
                SELECT * FROM station
                WHERE
                    calc_geo_dist(@start_lat, @start_lon, lat_center, lon_center) <= radius
            )
		);
        -- 0 if ended outside of associated city, 1 if ended within city
        SET @ended_inside_city = (
            SELECT EXISTS (
                SELECT * FROM city
                WHERE
                    id = OLD.city_id
                    AND calc_geo_dist(NEW.lat_pos, NEW.lon_pos, lat_center, lon_center) <= radius
            )
        );

        -- TOTAL COST FOR SINGLE SCOOTER TRIP
        --

        -- if scooter was collected outside allowed zone and parked near charging station or zone, give discount
        IF @started_inside_city = 0 AND @ended_inside_city = 1 THEN
            SET @start_cost = @start_cost - @bring_home_discount;
        END IF;

        -- if ending at a station, add normal parking cost
        IF @ended_at_station = 1 THEN
            SET @total_cost = @start_cost + @travel_cost + @parking_cost;
        -- if ending in city but not at a station, add city cost
        ELSEIF @ended_inside_city = 1 THEN
            SET @parking_cost = @parking_cost + 20;
            SET @total_cost = @start_cost + @travel_cost + (@parking_cost);
        -- if not ending within allowed zone, add unallowed (and expensive) cost
        ELSE
            SET @parking_cost = @parking_cost + 80;
            SET @total_cost = @start_cost + @travel_cost + @parking_cost;
        END IF;


        -- UPDATE CUSTOMER LOG ENTRY
        --
        UPDATE logg
        SET
            end_time = NOW(),
            end_lat = NEW.lat_pos,
            end_lon = NEW.lon_pos,
            start_cost = @start_cost,
            travel_cost = @travel_cost,
            parking_cost = @parking_cost,
            total_cost = @total_cost
        WHERE  -- find latest id (current travel log) with this customer
            id = (SELECT * FROM (SELECT id FROM logg WHERE customer_id=OLD.customer_id ORDER BY id DESC LIMIT 1) AS l);
    END IF;
END
;;
DELIMITER ;



CREATE VIEW v_logg AS
SELECT
    cus.username AS username, -- don't change column names to simplify for frontend
    s.location,
    l.start_time,
    l.end_time,
    l.start_lat,
    l.start_lon,
    l.end_lat,
    l.end_lon,
    l.total_cost,
    c.name
FROM customer AS cus
LEFT JOIN logg as l
ON cus.id = l.customer_id
LEFT JOIN scooter as sc
ON sc.id = l.scooter_id
LEFT JOIN station as s
ON s.id = sc.station_id
LEFT JOIN city as c
ON c.id = s.id
;


-- EXAMPLES OF OLDER PROCEDURES BELOW








-- -- PROCEDURES CALLED IN src/eshop.js
-- DROP PROCEDURE IF EXISTS ship_order; -- cli
-- DELIMITER ;;
-- CREATE PROCEDURE ship_order(
--     a_orderid CHAR(20)
-- )

-- BEGIN
--     UPDATE bestallning
--         SET skickad = CURRENT_TIMESTAMP
--     WHERE
--         orderid = a_orderid;

--     -- update lagerantal
--     UPDATE produkt2bestallning as p2b
--     LEFT JOIN produkt2lager AS p2l
--     ON p2b.produkt_id = p2l.produkt_id
--     SET p2l.antal = p2l.antal - p2b.antal
--     WHERE order_id = a_orderid;

--     -- if any lagerantal lower than 0, set to 0
--     UPDATE produkt2lager
--         SET antal = 0
--         WHERE antal < 0;

--     -- AFTER SHIPPED, CREATE FAKTURA ROW
--     INSERT INTO faktura (fakturanummer) VALUES (a_orderid);

--     -- CREATE FAKTURARADER ROWS FOR THAT ORDER, ONE ROW FOR EACH PRODUCT
--     SET @last_faktura_nr = (SELECT fakturanummer FROM faktura ORDER BY fakturanummer DESC LIMIT 1);
--     INSERT INTO fakturarader (order_id, produkt_id)
--     SELECT order_id, produkt_id FROM produkt2bestallning
--     WHERE order_id=@last_faktura_nr;

-- END
-- ;;
-- DELIMITER ;


-- -- PROCEDURES CALLED IN src/eshop.js
-- DROP PROCEDURE IF EXISTS payed_invoice; -- cli
-- DELIMITER ;;
-- CREATE PROCEDURE payed_invoice(
--     a_invoiceid CHAR(20),
--     a_date DATE -- YYYY-MM-DD
-- )
-- BEGIN
--     UPDATE bestallning
--         SET betald = a_date
--     WHERE orderid = a_invoiceid;
-- END;
-- ;;
-- DELIMITER ;
