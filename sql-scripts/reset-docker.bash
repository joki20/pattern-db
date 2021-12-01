mysql -h 127.0.0.1 --port 6666 -u root -pfstr_hrdr_sctr < setup.sql > /dev/null

mysql -h 127.0.0.1 --port 6666 -u root -pfstr_hrdr_sctr sctr < ddl.sql > /dev/null

mysql -h 127.0.0.1 --port 6666 -u root -pfstr_hrdr_sctr sctr < insert.sql > /dev/null