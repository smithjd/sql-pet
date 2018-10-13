06-docker-setup-postgres-with-dvdrental-piecemeal.R
================
John David Smith
2018-10-11

Step-by-step Docker container setup This needs to run *outside a
project* to compile correctly because of the complexities of how knitr
sets working directories (or because we don’t really understand how it
works\!) The purpose of this code is to

  - Replicate the docker container generated in Chapter 5 of the book,
    but in a step-by-step fashion
  - Show that the `dvdrental` database persists when stopped and started
    up again.

## Overview

Doing all of this in a step-by-step way that might be useful to
understand how each of the steps involved in setting up a persistent
PostgreSQL database works. If you are satisfied with the method shown in
Chapter 5, skip this and only come back if you’re interested in picking
apart the
    steps.

``` r
library(tidyverse)
```

    ## ── Attaching packages ───────────────────────────────────────────────────────────────────────────────── tidyverse 1.2.1 ──

    ## ✔ ggplot2 3.0.0     ✔ purrr   0.2.5
    ## ✔ tibble  1.4.2     ✔ dplyr   0.7.6
    ## ✔ tidyr   0.8.1     ✔ stringr 1.3.1
    ## ✔ readr   1.1.1     ✔ forcats 0.3.0

    ## ── Conflicts ──────────────────────────────────────────────────────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()

``` r
library(DBI)
library(RPostgres)
library(glue)
```

    ## 
    ## Attaching package: 'glue'

    ## The following object is masked from 'package:dplyr':
    ## 
    ##     collapse

``` r
require(knitr)
```

    ## Loading required package: knitr

``` r
library(dbplyr)
```

    ## 
    ## Attaching package: 'dbplyr'

    ## The following objects are masked from 'package:dplyr':
    ## 
    ##     ident, sql

``` r
library(sqlpetr)
```

## Download the `dvdrental` backup file

The first step is to get a local copy of the `dvdrental` PostgreSQL
restore file. It comes in a zip format and needs to be un-zipped.

``` r
opts_knit$set(root.dir = normalizePath('../'))
if (!require(downloader)) install.packages("downloader")
```

    ## Loading required package: downloader

``` r
library(downloader)

download("http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip", destfile = "dvdrental.zip")

unzip("dvdrental.zip", exdir = ".") # creates a tar archhive named "dvdrental.tar"
```

Check on where we are and what we have in this directory:

``` r
getwd()
```

    ## [1] "/Users/jds/Documents/Library/R/r-system/sql-pet"

``` r
dir()
```

    ##  [1] "_bookdown.yml"                              
    ##  [2] "_output.yml"                                
    ##  [3] "02-docker_hosting_for_windows.Rmd"          
    ##  [4] "03-learning-goals-use-cases.Rmd"            
    ##  [5] "04-docker-setup-postgres-connect-with-r.Rmd"
    ##  [6] "05-docker-setup-postgres-with-dvdrental.Rmd"
    ##  [7] "10-r-postgres-interaction.Rmd"              
    ##  [8] "11-elementary-queries.Rmd"                  
    ##  [9] "12-a-production-perspective.Rmd"            
    ## [10] "13-sql_pet-examples-part-a.Rmd"             
    ## [11] "14-sql_pet-examples-part-b.Rmd"             
    ## [12] "21-r-query-postgres-metadata.Rmd"           
    ## [13] "71-explain-queries.Rmd"                     
    ## [14] "72-sql-query-steps.Rmd"                     
    ## [15] "73-write-to-the-database.Rmd"               
    ## [16] "89-resources.Rmd"                           
    ## [17] "90-references.Rmd"                          
    ## [18] "92-environment_diagram.Rmd"                 
    ## [19] "book-src"                                   
    ## [20] "book.bib"                                   
    ## [21] "build_book.R"                               
    ## [22] "CODE_OF_CONDUCT.md"                         
    ## [23] "Contributing.md"                            
    ## [24] "diagrams"                                   
    ## [25] "docs"                                       
    ## [26] "dvdrental.Dockerfile"                       
    ## [27] "dvdrental.tar"                              
    ## [28] "dvdrental.zip"                              
    ## [29] "index.Rmd"                                  
    ## [30] "init-dvdrental.sh"                          
    ## [31] "LICENSE"                                    
    ## [32] "maintaining-the-bookdown-site.md"           
    ## [33] "packages.bib"                               
    ## [34] "preamble.tex"                               
    ## [35] "project-file-structure.md"                  
    ## [36] "r-database-docker.rds"                      
    ## [37] "README.md"                                  
    ## [38] "render5ecc5aac40a8.rds"                     
    ## [39] "screenshots"                                
    ## [40] "sql-pet.Rproj"                              
    ## [41] "style.css"

## Verify that Docker is up and running:

``` r
system2("docker", "version", stdout = TRUE, stderr = TRUE)
```

    ##  [1] "Client:"                                        
    ##  [2] " Version:           18.06.1-ce"                 
    ##  [3] " API version:       1.38"                       
    ##  [4] " Go version:        go1.10.3"                   
    ##  [5] " Git commit:        e68fc7a"                    
    ##  [6] " Built:             Tue Aug 21 17:21:31 2018"   
    ##  [7] " OS/Arch:           darwin/amd64"               
    ##  [8] " Experimental:      false"                      
    ##  [9] ""                                               
    ## [10] "Server:"                                        
    ## [11] " Engine:"                                       
    ## [12] "  Version:          18.06.1-ce"                 
    ## [13] "  API version:      1.38 (minimum version 1.12)"
    ## [14] "  Go version:       go1.10.3"                   
    ## [15] "  Git commit:       e68fc7a"                    
    ## [16] "  Built:            Tue Aug 21 17:29:02 2018"   
    ## [17] "  OS/Arch:          linux/amd64"                
    ## [18] "  Experimental:     true"

Remove the `sql-pet` container if it exists (e.g., from a prior run)

``` r
if (system2("docker", "ps -a", stdout = TRUE) %>%
    grepl(x = ., pattern = 'sql-pet') %>%
    any()) {
  system2("docker", "rm -f sql-pet")
}
```

## Build the Docker Container

Build an image that derives from postgres:10. Connect the local and
Docker directories that need to be shared. Expose the standard
PostgreSQL port 5432.

``` r
wd <- getwd()

docker_cmd <- glue(
  "run ",      # Run is the Docker command.  Everything that follows are `run` parameters.
  "--detach ", # (or `-d`) tells Docker to disconnect from the terminal / program issuing the command
  " --name sql-pet ",     # tells Docker to give the container a name: `sql-pet`
  "--publish 5432:5432 ", # tells Docker to expose the Postgres port 5432 to the local network with 5432
  "--mount ", # tells Docker to mount a volume -- mapping Docker's internal file structure to the host file structure
  'type=bind,source="', wd, '",target=/petdir',
  " postgres:10 " # tells Docker the image that is to be run (after downloading if necessary)
)
cat('docker ',docker_cmd)
```

    ## docker  run --detach  --name sql-pet --publish 5432:5432 --mount type=bind,source="/Users/jds/Documents/Library/R/r-system/sql-pet",target=/petdir postgres:10

``` r
system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

    ## [1] "e9e6c90de934e700fbccc06cc729270ed6a2921198514b7b31c7c6df9948b32b"

Peek inside the docker container and list the files in the `petdir`
directory. Notice that `dvdrental.tar` is in both.

``` r
opts_knit$set(root.dir = normalizePath('../'))
system2('docker', 'exec sql-pet ls petdir | grep "dvdrental.tar" ',
        stdout = TRUE, stderr = TRUE)
```

    ## [1] "dvdrental.tar"

``` r
dir(wd, pattern = "dvdrental.tar")
```

    ## [1] "dvdrental.tar"

## Create the database and restore from the backup

We can execute programs inside the Docker container with the `exec`
command. In this case we tell Docker to execute the `psql` program
inside the `sql-pet` container and pass it some commands as follows.

``` r
Sys.sleep(2)  # is this really needed?

system2("docker", "ps -a", stdout = TRUE, stderr = TRUE)
```

    ## [1] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES"    
    ## [2] "e9e6c90de934        postgres:10         \"docker-entrypoint.s…\"   3 seconds ago       Up 2 seconds        0.0.0.0:5432->5432/tcp   sql-pet"

inside Docker, execute the postgress SQL command-line program to create
the dvdrental
database:

``` r
system2('docker', 'exec sql-pet psql -U postgres -c "CREATE DATABASE dvdrental;"',
        stdout = TRUE, stderr = TRUE)
```

    ## [1] "CREATE DATABASE"

The `psql` program repeats back to us what it has done, e.g., to create
a database named `dvdrental`. Next we execute a different program in the
Docker container, `pg_restore`, and tell it where the restore file is
located. If successful, the `pg_restore` just responds with a very
laconic `character(0)`. restore the database from the .tar file

``` r
Sys.sleep(2)  # the wait may or may not be needed.
system2("docker", "exec sql-pet pg_restore -U postgres -d dvdrental petdir/dvdrental.tar", stdout = TRUE, stderr = TRUE)
```

    ## character(0)

``` r
file.remove("dvdrental.tar") # the tar file is no longer needed.
```

    ## Warning in file.remove("dvdrental.tar"): cannot remove file
    ## 'dvdrental.tar', reason 'No such file or directory'

    ## [1] FALSE

## Connect to the database with R

If you are interested take a look inside the
`sp_get_postgres_connection` function to see how the DBI package is
being
used.

``` r
con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                                  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                                  dbname = "dvdrental",
                                  seconds_to_test = 20)

dbListTables(con)
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

``` r
dbDisconnect(con)

## Stop and start to demonstrate persistence
```

Stop the container

``` r
sp_docker_stop("sql-pet")
```

    ## [1] "sql-pet"

Restart the container and verify that the dvdrental tables are still
there

``` r
sp_docker_start("sql-pet")

con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                                  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                                  dbname = "dvdrental",
                                  seconds_to_test = 10)
```

## Cleaning up

It’s always good to have R disconnect from the database

``` r
dbDisconnect(con)
```

Stop the container and show that the container is still there, so can be
started again.

``` r
sp_docker_stop("sql-pet")
```

    ## [1] "sql-pet"

show that the container still exists even though it’s not running

``` r
psout <- system2("docker", "ps -a", stdout = TRUE)
psout[grepl(x = psout, pattern = 'sql-pet')]
```

    ## [1] "e9e6c90de934        postgres:10         \"docker-entrypoint.s…\"   10 seconds ago      Exited (0) Less than a second ago                       sql-pet"

We are leaving the `sql-pet` container so it can be used in running the
rest of the examples and book.
