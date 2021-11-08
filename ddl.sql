-- All code with tables, views, procedures, triggers, and so on.
-- DROP TABLES, START WITH FOREIGN KEYS TO ELIMINATE DEPENDENCIES
DROP TABLE IF EXISTS logg;
DROP TABLE IF EXISTS scooter;
DROP TABLE IF EXISTS station;
DROP TABLE IF EXISTS city;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS adm;

DROP VIEW IF EXISTS v_logg;

-- --------------------------------------------------------------------------------------
--
-- produkt, kategori, produkt2lager
--
CREATE TABLE adm
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `username` CHAR(20),
    `password` CHAR(255), -- https://www.php.net/manual/en/function.password-hash.php

    PRIMARY KEY (`id`)
)
ENGINE INNODB
;

CREATE TABLE customer
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `username` CHAR(20) UNIQUE,
    `password` CHAR(255),
    `funds` DECIMAL DEFAULT 0,
    `payment_terms` CHAR(10),

    PRIMARY KEY (`id`)
)
ENGINE INNODB
-- CHARSET utf8mb4
-- COLLATE utf8_swedish_ci
;

CREATE TABLE city
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` CHAR(20) NOT NULL UNIQUE,
    `lat_center` DECIMAL(8,6),
    `lon_center` DECIMAL(9,6),
    `radius` DECIMAL,

    PRIMARY KEY (`id`)
)
ENGINE INNODB
;

CREATE TABLE station
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `city_id` INT,
    `location` CHAR(20),
    `lat_center` DECIMAL,
    `lon_center` DECIMAL,
    `radius` DECIMAL DEFAULT 0.002,
    `charge` BOOLEAN NOT NULL DEFAULT 1, -- true

    PRIMARY KEY (`id`),
    FOREIGN KEY (`city_id`) REFERENCES `city` (`id`)
)
ENGINE INNODB
;

CREATE TABLE scooter
(
    `id` INT NOT NULL AUTO_INCREMENT,
    `customer_id` INT,
    `city_id` INT,
    `station_id` INT,
    `rented` BOOLEAN DEFAULT 0, -- false
    `lat_pos` DECIMAL,
    `lon_pos` DECIMAL,
    `maintenance_mode` BOOLEAN DEFAULT 0, -- false
    `active` BOOLEAN DEFAULT 1, -- true
    `speed` DECIMAL,
    `battery_level` DECIMAL,

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
    `end_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `start_lat` DECIMAL,
    `start_lon` DECIMAL,
    `end_lat` DECIMAL,
    `end_lon` DECIMAL,
    `total_cost` DECIMAL DEFAULT 0,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
    FOREIGN KEY (`scooter_id`) REFERENCES `scooter` (`id`)
)
ENGINE INNODB
;

DROP TRIGGER IF EXISTS logg_insert;
DROP TRIGGER IF EXISTS logg_update;

DELIMITER ;;
CREATE TRIGGER logg_insert
AFTER UPDATE
ON scooter FOR EACH ROW -- chech each table row
BEGIN
    -- if a customer is assigned to scooter
    IF (OLD.customer_id = NULL AND NEW.customer_id != NULL) THEN
        -- insert new entry into logg table user, scooter, start time, lat, lot
        INSERT INTO logg (customer_id, scooter_id, start_time, start_lat, start_lon, total_cost)
        VALUES (NEW.customer_id, NEW.id, NOW(), OLD.lat_pos, OLD.lon_pos, @start_cost);

        -- UPDATE SCOOTER STATUS
        --
        -- NOTE: a button press will add customer_id for this scooter
        UPDATE scooter
        SET
            rented = 1,
            speed = 25 -- km/h
        WHERE
            id = (SELECT id FROM scooter WHERE id=NEW.id);
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
    IF (OLD.customer_id != NULL AND NEW.customer_id = NULL) THEN
        -- start cost
        SET @start_cost = 20;
        -- travelling cost
        SET @price_per_min = 2.50;
        SET @start_time = (SELECT start_time FROM logg WHERE customer_id = OLD.customer_id ORDER BY id DESC LIMIT 1);
        SET @minutes_traveled = TIMESTAMPDIFF(MINUTE, @start_time, NOW());
        SET @travel_cost = @price_per_min * @minutes_traveled;
        -- parking prices
        SET @parking_cost_station = 20;
        SET @parking_cost_zone = 30;
        SET @parking_cost_unallowed = 100;
        -- total cost
        SET @total_cost = 0;
        -- start points
        SET @start_lat = (SELECT start_lat FROM logg WHERE customer_id = OLD.customer_id ORDER BY id DESC LIMIT 1);
        SET @start_lon = (SELECT start_lon FROM logg WHERE customer_id = OLD.customer_id ORDER BY id DESC LIMIT 1);

        -- 1 if started outside of zone, 0 if started within zone or at station
        SET @started_outside_zone = (
            SELECT EXISTS (
                SELECT * FROM station
                WHERE
                    -- not within allowed radius
                    NOT ABS(NEW.lat_pos-lat_center) <= radius OR
                    NOT ABS(NEW.lon_pos-lat_center) <= radius
            )
        );


        -- PARKING AT A CHARGING STATION OR A ZONE
        --
        -- check if parked at a STATION, sets 0 or 1
        SET @ends_station = (
            SELECT EXISTS (
                SELECT * FROM station
                WHERE
                    charge = 1 -- indicates station
                AND
                    ABS(NEW.lat_pos-lat_center) <= radius
                AND
                    ABS(NEW.lat_pos-lat_center) <= radius
            )
		);
        -- check if parked within radius of any station but NOT at a station, sets 0 or 1
        SET @ends_zone = (
            SELECT EXISTS (
                SELECT * FROM station
                WHERE
                    charge = 0 -- indicates zone
                AND
                    ABS(NEW.lat_pos-lat_center) <= radius
                AND
                    ABS(NEW.lon_pos-lat_center) <= radius
            )
        );


        -- PAYMENT
        --
        -- INVOICE
        IF (SELECT payment_terms FROM customer WHERE id = OLD.customer_id) = 'invoice' THEN
        -- if scooter was collected outside allowed zone and parked near charging station or zone, give discount
            IF @started_outside_zone = 1 AND (@ends_station = 1 OR @ends_zone = 1) THEN
                SET @start_cost = @start_cost - 10; -- 10 kr discount
            END IF;

            -- if ending at a station, add station cost
            IF @ends_station = 1 THEN
                SET @total_cost = @start_cost + @travel_cost + @parking_cost_station;
            -- if ending in a zone but not at a station, add zone cost
            ELSEIF @ends_zone = 1 THEN
                SET @total_cost = @start_cost + @travel_cost + @parking_cost_zone;
            -- if not ending within allowed zone, add unallowed (and expensive) parking cost
            ELSEIF @ends_station = 0 AND @ends_zone = 0 THEN
                SET @total_cost = @start_cost + @travel_cost + @parking_cost_unallowed;
            END IF;
        -- -- AUTOGIRO
        ELSE
            SET @total_cost = 0;
        END IF;


        -- UPDATE CUSTOMER LOG ENTRY
        --
        UPDATE logg
        SET
            end_time = NOW(),
            end_lat = NEW.lat_pos,
            end_lon = NEW.lon_pos,
            total_cost = @start_cost
        WHERE  -- find latest id (current travel log) with this customer
            id = (SELECT id FROM logg WHERE customer_id=OLD.customer_id ORDER BY id DESC LIMIT 1);


        -- UPDATE SCOOTER STATUS
        --
        -- NOTE: a button press will remove customer_id from this scooter
        UPDATE scooter
        SET
            customer_id = NULL,
            rented = 0,
            speed = 0
        WHERE
            id = (SELECT id FROM scooter WHERE id=NEW.id);

    END IF;
END
;;
DELIMITER ;



-- orderrad, produktid, produkt, antal, pris, totalpris, summa
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


