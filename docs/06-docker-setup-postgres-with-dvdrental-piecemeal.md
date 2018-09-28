# A persistent database in Postgres in Docker - piecemeal (06)

## Overview

This chapter essentially repeats what was presented in the previous one, but does it in a step-by-step way that might be useful to understand how each of the steps involved in setting up a persistent PostgreSQL database works.  If you are satisfied with the method shown in that chapter, skip this one for now.


Note that `tidyverse`, `DBI`, `RPostgres`, and `glue` are loaded.



## Retrieve the backup file

The first step is to get a local copy of the `dvdrental` PostgreSQL restore file.  It comes in a zip format and needs to be un-zipped.  Use the `downloader` and `here` packages to keep track of things.

```r
if (!require(downloader)) install.packages("downloader")
```

```
## Loading required package: downloader
```

```r
if (!require(here)) install.packages("here")
```

```
## Loading required package: here
```

```
## here() starts at /Users/jds/Documents/Library/R/r-system/sql-pet/r-database-docker
```

```r
library(downloader, here)

download("http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip", destfile = here("dvdrental.zip"))

unzip(here("dvdrental.zip"), exdir = here()) # creates a tar archhive named "dvdrental.tar"

file.remove(here("dvdrental.zip")) # the Zip file is no longer needed.
```

```
## [1] TRUE
```

## Now, verify that Docker is up and running:

```r
system2("docker", "version", stdout = TRUE, stderr = TRUE)
```

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
```

Remove the `sql-pet` container if it exists (e.g., from a prior run)

```r
if (system2("docker", "ps -a", stdout = TRUE) %>% 
   grepl(x = ., pattern = 'sql-pet') %>% 
   any()) {
     system2("docker", "rm -f sql-pet")
}
```

## Build the Docker Image

Build an image that derives from postgres:10.  Connect the local and Docker directories that need to be shared.  Expose the standard PostgreSQL port 5432.

  " postgres-dvdrental" # tells Docker the image that is to be run (after downloading if necessary)


```r
wd <- getwd()

docker_cmd <- glue(
  "run ",      # Run is the Docker command.  Everything that follows are `run` parameters.
  "--detach ", # (or `-d`) tells Docker to disconnect from the terminal / program issuing the command
  " --name sql-pet ",     # tells Docker to give the container a name: `sql-pet`
  "--publish 5432:5432 ", # tells Docker to expose the Postgres port 5432 to the local network with 5432
  "--mount ", # tells Docker to mount a volume -- mapping Docker's internal file structure to the host file structure
  'type=bind,source="', wd, '/",target=/petdir',
  " postgres:10 " # tells Docker the image that is to be run (after downloading if necessary)
)
cat('docker ',docker_cmd)
```

```
## docker  run --detach  --name sql-pet --publish 5432:5432 --mount type=bind,source="/Users/jds/Documents/Library/R/r-system/sql-pet/r-database-docker/",target=/petdir postgres:10
```

```r
system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

```
## [1] "df141df324e0f61a771555adae6fa8be6911120e7a50bbd860391d34e66b175b"
```

Peek inside the docker container and list the files in the `petdir` directory.  Notice that `dvdrental.tar` is in both.

```r
system2('docker', 'exec sql-pet ls petdir | grep "dvdrental.tar" ',
        stdout = TRUE, stderr = TRUE)
```

```
## [1] "dvdrental.tar"
```

```r
dir(wd, pattern = "dvdrental.tar")
```

```
## [1] "dvdrental.tar"
```

We can execute programs inside the Docker container with the `exec` command.  In this case we tell Docker to execute the `psql` program inside the `sql-pet` container and pass it some commands.

```r
Sys.sleep(2)  # is this really needed?
# inside Docker, execute the postgress SQL command-line program to create the dvdrental database:
system2('docker', 'exec sql-pet psql -U postgres -c "CREATE DATABASE dvdrental;"',
        stdout = TRUE, stderr = TRUE)
```

```
## [1] "CREATE DATABASE"
```
The `psql` program repeats back to us what it has done, e.g., to create a database named `dvdrental`.

Next we execute a different program in the Docker container, `pg_restore`, and tell it where the restore file is located.  If successful, the `pg_restore` just responds with a very laconic `character(0)`.

```r
# restore the database from the .tar file
system2("docker", "exec sql-pet pg_restore -U postgres -d dvdrental petdir/dvdrental.tar", stdout = TRUE, stderr = TRUE)
```

```
## character(0)
```

```r
file.remove(here("dvdrental.tar")) # the tar file is no longer needed.
```

```
## [1] TRUE
```

Use the DBI package to connect to PostgreSQL.  But first, wait for Docker & PostgreSQL to come up before connecting.

We have loaded the `wait_for_postgres` function behind the scenes.


```r
con <- wait_for_postgres(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
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

```r
dbListFields(con, "film")
```

```
##  [1] "film_id"          "title"            "description"     
##  [4] "release_year"     "language_id"      "rental_duration" 
##  [7] "rental_rate"      "length"           "replacement_cost"
## [10] "rating"           "last_update"      "special_features"
## [13] "fulltext"
```

```r
dbDisconnect(con)
```
## Stop and start to demonstrate persistence

Stop the container

```r
system2('docker', 'stop sql-pet',
        stdout = TRUE, stderr = TRUE)
```

```
## [1] "sql-pet"
```
Restart the container and verify that the dvdrental tables are still there

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

glimpse(dbReadTable(con, "film"))
```

```
## Observations: 1,000
## Variables: 13
## $ film_id          <int> 133, 384, 8, 98, 1, 2, 3, 4, 5, 6, 7, 9, 10, ...
## $ title            <chr> "Chamber Italian", "Grosse Wonderful", "Airpo...
## $ description      <chr> "A Fateful Reflection of a Moose And a Husban...
## $ release_year     <int> 2006, 2006, 2006, 2006, 2006, 2006, 2006, 200...
## $ language_id      <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
## $ rental_duration  <int> 7, 5, 6, 4, 6, 3, 7, 5, 6, 3, 6, 3, 6, 6, 6, ...
## $ rental_rate      <dbl> 4.99, 4.99, 4.99, 4.99, 0.99, 4.99, 2.99, 2.9...
## $ length           <int> 117, 49, 54, 73, 86, 48, 50, 117, 130, 169, 6...
## $ replacement_cost <dbl> 14.99, 19.99, 15.99, 12.99, 20.99, 12.99, 18....
## $ rating           <chr> "NC-17", "R", "R", "PG-13", "PG", "G", "NC-17...
## $ last_update      <dttm> 2013-05-26 14:50:58, 2013-05-26 14:50:58, 20...
## $ special_features <chr> "{Trailers}", "{\"Behind the Scenes\"}", "{Tr...
## $ fulltext         <chr> "'chamber':1 'fate':4 'husband':11 'italian':...
```

Stop the container & show that the container is still there, so can be started again.

```r
system2('docker', 'stop sql-pet',
        stdout = TRUE, stderr = TRUE)
```

```
## [1] "sql-pet"
```

```r
# show that the container still exists even though it's not running
psout <- system2("docker", "ps -a", stdout = TRUE)
psout[grepl(x = psout, pattern = 'sql-pet')]
```

```
## [1] "df141df324e0        postgres:10         \"docker-entrypoint.s…\"   18 seconds ago      Exited (137) Less than a second ago                       sql-pet"
```

## Cleaning up

Next time, you can just use this command to start the container:

`system2("docker",  "start sql-pet", stdout = TRUE, stderr = TRUE)`

And after disconnecting from it the container can be completely removed with:

`system2("docker",  "rm sql-pet -f", stdout = TRUE, stderr = TRUE)`

## Using the `sql-pet` container in the rest of the book

After this point in the book, we assume that Docker is up and that we can always start up our *sql-pet database* with:

`system2("docker",  "start sql-pet", stdout = TRUE, stderr = TRUE)`
