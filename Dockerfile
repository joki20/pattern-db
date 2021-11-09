FROM mysql:latest

ENV MYSQL_ROOT_PASSWORD=fstr_hrdr_sctr

# these sql scripts are automatically run when starting a new container,
# see the 'Initializing a fresh instance' section here:
# https://hub.docker.com/_/mysql
COPY setup.sql /docker-entrypoint-initdb.d/1-setup.sql
COPY ./ddl.sql /docker-entrypoint-initdb.d/2-ddl.sql
COPY insert.sql /docker-entrypoint-initdb.d/3-insert.sql
