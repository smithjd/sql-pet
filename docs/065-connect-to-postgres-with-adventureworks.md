# Connect to the adventureworks database in PostgreSQL{#chapter_connect-to-adventureworks-db}

> This chapter demonstrates how to:
>
>  * Create and connect to the PostgreSQL `adventureworks` database in Docker
>  * Keep necessary credentials secret while being available to R when it executes.
>  * Connect to and disconnect R from the `adventureworks` database
>  * Set up the environment for subsequent chapters

## Overview

Docker commands can be run from a terminal (e.g., the Rstudio Terminal pane) or with a `system2()` command.  The necessary functions to start, stop Docker containers and do other busy work are provided in the `sqlpetr` package.  

> Note: The functions in the package are designed to help you focus on interacting with a dbms from R.  You can ignore how they work until you are ready to delve into the details.  They are all named to begin with `sp_`.  The first time a function is called in the book, we provide a note explaining its use.


Please install the `sqlpetr` package if not already installed:

```r
library(devtools)
if (!require(sqlpetr)) {
    remotes::install_github(
      "smithjd/sqlpetr",
      force = TRUE, build = FALSE, quiet = TRUE)
}
```
Note that when you install this package the first time, it will ask you to update the packages it uses and that may take some time.

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

## Verify that Docker is up, running, and clean up if necessary

> The `sp_check_that_docker_is_up` function from the `sqlpetr` package checks whether Docker is up and running.  If it's not, then you need to install, launch or re-install Docker.


```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up but running no containers"
```


```r
sp_docker_start("adventureworks")
```


## Connect to PostgreSQL with R

*CHECK for `sqlpetr` update!`  The `sp_make_simple_pg` function we called above created a container from the
`postgres:11` library image downloaded from Docker Hub. As part of the process, it set the password for the PostgreSQL database superuser `postgres` to the value 
"postgres".

For simplicity, we are using a weak password at this point and it's shown here 
and in the code in plain text. That is bad practice because user credentials 
should not be shared in open code like that.  A [subsequent chapter](#dbms-login)
demonstrates how to store and use credentials to access the DBMS so that they 
are kept private.

> The `sp_get_postgres_connection` function from the `sqlpetr` package gets a DBI connection string to a PostgreSQL database, waiting if it is not ready. This function connects to an instance of PostgreSQL and we assign it to a symbol, `con`, for subsequent use. The `connctions_tab = TRUE` parameter opens a connections tab that's useful for navigating a database.

> Note that we are using port *5439* for PostgreSQL inside the container and published to `localhost`. Why? If you have PostgreSQL already running on the host or another container, it probably claimed port 5432, since that's the default. So we need to use a different port for *our* PostgreSQL container.

Use the DBI package to connect to the `adventureworks` database in PostgreSQL.  Remember the settings discussion about [keeping passwords hidden][Pause for some security considerations]


```r
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,  # this version still using 5432!!!
  user = "postgres",
  password = "postgres",
  dbname = "adventureworks",
  seconds_to_test = 20, connection_tab = TRUE
)
```
That's equivalent to excuting this code to download the table from the DBMS to a local data frame:

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
##  1 adventureworks sales              postgres    
##  2 adventureworks sa                 postgres    
##  3 adventureworks purchasing         postgres    
##  4 adventureworks pu                 postgres    
##  5 adventureworks production         postgres    
##  6 adventureworks pr                 postgres    
##  7 adventureworks person             postgres    
##  8 adventureworks pe                 postgres    
##  9 adventureworks humanresources     postgres    
## 10 adventureworks hr                 postgres    
## 11 adventureworks information_schema postgres    
## 12 adventureworks public             postgres    
## 13 adventureworks pg_catalog         postgres    
## 14 adventureworks pg_toast_temp_1    postgres    
## 15 adventureworks pg_temp_1          postgres    
## 16 adventureworks pg_toast           postgres
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
##  [1] "countryregioncurrency"             
##  [2] "customer"                          
##  [3] "currencyrate"                      
##  [4] "creditcard"                        
##  [5] "personcreditcard"                  
##  [6] "specialoffer"                      
##  [7] "specialofferproduct"               
##  [8] "salesorderheadersalesreason"       
##  [9] "shoppingcartitem"                  
## [10] "salespersonquotahistory"           
## [11] "salesperson"                       
## [12] "currency"                          
## [13] "store"                             
## [14] "salesorderheader"                  
## [15] "salesorderdetail"                  
## [16] "salesreason"                       
## [17] "salesterritoryhistory"             
## [18] "vindividualcustomer"               
## [19] "vpersondemographics"               
## [20] "vsalesperson"                      
## [21] "vsalespersonsalesbyfiscalyears"    
## [22] "vsalespersonsalesbyfiscalyearsdata"
## [23] "vstorewithaddresses"               
## [24] "vstorewithcontacts"                
## [25] "vstorewithdemographics"            
## [26] "salestaxrate"                      
## [27] "salesterritory"
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
##   .. .. ..@ typnames:'data.frame':	796 obs. of  2 variables:
##   .. .. .. ..$ oid    : int [1:796] 16 17 18 19 20 21 22 23 24 25 ...
##   .. .. .. ..$ typname: chr [1:796] "bool" "bytea" "char" "name" ...
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
##  [1] "user_mappings"                   "tablefunc_crosstab_2"           
##  [3] "_tablefunc_crosstab_2"           "tablefunc_crosstab_3"           
##  [5] "_tablefunc_crosstab_3"           "tablefunc_crosstab_4"           
##  [7] "_tablefunc_crosstab_4"           "AccountNumber"                  
##  [9] "_AccountNumber"                  "Flag"                           
## [11] "_Flag"                           "Name"                           
## [13] "_Name"                           "NameStyle"                      
## [15] "_NameStyle"                      "OrderNumber"                    
## [17] "_OrderNumber"                    "Phone"                          
## [19] "_Phone"                          "department"                     
## [21] "_department"                     "pg_toast_16439"                 
## [23] "d"                               "_d"                             
## [25] "employee"                        "_employee"                      
## [27] "pg_toast_16450"                  "e"                              
## [29] "_e"                              "employeedepartmenthistory"      
## [31] "_employeedepartmenthistory"      "edh"                            
## [33] "_edh"                            "employeepayhistory"             
## [35] "_employeepayhistory"             "pg_toast_16482"                 
## [37] "eph"                             "_eph"                           
## [39] "jobcandidate"                    "_jobcandidate"                  
## [41] "pg_toast_16495"                  "jc"                             
## [43] "_jc"                             "shift"                          
## [45] "_shift"                          "pg_toast_16506"                 
## [47] "s"                               "_s"                             
## [49] "department_departmentid_seq"     "jobcandidate_jobcandidateid_seq"
## [51] "shift_shiftid_seq"               "address"                        
## [53] "_address"                        "businessentityaddress"          
## [55] "_businessentityaddress"          "countryregion"                  
## [57] "_countryregion"                  "pg_toast_16533"
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
## # A tibble: 2 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
## 1 45eff02a8ccf post… docker… 2019-08-0… 27 sec… <NA>  Exite… 0B (… adve…
## 2 185a8e082757 post… docker… 2019-08-0… 23 hou… <NA>  Exite… 63B … adv11
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
## 1 45eff02a8ccf post… docker… 2019-08-0… 29 sec… 0.0.… Up Le… 63B … adve…
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
## 45eff02a8ccf        postgres:11         "docker-entrypoint.s…"   29 seconds ago      Exited (0) Less than a second ago                       adventureworks
## 185a8e082757        postgres:11         "docker-entrypoint.s…"   23 hours ago        Exited (137) 23 hours ago                               adv11
```

Next time, you can just use this command to start the container: 

> `sp_docker_start("adventureworks")`

And once stopped, the container can be removed with:

> `sp_check_that_docker_is_up("adventureworks")`

## Using the `adventureworks` container in the rest of the book

After this point in the book, we assume that Docker is up and that we can always start up our *adventureworks database* with:

> `sp_docker_start("adventureworks")`

