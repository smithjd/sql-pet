# A persistent database in Postgres in Docker - all at once

## Overview

You've already connected to Postgres with R, now you need a "realistic" (`dvdrental`) database. We're going to demonstrate how to set one up, with two different approaches.  This chapter and the next do the same job, illustrating the different approaches that you can take and helping you see the different points whwere you could swap what's provided here with a different DBMS or a different backup file or something else.

The code in this first version is recommended because it is an "all in one" approach.  Details about how it works and how you might modify it are included below.

Note that this approach relies on two files that have quote that's not shown here: [dvdrental.Dockerfile](./dvdrental.Dockerfile) and [init-dvdrental.sh](init-dvdrental.sh).  They are discussed below.

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
Remove the `pet` container if it exists (e.g., from a prior run)

```r
if (system2("docker", "ps -a", stdout = TRUE) %>% 
   grepl(x = ., pattern = 'postgres-dvdrental.+pet') %>% 
   any()) {
     system2("docker", "rm -f pet")
}
```
## Build the Docker Image
Build an image that derives from postgres:10, defined in `dvdrental.Dockerfile`, that is set up to restore and load the dvdrental db on startup.  The `dvdrental.Dockerfile` is shown and discussed below.  

```r
system2("docker", "build -t postgres-dvdrental -f dvdrental.Dockerfile .", stdout = TRUE, stderr = TRUE)
```

```
##  [1] "Sending build context to Docker daemon  540.7kB\r\r"                                                                                                                                                                                                                                                                                                                                           
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

docker_cmd <- paste0(
  "run -d --name pet --publish 5432:5432 ",
  '--mount "type=bind,source=', wd,
  '/,target=/petdir"',
    " postgres-dvdrental"
)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

```
## [1] "66928eddb1ac56da90f3a873459c09444606f4032c02197e0dc1e6d9c1e44852"
```
## Connect to Postgres with R

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

Sys.sleep(1) # Can take a moment to disconnect.
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

```r
Sys.sleep(2) # can take a moment for Docker to stop the container.
```
Restart the container and verify that the dvdrental tables are still there

```r
system2("docker",  "start pet", stdout = TRUE, stderr = TRUE)
```

```
## [1] "pet"
```

```r
Sys.sleep(2) # need to wait for Docker & Postgres to come up before connecting.

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
psout[grepl(x = psout, pattern = 'postgres-dvdrental.+pet')]
```

```
## [1] "66928eddb1ac        postgres-dvdrental   \"docker-entrypoint.s…\"   22 seconds ago      Exited (137) Less than a second ago                       pet"
```

```r
system2('docker', 'rm pet',
        stdout = TRUE, stderr = TRUE)
```

```
## [1] "pet"
```
Next time, you can just use this command to start the container:

`system2("docker",  "start pet", stdout = TRUE, stderr = TRUE)`

And once stopped, the container can be removed with:

`system2("docker",  "rm pet", stdout = TRUE, stderr = TRUE)`
