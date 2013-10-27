#!/bin/bash

# Define the database user we use to initialize the example database
# Usually this is root
user="root"

# Define the SQL file with the information to set up the example
# database. In this case it is example.sql in the same directory.
file="./example.sql"

cat $file | /usr/bin/mysql -u $user -p
