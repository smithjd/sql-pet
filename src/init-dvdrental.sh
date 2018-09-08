#!/bin/bash

psql -U postgres -c "CREATE DATABASE dvdrental;"
pg_restore -v -U postgres -d dvdrental /tmp/dvdrental.tar
rm -f /tmp/dvdrental.tar
