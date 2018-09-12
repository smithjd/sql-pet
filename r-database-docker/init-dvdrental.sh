#!/bin/bash

# This script is run by the postgres docker container as it starts up.
# ...it runs as soon as the database server is available, but before it's available to accept connections

# Use the POstgres command-line utility to create the dvdrental database in postgres.
psql -U postgres -c "CREATE DATABASE dvdrental;"
# Restore the database from the dumpfile.
pg_restore -v -U postgres -d dvdrental /tmp/dvdrental.tar
# Remove the dumpfile (note that this does not save space in the image filesystem,
#   it just removes clutter from /tmp directory...).
rm -f /tmp/dvdrental.tar
