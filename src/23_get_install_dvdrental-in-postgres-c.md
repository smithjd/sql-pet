Get and Install dvdrental database in Postgres - version c
================
John D. Smith (with mods by Scott Came)
9/3/2018

## Create a Postgres container, restore dvdrental database, test connection

verify that Docker is up and running:

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
    ## [19] " Kubernetes:"                                   
    ## [20] "  Version:          v1.10.3"                    
    ## [21] "  StackAPI:         v1beta2"

build an image that derives from postgres:10, defined in
dvdrental.Dockerfile, that is set up to restore and load the dvdrental
db on
startup

``` r
system2("docker", "build -t postgres-dvdrental -f dvdrental.Dockerfile .", stdout = TRUE, stderr = TRUE)
```

    ##  [1] "Sending build context to Docker daemon  27.65kB\r\r"                                                                                                                                                                                                                                                                                                                                           
    ##  [2] "Step 1/4 : FROM postgres:10"                                                                                                                                                                                                                                                                                                                                                                   
    ##  [3] " ---> ac25c2bac3c4"                                                                                                                                                                                                                                                                                                                                                                            
    ##  [4] "Step 2/4 : WORKDIR /tmp"                                                                                                                                                                                                                                                                                                                                                                       
    ##  [5] " ---> Using cache"                                                                                                                                                                                                                                                                                                                                                                             
    ##  [6] " ---> 7fcddd04bd0d"                                                                                                                                                                                                                                                                                                                                                                            
    ##  [7] "Step 3/4 : COPY init-dvdrental.sh /docker-entrypoint-initdb.d/"                                                                                                                                                                                                                                                                                                                                
    ##  [8] " ---> Using cache"                                                                                                                                                                                                                                                                                                                                                                             
    ##  [9] " ---> 70d5ae5da0ee"                                                                                                                                                                                                                                                                                                                                                                            
    ## [10] "Step 4/4 : RUN apt-get -qq update &&   apt-get install -y -qq curl zip  > /dev/null 2>&1 &&   curl -Os http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip &&   unzip dvdrental.zip &&   rm dvdrental.zip &&   chmod ugo+w dvdrental.tar &&   chown postgres dvdrental.tar &&   chmod u+x /docker-entrypoint-initdb.d/init-dvdrental.sh &&   apt-get remove -y curl zip"
    ## [11] " ---> Using cache"                                                                                                                                                                                                                                                                                                                                                                             
    ## [12] " ---> 5819141d8fe3"                                                                                                                                                                                                                                                                                                                                                                            
    ## [13] "Successfully built 5819141d8fe3"                                                                                                                                                                                                                                                                                                                                                               
    ## [14] "Successfully tagged postgres-dvdrental:latest"

remove the `pet` container if it
exists

``` r
if(system2("docker", "ps -a", stdout=TRUE) %>% grepl(x=., pattern='postgres-dvdrental.+pet') %>% any()) {
  system2("docker", "rm -f pet")
}
```

run docker to bring up postgres. The first time it runs it will take a
minute to create the Postgres environment.

``` r
wd <- getwd()

docker_cmd <- paste0(
  "run -d --name pet --publish 5432:5432 ",
  '--mount "type=bind,source=', wd,
  '/,target=/petdir"',
    " postgres-dvdrental"
)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

    ## [1] "f3566f0db69dbc41ebf8b55454414762ceeb9d59b2b0de197ac73fd4c62d0d3b"

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
psout <- system2("docker", "ps -a", stdout=TRUE)
psout[grepl(x=psout, pattern='postgres-dvdrental.+pet')]
```

    ## [1] "f3566f0db69d        postgres-dvdrental                          \"docker-entrypoint.s…\"   9 seconds ago       Exited (0) Less than a second ago                       pet"

``` r
#
# Once stopped, the container could be removed with:
#
# system2('docker', 'rm pet ',
#         stdout = TRUE, stderr = TRUE)
```
