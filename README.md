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

* Install Docker and verify that it's running with

  `$ docker -v`

* Download this repo
* From terminal, run: 

  `$ docker-compose up`

* Use `test_postgres.Rmd` to demonstrate that you have a persistent database by uploading `mtcars`

docker-compose stop


# Resources

* Picking up ideas and tips from Ed Borasky's [Data Science pet containers]( https://github.com/hackoregon/data-science-pet-containers).  This repo creates a framework based on that Hack Oregon example.
* An [introductory tutorial](https://docker-curriculum.com/)
* Usage examples of [Postgres with Docker](https://amattn.com/p/tutorial_postgresql_usage_examples_with_docker.html)

