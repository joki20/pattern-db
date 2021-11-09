# SCTR database
This repository is part of a group project done for the ['pattern' course](https://www.bth.se/utbildning/program-och-kurser/kurser/20232/BR4QJ/) at Blekinge Institute of Technology.

This repository consists of code for building a Docker container running a MySQL Server with a database named 'pattern', which includes a database, tables and data as defined in 'setup.sql', 'ddl.sql' and 'insert.sql'.

## Build and run with Docker
Build
```bash
cd /path/to/this/dir
docker build . -t sctr/db:private
docker run --name sctr-db -p 6666:3306 -d sctr/db:private
```

Connect (after starting container and waiting ~30s for it to finish initialization)
```bash
# this should send you straight to the mysql CLI client, interacting with the sctr
# database in the container
mysql -h 127.0.0.1 --port 6666 -u root -pfstr_hrdr_sctr sctr
# try running e. g. `SHOW TABLES;`
# exit to quit
```

Remove the container
```bash
docker stop sctr-db
docker rm sctr-db
```

_Note_ that this is only for development - in the end, this repository's code and Dockerfile are to be used by a docker-compose file which combines all parts of the SCTR project.