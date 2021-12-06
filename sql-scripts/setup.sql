-- -----------------------------------
-- CREATE DATABASE AND ADD PRIVILLEGES
-- -----------------------------------

SET NAMES 'utf8';
-- CREATE DATABASE (and test database)
DROP DATABASE IF EXISTS sctr;
DROP DATABASE IF EXISTS test_sctr;
-- set root password
ALTER USER 'root'@'localhost'
IDENTIFIED WITH caching_sha2_password
BY 'fstr_hrdr_sctr';

CREATE DATABASE sctr CHARACTER SET utf8mb4 COLLATE utf8mb4_swedish_ci;
CREATE DATABASE test_sctr CHARACTER SET utf8mb4 COLLATE utf8mb4_swedish_ci;

-- USE DATABASE
SHOW DATABASES LIKE "%sctr%"; -- show databases containing word 'scooter'
USE sctr; -- choose database

-- CREATE USER (mariaDB)
DROP USER IF EXISTS 'user'@'%'; -- remove user if exists
CREATE USER IF NOT EXISTS 'user'@'%'
IDENTIFIED
BY 'pass';
-- IF MySQL version > 8.0.4:
-- IDENTIFIED WITH
-- mysql_native_password
-- BY 'pass';

-- GIVE FULL PRIVILEGES TO USER
GRANT ALL PRIVILEGES
ON *.* -- ON *.* for all databases, or database_name.* for specific database. *.* Also allows csv file insertion
TO 'user'@'%'
;

-- SHOW GRANTS
SHOW GRANTS FOR 'user'@'%'; -- or ...FOR CURRENT_USER

SELECT
    User,
    Host,
    Grant_priv,
    plugin
FROM mysql.user
WHERE
    User IN ('root', 'user') -- user euqal to root and user
ORDER BY User
;

-- open in cmd or cygwin
-- $ mysql -uuser -ppass (eller -p) sctr
-- show databases;

-- recreate database (as root, since 'user' does not have privilege to create database)
-- table makes it look prettier
-- $ mysql --table -uroot -p < setup.sql
