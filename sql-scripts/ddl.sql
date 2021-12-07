-- ------------------------------------------
-- CREATE TABLES, FUNCTIONS AND TRIGGER LOGIC
-- ------------------------------------------


 -- choose database (needed for MySQL Docker containers)
USE sctr;


-- -----------------------------------
-- DROP TABLES, FUNCTIONS AND TRIGGERS
-- -----------------------------------

-- Drop tables, start with foreign keys to eliminate dependencies
DROP TABLE IF EXISTS apikeys;
DROP TABLE IF EXISTS logg;
DROP TABLE IF EXISTS scooter;
DROP TABLE IF EXISTS station;
DROP TABLE IF EXISTS city;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS adm;
-- drop functions
DROP FUNCTION IF EXISTS deg_to_rad;
DROP FUNCTION IF EXISTS calc_geo_dist;
-- drop triggers
DROP TRIGGER IF EXISTS logg_insert;
DROP TRIGGER IF EXISTS logg_update;


-- -------------
-- CREATE TABLES
-- -------------

CREATE TABLE apikeys
(
    `client` VARCHAR(100),
    `apikey` VARCHAR(64) UNIQUE,

    PRIMARY KEY (`apikey`)
)
ENGINE INNODB
;


CREATE TABLE adm
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `username` VARCHAR(20),
    `token` VARCHAR(200) DEFAULT NULL,

    PRIMARY KEY (`id`)
)
ENGINE INNODB
;

CREATE TABLE customer
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `username` VARCHAR(20) UNIQUE,
    `token` VARCHAR(200) DEFAULT NULL,
    `funds` DECIMAL(7, 2) DEFAULT 0,
    `payment_terms` VARCHAR(7) DEFAULT NULL,

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
    `battery_level` DECIMAL(5,2) DEFAULT 100,
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

-- Set all ID to start from 1
ALTER TABLE scooter AUTO_INCREMENT = 1;
ALTER TABLE customer AUTO_INCREMENT = 1;
ALTER TABLE adm AUTO_INCREMENT = 1;
ALTER TABLE city AUTO_INCREMENT = 1;
ALTER TABLE logg AUTO_INCREMENT = 1;


-- ----------------
-- CREATE FUNCTIONS
-- ----------------

DELIMITER ;;
-- Convert an angle in degrees to radians
CREATE FUNCTION deg_to_rad(
	angle_degrees DECIMAL(9, 6)
)
RETURNS FLOAT
DETERMINISTIC
BEGIN
    RETURN angle_degrees / 180 * PI();
END;;
DELIMITER ;

DELIMITER ;;
-- Given a start/end point, returns 'as-the-crow-flies' distance in kilometers,
-- based on the Haversine formula. (https://www.movable-type.co.uk/scripts/latlong.html)
CREATE FUNCTION calc_geo_dist(
	start_lat DECIMAL(9, 6),
    start_lon DECIMAL(9, 6),
    end_lat DECIMAL(9, 6),
    end_lon DECIMAL(9, 6)
)
RETURNS FLOAT
DETERMINISTIC
BEGIN
    SET @EARTH_RADIUS_KM = 6371;
    SET @start_lat_r = deg_to_rad(start_lat);
    SET @start_lon_r = deg_to_rad(start_lon);
    SET @end_lat_r = deg_to_rad(end_lat);
    SET @end_lon_r = deg_to_rad(end_lon);
    SET @d_lat_r = @end_lat_r - @start_lat_r;
    SET @d_lon_r = @end_lon_r - @start_lon_r;
    SET @a_term1 = POWER(SIN(@d_lat_r / 2), 2);
    SET @a_term2 = COS(@start_lat_r) * COS(@end_lat_r) * POWER(SIN(@d_lon_r / 2), 2);
    SET @a = @a_term1 + @a_term2;
    SET @c = 2 * ATAN2(SQRT(@a), SQRT(1-@a));
    RETURN @EARTH_RADIUS_KM * @c;
END;;
DELIMITER ;


-- ----------------
-- CREATE TRIGGERS
-- ----------------

DELIMITER ;;
-- This trigger will insert a new travel log entry when a customer is assigned to a scooter
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
-- This trigger updates current travel log entry when customer not assigned anymore to scooter
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


        -- IF USER HAS PREPAID, HANDLE PAYMENT AUTOMATICALLY
        --
        SET @payment_choice = (SELECT payment_terms FROM customer WHERE id = OLD.customer_id);

        IF @payment_choice = 'prepaid' THEN
            UPDATE customer
            SET
                funds = funds - @total_cost,
                payment_terms = IF(funds - @total_cost < 0, "invoice", field)
            WHERE
                id = (SELECT * FROM (SELECT id FROM customer WHERE id = OLD.customer_id LIMIT 1) AS l);
        END IF;
    END IF;
END
;;
DELIMITER ;
