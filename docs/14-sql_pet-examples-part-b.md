# Postgres Examples, part B (14)







## Verify Docker is up and running:

```r
result <- system2("docker", "version", stdout = TRUE, stderr = TRUE)
result
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
verify pet DB is available, it may be stopped.

```r
result <- system2("docker", "ps -a", stdout = TRUE, stderr = TRUE)
result
```

```
## [1] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                     PORTS               NAMES"    
## [2] "baca0bf84b20        postgres:10         \"docker-entrypoint.s…\"   30 seconds ago      Exited (0) 2 seconds ago                       sql-pet"
```

```r
any(grepl('Up .+pet$',result))
```

```
## [1] FALSE
```
Start up the `docker-pet` container

```r
result <- system2("docker", "start sql-pet", stdout = TRUE, stderr = TRUE)
result
```

```
## [1] "sql-pet"
```


now connect to the database with R

```r
con <- wait_for_postgres(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "dvdrental",
                         seconds_to_test = 10)
```
All of the material from this file has moved to files 71, 72, and 73.

Clean up

```r
# dbRemoveTable(con, "cars")
# dbRemoveTable(con, "mtcars")
# dbRemoveTable(con, "cust_movies")

# diconnect from the db
dbDisconnect(con)

result <- system2("docker", "stop sql-pet", stdout = TRUE, stderr = TRUE)
result
```

```
## [1] "sql-pet"
```

