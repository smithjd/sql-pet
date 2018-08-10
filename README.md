SQL Pet
=======

# Goals

The use case for this repo is:

* You are running R through Rstudio and want to experiment with some of the intricacies of working with an SQL database that has:
    + a moderately complex and unfamiliar structure. Using [the Postgres version of dvd rental database](http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip) in this case
    + requires passwords and other features found in an organizational environment
    + mostly read but sometimes write to the database

* Run PostgresSQL on a Docker container

# Instructions

* Install Docker. Verify that it's running with

     `$ docker -v`

* Download this repo and cd to the directory in which you've downloaded the repo

* From terminal, run `docker-compose`. Your container will be named `ql-pet_postgres9_1`: 

     `$ docker-compose up`

* Use `test_postgres.Rmd` to demonstrate that you have a persistent database by uploading `mtcars` to Postgres, then stopping the Docker container, restarting it, and finally determining that `mtcars` is still there.

* In another terminal session, use the `stop` command to stop the container (and the Postgres database).  You should get a 0 return code.  If you forgot to disconnect from Postres in R, you will get a 137 return code.

    `$ docker-compose stop`

* get a command prompt inside the docker container running Postgres

    `$ docker exec -ti sql-pet_postgres9_1 sh`

* Download the backup file for the dvdrental test database by executing a command inside the docker container with:

   `$ docker exec sql-pet_postgres9_1 /src/get_dvdrental.sh`

    `psql -U postgres -c CREATE DATABASE dvdrental;`

no complaint, but it doesn't seem to have done anything

`pg_restore -U postgres -d dvdrental /src/dvdrental.tar`

gets: `database "dvdrental" does not exist`

# Resources

* Picking up ideas and tips from Ed Borasky's [Data Science pet containers]( https://github.com/hackoregon/data-science-pet-containers).  This repo creates a framework based on that Hack Oregon example.
* An [introductory tutorial](https://docker-curriculum.com/)
* Usage examples of [Postgres with Docker](https://amattn.com/p/tutorial_postgresql_usage_examples_with_docker.html)

