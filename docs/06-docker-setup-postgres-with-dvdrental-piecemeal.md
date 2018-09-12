# A persistent database in Postgres in Docker - piecemeal

## Overview

This chapter essentially repeats what was presented in the previous one, but does it in a step-by-step way that might be useful to understand how each of the steps involved in setting up a persistent Postgres database works.  If you are satisfied with the method shown in that chapter, skip this one for now.


## Retrieve the backup file

The first step is to get a local copy of the `dvdrental` Postgres restore file.  It comes in a zip format and needs to be un-zipped.  Use the `downloader` and `here` packages to keep track of things.

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

Remove the `pet` container if it exists (e.g., from a prior run)

```r
if (system2("docker", "ps -a", stdout = TRUE) %>% 
   grepl(x = ., pattern = 'pet') %>% 
   any()) {
     system2("docker", "rm -f pet")
}
```

## Build the Docker Image

Build an image that derives from postgres:10.  Connect the local and Docker directories that need to be shared.  Expose the standard Postgres port 5432.

```r
wd <- getwd()

docker_cmd <- paste0(
  "run -d --name pet --publish 5432:5432 ",
  '--mount "type=bind,source=', wd,
  '/,target=/petdir"',
    " postgres:10"
)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

```
## [1] "b343536d29685419e7821ba27190f29860db7c412b7dc97004e3c47c43b19b6e"
```

Peek inside the docker container and list the files in the `petdir` directory.  Notice that `dvdrental.tar` is in both.

```r
system2('docker', 'exec pet ls petdir | grep "dvdrental.tar" ',
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

We can execute programs inside the Docker container with the `exec` command.  In this case we tell Docker to execute the `psql` program inside the `pet` container and pass it some commands.

```r
Sys.sleep(2)
# inside Docker, execute the postgress SQL command-line program to create the dvdrental database:
system2('docker', 'exec pet psql -U postgres -c "CREATE DATABASE dvdrental;"',
        stdout = TRUE, stderr = TRUE)
```

```
## [1] "CREATE DATABASE"
```
The `psql` program repeats back to us what it has done, e.g., to create a databse named `dvdrental`.

Next we execute a different program in the Docker container, `pg_restore`, and tell it where the restore file is located.  If successful, the `pg_restore` just responds with a very laconic `character(0)`.

```r
Sys.sleep(2)
# restore the database from the .tar file
system2("docker", "exec pet pg_restore -U postgres -d dvdrental petdir/dvdrental.tar", stdout = TRUE, stderr = TRUE)
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

Use the DBI package to connect to Postgres.  But first, wait for Docker & Postgres to come up before connecting.

```r
Sys.sleep(4) 

con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "localhost",
                      port = "5432",
                      user = "postgres",
                      password = "postgres",
                      dbname = "dvdrental" ) # note that the dbname is specified

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
dbListFields(con, "rental")
```

```
## [1] "rental_id"    "rental_date"  "inventory_id" "customer_id" 
## [5] "return_date"  "staff_id"     "last_update"
```

```r
dbDisconnect(con)
```
## Stop and start to demonstrate persistence

Stop the container

```r
system2('docker', 'stop pet',
        stdout = TRUE, stderr = TRUE)
```

```
## [1] "pet"
```
Restart the container and verify that the dvdrental tables are still there

```r
system2("docker",  "start pet", stdout = TRUE, stderr = TRUE)
```

```
## [1] "pet"
```

```r
Sys.sleep(1) # need to wait for Docker & Postgres to come up before connecting.

con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "localhost",
                      port = "5432",
                      user = "postgres",
                      password = "postgres",
                      dbname = "dvdrental" ) # note that the dbname is specified

glimpse(dbReadTable(con, "rental"))
```

```
## Observations: 16,044
## Variables: 7
## $ rental_id    <int> 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1...
## $ rental_date  <dttm> 2005-05-24 22:54:33, 2005-05-24 23:03:39, 2005-0...
## $ inventory_id <int> 1525, 1711, 2452, 2079, 2792, 3995, 2346, 2580, 1...
## $ customer_id  <int> 459, 408, 333, 222, 549, 269, 239, 126, 399, 142,...
## $ return_date  <dttm> 2005-05-28 19:40:33, 2005-06-01 22:12:39, 2005-0...
## $ staff_id     <int> 1, 1, 2, 1, 1, 2, 2, 1, 2, 2, 2, 1, 1, 1, 2, 1, 2...
## $ last_update  <dttm> 2006-02-16 02:30:53, 2006-02-16 02:30:53, 2006-0...
```

Stop the container & show that the container is still there, so can be started again.

```r
system2('docker', 'stop pet',
        stdout = TRUE, stderr = TRUE)
```

```
## [1] "pet"
```

```r
# show that the container still exists even though it's not running
psout <- system2("docker", "ps -a", stdout = TRUE)
psout[grepl(x = psout, pattern = 'pet')]
```

```
## [1] "b343536d2968        postgres:10         \"docker-entrypoint.s…\"   24 seconds ago      Exited (137) Less than a second ago                       pet"
```

Next time, you can just use this command to start the container:

`system2("docker",  "start pet", stdout = TRUE, stderr = TRUE)`

And after disconnecting from it the container can be completely removed with:

`system2("docker",  "rm pet -f", stdout = TRUE, stderr = TRUE)`
