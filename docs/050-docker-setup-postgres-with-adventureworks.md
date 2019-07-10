# Create the adventureworks database in PostgreSQL in Docker {#chapter_setup-adventureworks-db}

> NOTE: This chapter doesn't go into the details of *creating* or *restoring* the `adventureworks` database.  For more detail on what's going on behind the scenes, you can examine the step-by-step code in:
>
> ` source('book-src/restore-adventureworks-postgres-on-docker.R') `

> This chapter demonstrates how to:
>
>  * Setup the `adventureworks` database in Docker
>  * Stop and start Docker container to demonstrate persistence
>  * Connect to and disconnect R from the `adventureworks` database
>  * Set up the environment for subsequent chapters

## Overview

In the last chapter we connected to PostgreSQL from R.  Now we set up a "realistic" database named `adventureworks`. There are different approaches to doing this: this chapter sets it up in a way that doesn't show all the Docker details.

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
## [1] "Docker is up but running no containers"
```

## Clean up if appropriate
Force-remove the `adventureworks` container if it exist (e.g., from a prior runs):

```r
sp_docker_remove_container("adventureworks")
```

```
## [1] 0
```
## Build the pet-sql Docker image

**UPDATE:** For the rest of the book we will be using a Docker image called
`adventureworks`. To save space here in the book, we've created a function
in `sqlpetr` to build this image, called [`sp_make_dvdrental_image`](https://smithjd.github.io/sqlpetr/reference/sp_make_dvdrental_image.html). Vignette [Building the `hsrample` Docker Image
](https://smithjd.github.io/sqlpetr/articles/building-the-dvdrental-docker-image.html) describes the build process.


```r
# sp_make_dvdrental_image("postgres-dvdrental")
source(here("book-src", "restore-adventureworks-postgres-on-docker.R"))
```

```
## docker  run --detach  --name adventureworks --publish 5432:5432 --mount type=bind,source="/Users/jds/Documents/Library/R/r-system/sql-pet",target=/petdir postgres:10
```

**UPDATE:** Did it work? We have a function that lists the images into a tibble!


```r
sp_docker_start("adventureworks")
sp_docker_images_tibble()  # Doesn't produce the expected output.
```

```
## # A tibble: 6 x 7
##   image_id  repository   tag    digest           created created_at   size 
##   <chr>     <chr>        <chr>  <chr>            <chr>   <chr>        <chr>
## 1 1523f751… adventurewo… latest <none>           2 week… 2019-06-19 … 475MB
## 2 602a8e50… <none>       <none> <none>           2 week… 2019-06-19 … 365MB
## 3 4e045cb8… postgres     latest sha256:1518027f… 4 week… 2019-06-10 … 312MB
## 4 aff06852… postgres-dv… latest <none>           2 mont… 2019-04-26 … 294MB
## 5 c149455a… <none>       <none> <none>           3 mont… 2019-03-18 … 252MB
## 6 3e016ba4… postgres     10     sha256:5c702997… 4 mont… 2019-03-04 … 230MB
```

## Run the pet-sql Docker Image
**UPDATE:** Now we can run the image in a container and connect to the database. To run the
image we use an `sqlpetr` function called [`sp_pg_docker_run`](https://smithjd.github.io/sqlpetr/reference/sp_pg_docker_run.html)


```r
# sp_pg_docker_run(
#   container_name = "adventureworks",
#   image_tag = "adventureworks",
#   postgres_password = "postgres"
# )
```

**UPDATE:** Did it work?

```r
sp_docker_containers_tibble()
```

```
## # A tibble: 1 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
## 1 f465fab9741b post… docker… 2019-07-1… 12 sec… 0.0.… Up 10… 63B … adve…
## # … with 3 more variables: labels <chr>, mounts <chr>, networks <chr>
```

## Connect to PostgreSQL with R

Use the DBI package to connect to the `adventureworks` database in PostgreSQL.  Remember the settings discussion about [keeping passwords hidden][Pause for some security considerations]


```r
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "adventureworks",
  seconds_to_test = 20, connection_tab = TRUE
)
```
For the moment we by-pass some complexity that results from the fact that the `adventureworks` has multiple *schemas* and that we are interested in only one of them, named `adventureworks`.  

```r
tbl(con, in_schema("information_schema", "schemata")) %>%
  select(catalog_name, schema_name, schema_owner) %>%
  collect()
```

```
## Warning: `overscope_eval_next()` is deprecated as of rlang 0.2.0.
## Please use `eval_tidy()` with a data mask instead.
## This warning is displayed once per session.
```

```
## Warning: `overscope_clean()` is deprecated as of rlang 0.2.0.
## This warning is displayed once per session.
```

```
## # A tibble: 16 x 3
##    catalog_name   schema_name        schema_owner
##    <chr>          <chr>              <chr>       
##  1 adventureworks pg_toast           postgres    
##  2 adventureworks pg_temp_1          postgres    
##  3 adventureworks pg_toast_temp_1    postgres    
##  4 adventureworks pg_catalog         postgres    
##  5 adventureworks public             postgres    
##  6 adventureworks information_schema postgres    
##  7 adventureworks hr                 postgres    
##  8 adventureworks humanresources     postgres    
##  9 adventureworks pe                 postgres    
## 10 adventureworks person             postgres    
## 11 adventureworks pr                 postgres    
## 12 adventureworks production         postgres    
## 13 adventureworks pu                 postgres    
## 14 adventureworks purchasing         postgres    
## 15 adventureworks sa                 postgres    
## 16 adventureworks sales              postgres
```

Schemas will be discussed later on because multiple schemas are the norm in an enterprise database environment, but they are a side issue at this point.  So we switch the order in which PostgreSQL searches for objects with the following SQL code:

```r
dbExecute(con, "set search_path to humanresources, public;")
```

```
## [1] 0
```
With the custom `search_path`, the following command works, but it will fail without out it.

```r
dbListTables(con)
```

```
##  [1] "shift"                      "employee"                  
##  [3] "jobcandidate"               "vemployee"                 
##  [5] "vemployeedepartment"        "vemployeedepartmenthistory"
##  [7] "vjobcandidate"              "vjobcandidateeducation"    
##  [9] "vjobcandidateemployment"    "department"                
## [11] "employeedepartmenthistory"  "employeepayhistory"
```
Same for `dbListFields`:

```r
dbListFields(con, "employee")
```

```
##  [1] "businessentityid" "nationalidnumber" "loginid"         
##  [4] "jobtitle"         "birthdate"        "maritalstatus"   
##  [7] "gender"           "hiredate"         "salariedflag"    
## [10] "vacationhours"    "sickleavehours"   "currentflag"     
## [13] "rowguid"          "modifieddate"     "organizationnode"
```

Thus with this search order, the following two produce identical results:

```r
tbl(con, in_schema("humanresources", "employee")) %>%
  head()
```

```
## # Source:   lazy query [?? x 15]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##   businessentityid nationalidnumber loginid jobtitle birthdate 
##              <int> <chr>            <chr>   <chr>    <date>    
## 1                1 295847284        "adven… Chief E… 1969-01-29
## 2                2 245797967        "adven… Vice Pr… 1971-08-01
## 3                3 509647174        "adven… Enginee… 1974-11-12
## 4                4 112457891        "adven… Senior … 1974-12-23
## 5                5 695256908        "adven… Design … 1952-09-27
## 6                6 998320692        "adven… Design … 1959-03-11
## # … with 10 more variables: maritalstatus <chr>, gender <chr>,
## #   hiredate <date>, salariedflag <lgl>, vacationhours <int>,
## #   sickleavehours <int>, currentflag <lgl>, rowguid <chr>,
## #   modifieddate <dttm>, organizationnode <chr>
```

```r
tbl(con, "employee") %>%
  head()
```

```
## # Source:   lazy query [?? x 15]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##   businessentityid nationalidnumber loginid jobtitle birthdate 
##              <int> <chr>            <chr>   <chr>    <date>    
## 1                1 295847284        "adven… Chief E… 1969-01-29
## 2                2 245797967        "adven… Vice Pr… 1971-08-01
## 3                3 509647174        "adven… Enginee… 1974-11-12
## 4                4 112457891        "adven… Senior … 1974-12-23
## 5                5 695256908        "adven… Design … 1952-09-27
## 6                6 998320692        "adven… Design … 1959-03-11
## # … with 10 more variables: maritalstatus <chr>, gender <chr>,
## #   hiredate <date>, salariedflag <lgl>, vacationhours <int>,
## #   sickleavehours <int>, currentflag <lgl>, rowguid <chr>,
## #   modifieddate <dttm>, organizationnode <chr>
```


Disconnect from the database:

```r
dbDisconnect(con)
```
## Stop and start to demonstrate persistence

Stop the container:

```r
sp_docker_stop("adventureworks")
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
## # A tibble: 2 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
## 1 f465fab9741b post… docker… 2019-07-1… 13 sec… <NA>  Exite… 0B (… adve…
## 2 dee42b174456 post… docker… 2019-06-1… 4 week… <NA>  Exite… 0B (… hrsa…
## # … with 3 more variables: labels <chr>, mounts <chr>, networks <chr>
```


Restart the container and verify that the adventureworks tables are still there:

```r
sp_docker_start("adventureworks")
sp_docker_containers_tibble()
```

```
## # A tibble: 1 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
## 1 f465fab9741b post… docker… 2019-07-1… 14 sec… 0.0.… Up Le… 63B … adve…
## # … with 3 more variables: labels <chr>, mounts <chr>, networks <chr>
```
Connect to the `adventureworks` database in PostgreSQL:

```r
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "adventureworks",
  seconds_to_test = 30
)
```

Check that you can still see the first few rows of the `employeeinfo` table:

```r
tbl(con, in_schema("humanresources", "employee")) %>%
  head()
```

```
## # Source:   lazy query [?? x 15]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##   businessentityid nationalidnumber loginid jobtitle birthdate 
##              <int> <chr>            <chr>   <chr>    <date>    
## 1                1 295847284        "adven… Chief E… 1969-01-29
## 2                2 245797967        "adven… Vice Pr… 1971-08-01
## 3                3 509647174        "adven… Enginee… 1974-11-12
## 4                4 112457891        "adven… Senior … 1974-12-23
## 5                5 695256908        "adven… Design … 1952-09-27
## 6                6 998320692        "adven… Design … 1959-03-11
## # … with 10 more variables: maritalstatus <chr>, gender <chr>,
## #   hiredate <date>, salariedflag <lgl>, vacationhours <int>,
## #   sickleavehours <int>, currentflag <lgl>, rowguid <chr>,
## #   modifieddate <dttm>, organizationnode <chr>
```

## Cleaning up

Always have R disconnect from the database when you're done.

```r
dbDisconnect(con)
```

Stop the `sql-pet` container:

```r
sp_docker_stop("adventureworks")
```
Show that the container still exists even though it's not running


```r
sp_show_all_docker_containers()
```

```
## CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                              PORTS               NAMES
## f465fab9741b        postgres:10         "docker-entrypoint.s…"   15 seconds ago      Exited (0) Less than a second ago                       adventureworks
## dee42b174456        postgres:10         "docker-entrypoint.s…"   4 weeks ago         Exited (0) 2 weeks ago                                  hrsample
```

Next time, you can just use this command to start the container: 

> `sp_docker_start("adventureworks")`

And once stopped, the container can be removed with:

> `sp_check_that_docker_is_up("adventureworks")`

## Using the `sql-pet` container in the rest of the book

After this point in the book, we assume that Docker is up and that we can always start up our *sql-pet database* with:

> `sp_docker_start("adventureworks")`

