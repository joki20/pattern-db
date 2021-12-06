#!/usr/bin/env bash
#
# Above means execute all rows in file with bash
# Do all steps below with: bash reset.bash
#

# 1. CREATE DB AS ROOT AND user:pass
echo ">>> Reset to beginning"
echo ">>> Initiate database and users ($file)"
mysql -uroot -pfstr_hrdr_sctr < setup.sql > /dev/null # /dev/null hides prints inside sql files except error messages

# 2. CREATE TABLES AND VIEWS
file="ddl.sql" # variable $file created
echo ">>> Create tables and views ($file)"
mysql -uuser sctr < $file > /dev/null # -ppass not needed since .my.cnf in home folder was updated to include password

# 3. INSERT DATA
file="insert.sql"
echo ">>> Insert data ($file)"
mysql -uuser sctr < $file > /dev/null

# BACKUP DB
# mysqldump -uroot -p --routines --add-drop-database sctr > backup.sql

# START BACKUP
# mysql -uroot -p sctr < backup.sql
