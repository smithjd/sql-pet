Get and Install dvdrental database in Postgres - version c
================
John D. Smith (with mods by Scott Came)
9/3/2018

## Create a Postgres container, restore dvdrental database, test connection

## verify that Docker is up and running:

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

``` r
# build an image that derives from postgres:9.4, defined in dvdrental.Dockerfile, that is set up to restore and load the dvdrental db on startup

system2("docker", "build -t postgres-dvdrental -f dvdrental.Dockerfile .", stdout = TRUE, stderr = TRUE)
```

    ##  [1] "Sending build context to Docker daemon   25.6kB\r\r"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    ##  [2] "Step 1/3 : FROM postgres:9.4"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
    ##  [3] " ---> 778c7dfbeb5d"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
    ##  [4] "Step 2/3 : WORKDIR /tmp"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    ##  [5] " ---> Using cache"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
    ##  [6] " ---> 9f4810c5dfe0"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
    ##  [7] "Step 3/3 : RUN apt-get -qq update && apt-get install -y -qq curl zip  > /dev/null 2>&1 &&   curl -Os http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip &&   unzip dvdrental.zip &&   rm dvdrental.zip &&   chmod ugo+w dvdrental.tar &&   chown postgres dvdrental.tar &&   echo '#!/bin/bash' > /docker-entrypoint-initdb.d/dvdrental.sh &&   echo 'psql -U postgres -c \"CREATE DATABASE dvdrental;\"' >> /docker-entrypoint-initdb.d/dvdrental.sh &&   echo 'pg_restore -v -U postgres -d dvdrental /tmp/dvdrental.tar' >> /docker-entrypoint-initdb.d/dvdrental.sh &&   echo 'rm -f /tmp/dvdrental.tar' >> /docker-entrypoint-initdb.d/dvdrental.sh &&   chmod u+x /docker-entrypoint-initdb.d/dvdrental.sh &&   apt-get remove -y curl zip"
    ##  [8] " ---> Using cache"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
    ##  [9] " ---> 38315a3acca7"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
    ## [10] "Successfully built 38315a3acca7"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
    ## [11] "Successfully tagged postgres-dvdrental:latest"

``` r
# run docker to bring up postgres.  The first time it runs it will take a minute to create the Postgres environment.

wd <- getwd()

docker_cmd <- paste0(
  "run -d --name pet --publish 5432:5432 ",
  '--mount "type=bind,source=', wd,
  '/,target=/petdir"',
    " postgres-dvdrental"
)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

    ## [1] "de13fc3c7038daf1342bdae56eb70224a68edd4093f698a302cbd3cc707a8215"

now connect to the database with R

``` r
# need to wait for Docker & Postgres to come up before connecting.
Sys.sleep(5) 

con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "localhost",
                      port = "5432",
                      user = "postgres",
                      password = "postgres",
                      dbname = "dvdrental" ) # note that the dbname is specified

dbListTables(con)
```

    ##  [1] "actor_info"                 "customer_list"             
    ##  [3] "film_list"                  "nicer_but_slower_film_list"
    ##  [5] "sales_by_film_category"     "sales_by_store"            
    ##  [7] "staff"                      "inventory"                 
    ##  [9] "country"                    "store"                     
    ## [11] "staff_list"                 "language"                  
    ## [13] "actor"                      "category"                  
    ## [15] "city"                       "rental"                    
    ## [17] "film_actor"                 "address"                   
    ## [19] "film_category"              "film"                      
    ## [21] "customer"                   "payment"

``` r
dbListFields(con, "rental")
```

    ## [1] "rental_id"    "rental_date"  "inventory_id" "customer_id" 
    ## [5] "return_date"  "staff_id"     "last_update"

``` r
dbDisconnect(con)
```

Stop the container

``` r
system2('docker', 'stop pet',
        stdout = TRUE, stderr = TRUE)
```

    ## [1] "pet"

Restart the container and verify that the dvdrental database is still
there

``` r
docker_cmd <- paste0(
  "start pet"
)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

    ## [1] "pet"

``` r
Sys.sleep(1) # need to wait for Docker & Postgres to come up before connecting.

con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "localhost",
                      port = "5432",
                      user = "postgres",
                      password = "postgres",
                      dbname = "dvdrental" ) # note that the dbname is specified

dbListTables(con)
```

    ##  [1] "actor_info"                 "customer_list"             
    ##  [3] "film_list"                  "nicer_but_slower_film_list"
    ##  [5] "sales_by_film_category"     "sales_by_store"            
    ##  [7] "staff"                      "inventory"                 
    ##  [9] "country"                    "store"                     
    ## [11] "staff_list"                 "language"                  
    ## [13] "actor"                      "category"                  
    ## [15] "city"                       "rental"                    
    ## [17] "film_actor"                 "address"                   
    ## [19] "film_category"              "film"                      
    ## [21] "customer"                   "payment"

``` r
dbListFields(con, "rental")
```

    ## [1] "rental_id"    "rental_date"  "inventory_id" "customer_id" 
    ## [5] "return_date"  "staff_id"     "last_update"

``` r
dbDisconnect(con)
```

Stop the container & show that it is still there, so can be started
again.

``` r
system2('docker', 'stop pet',
        stdout = TRUE, stderr = TRUE)
```

    ## [1] "pet"

``` r
# show that the container still exists
system2('docker', 'ps -a',
        stdout = TRUE, stderr = TRUE)
```

    ## [1] "CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS                              PORTS                    NAMES"                    
    ## [2] "de13fc3c7038        postgres-dvdrental   \"docker-entrypoint.s…\"   9 seconds ago       Exited (0) Less than a second ago                            pet"                    
    ## [3] "a47c64e6c3ac        61205f6444f9         \"/bin/sh -c 'cd /tmp…\"   4 days ago          Exited (1) 4 days ago                                        affectionate_heisenberg"
    ## [4] "386259e955e6        fdc37809b564         \"/bin/sh -c 'rm /opt…\"   5 days ago          Exited (1) 5 days ago                                        elegant_wright"         
    ## [5] "5cc9750838cc        mariadb              \"docker-entrypoint.s…\"   6 weeks ago         Up 3 hours                          0.0.0.0:3306->3306/tcp   mariadb"

``` r
#
# Once stopped, the container could be removed with:
#
# system2('docker', 'rm pet ',
#         stdout = TRUE, stderr = TRUE)
```
