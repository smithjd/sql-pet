# Create the dvdrental database in PostgreSQL in Docker {#chapter_setup-dvdrental-db}

> This chapter demonstrates how to:
>
>  * Setup the `dvdrental` database in Docker
>  * Stop and start Docker container to demonstrate persistence
>  * Connect to and disconnect R from the `dvdrental` database
>  * Set up the environment for subsequent chapters

## Overview

In the last chapter we connected to PostgreSQL from R.  Now we set up a "realistic" database named `dvdrental`. There are different approaches to doing this: this chapter sets it up in a way that doesn't show all the Docker details.

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
Force-remove the `cattle` and `sql-pet` containers if they exist (e.g., from a prior runs):

```r
sp_docker_remove_container("cattle")
```

```
## [1] 0
```

```r
sp_docker_remove_container("sql-pet")
```

```
## [1] 0
```
## Build the pet-sql Docker image
For the rest of the book we will be using a Docker image called
`postgres-dvdrental`. To save space here in the book, we've created a function
in `sqlpetr` to build this image, called [`sp_make_dvdrental_image`](https://smithjd.github.io/sqlpetr/reference/sp_make_dvdrental_image.html). Vignette [Building the `dvdrental` Docker Image
](https://smithjd.github.io/sqlpetr/articles/building-the-dvdrental-docker-image.html) describes the build process.


```r
sp_make_dvdrental_image("postgres-dvdrental")
```

Did it work? We have a function that lists the images into a tibble!

```r
sp_docker_images_tibble()
```

```
## Warning: 7 parsing failures.
## row col  expected    actual         file
##   1  -- 1 columns 7 columns literal data
##   2  -- 1 columns 7 columns literal data
##   3  -- 1 columns 7 columns literal data
##   4  -- 1 columns 7 columns literal data
##   5  -- 1 columns 7 columns literal data
## ... ... ......... ......... ............
## See problems(...) for more details.
```

```
## # A tibble: 7 x 1
##   image_id_repository_tag_digest_created_created_at_size
##   <chr>                                                 
## 1 97e0890eea7d                                          
## 2 6699b3ab3974                                          
## 3 f94f2247ea09                                          
## 4 46e6e5937df7                                          
## 5 ebdd3a33f882                                          
## 6 2fd32ba146a8                                          
## 7 8ee0fb4d4cfc
```

## Run the pet-sql Docker Image
Now we can run the image in a container and connect to the database. To run the
image we use an `sqlpetr` function called [`sp_pg_docker_run`](https://smithjd.github.io/sqlpetr/reference/sp_pg_docker_run.html)

When the image runs in the container, we can mount the current working directory
into a path in the container. You'll see this in action in a future chapter. 
Docker will create this path if it doesn't exist.

To specify the path, set the parameter `mount_here_as` to the name you want.
Rules for the name:

* If you don't want to mount into the container, specify `NULL`. This is the 
default!
* The name must start with a `/` and be a valid absolute path.
The name should contain only slashes, letters, numbers and underscores. Other characters may or may not work. The `snakecase` package is your friend.


```r
sp_pg_docker_run(
  container_name = "sql-pet",
  image_tag = "postgres-dvdrental",
  postgres_password = "postgres",
  mount_here_as = "/petdir"
)
```

Did it work?

```r
sp_docker_containers_tibble()
```

```
## Warning: 1 parsing failure.
## row col  expected     actual         file
##   1  -- 1 columns 12 columns literal data
```

```
## # A tibble: 1 x 1
##   container_id_image_command_created_at_created_ports_status_size_names_la…
##   <chr>                                                                    
## 1 5bbf878aaf9a
```

## Connect to PostgreSQL with R

Use the DBI package to connect to the `dvdrental` database in PostgreSQL.  Remember the settings discussion about [keeping passwords hidden][Pause for some security considerations]


```r
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "dvdrental",
  seconds_to_test = 30
)
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
sp_docker_containers_tibble()
```

```
## # A tibble: 0 x 0
```

When we stopped `sql-pet`, it no longer appeared in the tibble. But the
container is still there. `sp_docker_containers_tibble` by default only lists
the *running* containers. But we can use the `list_all` option and see it:


```r
sp_docker_containers_tibble(list_all = TRUE)
```

```
## Warning: 4 parsing failures.
## row col  expected     actual         file
##   1  -- 1 columns 12 columns literal data
##   2  -- 1 columns 12 columns literal data
##   3  -- 1 columns 12 columns literal data
##   4  -- 1 columns 12 columns literal data
```

```
## # A tibble: 4 x 1
##   container_id_image_command_created_at_created_ports_status_size_names_la…
##   <chr>                                                                    
## 1 5bbf878aaf9a                                                             
## 2 1261c73d983d                                                             
## 3 12c5f548caac                                                             
## 4 8082929a1424
```


Restart the container and verify that the dvdrental tables are still there:

```r
sp_docker_start("sql-pet")
sp_docker_containers_tibble()
```

```
## Warning: 1 parsing failure.
## row col  expected     actual         file
##   1  -- 1 columns 12 columns literal data
```

```
## # A tibble: 1 x 1
##   container_id_image_command_created_at_created_ports_status_size_names_la…
##   <chr>                                                                    
## 1 5bbf878aaf9a
```
Connect to the `dvdrental` database in PostgreSQL:

```r
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "dvdrental",
  seconds_to_test = 30
)
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
## CONTAINER ID        IMAGE                             COMMAND                  CREATED             STATUS                              PORTS                                     NAMES
## 5bbf878aaf9a        postgres-dvdrental                "docker-entrypoint..."   10 seconds ago      Exited (0) Less than a second ago                                             sql-pet
## 1261c73d983d        docker.io/dpage/pgadmin4:latest   "/entrypoint.sh"         9 hours ago         Exited (255) 9 hours ago            443/tcp, 0.0.0.0:8686->80/tcp             pgadmin4
## 12c5f548caac        rstatsp:latest                    "/bin/sh -c 'servi..."   9 hours ago         Exited (255) 9 hours ago            80/tcp, 443/tcp, 0.0.0.0:8004->8004/tcp   rstats
## 8082929a1424        postgis:latest                    "docker-entrypoint..."   9 hours ago         Exited (255) 9 hours ago            0.0.0.0:5439->5432/tcp                    postgis
```

Next time, you can just use this command to start the container: 

> `sp_docker_start("sql-pet")`

And once stopped, the container can be removed with:

> `sp_check_that_docker_is_up("sql-pet")`

## Using the `sql-pet` container in the rest of the book

After this point in the book, we assume that Docker is up and that we can always start up our *sql-pet database* with:

> `sp_docker_start("sql-pet")`
