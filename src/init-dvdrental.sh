#!/bin/bash

# this script is run by the postgres docker container as it starts up
# ...it runs as soon as the database server is available, but before it's available to accept connections

# create the dvdrental database
psql -U postgres -c "CREATE DATABASE dvdrental;"
# restore the database from the dumpfile
pg_restore -v -U postgres -d dvdrental /tmp/dvdrental.tar
# remove the dumpfile (note that this does not save space in the image filesystem, but at least the file isn't cluttering the /tmp directory...)
rm -f /tmp/dvdrental.tar
