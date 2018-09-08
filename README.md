SQL Pet Tutorial
=======

# Next Meeting 9/22 @10:00am
Location: SW 2730 SW Moody Ave, Portland, OR 97201 

## Agenda items go here: https://github.com/smithjd/sql-pet/projects/1

# Documentation

* Project documentation is here: https://smithjd.github.io/sql-pet/

# Docker & Postgres tips -> Chapter 10?

## Postgres

* Loading the [dvdrental database into Postgres](http://www.postgresqltutorial.com/load-postgresql-sample-database/)
* To explore the Postgres environment it's worth browsing around inside the Docker command with a shell.

  + To run the Docker container that contains Postgres, you can enter this from a command prompt:

    `$ docker exec -ti sql-pet_postgres9_1 sh`

  + To exit Docker enter:

    `# exit`

  + Inside Docker, you can enter the Postgres command-line utility psql by entering 

    `# psql -U postgres`

    Handy [psql commands](https://gpdb.docs.pivotal.io/gs/43/pdf/PSQLQuickRef.pdf) include:

    + `postgres=# \h`          # psql help
    + `postgres=# \dt`         # list Postgres tables
    + `postgres=# \c dbname`   # connect to databse dbname
    + `postgres=# \l`          # list Postgres databases
    + `postgres=# \conninfo`   # display information about current connection
    + `postgres=# \q`          # exit psql
