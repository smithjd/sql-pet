# SQL Pet Tutorial

# Next Meeting 9/15 @10am
Location: Study room 2B at Central Library, Downtown Portland -- 801 SW 10th 

## Projects

* Meeting agenda items go here: https://github.com/smithjd/sql-pet/projects/1
* Kanban is here: https://github.com/smithjd/sql-pet/projects/2 

# Book: https://smithjd.github.io/sql-pet/

* Tutorial materials go in the Book
* Executable code is in the /src directory
  + selected chunks are move to the book as described here: https://bookdown.org/yihui/bookdown/new-session.html 

## More Docker & Postgres tips 

Do these items have a place?

### Postgres

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
