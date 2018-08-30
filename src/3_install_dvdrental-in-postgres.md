Install dvdrental database in Postgres
================
John D. Smith
8/12/2018

``` r
if (!require(here)) install.packages("here")
```

    ## Loading required package: here

    ## here() starts at /Users/jds/Documents/Library/R/r-system/sql-pet

``` r
library(here)

# run get_dvdrental-zipfile.Rmd first

# verify that Docker is up and running:

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
# run docker-compose to bring up postgres.  The first time it runs it will take a minute to create the Postgres environment.

system2("docker-compose", "up -d", stdout = TRUE, stderr = TRUE)
```

    ## [1] "Starting sql-pet_dat_1 ... \r"                                                                             
    ## [2] "\033[1A\033[2K\rStarting sql-pet_dat_1 ... \033[32mdone\033[0m\r\033[1BStarting sql-pet_postgres9_1 ... \r"
    ## [3] "\033[1A\033[2K\rStarting sql-pet_postgres9_1 ... \033[32mdone\033[0m\r\033[1B"

``` r
# inside Docker, execute the postgress SQL command line program to create the dvdrental database:

system2('docker', 'exec sql-pet_postgres9_1 psql -U postgres -c "CREATE DATABASE dvdrental;"',
        stdout = TRUE, stderr = TRUE)
```

    ## [1] "CREATE DATABASE"

``` r
# verify that R is running with the right directory (the repo's)
system2("pwd", stdout = TRUE, stderr = TRUE)
```

    ## [1] "/Users/jds/Documents/Library/R/r-system/sql-pet/src"

``` r
# restore the database from the .tar file

system2("docker", "exec sql-pet_postgres9_1 pg_restore -U postgres -d dvdrental /src/dvdrental.tar", stdout = TRUE, stderr = TRUE)
```

    ## Warning in system2("docker", "exec sql-pet_postgres9_1 pg_restore -U
    ## postgres -d dvdrental /src/dvdrental.tar", : running command ''docker' exec
    ## sql-pet_postgres9_1 pg_restore -U postgres -d dvdrental /src/dvdrental.tar
    ## 2>&1' had status 1

    ## [1] "pg_restore: [archiver] could not open input file \"/src/dvdrental.tar\": No such file or directory"
    ## attr(,"status")
    ## [1] 1

``` r
# verify that the dvdrental database exists
system2('docker', 'exec sql-pet_postgres9_1 psql -U postgres -c "\\l"', stdout = TRUE, stderr = TRUE)
```

    ##  [1] "                                 List of databases"                                 
    ##  [2] "   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges   "
    ##  [3] "-----------+----------+----------+------------+------------+-----------------------"
    ##  [4] " dvdrental | postgres | UTF8     | en_US.utf8 | en_US.utf8 | "                      
    ##  [5] " postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 | "                      
    ##  [6] " template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +"
    ##  [7] "           |          |          |            |            | postgres=CTc/postgres" 
    ##  [8] " template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +"
    ##  [9] "           |          |          |            |            | postgres=CTc/postgres" 
    ## [10] "(4 rows)"                                                                           
    ## [11] ""

``` r
# Cleanup

file.remove(here("src", "dvdrental.tar"))
```

    ## Warning in file.remove(here("src", "dvdrental.tar")): cannot remove file '/
    ## Users/jds/Documents/Library/R/r-system/sql-pet/src/dvdrental.tar', reason
    ## 'No such file or directory'

    ## [1] FALSE

``` r
system2("docker-compose", "stop", stdout = TRUE, stderr = TRUE)
```

    ## [1] "Stopping sql-pet_postgres9_1 ... \r"                                          
    ## [2] "\033[1A\033[2K\rStopping sql-pet_postgres9_1 ... \033[32mdone\033[0m\r\033[1B"
