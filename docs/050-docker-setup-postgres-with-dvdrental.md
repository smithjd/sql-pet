# Create the hrsample database in PostgreSQL in Docker {#chapter_setup-hrsample-db}

> NOTE: This chapter doesn't go into the details of *creating* or *restoring* the `hrsample` database.  For more detail on what's going on behind the scenes, you can examine the step-by-step code in:
>
> ` source('book-src/restore-hrsample-postgres-on-docker.R') `

> This chapter demonstrates how to:
>
>  * Setup the `hrsample` database in Docker
>  * Stop and start Docker container to demonstrate persistence
>  * Connect to and disconnect R from the `hrsample` database
>  * Set up the environment for subsequent chapters

## Overview

In the last chapter we connected to PostgreSQL from R.  Now we set up a "realistic" database named `hrsample`. There are different approaches to doing this: this chapter sets it up in a way that doesn't show all the Docker details.

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
library(here)
```

## Verify that Docker is up and running

```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up, running these containers:"                                                                                                     
## [2] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES"     
## [3] "a66142ed0ec2        postgres:10         \"docker-entrypoint.s…\"   9 minutes ago       Up 2 minutes        0.0.0.0:5432->5432/tcp   hrsample"
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
sp_docker_remove_container("hrsample")
```

```
## [1] 0
```
## Build the pet-sql Docker image

**UPDATE:** For the rest of the book we will be using a Docker image called
`hrsample`. To save space here in the book, we've created a function
in `sqlpetr` to build this image, called [`sp_make_dvdrental_image`](https://smithjd.github.io/sqlpetr/reference/sp_make_dvdrental_image.html). Vignette [Building the `hsrample` Docker Image
](https://smithjd.github.io/sqlpetr/articles/building-the-dvdrental-docker-image.html) describes the build process.


```r
# sp_make_dvdrental_image("postgres-dvdrental")
source(here("book-src", "restore-hrsample-postgres-on-docker.R"))
```

```
## docker  run --detach  --name hrsample --publish 5432:5432 --mount type=bind,source="/Users/jds/Documents/Library/R/r-system/sql-pet",target=/petdir postgres:10
```

**UPDATE:** Did it work? We have a function that lists the images into a tibble!


```r
sp_docker_start("hrsample")
sp_docker_images_tibble()  # Doesn't produce the expected output.
```

```
## # A tibble: 3 x 7
##   image_id  repository   tag    digest           created created_at   size 
##   <chr>     <chr>        <chr>  <chr>            <chr>   <chr>        <chr>
## 1 aff06852… postgres-dv… latest <none>           6 week… 2019-04-26 … 294MB
## 2 c149455a… <none>       <none> <none>           2 mont… 2019-03-18 … 252MB
## 3 3e016ba4… postgres     10     sha256:5c702997… 3 mont… 2019-03-04 … 230MB
```

## Run the pet-sql Docker Image
**UPDATE:** Now we can run the image in a container and connect to the database. To run the
image we use an `sqlpetr` function called [`sp_pg_docker_run`](https://smithjd.github.io/sqlpetr/reference/sp_pg_docker_run.html)


```r
sp_pg_docker_run(
  container_name = "sql-pet",
  image_tag = "postgres-dvdrental",
  postgres_password = "postgres"
)
```

**UPDATE:** Did it work?

```r
sp_docker_containers_tibble()
```

```
## # A tibble: 1 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
## 1 dee42b174456 post… docker… 2019-06-1… 10 sec… 0.0.… Up Le… 63B … hrsa…
## # … with 3 more variables: labels <chr>, mounts <chr>, networks <chr>
```

## Connect to PostgreSQL with R

Use the DBI package to connect to the `hrsample` database in PostgreSQL.  Remember the settings discussion about [keeping passwords hidden][Pause for some security considerations]


```r
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "hrsample",
  seconds_to_test = 30, connection_tab = TRUE
)
```
For the moment we by-pass some complexity that results from the fact that the `hrsample` has multiple *schemas* and that we are interested in only one of them, named `hrsample`.  

```r
tbl(con, in_schema("information_schema", "schemata")) %>%
  select(catalog_name, schema_name, schema_owner) %>%
  collect()
```

```
## # A tibble: 7 x 3
##   catalog_name schema_name        schema_owner
##   <chr>        <chr>              <chr>       
## 1 hrsample     pg_toast           postgres    
## 2 hrsample     pg_temp_1          postgres    
## 3 hrsample     pg_toast_temp_1    postgres    
## 4 hrsample     pg_catalog         postgres    
## 5 hrsample     public             postgres    
## 6 hrsample     information_schema postgres    
## 7 hrsample     hrsample           postgres
```

Schemas will be discussed later on because multiple schemas are the norm in an enterprise database environment, but they are a side issue at this point.  So we switch the order in which PostgreSQL searches for objects with the following SQL code:

```r
dbExecute(con, "set search_path to hrsample, public;")
```

```
## [1] 0
```
With the custom `search_path`, the following command works, but it will fail without out it.

```r
dbListTables(con)
```

```
##  [1] "contact_table"     "deskhistory"       "deskjob"          
##  [4] "education_table"   "employeeinfo"      "hierarchy"        
##  [7] "performancereview" "recruiting_table"  "rollup_view"      
## [10] "salaryhistory"     "skills_table"
```
Same for `dbListFields`:

```r
dbListFields(con, "employeeinfo")
```

```
## [1] "employee_num" "first_name"   "last_name"    "city"        
## [5] "state"
```

Thus with this search order, the following two produce identical results:

```r
tbl(con, in_schema("hrsample", "employeeinfo")) %>%
  head()
```

```
## # Source:   lazy query [?? x 5]
## # Database: postgres [postgres@localhost:5432/hrsample]
##   employee_num first_name last_name   city        state
##          <int> <chr>      <chr>       <chr>       <chr>
## 1            3 Lana       Chrostowski Utica       MS   
## 2           20 Justine    Kopiasz     Milnor      ND   
## 3           21 Claude     Feldman     Woodville   AL   
## 4           38 Ronald     Finona      West Glover VT   
## 5           39 Stewart    Pruess      Martin      OH   
## 6           41 Nona       Favalora    Pascagoula  MS
```

```r
tbl(con, "employeeinfo") %>%
  head()
```

```
## # Source:   lazy query [?? x 5]
## # Database: postgres [postgres@localhost:5432/hrsample]
##   employee_num first_name last_name   city        state
##          <int> <chr>      <chr>       <chr>       <chr>
## 1            3 Lana       Chrostowski Utica       MS   
## 2           20 Justine    Kopiasz     Milnor      ND   
## 3           21 Claude     Feldman     Woodville   AL   
## 4           38 Ronald     Finona      West Glover VT   
## 5           39 Stewart    Pruess      Martin      OH   
## 6           41 Nona       Favalora    Pascagoula  MS
```


Disconnect from the database:

```r
dbDisconnect(con)
```
## Stop and start to demonstrate persistence

Stop the container:

```r
sp_docker_stop("hrsample")
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
## # A tibble: 1 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
## 1 dee42b174456 post… docker… 2019-06-1… 12 sec… <NA>  Exite… 0B (… hrsa…
## # … with 3 more variables: labels <chr>, mounts <chr>, networks <chr>
```


Restart the container and verify that the hrsample tables are still there:

```r
sp_docker_start("hrsample")
sp_docker_containers_tibble()
```

```
## # A tibble: 1 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
## 1 dee42b174456 post… docker… 2019-06-1… 13 sec… 0.0.… Up Le… 63B … hrsa…
## # … with 3 more variables: labels <chr>, mounts <chr>, networks <chr>
```
Connect to the `hrsample` database in PostgreSQL:

```r
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "hrsample",
  seconds_to_test = 30
)
```

Check that you can still see the first few rows of the `employeeinfo` table:

```r
tbl(con, in_schema("hrsample", "employeeinfo")) %>%
  head()
```

```
## # Source:   lazy query [?? x 5]
## # Database: postgres [postgres@localhost:5432/hrsample]
##   employee_num first_name last_name   city        state
##          <int> <chr>      <chr>       <chr>       <chr>
## 1            3 Lana       Chrostowski Utica       MS   
## 2           20 Justine    Kopiasz     Milnor      ND   
## 3           21 Claude     Feldman     Woodville   AL   
## 4           38 Ronald     Finona      West Glover VT   
## 5           39 Stewart    Pruess      Martin      OH   
## 6           41 Nona       Favalora    Pascagoula  MS
```

## Cleaning up

Always have R disconnect from the database when you're done.

```r
dbDisconnect(con)
```

Stop the `sql-pet` container:

```r
sp_docker_stop("hrsample")
```
Show that the container still exists even though it's not running


```r
sp_show_all_docker_containers()
```

```
## CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                              PORTS               NAMES
## dee42b174456        postgres:10         "docker-entrypoint.s…"   14 seconds ago      Exited (0) Less than a second ago                       hrsample
```

Next time, you can just use this command to start the container: 

> `sp_docker_start("hrsample")`

And once stopped, the container can be removed with:

> `sp_check_that_docker_is_up("hrsample")`

## Using the `sql-pet` container in the rest of the book

After this point in the book, we assume that Docker is up and that we can always start up our *sql-pet database* with:

> `sp_docker_start("hrsample")`


