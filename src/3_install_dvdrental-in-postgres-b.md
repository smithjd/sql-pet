Install dvdrental database in Postgres - version b
================
John D. Smith
8/12/2018

## Create a Postgres container, restore dvdrental database, test connection

## Be sure to run /src/get\_dvdrental-zipfile.Rmd first

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
# run docker to bring up postgres.  The first time it runs it will take a minute to create the Postgres environment.

wd <- getwd()

docker_cmd <- paste0(
  "run -d --name pet --publish 5432:5432 ",
  '--mount "type=bind,source=', wd,
  '/,target=/petdir"',
    " postgres:9.4"
)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

    ## [1] "849deae2d284de407ae8b357dee8cf32e65c5eaa6f78ee433dafb9146e191e3e"

``` r
# show files in your working directory
system2('docker', 'exec pet ls petdir',
        stdout = TRUE, stderr = TRUE)
```

    ##  [1] "1_test_postgres-b.md"                 
    ##  [2] "1_test_postgres-b.R"                  
    ##  [3] "1_test_postgres.md"                   
    ##  [4] "1_test_postgres.R"                    
    ##  [5] "2_get_dvdrental-zipfile.md"           
    ##  [6] "2_get_dvdrental-zipfile.Rmd"          
    ##  [7] "3_install_dvdrental-in-postgres-b.md" 
    ##  [8] "3_install_dvdrental-in-postgres-b.Rmd"
    ##  [9] "3_install_dvdrental-in-postgres.md"   
    ## [10] "3_install_dvdrental-in-postgres.Rmd"  
    ## [11] "4_test_dvdrental-database-b.Rmd"      
    ## [12] "4_test_dvdrental-database_files"      
    ## [13] "4_test_dvdrental-database.md"         
    ## [14] "4_test_dvdrental-database.Rmd"        
    ## [15] "dvdrental.tar"

``` r
Sys.sleep(2)
# inside Docker, execute the postgress SQL command-line program to create the dvdrental database:
system2('docker', 'exec pet psql -U postgres -c "CREATE DATABASE dvdrental;"',
        stdout = TRUE, stderr = TRUE)
```

    ## [1] "CREATE DATABASE"

``` r
Sys.sleep(2)
# restore the database from the .tar file
system2("docker", "exec pet pg_restore -U postgres -d dvdrental petdir/dvdrental.tar", stdout = TRUE, stderr = TRUE)
```

    ## character(0)

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

    ## [1] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                              PORTS               NAMES"
    ## [2] "849deae2d284        postgres:9.4        \"docker-entrypoint.s…\"   14 seconds ago      Exited (0) Less than a second ago                       pet"

``` r
#
# Once stopped, the container could be removed with:
#
# system2('docker', 'rm pet ',
#         stdout = TRUE, stderr = TRUE)
```
