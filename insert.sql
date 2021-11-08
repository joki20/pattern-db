DELETE FROM customer;

INSERT INTO 
    customer (username, password, funds, payment_terms)
VALUES 
    ('janni', 'janni', 200.0, 'prepaid'), 
    ('ahlstrm', 'frida', 1000.0, 'credit'),
    ('datalowe', 'lowe', 300.0, 'prepaid'),
    ('jokris', 'johan', 450.0, 'credit');

DELETE FROM city;

INSERT INTO
    city (name, lat_center, lon_center, radius)
VALUES
    ('Tidaholm', 58.1815656, 13.9546027, 0),
    ('Bjästa', 63.2012144, 18.4735663, 0),
    ('Klågerup', 55.5955693, 13.2308113, 0);