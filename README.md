SQL Pet
=======

# Goals

The use case for this repo is:

* You are running R through Rstudio and want to experiment with some of the intricacies of working with an SQL database that has:
    + a moderately complex and unfamiliar structure. 
    + requires passwords and other features found in an organizational environment
    + mostly read but sometimes write to the database

    This example use [the Postgres version of "dvd rental" database](http://www.postgresqltutorial.com/postgresql-sample-database/), which can be  [downloaded here](http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip).  Here's a glimpse of it's structure:
    
    ![Entity Relationship diagram for the dvdrental database](fig/dvdrental-er-diagram.png)

* You want to run PostgresSQL on a Docker container, avoiding any problems that might come up from running 

# Instructions

## Docker & Postgres

* Install Docker. Verify that it's running with

     `$ docker -v`

* Download this repo and cd to the directory in which you've downloaded the repo

* From terminal, run `docker-compose`. Your container will be named `sql-pet_postgres9_1`: 

     `$ docker-compose up`

* Use `test_postgres.Rmd` to demonstrate that you have a persistent database by uploading `mtcars` to Postgres, then stopping the Docker container, restarting it, and finally determining that `mtcars` is still there.

* In another terminal session, use the `stop` command to stop the container (and the Postgres database).  You should get a 0 return code.  If you forgot to disconnect from Postgres in R, you will get a 137 return code.

    `$ docker-compose stop`

## DVD Rental database installation

* Download the backup file for the dvdrental test database by executing a command inside the docker container with:

   `$ docker exec sql-pet_postgres9_1 /src/get_dvdrental.sh`

* get a command prompt inside the docker container running Postgres

    `$ docker exec -ti sql-pet_postgres9_1 /bin/bash`

    To exit Docker enter:

    `# exit`

* Inside Docker, you can enter the Postgres command-line utility psql by entering 

    `# psql -U postgres`

    Handy commands inside psql include:

    + `postgres=# \h`          # psql help
    + `postgres=# \dt`         # list Postgres tables
    + `postgres=# \c dbname`   # connect to databse dbname
    + `postgres=# \l`          # list Postgres databases
    + `postgres=# \conninfo`   # list Postgres databases
    + `postgres=# \q`          # exit psql

* Back on the command line (inside Docker) you would create the database with:

    `psql -U postgres -c "CREATE DATABASE dvdrental;"`

* unzip the zip archive to create the `tar` archive `dvdrental.tar`:

    `# cd src; unzip dvdrental.zip; cd ..`

* to load it into Postgres:

    `pg_restore -U postgres -d dvdrental /src/dvdrental.tar`

It doesn't give you any feedback when it works, but now dvdrental database is there and it has data in it.

## Interacting with Postgres from R

* passwords
* overview investigation
* dplyr queries
* what goes on the database side vs what goes on the R side
* examining dplyr queries
* rewriting SQL
* performance considerations

# Resources

* Picking up ideas and tips from Ed Borasky's [Data Science pet containers]( https://github.com/hackoregon/data-science-pet-containers).  This repo creates a framework based on that Hack Oregon example.
* A very good [introductory Docker tutorial](https://docker-curriculum.com/)
* Usage examples of [Postgres with Docker](https://amattn.com/p/tutorial_postgresql_usage_examples_with_docker.html)
* Loading the [dvdrental database into Postgres](http://www.postgresqltutorial.com/load-postgresql-sample-database/)
