Install dvdrental database in Postgres
================
John D. Smith
8/12/2018

``` r
if (!require(here)) install.packages("here")
```

    ## Loading required package: here

    ## here() starts at /Users/jds/Documents/Library/R/r-system/sql-pet

``` r
library(here)

# run get_dvdrental-zipfile.Rmd first

# verify that Docker is up and running:

system("docker version")

# run docker-compose to bring up postgres.  The first time it runs it will take a minute to create the Postgres environment.

system("docker-compose up -d")

# inside Docker, execute the postgress SQL command line program to create the dvdrental database:

system('docker exec sql-pet_postgres9_1 psql -U postgres -c "CREATE DATABASE dvdrental;"')

# verify that R is running with the right directory (the repo's)
system("pwd")

# restore the database from the .tar file

system("docker exec sql-pet_postgres9_1 pg_restore -U postgres -d dvdrental /src/dvdrental.tar")


# verify that the dvdrental database exists
system('docker exec sql-pet_postgres9_1 psql -U postgres -c "\\l"')

# Cleanup

file.remove(here("src", "dvdrental.tar"))
```

    ## [1] TRUE

``` r
system("docker-compose stop")
```
