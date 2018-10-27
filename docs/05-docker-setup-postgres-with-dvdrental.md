# The dvdrental database in Postgres in Docker (05)

At the end of this chapter, you will be able to 

  * Setup the `dvdrental` database
  * Stop and start Docker container to demonstrate persistence
  * Connect to and disconnect R from the `dvdrental` database
  * Execute the code in subsequent chapters

## Overview

In the last chapter we connected to PostgreSQL from R.  Now we set up a "realistic" database named `dvdrental`. There are two different approaches to doing this: this chapter sets it up in a way that doesn't delve into the Docker details.  If you are interested, you can examine the functions provided in `sqlpetr` to see how it works or look at an alternative approach in  [docker-detailed-postgres-setup-with-dvdrental.R](./book-src/docker-detailed-postgres-setup-with-dvdrental.R))


Note that `tidyverse`, `DBI`, `RPostgres`, and `glue` are loaded.

## Verify that Docker is up and running

```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up but running no containers"
```

## Clean up if appropriate
Remove the `sql-pet` container if it exists (e.g., from a prior run)

```r
sp_docker_remove_container("sql-pet")
```

```
## Warning in system2("docker", docker_command, stdout = TRUE, stderr = TRUE):
## running command ''docker' rm -f sql-pet 2>&1' had status 1
```

```
## [1] "Error: No such container: sql-pet"
## attr(,"status")
## [1] 1
```
## Build the Docker Image
Build an image that derives from postgres:10, defined in `dvdrental.Dockerfile`, that is set up to restore and load the dvdrental db on startup.  The [dvdrental.Dockerfile](./dvdrental.Dockerfile) is discussed below.  

```r
system2("docker", 
        glue("build ", # tells Docker to build an image that can be loaded as a container
          "--tag postgres-dvdrental ", # (or -t) tells Docker to name the image
          "--file dvdrental.Dockerfile ", #(or -f) tells Docker to read `build` instructions from the dvdrental.Dockerfile
          " . "),  # tells Docker to look for dvdrental.Dockerfile, and files it references, in the current directory
          stdout = TRUE, stderr = TRUE)
```

```
##  [1] "Sending build context to Docker daemon  41.63MB\r\r"                                                                                                                                                                                                                                                                                                                                           
##  [2] "Step 1/4 : FROM postgres:10"                                                                                                                                                                                                                                                                                                                                                                   
##  [3] " ---> ac25c2bac3c4"                                                                                                                                                                                                                                                                                                                                                                            
##  [4] "Step 2/4 : WORKDIR /tmp"                                                                                                                                                                                                                                                                                                                                                                       
##  [5] " ---> Using cache"                                                                                                                                                                                                                                                                                                                                                                             
##  [6] " ---> 3f00a18e0bdf"                                                                                                                                                                                                                                                                                                                                                                            
##  [7] "Step 3/4 : COPY init-dvdrental.sh /docker-entrypoint-initdb.d/"                                                                                                                                                                                                                                                                                                                                
##  [8] " ---> Using cache"                                                                                                                                                                                                                                                                                                                                                                             
##  [9] " ---> 3453d61d8e3e"                                                                                                                                                                                                                                                                                                                                                                            
## [10] "Step 4/4 : RUN apt-get -qq update &&   apt-get install -y -qq curl zip  > /dev/null 2>&1 &&   curl -Os http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip &&   unzip dvdrental.zip &&   rm dvdrental.zip &&   chmod ugo+w dvdrental.tar &&   chown postgres dvdrental.tar &&   chmod u+x /docker-entrypoint-initdb.d/init-dvdrental.sh &&   apt-get remove -y curl zip"
## [11] " ---> Using cache"                                                                                                                                                                                                                                                                                                                                                                             
## [12] " ---> f5e93aa64875"                                                                                                                                                                                                                                                                                                                                                                            
## [13] "Successfully built f5e93aa64875"                                                                                                                                                                                                                                                                                                                                                               
## [14] "Successfully tagged postgres-dvdrental:latest"
```

## Run the Docker Image
Run docker to bring up postgres.  The first time it runs it will take a minute to create the PostgreSQL environment.  There are two important parts to this that may not be obvious:

  * The `source=` parameter points to [dvdrental.Dockerfile](./dvdrental.Dockerfile), which does most of the heavy lifting.  It has detailed, line-by-line comments to explain what it is doing.  
  *  *Inside* [dvdrental.Dockerfile](./dvdrental.Dockerfile) the command `COPY init-dvdrental.sh /docker-entrypoint-initdb.d/` copies  [init-dvdrental.sh](init-dvdrental.sh) from the local file system into the specified location in the Docker container.  When the PostgreSQL Docker container initializes, it looks for that file and executes it. 
  
Doing all of that work behind the scenes involves two layers of complexity.  Depending on how you look at it, that may be more or less difficult to understand than the method shown in the next Chapter.


```r
wd <- getwd()

docker_cmd <- glue(
  "run ",      # Run is the Docker command.  Everything that follows are `run` parameters.
  "--detach ", # (or `-d`) tells Docker to disconnect from the terminal / program issuing the command
  " --name sql-pet ",     # tells Docker to give the container a name: `sql-pet`
  "--publish 5432:5432 ", # tells Docker to expose the Postgres port 5432 to the local network with 5432
  "--mount ", # tells Docker to mount a volume -- mapping Docker's internal file structure to the host file structure
  "type=bind,", # tells Docker that the mount command points to an actual file on the host system
  'source="', # specifies the directory on the host to mount into the container at the mount point specified by `target=`
  wd, '",', # the current working directory, as retrieved above
  "target=/petdir", # tells Docker to refer to the current directory as "/petdir" in its file system
  " postgres-dvdrental" # tells Docker to run the image was built in the previous step
)

# if you are curious you can paste this string into a terminal window after the command 'docker':
docker_cmd
```

```
## run --detach  --name sql-pet --publish 5432:5432 --mount type=bind,source="/Users/jds/Documents/Library/R/r-system/sql-pet",target=/petdir postgres-dvdrental
```

```r
system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

```
## [1] "a01b7b5e77f798d05768ef3408a3896b4fc6031df6553cdb76f15a3e5f0f93da"
```
## Connect to Postgres with R

Use the DBI package to connect to PostgreSQL.  


```r
con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "dvdrental",
                         seconds_to_test = 10)
```

List the tables in the database and the fields in one of those tables.  Then disconnect from the database.

```r
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
sp_docker_stop("sql-pet")
```

```
## [1] "sql-pet"
```
Restart the container and verify that the dvdrental tables are still there

```r
sp_docker_start("sql-pet")

con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "dvdrental",
                         seconds_to_test = 10)
```

Check that you can still see the fields in the `rental` table:

```r
dbListFields(con, "rental")
```

```
## [1] "rental_id"    "rental_date"  "inventory_id" "customer_id" 
## [5] "return_date"  "staff_id"     "last_update"
```

## Cleaning up

Always have R disconnect from the database when you're done.

```r
dbDisconnect(con)
```

Stop the container and show that the container is still there, so can be started again.

```r
sp_docker_stop("sql-pet")
```

```
## [1] "sql-pet"
```

```r
# show that the container still exists even though it's not running
sp_show_all_docker_containers()
```

```
## [1] "CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS                              PORTS               NAMES"    
## [2] "a01b7b5e77f7        postgres-dvdrental   \"docker-entrypoint.s…\"   8 seconds ago       Exited (0) Less than a second ago                       sql-pet"
```

Next time, you can just use this command to start the container: 

`sp_docker_start("sql-pet")`

And once stopped, the container can be removed with:

`sp_check_that_docker_is_up("sql-pet)`

## Using the `sql-pet` container in the rest of the book

After this point in the book, we assume that Docker is up and that we can always start up our *sql-pet database* with:

`sp_docker_stop("sql-pet")`
