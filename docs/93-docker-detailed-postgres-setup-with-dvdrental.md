# APPENDIX C - Creating the sql-pet Docker container a step at a time
Step-by-step Docker container setup with dvdrental database installed
This needs to run *outside a project* to compile correctly because of
the complexities of how knitr sets working directories (or because we
don’t really understand how it works!) The purpose of this code is to

  - Replicate the docker container generated in Chapter 5 of the book,
    but in a step-by-step fashion
  - Show that the `dvdrental` database persists when stopped and started
    up again.

## Overview

Doing all of this in a step-by-step way that might be useful to
understand how each of the steps involved in setting up a persistent
PostgreSQL database works. If you are satisfied with the method shown in
Chapter 5, skip this and only come back if you’re interested in picking
apart the steps.


```r
library(tidyverse)
```

```
## ── Attaching packages ─────────────────────────────────────────────────────────────────────── tidyverse 1.2.1 ──
```

```
## ✔ ggplot2 3.0.0     ✔ purrr   0.2.5
## ✔ tibble  1.4.2     ✔ dplyr   0.7.6
## ✔ tidyr   0.8.1     ✔ stringr 1.3.1
## ✔ readr   1.1.1     ✔ forcats 0.3.0
```

```
## ── Conflicts ────────────────────────────────────────────────────────────────────────── tidyverse_conflicts() ──
## ✖ dplyr::filter() masks stats::filter()
## ✖ dplyr::lag()    masks stats::lag()
```

```r
library(DBI)
library(RPostgres)
library(glue)
```

```
## 
## Attaching package: 'glue'
```

```
## The following object is masked from 'package:dplyr':
## 
##     collapse
```

```r
require(knitr)
```

```
## Loading required package: knitr
```

```r
library(dbplyr)
```

```
## 
## Attaching package: 'dbplyr'
```

```
## The following objects are masked from 'package:dplyr':
## 
##     ident, sql
```

```r
library(sqlpetr)
library(here)
```

```
## here() starts at /Users/jds/Documents/Library/R/r-system/sql-pet
```

## Download the `dvdrental` backup file

The first step is to get a local copy of the `dvdrental` PostgreSQL
**restore file**. It comes in a zip format and needs to be un-zipped.


```r
opts_knit$set(root.dir = normalizePath('../'))
if (!require(downloader)) install.packages("downloader")
```

```
## Loading required package: downloader
```

```r
library(downloader)

download("http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip", destfile = glue(here("dvdrental.zip")))

unzip("dvdrental.zip", exdir = here()) # creates a tar archhive named "dvdrental.tar"
```

Check on where we are and what we have in this directory:


```r
dir(path = here(), pattern = "^dvdrental(.tar|.zip)")
```

```
## [1] "dvdrental.tar" "dvdrental.zip"
```

```r
sp_show_all_docker_containers()
```

```
## [1] "CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS                     PORTS               NAMES"    
## [2] "7a231ee827e1        postgres-dvdrental   \"docker-entrypoint.s…\"   58 seconds ago      Exited (0) 6 seconds ago                       sql-pet"
```

Remove the `sql-pet` container if it exists (e.g., from a prior run)


```r
if (system2("docker", "ps -a", stdout = TRUE) %>%
    grepl(x = ., pattern = 'sql-pet') %>%
    any()) {
  sp_docker_remove_container("sql-pet")
}
```

```
## [1] "sql-pet"
```

## Build the Docker Container

Build an image that derives from postgres:10. Connect the local and
Docker directories that need to be shared. Expose the standard
PostgreSQL port 5432.


```r
wd <- here()
wd
```

```
## [1] "/Users/jds/Documents/Library/R/r-system/sql-pet"
```

```r
docker_cmd <- glue(
  "run ",      # Run is the Docker command.  Everything that follows are `run` parameters.
  "--detach ", # (or `-d`) tells Docker to disconnect from the terminal / program issuing the command
  " --name sql-pet ",     # tells Docker to give the container a name: `sql-pet`
  "--publish 5432:5432 ", # tells Docker to expose the Postgres port 5432 to the local network with 5432
  "--mount ", # tells Docker to mount a volume -- mapping Docker's internal file structure to the host file structure
  'type=bind,source="', wd, '",target=/petdir',
  " postgres:10 " # tells Docker the image that is to be run (after downloading if necessary)
)

docker_cmd
```

```
## run --detach  --name sql-pet --publish 5432:5432 --mount type=bind,source="/Users/jds/Documents/Library/R/r-system/sql-pet",target=/petdir postgres:10
```




```r
system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

```
## [1] "0a9beaa5ba4780672ace3fa16cae9dff00718b62ae155d799235855b6120d5b8"
```

Peek inside the docker container and list the files in the `petdir`
directory. Notice that `dvdrental.tar` is in both.


```r
# local file system:
dir(path = here(), pattern = "^dvdrental.tar")
```

```
## [1] "dvdrental.tar"
```

```r
# inside docker
system2('docker', 'exec sql-pet ls petdir | grep "dvdrental.tar" ',
        stdout = TRUE, stderr = TRUE)
```

```
## [1] "dvdrental.tar"
```

```r
Sys.sleep(3)
```


## Create the database and restore from the backup

We can execute programs inside the Docker container with the `exec`
command. In this case we tell Docker to execute the `psql` program
inside the `sql-pet` container and pass it some commands as follows.


```r
sp_show_all_docker_containers()
```

```
## [1] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES"    
## [2] "0a9beaa5ba47        postgres:10         \"docker-entrypoint.s…\"   3 seconds ago       Up 3 seconds        0.0.0.0:5432->5432/tcp   sql-pet"
```
inside Docker, execute the postgress SQL command-line program to create the dvdrental database:


```r
system2('docker', 'exec sql-pet psql -U postgres -c "CREATE DATABASE dvdrental;"',
        stdout = TRUE, stderr = TRUE)
```

```
## [1] "CREATE DATABASE"
```

```r
Sys.sleep(3)
```

The `psql` program repeats back to us what it has done, e.g., to create
a database named `dvdrental`. Next we execute a different program in the
Docker container, `pg_restore`, and tell it where the restore file is
located. If successful, the `pg_restore` just responds with a very
laconic `character(0)`. restore the database from the .tar file


```r
system2("docker", "exec sql-pet pg_restore -U postgres -d dvdrental petdir/dvdrental.tar", stdout = TRUE, stderr = TRUE)
```

```
## character(0)
```

```r
Sys.sleep(3)
```

## Connect to the database with R

If you are interested take a look inside the `sp_get_postgres_connection` function to see how the DBI package is beingcused.


```r
con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                                  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                                  dbname = "dvdrental",
                                  seconds_to_test = 20)

dbListTables(con)
```

```
##  [1] "actor_info"                 "customer_list"             
##  [3] "film_list"                  "nicer_but_slower_film_list"
##  [5] "sales_by_film_category"     "staff"                     
##  [7] "sales_by_store"             "staff_list"                
##  [9] "category"                   "film_category"             
## [11] "country"                    "actor"                     
## [13] "language"                   "inventory"                 
## [15] "payment"                    "rental"                    
## [17] "city"                       "store"                     
## [19] "film"                       "address"                   
## [21] "film_actor"                 "customer"
```


```r
dbDisconnect(con)

# Stop and start to demonstrate persistence
```

Stop the container


```r
sp_docker_stop("sql-pet")
```

```
## [1] "sql-pet"
```

Restart the container and verify that the dvdrental tables are still
there


```r
sp_docker_start("sql-pet")

con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                                  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                                  dbname = "dvdrental",
                                  seconds_to_test = 10)
dbListTables(con)
```

```
##  [1] "actor_info"                 "customer_list"             
##  [3] "film_list"                  "nicer_but_slower_film_list"
##  [5] "sales_by_film_category"     "staff"                     
##  [7] "sales_by_store"             "staff_list"                
##  [9] "category"                   "film_category"             
## [11] "country"                    "actor"                     
## [13] "language"                   "inventory"                 
## [15] "payment"                    "rental"                    
## [17] "city"                       "store"                     
## [19] "film"                       "address"                   
## [21] "film_actor"                 "customer"
```

## Cleaning up

It’s always good to have R disconnect from the database


```r
dbDisconnect(con)
```

Stop the container and show that the container is still there, so can be
started again.


```r
sp_docker_stop("sql-pet")
```

```
## [1] "sql-pet"
```

show that the container still exists even though it’s not running


```r
sp_show_all_docker_containers()
```

```
## [1] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                              PORTS               NAMES"    
## [2] "0a9beaa5ba47        postgres:10         \"docker-entrypoint.s…\"   14 seconds ago      Exited (0) Less than a second ago                       sql-pet"
```

We are leaving the `sql-pet` container intact so it can be used in running the
rest of the examples and book. 

Clean up by removing the local files used in creating the database:

```r
file.remove(here("dvdrental.zip"))
```

```
## [1] TRUE
```

```r
file.remove(here("dvdrental.tar"))
```

```
## [1] TRUE
```

