# A persistent database in Postgres in Docker - all at once

## Overview

You've already connected to Postgres with R, now you need a "realistic" (`dvdrental`) database. We're going to demonstrate how to set one up, with two different approaches.  This chapter and the next do the same job, illustrating the different approaches that you can take and helping you see the different points whwere you could swap what's provided here with a different DBMS or a different backup file or something else.

## setup the discussion here

The code in this first version is recommended because it is an "all in one" approach.  Details about how it works and how you might modify it are included below.  There is another version in the the next chapter that you can use to investigate Docker commands and components.

Note that this approach relies on two files that have quote that's not shown here: [dvdrental.Dockerfile](./dvdrental.Dockerfile) and [init-dvdrental.sh](init-dvdrental.sh).  They are discussed below.

Note that `tidyverse`, `DBI`, `RPostgres`, and `glue` are loaded.



## First, verify that Docker is up and running:

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

## Clean up if appropriate
Remove the `sql-pet` container if it exists (e.g., from a prior run)

```r
if (system2("docker", "ps -a", stdout = TRUE) %>% 
   grepl(x = ., pattern = 'sql-pet') %>% 
   any()) {
     system2("docker", "rm -f sql-pet")
}
```
## Build the Docker Image
Build an image that derives from postgres:10, defined in `dvdrental.Dockerfile`, that is set up to restore and load the dvdrental db on startup.  The [dvdrental.Dockerfile](./dvdrental.Dockerfile) is discussed below.  

```r
system2("docker", 
        glue("build ", # tells Docker to build an image that can be loaded as a container
          "--tag postgres-dvdrental ", # (or -t) tells Docker to name the image
          "--file dvdrental.Dockerfile ", #(or -f) tells Docker to read `build` instructions from the dvdrental.Dockerfile
          " . "),  # tells Docker to look for dvdrental.Dockerfile in the current directory
          stdout = TRUE, stderr = TRUE)
```

```
##  [1] "Sending build context to Docker daemon  11.96MB\r\r"                                                                                                                                                                                                                                                                                                                                           
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
Run docker to bring up postgres.  The first time it runs it will take a minute to create the Postgres environment.  There are two important parts to this that may not be obvious:

  * The `source=` paramter points to [dvdrental.Dockerfile](./dvdrental.Dockerfile), which does most of the heavy lifting.  It has detailed, line-by-line comments to explain what it is doing.  
  *  *Inside* [dvdrental.Dockerfile](./dvdrental.Dockerfile) the comand `COPY init-dvdrental.sh /docker-entrypoint-initdb.d/` copies  [init-dvdrental.sh](init-dvdrental.sh) from the local file system into the specified location in the Docker container.  When the Postgres Docker container initializes, it looks for that file and executes it. 

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
  "source='", # tells Docker where the local file will be found
  wd, "/',", # the current working directory, as retrieved above
  "target=/petdir", # tells Docker to refer to the current directory as "/petdir" in its file system
  " postgres-dvdrental" # tells Docker to run the image was built in the previous step
)

# if you are curious you can paste this string into a terminal window after the command 'docker':
docker_cmd
```

```
## run --detach  --name sql-pet --publish 5432:5432 --mount type=bind,source='/Users/jds/Documents/Library/R/r-system/sql-pet/r-database-docker/',target=/petdir postgres-dvdrental
```

```r
system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

```
## [1] "6f9eca291846b5e81445a4de60b77d980e3698cbc4a80b76bff7d1ff7c8555f4"
```
## Connect to Postgres with R
Use the DBI package to connect to Postgres.  But first, wait for Docker & Postgres to come up before connecting.

We have loaded the `wait_for_postgres` function behind the scenes.


```r
con <- wait_for_postgres(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "dvdrental",
                         seconds_to_test = 10)


# if (con == "it's not there") {stop()}

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

Sys.sleep(2) # Can take a moment to disconnect.
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

```r
Sys.sleep(3) # can take a moment for Docker to stop the container.
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
It's always good to have R disconnect from the database

```r
dbDisconnect(con)
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
## [1] "6f9eca291846        postgres-dvdrental   \"docker-entrypoint.s…\"   21 seconds ago      Exited (137) Less than a second ago                       sql-pet"
```

## Cleaning up

Next time, you can just use this command to start the container:

`system2("docker",  "start sql-pet", stdout = TRUE, stderr = TRUE)`

And once stopped, the container can be removed with:

`system2("docker",  "rm sql-pet", stdout = TRUE, stderr = TRUE)`

## Using the `sql-pet` container in the rest of the book

After this point in the book, we assume that Docker is up and that we can always start up our *sql-pet database* with:

`system2("docker",  "start sql-pet", stdout = TRUE, stderr = TRUE)`
