# The dvdrental database in Postgres in Docker (05a)

> This chapter demonstrates how to:
>
>  * Setup the `dvdrental` database in Docker
>  * Stop and start Docker container to demonstrate persistence
>  * Connect to and disconnect R from the `dvdrental` database
>  * Set up the environment for subsequent chapters

## Overview

In the last chapter we connected to PostgreSQL from R.  Now we set up a "realistic" database named `dvdrental`. There are different approaches to doing this: this chapter sets it up in a way that doesn't delve into the Docker details.  If you are interested, you can look at an alternative approach in [Creating the sql-pet Docker container a step at a time](Creating the sql-pet Docker container one step at a time \(93\)) that breaks the process down into smaller chunks.

These packages are called in this Chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)
require(knitr)
library(dbplyr)
library(sqlpetr)
library(bookdown)
```

## Verify that Docker is up and running

```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up but running no containers"
```

## Clean up if appropriate
Remove the `cattle` and `sql-pet` containers if they exist (e.g., from a prior runs):

```r
sp_docker_remove_container("cattle")
sp_docker_remove_container("sql-pet")
```
## Build the pet-sql Docker Image

Build an image that derives from postgres:10.  The commands in `dvdrental.Dockerfile` creates a Docker container running PostgreSQL, and loads the `dvdrental` database.  The [dvdrental.Dockerfile](./dvdrental.Dockerfile) is discussed below.  

```r
docker_messages <- system2("docker", 
        glue("build ", # tells Docker to build an image that can be loaded as a container
          "--tag postgres-dvdrental ", # (or -t) tells Docker to name the image
          "--file dvdrental.Dockerfile ", #(or -f) tells Docker to read `build` instructions from the dvdrental.Dockerfile
          " . "),  # tells Docker to look for dvdrental.Dockerfile, and files it references, in the current directory
          stdout = TRUE, stderr = TRUE)

cat(docker_messages, sep = "\n")
```

```
## Sending build context to Docker daemon  62.12MB
## Step 1/4 : FROM postgres:10
##  ---> ac25c2bac3c4
## Step 2/4 : WORKDIR /tmp
##  ---> Using cache
##  ---> 3f00a18e0bdf
## Step 3/4 : COPY init-dvdrental.sh /docker-entrypoint-initdb.d/
##  ---> Using cache
##  ---> 3453d61d8e3e
## Step 4/4 : RUN apt-get -qq update &&   apt-get install -y -qq curl zip  > /dev/null 2>&1 &&   curl -Os http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip &&   unzip dvdrental.zip &&   rm dvdrental.zip &&   chmod ugo+w dvdrental.tar &&   chown postgres dvdrental.tar &&   chmod u+x /docker-entrypoint-initdb.d/init-dvdrental.sh &&   apt-get remove -y curl zip
##  ---> Using cache
##  ---> f5e93aa64875
## Successfully built f5e93aa64875
## Successfully tagged postgres-dvdrental:latest
```

## Run the pet-sql Docker Image
Run docker to bring up postgres.  The first time it runs it will take a minute to create the PostgreSQL environment.  There are two important parts to this that may not be obvious:

  * The `source=` parameter points to [dvdrental.Dockerfile](./dvdrental.Dockerfile), which does most of the heavy lifting.  It has detailed, line-by-line comments to explain what it is doing.  
  *  *Inside* [dvdrental.Dockerfile](./dvdrental.Dockerfile) the command `COPY init-dvdrental.sh /docker-entrypoint-initdb.d/` copies  [init-dvdrental.sh](init-dvdrental.sh) from the local file system into the specified location in the Docker container.  When the PostgreSQL Docker container initializes, it looks for that file and executes it. 
  
Doing all of that work behind the scenes involves two layers.  Depending on how you look at it, that may be more or less difficult to understand than [an alternative method](book-src/docker-detailed-postgres-setup-with-dvdrental.R).


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
```

If you are curious you can paste  `docker_cmd` into a terminal window after the command 'docker':

```r
system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

```
## [1] "76ea948d689cbb4460f5c1aecee9943ab7ae684731452c36aecb75d075414811"
```
## Connect to Postgres with R

Use the DBI package to connect to the `dvdrental` database in PostgreSQL.  Remember the settings discussion about [keeping passwords hidden][Pause for some security considerations]


```r
con <- sp_get_postgres_connection(password = "postgres",
                         user = "postgres",
                         dbname = "dvdrental",
                         seconds_to_test = 10)
```

List the tables in the database and the fields in one of those tables.  

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

Disconnect from the database:

```r
dbDisconnect(con)
```
## Stop and start to demonstrate persistence

Stop the container:

```r
sp_docker_stop("sql-pet")
```
Restart the container and verify that the dvdrental tables are still there:

```r
sp_docker_start("sql-pet")
```
Connect to the `dvdrental` database in postgreSQL:

```r
con <- sp_get_postgres_connection(user = "postgres",
                         password = "postgres",
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

Stop the `sql-pet` container:

```r
sp_docker_stop("sql-pet")
```
Show that the container still exists even though it's not running


```r
sp_show_all_docker_containers()
```

```
## CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS                              PORTS               NAMES
## 76ea948d689c        postgres-dvdrental   "docker-entrypoint.s…"   8 seconds ago       Exited (0) Less than a second ago                       sql-pet
```

Next time, you can just use this command to start the container: 

> `sp_docker_start("sql-pet")`

And once stopped, the container can be removed with:

> `sp_check_that_docker_is_up("sql-pet")`

## Using the `sql-pet` container in the rest of the book

After this point in the book, we assume that Docker is up and that we can always start up our *sql-pet database* with:

> `sp_docker_start("sql-pet")`
