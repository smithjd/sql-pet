# Introduction: Postgres queries from R (10)


Note that `tidyverse`, `DBI`, `RPostgres`, `glue`, and `knitr` are loaded.  Also, we've sourced the `[db-login-batch-code.R]('r-database-docker/book-src/db-login-batch-code.R')` file which is used to log in to PostgreSQL.





## Basics

* Keeping passwords secure.
* Coverage in this book.  There are many SQL tutorials that are available.  For example, we are drawing some materials from  [a tutorial we recommend](http://www.postgresqltutorial.com/postgresql-sample-database/).  In particular, we will not replicate the lessons there, which you might want to complete.  Instead, we are showing strategies that are recommended for R users.  That will include some translations of queries that are discussed there.

## Ask yourself, what are you aiming for?

* Differences between production and data warehouse environments.
* Learning to keep your DBAs happy:
  + You are your own DBA in this simulation, so you can wreak havoc and learn from it, but you can learn to be DBA-friendly here.
  + In the end it's the subject-matter experts that understand your data, but you have to work with your DBAs first.

## Get some basic information about your database

Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go.

```r
system2("docker",  "start sql-pet", stdout = TRUE, stderr = TRUE)
```

```
## [1] "sql-pet"
```

```r
con <- wait_for_postgres(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "dvdrental",
                         seconds_to_test = 10)
```

