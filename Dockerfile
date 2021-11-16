FROM mysql:latest

ENV MYSQL_ROOT_PASSWORD=fstr_hrdr_sctr

# these sql scripts are automatically run when starting a new container,
# see the 'Initializing a fresh instance' section here:
# https://hub.docker.com/_/mysql
COPY sql-scripts/setup.sql /docker-entrypoint-initdb.d/1-setup.sql
COPY sql-scripts/ddl.sql /docker-entrypoint-initdb.d/2-ddl.sql
COPY sql-scripts/insert.sql /docker-entrypoint-initdb.d/3-insert.sql

# copy custom MySQL configuration file to enable reading from local
# (CSV) files
COPY docker-setup-files/custom_my.cnf /etc/mysql/my.cnf

# copy the CSV files themselves (which are used to populate the database with
# initial data) to root directory, since that is the 'working directory' when
# the 'initdb' SQL scripts are executed
COPY sql-scripts/*.csv /
