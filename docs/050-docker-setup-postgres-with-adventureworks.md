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
## Build the adventureworks Docker image

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
## 1 1523f751… adventurewo… latest <none>           6 week… 2019-06-19 … 475MB
## 2 602a8e50… <none>       <none> <none>           6 week… 2019-06-19 … 365MB
## 3 4e045cb8… postgres     latest sha256:1518027f… 7 week… 2019-06-10 … 312MB
## 4 aff06852… postgres-dv… latest <none>           3 mont… 2019-04-26 … 294MB
## 5 c149455a… <none>       <none> <none>           4 mont… 2019-03-18 … 252MB
## 6 3e016ba4… postgres     10     sha256:5c702997… 5 mont… 2019-03-04 … 230MB
```

## Run the adventureworks Docker Image
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
## 1 a6bbd6156e97 post… docker… 2019-08-0… 15 sec… 0.0.… Up 13… 63B … adve…
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
For the moment we by-pass some complexity that results from the fact that the `adventureworks` database has multiple *schemas* and that we are interested in only one of them, named `information_schema`.  

```r
tbl(con, in_schema("information_schema", "schemata")) %>%
  select(catalog_name, schema_name, schema_owner) %>%
  collect()
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
dbExecute(con, "set search_path to sales, public;")
```

```
## [1] 0
```
With the custom `search_path`, the following command works, but it will fail without out it.

```r
dbListTables(con)
```

```
##  [1] "currency"                          
##  [2] "salesorderheader"                  
##  [3] "store"                             
##  [4] "specialoffer"                      
##  [5] "customer"                          
##  [6] "personcreditcard"                  
##  [7] "salesorderheadersalesreason"       
##  [8] "shoppingcartitem"                  
##  [9] "salesorderdetail"                  
## [10] "creditcard"                        
## [11] "specialofferproduct"               
## [12] "salestaxrate"                      
## [13] "salesperson"                       
## [14] "vindividualcustomer"               
## [15] "vpersondemographics"               
## [16] "vsalesperson"                      
## [17] "vsalespersonsalesbyfiscalyears"    
## [18] "vsalespersonsalesbyfiscalyearsdata"
## [19] "vstorewithaddresses"               
## [20] "vstorewithcontacts"                
## [21] "vstorewithdemographics"            
## [22] "salespersonquotahistory"           
## [23] "currencyrate"                      
## [24] "countryregioncurrency"             
## [25] "salesreason"                       
## [26] "salesterritory"                    
## [27] "salesterritoryhistory"
```
Same for `dbListFields`:

```r
dbListFields(con, "salesperson")
```

```
## [1] "businessentityid" "territoryid"      "salesquota"      
## [4] "bonus"            "commissionpct"    "salesytd"        
## [7] "saleslastyear"    "rowguid"          "modifieddate"
```

Thus with this search order, the following two produce identical results:

```r
tbl(con, in_schema("sales", "salesperson")) %>%
  head()
```

```
## # Source:   lazy query [?? x 9]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##   businessentityid territoryid salesquota bonus commissionpct salesytd
##              <int>       <int>      <dbl> <dbl>         <dbl>    <dbl>
## 1              274          NA         NA     0         0      559698.
## 2              275           2     300000  4100         0.012 3763178.
## 3              276           4     250000  2000         0.015 4251369.
## 4              277           3     250000  2500         0.015 3189418.
## 5              278           6     250000   500         0.01  1453719.
## 6              279           5     300000  6700         0.01  2315186.
## # … with 3 more variables: saleslastyear <dbl>, rowguid <chr>,
## #   modifieddate <dttm>
```

```r
tbl(con, "salesperson") %>%
  head()
```

```
## # Source:   lazy query [?? x 9]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##   businessentityid territoryid salesquota bonus commissionpct salesytd
##              <int>       <int>      <dbl> <dbl>         <dbl>    <dbl>
## 1              274          NA         NA     0         0      559698.
## 2              275           2     300000  4100         0.012 3763178.
## 3              276           4     250000  2000         0.015 4251369.
## 4              277           3     250000  2500         0.015 3189418.
## 5              278           6     250000   500         0.01  1453719.
## 6              279           5     300000  6700         0.01  2315186.
## # … with 3 more variables: saleslastyear <dbl>, rowguid <chr>,
## #   modifieddate <dttm>
```

## `dplyr` connection objects
As introduced in the previous chapter, the `dplyr::tbl` function creates an object that might **look** like a data frame in that when you enter it on the command line, it prints a bunch of rows from the dbms table.  But it is actually a **list** object that `dplyr` uses for constructing queries and retrieving data from the DBMS.  

The following code illustrates these issues.  The `dplyr::tbl` function creates the connection object that we store in an object named `person_table`:

```r
person_table <- dplyr::tbl(con, in_schema("person", "person")) %>% 
  select(-rowguid) %>% 
  rename(personal_details_updated = modifieddate)
```

At first glance, it _acts_ like a data frame when you print it, although it only prints 10 of the table's 1,000 rows:

```r
person_table
```

```
## # Source:   lazy query [?? x 12]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##    businessentityid persontype namestyle title firstname middlename
##               <int> <chr>      <lgl>     <chr> <chr>     <chr>     
##  1                1 EM         FALSE     <NA>  Ken       J         
##  2                2 EM         FALSE     <NA>  Terri     Lee       
##  3                3 EM         FALSE     <NA>  Roberto   <NA>      
##  4                4 EM         FALSE     <NA>  Rob       <NA>      
##  5                5 EM         FALSE     Ms.   Gail      A         
##  6                6 EM         FALSE     Mr.   Jossef    H         
##  7                7 EM         FALSE     <NA>  Dylan     A         
##  8                8 EM         FALSE     <NA>  Diane     L         
##  9                9 EM         FALSE     <NA>  Gigi      N         
## 10               10 EM         FALSE     <NA>  Michael   <NA>      
## # … with more rows, and 6 more variables: lastname <chr>, suffix <chr>,
## #   emailpromotion <int>, additionalcontactinfo <chr>, demographics <chr>,
## #   personal_details_updated <dttm>
```

However, notice that the first output line shows `??`, rather than providing the number of rows in the table. Similarly, the next to last line shows:
```
    … with more rows, and 8 more variables
```
whereas the output for a normal `tbl` of this film data would say:
```
    … with more 1,000, and 8 more variables
```

So even though `person_table` is a `tbl`, it's **also** a `tbl_PqConnection`:

```r
class(person_table)
```

```
## [1] "tbl_PqConnection" "tbl_dbi"          "tbl_sql"         
## [4] "tbl_lazy"         "tbl"
```

It is not just a normal `tbl` of data. We can see that from the structure of `person_table`:

```r
str(person_table)
```

```
## List of 2
##  $ src:List of 2
##   ..$ con  :Formal class 'PqConnection' [package "RPostgres"] with 3 slots
##   .. .. ..@ ptr     :<externalptr> 
##   .. .. ..@ bigint  : chr "integer64"
##   .. .. ..@ typnames:'data.frame':	785 obs. of  2 variables:
##   .. .. .. ..$ oid    : int [1:785] 16 17 18 19 20 21 22 23 24 25 ...
##   .. .. .. ..$ typname: chr [1:785] "bool" "bytea" "char" "name" ...
##   ..$ disco: NULL
##   ..- attr(*, "class")= chr [1:4] "src_PqConnection" "src_dbi" "src_sql" "src"
##  $ ops:List of 4
##   ..$ name: chr "select"
##   ..$ x   :List of 2
##   .. ..$ x   : 'ident_q' chr "person.person"
##   .. ..$ vars: chr [1:13] "businessentityid" "persontype" "namestyle" "title" ...
##   .. ..- attr(*, "class")= chr [1:3] "op_base_remote" "op_base" "op"
##   ..$ dots: list()
##   ..$ args:List of 1
##   .. ..$ vars:List of 12
##   .. .. ..$ businessentityid        : symbol businessentityid
##   .. .. ..$ persontype              : symbol persontype
##   .. .. ..$ namestyle               : symbol namestyle
##   .. .. ..$ title                   : symbol title
##   .. .. ..$ firstname               : symbol firstname
##   .. .. ..$ middlename              : symbol middlename
##   .. .. ..$ lastname                : symbol lastname
##   .. .. ..$ suffix                  : symbol suffix
##   .. .. ..$ emailpromotion          : symbol emailpromotion
##   .. .. ..$ additionalcontactinfo   : symbol additionalcontactinfo
##   .. .. ..$ demographics            : symbol demographics
##   .. .. ..$ personal_details_updated: symbol modifieddate
##   ..- attr(*, "class")= chr [1:3] "op_select" "op_single" "op"
##  - attr(*, "class")= chr [1:5] "tbl_PqConnection" "tbl_dbi" "tbl_sql" "tbl_lazy" ...
```

It has only _two_ rows!  The first row contains all the information in the `con` object, which contains information about all the tables and objects in the database:

```r
person_table$src$con@typnames$typname[380:437]
```

```
##  [1] "tablefunc_crosstab_4"            "_tablefunc_crosstab_4"          
##  [3] "AccountNumber"                   "Flag"                           
##  [5] "Name"                            "NameStyle"                      
##  [7] "OrderNumber"                     "Phone"                          
##  [9] "department"                      "_department"                    
## [11] "pg_toast_16433"                  "d"                              
## [13] "_d"                              "employee"                       
## [15] "_employee"                       "pg_toast_16444"                 
## [17] "e"                               "_e"                             
## [19] "employeedepartmenthistory"       "_employeedepartmenthistory"     
## [21] "edh"                             "_edh"                           
## [23] "employeepayhistory"              "_employeepayhistory"            
## [25] "pg_toast_16476"                  "eph"                            
## [27] "_eph"                            "jobcandidate"                   
## [29] "_jobcandidate"                   "pg_toast_16489"                 
## [31] "jc"                              "_jc"                            
## [33] "shift"                           "_shift"                         
## [35] "pg_toast_16500"                  "s"                              
## [37] "_s"                              "department_departmentid_seq"    
## [39] "jobcandidate_jobcandidateid_seq" "shift_shiftid_seq"              
## [41] "address"                         "_address"                       
## [43] "businessentityaddress"           "_businessentityaddress"         
## [45] "countryregion"                   "_countryregion"                 
## [47] "pg_toast_16527"                  "emailaddress"                   
## [49] "_emailaddress"                   "person"                         
## [51] "_person"                         "pg_toast_16539"                 
## [53] "personphone"                     "_personphone"                   
## [55] "pg_toast_16551"                  "phonenumbertype"                
## [57] "_phonenumbertype"                "pg_toast_16558"
```
The second row contains a list of the columns in the `film` table, among other things:

```r
person_table$ops$vars
```

```
## NULL
```
`person_table` holds information needed to get the data from the 'film' table, but `person_table` does not hold the data itself. In the following sections, we will examine more closely this relationship between the `person_table` object and the data in the database's 'film' table.

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

When we stopped `adventureworks`, it no longer appeared in the tibble. But the
container is still there. `sp_docker_containers_tibble` by default only lists
the *running* containers. But we can use the `list_all` option and see it:


```r
sp_docker_containers_tibble(list_all = TRUE)
```

```
## # A tibble: 1 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
## 1 a6bbd6156e97 post… docker… 2019-08-0… 16 sec… <NA>  Exite… 0B (… adve…
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
## 1 a6bbd6156e97 post… docker… 2019-08-0… 17 sec… 0.0.… Up Le… 0B (… adve…
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
tbl(con, in_schema("sales", "salesperson")) %>%
  head()
```

```
## # Source:   lazy query [?? x 9]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##   businessentityid territoryid salesquota bonus commissionpct salesytd
##              <int>       <int>      <dbl> <dbl>         <dbl>    <dbl>
## 1              274          NA         NA     0         0      559698.
## 2              275           2     300000  4100         0.012 3763178.
## 3              276           4     250000  2000         0.015 4251369.
## 4              277           3     250000  2500         0.015 3189418.
## 5              278           6     250000   500         0.01  1453719.
## 6              279           5     300000  6700         0.01  2315186.
## # … with 3 more variables: saleslastyear <dbl>, rowguid <chr>,
## #   modifieddate <dttm>
```

## Cleaning up

Always have R disconnect from the database when you're done.

```r
dbDisconnect(con)
```

Stop the `adventureworks` container:

```r
sp_docker_stop("adventureworks")
```
Show that the container still exists even though it's not running


```r
sp_show_all_docker_containers()
```

```
## CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                              PORTS               NAMES
## a6bbd6156e97        postgres:10         "docker-entrypoint.s…"   19 seconds ago      Exited (0) Less than a second ago                       adventureworks
```

Next time, you can just use this command to start the container: 

> `sp_docker_start("adventureworks")`

And once stopped, the container can be removed with:

> `sp_check_that_docker_is_up("adventureworks")`

## Using the `adventureworks` container in the rest of the book

After this point in the book, we assume that Docker is up and that we can always start up our *adventureworks database* with:

> `sp_docker_start("adventureworks")`

