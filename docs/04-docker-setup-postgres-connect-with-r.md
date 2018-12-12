# Connecting Docker, Postgres, and R (04)

> This chapter demonstrates how to:
>
>  * Run, clean-up and close postgreSQL in docker containers.
>  * Keep necessary credentials secret while being available to R when it executes.
>  * Interact with PostgreSQL when it's running inside a Docker container.
>  * Read and write to PostgreSQL from R.

The following packages are used in this chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
require(knitr)
library(sqlpetr)
```

Please install the `sqlpetr` package if not already installed:

```r
library(devtools)
if (!require(sqlpetr)) devtools::install_github("smithjd/sqlpetr")
```
Note that when you install the package the first time, it will ask you to update the packages it uses and that can take some time.

## Verify that Docker is running

Docker commands can be run from a terminal (e.g., the Rstudio Terminal pane) or with a `system()` command.  We provide the necessary functions to start, stop Docker containers and do other busy work in the `sqlpetr` package.  As time permits and curiosity dictates, feel free to look at those functions to see how they work.

Check that docker is up and running:


```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up but running no containers"
```

## Clean up if appropriate
Remove the `cattle` and `sql-pet` containers if they exists (e.g., from a prior experiments).  

```r
sp_docker_remove_container("cattle")
```

```
## [1] 0
```

```r
sp_docker_remove_container("sql-pet")
```

```
## [1] 0
```

The convention we use in this book is to put docker commands in the `sqlpetr` package so that you can ignore them if you want.  However, the functions are set up so that you can easily see how to do things with Docker and modify if you want.

We name containers `cattle` for "throw-aways" and `pet` for ones we treasure and keep around.  :-)

```r
sp_make_simple_pg("cattle")
```

Docker returns a long string of numbers.  If you are running this command for the first time, Docker downloads the PostgreSQL image, which takes a bit of time.

The following command shows that a container named `cattle` is running `postgres:10`.  `postgres` is waiting for a connection:

```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up, running these containers:"                                                                                                       
## [2] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                  PORTS                    NAMES"   
## [3] "d5d93315b640        postgres:10         \"docker-entrypoint.s…\"   1 second ago        Up Less than a second   0.0.0.0:5432->5432/tcp   cattle"
```
## Connect, read and write to Postgres from R


### Connect with Postgres

Connect to the postgrSQL using the `sp_get_postgres_connection` function:

```r
con <- sp_get_postgres_connection(user = "postgres",
                         password = "postgres",
                         dbname = "postgres",
                         seconds_to_test = 10)
```
Notice that we are using the postgreSQL default username and password at this point and that it's in plain text. That is bad practice because user credentials should not be shared in this way.  In a subsequent chapter we'll demonstrate how to store and use credentials to access the dbms.

Make sure that you can connect to the PostgreSQL database that you started earlier. If you have been executing the code from this tutorial, the database will not contain any tables yet:


```r
dbListTables(con)
```

```
## character(0)
```

### Interact with Postgres

Write `mtcars` to PostgreSQL

```r
dbWriteTable(con, "mtcars", mtcars, overwrite = TRUE)
```

List the tables in the PostgreSQL database to show that `mtcars` is now there:


```r
dbListTables(con)
```

```
## [1] "mtcars"
```

```r
# list the fields in mtcars:
dbListFields(con, "mtcars")
```

```
##  [1] "mpg"  "cyl"  "disp" "hp"   "drat" "wt"   "qsec" "vs"   "am"   "gear"
## [11] "carb"
```

Download the table from the DBMS to a local data frame:

```r
mtcars_df <- tbl(con, "mtcars")

# Show a few rows:
knitr::kable(head(mtcars_df))
```



  mpg   cyl   disp    hp   drat      wt    qsec   vs   am   gear   carb
-----  ----  -----  ----  -----  ------  ------  ---  ---  -----  -----
 21.0     6    160   110   3.90   2.620   16.46    0    1      4      4
 21.0     6    160   110   3.90   2.875   17.02    0    1      4      4
 22.8     4    108    93   3.85   2.320   18.61    1    1      4      1
 21.4     6    258   110   3.08   3.215   19.44    1    0      3      1
 18.7     8    360   175   3.15   3.440   17.02    0    0      3      2
 18.1     6    225   105   2.76   3.460   20.22    1    0      3      1

## Clean up

Afterwards, always disconnect from the dbms:

```r
dbDisconnect(con)
```
Tell Docker to stop the `cattle` container:

```r
sp_docker_stop("cattle")
```

```
## [1] "cattle"
```

Tell Docker to remove the `cattle` container from it's library of active containers:

```r
sp_docker_remove_container("cattle")
```

```
## [1] 0
```

If we just **stop** the docker container but don't remove it (as we did with the `sp_docker_remove_container("cattle")` command), the `cattle` container will persist and we can start it up again later with `sp_docker_start("cattle")`.  In that case, `mtcars` would still be there and we could retrieve it from postgreSQL again.  Since `sp_docker_remove_container("cattle")`  has removed it, the updated database has been deleted.  (There are enough copies of `mtcars` in the world, so no great loss.)
